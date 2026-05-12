import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../pages/appointments/appointment_detail_page.dart';
import 'doctor_api_service.dart';
import 'doctor_auth_storage.dart';
import 'notification_store.dart';

class NotificationService {
  NotificationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> init() async {
    try {
      await FirebaseMessaging.instance.requestPermission();

      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[NotificationService] current FCM token: $token');
      if (token != null) {
        await _updateTokenIfLoggedIn(token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        debugPrint('[NotificationService] FCM token refreshed: $token');
        _updateTokenIfLoggedIn(token);
      });

      FirebaseMessaging.onMessage.listen((message) async {
        await _handleIncomingMessage(message, opened: false);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        await _handleIncomingMessage(message, opened: true);
      });

      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        await _handleIncomingMessage(initialMessage, opened: true);
      }
    } catch (error) {
      debugPrint('[NotificationService] init failed: $error');
    }
  }

  static Future<void> syncTokenAfterLogin() async {
    debugPrint(
      '\n\n════════════════════════════════════════════════════════════',
    );
    debugPrint('🔔 NOTIFICATION SERVICE - SYNC TOKEN AFTER LOGIN');
    debugPrint('════════════════════════════════════════════════════════════');

    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('📱 Firebase FCM Token: $token');
    debugPrint('🔍 Token is null: ${token == null}');
    debugPrint('🔍 Token length: ${token?.length ?? 0}');

    if (token == null) {
      debugPrint('❌ No FCM token available after login');
      debugPrint(
        '════════════════════════════════════════════════════════════\n\n',
      );
      return;
    }

    await _updateTokenIfLoggedIn(token);
    debugPrint(
      '════════════════════════════════════════════════════════════\n\n',
    );
  }

  static Future<void> _updateTokenIfLoggedIn(String token) async {
    final currentToken = await DoctorAuthStorage.getToken();

    debugPrint(
      '\n🔐 JWT Token stored: ${currentToken != null ? '✅ YES' : '❌ NO'}',
    );

    if (currentToken == null) {
      debugPrint('❌ Not logged in, skipping token update');
      return;
    }

    try {
      debugPrint('📤 Sending FCM token to backend...');
      final response = await DoctorApiService.updateFcmToken(fcmToken: token);
      debugPrint('✅ updateFcmToken status: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Backend successfully saved FCM token');
      } else {
        debugPrint('❌ Backend error: ${response.body}');
      }
    } catch (error) {
      debugPrint('❌ Token update error: $error');
    }
  }

  static Future<void> _handleIncomingMessage(
    RemoteMessage message, {
    bool opened = false,
  }) async {
    debugPrint(
      '[NotificationService] handleIncomingMessage opened=$opened data=${message.data}',
    );
    await _saveNotification(message);

    if (opened) {
      await _openNotificationFromMessage(message);
    } else {
      _showNotificationBanner(message);
    }
  }

  static Future<void> _openNotificationFromMessage(
    RemoteMessage message,
  ) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[NotificationService] navigator state is null');
      return;
    }

    var title = message.notification?.title ?? 'Booking details';
    var body =
        message.notification?.body ??
        message.data['message'] ??
        'You have a new booking update.';
    var patientName = message.data['patientName'] as String?;
    var status = message.data['status'] as String? ?? 'Pending';

    DateTime? appointmentTime;
    final rawDate = message.data['date']?.toString();
    final rawTime = message.data['time']?.toString();
    if (rawDate != null && rawTime != null) {
      try {
        if (RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(rawDate) &&
            RegExp(r'(AM|PM|am|pm)').hasMatch(rawTime)) {
          appointmentTime = DateFormat(
            'yyyy-MM-dd hh:mm a',
          ).parse('$rawDate $rawTime');
        } else {
          appointmentTime = DateTime.parse('$rawDate $rawTime');
        }
      } catch (_) {
        appointmentTime = null;
      }
    }

    final bookingId = message.data['bookingId']?.toString();
    if (bookingId != null && bookingId.isNotEmpty) {
      try {
        final response = await DoctorApiService.getDoctorBookingById(
          bookingId: bookingId,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final booking = data['booking'] as Map<String, dynamic>?;
          if (booking != null) {
            final user = booking['userId'] as Map<String, dynamic>?;
            final treatment = booking['treatment'] as Map<String, dynamic>?;
            final patient = user?['name'] as String?;
            final rawBookingDate = treatment?['date']?.toString();
            final rawBookingTime = treatment?['time']?.toString();
            if (patient != null) {
              patientName = patient;
            }
            if (rawBookingDate != null && rawBookingTime != null) {
              try {
                appointmentTime = DateTime.parse('$rawBookingDate $rawBookingTime');
              } catch (_) {
                appointmentTime = appointmentTime;
              }
            }
            status = (booking['status'] as String?) ?? status;
            body = booking['treatment'] != null
                ? 'Treatment request: ${treatment?['type'] ?? 'N/A'}'
                : body;
            title = booking['visitType'] != null
                ? 'Appointment request (${booking['visitType']})'
                : title;
          }
        }
      } catch (error) {
        debugPrint('[NotificationService] failed to load booking detail: $error');
      }
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => AppointmentDetailPage(
          title: title,
          message: body,
          patientName: patientName,
          appointmentTime: appointmentTime,
          status: status,
        ),
      ),
    );
  }

  static Future<void> _saveNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? 'New booking notification';
    final body =
        message.notification?.body ??
        message.data['message'] ??
        'You have a new booking update.';
    final id =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    await NotificationStore.addNotification(
      NotificationItem(
        id: id,
        title: title,
        message: body,
        at: DateTime.now(),
        read: false,
      ),
    );
  }

  static void _showNotificationBanner(RemoteMessage message) {
    final context = navigatorKey.currentState?.context;
    if (context == null) {
      debugPrint('[NotificationService] navigator context is null');
      return;
    }

    final title = message.notification?.title ?? 'New notification';
    final body =
        message.notification?.body ??
        message.data['message'] ??
        'You have a new booking update.';
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (messenger == null) {
      debugPrint('[NotificationService] ScaffoldMessenger not found');
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(color: Colors.white)),
          ],
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _openNotificationFromMessage(message),
        ),
      ),
    );
  }
}
