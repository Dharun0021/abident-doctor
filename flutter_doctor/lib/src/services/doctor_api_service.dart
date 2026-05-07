import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/doctor_auth_storage.dart';

class DoctorApiService {
  DoctorApiService._();

  static Future<String?> _readFcmToken() async {
    try {
      return FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  static Future<http.Response> register({
    required String name,
    required String email,
    required String password,
    required String specialization,
  }) async {
    final fcmToken = await _readFcmToken();

    return http.post(
      Uri.parse(AppConfig.doctorRegisterUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'specialization': specialization.trim(),
        if (fcmToken != null) 'fcmToken': fcmToken,
      }),
    );
  }

  static Future<http.Response> login({
    required String email,
    required String password,
  }) async {
    final fcmToken = await _readFcmToken();

    return http.post(
      Uri.parse(AppConfig.doctorLoginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        if (fcmToken != null) 'fcmToken': fcmToken,
      }),
    );
  }

  static Future<http.Response> updateProfile({
    String? name,
    String? email,
    String? specialization,
    String? password,
  }) async {
    final token = await DoctorAuthStorage.getToken();

    return http.put(
      Uri.parse(AppConfig.doctorProfileUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (name != null) 'name': name.trim(),
        if (email != null) 'email': email.trim(),
        if (specialization != null) 'specialization': specialization.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
      }),
    );
  }

  // Availability endpoints
  static Future<http.Response> createAvailability({
    required DateTime date,
    required String startTime,
    required String endTime,
    required int duration,
  }) async {
    final token = await DoctorAuthStorage.getToken();

    return http.post(
      Uri.parse(AppConfig.availabilityCreateUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'date': date.toIso8601String().split('T')[0],
        'startTime': startTime,
        'endTime': endTime,
        'duration': duration,
      }),
    );
  }

  /// Sends all slots in one request as:
  /// { date, slots: { slot1: { startTime, endTime }, slot2: {...}, ... } }
  static Future<http.Response> createBulkAvailability({
    required DateTime date,
    required List<Map<String, String>> slots,
  }) async {
    final token = await DoctorAuthStorage.getToken();

    final slotsMap = <String, dynamic>{};
    for (int i = 0; i < slots.length; i++) {
      slotsMap['slot${i + 1}'] = slots[i];
    }

    return http.post(
      Uri.parse(AppConfig.availabilityBulkCreateUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'date': date.toIso8601String().split('T')[0],
        'slots': slotsMap,
      }),
    );
  }

  static Future<http.Response> getAvailabilities() async {
    final token = await DoctorAuthStorage.getToken();

    return http.get(
      Uri.parse(AppConfig.availabilityListUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  static Future<http.Response> updateAvailability({
    required String availabilityId,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? duration,
    bool? isAvailable,
  }) async {
    final token = await DoctorAuthStorage.getToken();

    return http.put(
      Uri.parse('${AppConfig.baseUrl}/api/availability/$availabilityId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (date != null) 'date': date.toIso8601String().split('T')[0],
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (duration != null) 'duration': duration,
        if (isAvailable != null) 'isAvailable': isAvailable,
      }),
    );
  }

  static Future<http.Response> deleteAvailability({
    required String availabilityId,
  }) async {
    final token = await DoctorAuthStorage.getToken();

    return http.delete(
      Uri.parse('${AppConfig.baseUrl}/api/availability/$availabilityId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
