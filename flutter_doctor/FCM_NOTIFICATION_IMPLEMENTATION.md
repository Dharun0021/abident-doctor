# FCM Notification Implementation Guide for Abident Doctor App

This document explains the full Firebase Cloud Messaging (FCM) notification implementation used by the doctor app, including credentials, Flutter code, backend storage, and server-side delivery.

## 1. Firebase Credentials & Setup

### 1.1 Create / Register the Doctor Android App

1. Open Firebase Console: https://console.firebase.google.com/
2. Select your Firebase project, e.g. `abidant`.
3. Go to Project Settings > Your apps.
4. Add a new Android app if the doctor app is not already registered.
   - Package name: `com.example.flutter_doctor`
   - App nickname: `Flutter Doctor`
   - SHA-1 fingerprint: optional for FCM, but helpful for auth and other services.
5. Download `google-services.json`.
6. Copy it to the doctor app project at:
   - `abident_doctor/flutter_doctor/android/app/google-services.json`

### 1.2 Android Gradle / Plugin Configuration

In `android/build.gradle.kts` make sure you have:

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services") version "4.4.0" apply false
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

In `android/app/build.gradle.kts` make sure you apply:

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
```

### 1.3 Android Permissions

Add FCM permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 1.4 Firebase Service Account for Backend

For sending notifications from the backend, use a Firebase service account JSON.

1. In Firebase Console, go to Project Settings > Service accounts.
2. Generate a new private key.
3. Download the JSON file.
4. Place it in the backend project at `abident_backend/config/serviceAccountKey.json`, or set environment variables:
   - `FIREBASE_SERVICE_ACCOUNT_PATH`
   - or `FIREBASE_SERVICE_ACCOUNT_JSON`

## 2. Flutter App FCM Setup

### 2.1 Dependencies

Add these packages to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.0.0
  firebase_messaging: ^14.0.0
  http: ^0.13.0
```

Then run:

```bash
flutter pub get
```

### 2.2 Initialize Firebase and Notification Service

In `lib/main.dart`, initialize Firebase and FCM before running the app:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'src/services/notification_service.dart';
import 'src/services/notification_store.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FirebaseBackground] message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await NotificationStore.init();
  await NotificationService.init();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const DoctorApp());
}
```

### 2.3 NotificationService Overview

This file contains the main FCM logic in the doctor app:

- Request permission for notifications.
- Fetch the FCM token.
- Sync the token with the backend via `POST /api/doctor/update-fcm-token`.
- Listen for foreground, background, and app-open notifications.
- Save incoming notifications locally.
- Show a UI banner for foreground messages.
- Open the booking detail screen when a notification is tapped.

### 2.4 Full `NotificationService` Implementation

```dart
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

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        await _handleIncomingMessage(initialMessage, opened: true);
      }
    } catch (error) {
      debugPrint('[NotificationService] init failed: $error');
    }
  }

  static Future<void> syncTokenAfterLogin() async {
    debugPrint('🔔 NOTIFICATION SERVICE - SYNC TOKEN AFTER LOGIN');

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) {
      debugPrint('❌ No FCM token available after login');
      return;
    }

    await _updateTokenIfLoggedIn(token);
  }

  static Future<void> _updateTokenIfLoggedIn(String token) async {
    final currentToken = await DoctorAuthStorage.getToken();
    if (currentToken == null) {
      return;
    }

    try {
      final response = await DoctorApiService.updateFcmToken(fcmToken: token);
      debugPrint('✅ updateFcmToken status: ${response.statusCode}');
    } catch (error) {
      debugPrint('❌ Token update error: $error');
    }
  }

  static Future<void> _handleIncomingMessage(RemoteMessage message, {bool opened = false}) async {
    debugPrint('[NotificationService] handleIncomingMessage opened=$opened data=${message.data}');
    await _saveNotification(message);

    if (opened) {
      await _openNotificationFromMessage(message);
    } else {
      _showNotificationBanner(message);
    }
  }

  static Future<void> _openNotificationFromMessage(RemoteMessage message) async {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    var title = message.notification?.title ?? 'Booking details';
    var body = message.notification?.body ?? message.data['message'] ?? 'You have a new booking update.';
    var patientName = message.data['patientName'] as String?;
    var status = message.data['status'] as String? ?? 'Pending';

    DateTime? appointmentTime;
    final rawDate = message.data['date']?.toString();
    final rawTime = message.data['time']?.toString();
    if (rawDate != null && rawTime != null) {
      try {
        if (RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(rawDate) && RegExp(r'(AM|PM|am|pm)').hasMatch(rawTime)) {
          appointmentTime = DateFormat('yyyy-MM-dd hh:mm a').parse('$rawDate $rawTime');
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
        final response = await DoctorApiService.getDoctorBookingById(bookingId: bookingId);

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
            title = booking['visitType'] != null ? 'Appointment request (${booking['visitType']})' : title;
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
    final body = message.notification?.body ?? message.data['message'] ?? 'You have a new booking update.';
    final id = message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

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
      return;
    }

    final title = message.notification?.title ?? 'New notification';
    final body = message.notification?.body ?? message.data['message'] ?? 'You have a new booking update.';
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      ),
    );
  }
}
```

### 2.5 How token syncing works

- `NotificationService.init()` gets the FCM token and updates backend if the doctor is logged in.
- When the user logs in or registers, the app calls `NotificationService.syncTokenAfterLogin()`.
- The backend endpoint `POST /api/doctor/update-fcm-token` stores the token on the doctor document.
- The app sends the token with a bearer JWT authorization header.

## 3. Doctor API Service

This service sends the FCM token to the backend and also fetches booking data.

### 3.1 Relevant API endpoints in `AppConfig`

```dart
static const String doctorUpdateFcmTokenEndpoint = '/api/doctor/update-fcm-token';
static const String doctorRespondBookingEndpoint = '/api/doctor/respond';
static const String doctorBookingsEndpoint = '/api/booking/doctor';
```

### 3.2 Update FCM token method

```dart
static Future<http.Response> updateFcmToken({
  required String fcmToken,
}) async {
  final token = await DoctorAuthStorage.getToken();

  return http.post(
    Uri.parse(AppConfig.doctorUpdateFcmTokenUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'fcmToken': fcmToken,
    }),
  );
}
```

## 4. Backend FCM Token Storage

### 4.1 Backend endpoint

The backend route is defined in `abident_backend/routes/doctorRoutes.js`:

```js
router.post('/update-fcm-token', doctorAuth, updateFcmToken);
```

### 4.2 Controller implementation

This endpoint updates the doctor record with the latest FCM token:

```js
exports.updateFcmToken = async (req, res) => {
  try {
    const doctorId = req.userId;
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({ message: 'fcmToken is required' });
    }

    const doctor = await Doctor.findByIdAndUpdate(
      doctorId,
      { fcmToken },
      { new: true }
    );

    if (!doctor) {
      return res.status(404).json({ message: 'Doctor not found' });
    }

    return res.status(200).json({
      message: 'FCM token updated successfully',
      doctor: {
        id: doctor._id,
        name: doctor.name,
        email: doctor.email,
        specialization: doctor.specialization,
      },
    });
  } catch (error) {
    return res.status(500).json({ message: error.message });
  }
};
```

## 5. Backend Firebase Admin / Notification Sender

### 5.1 Backend Firebase initialization

The backend loads the service account in `abident_backend/config/firebase.js`:

```js
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const loadServiceAccount = () => {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
    return JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
  }

  const defaultPath = path.join(__dirname, 'serviceAccountKey.json');
  const envPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
    ? path.resolve(process.cwd(), process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
    : defaultPath;

  if (fs.existsSync(envPath)) {
    return require(envPath);
  }

  throw new Error('Firebase service account not found.');
};

try {
  const serviceAccount = loadServiceAccount();
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DATABASE_URL || undefined,
  });
} catch (error) {
  console.warn('Firebase not initialized. Add serviceAccountKey.json to enable FCM.');
}

module.exports = { admin };
```

### 5.2 Example notification sender

Add a helper in your backend to send FCM messages to a doctor:

```js
const { admin } = require('./config/firebase');

const sendDoctorNotification = async ({
  fcmToken,
  title,
  body,
  data,
}) => {
  if (!fcmToken) {
    throw new Error('FCM token is required');
  }

  const message = {
    token: fcmToken,
    notification: {
      title,
      body,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
  };

  const response = await admin.messaging().send(message);
  return response;
};
```

### 5.3 Sending a booking notification example

When a booking is created, send the doctor a message:

```js
const doctor = await Doctor.findById(doctorId);
if (doctor && doctor.fcmToken) {
  await sendDoctorNotification({
    fcmToken: doctor.fcmToken,
    title: 'New Appointment Request',
    body: `${patient.name} requested ${treatment.type}`,
    data: {
      bookingId: booking._id.toString(),
      patientName: patient.name,
      status: booking.status,
      visitType: booking.visitType,
      date: treatment.date,
      time: treatment.time,
      message: 'Tap to view booking details',
    },
  });
}
```

## 6. Notification Payload Tips

Use both `notification` and `data` payloads to support all app states.

- `notification`: shown by the OS when the app is backgrounded.
- `data`: always delivered to the app code, especially for navigation and deep link values.

Example payload:

```json
{
  "to": "<fcmToken>",
  "notification": {
    "title": "New Booking",
    "body": "You have a new appointment request."
  },
  "data": {
    "bookingId": "123",
    "patientName": "Dharun",
    "status": "PENDING",
    "visitType": "Clinic Visit",
    "date": "2026-05-10",
    "time": "14:15",
    "message": "Tap to view booking details"
  }
}
```

## 7. How the Doctor App handles notification events

1. `onMessage`: app is in foreground.
   - The app shows an in-app snackbar/banner.
   - It saves the notification to local store.
2. `onMessageOpenedApp`: user taps the notification.
   - The app opens `AppointmentDetailPage`.
   - It uses `bookingId` to load full booking details from the backend.
3. `getInitialMessage`: app was closed and opened by a notification.
   - The app processes the message and navigates accordingly.

## 8. Testing Steps

1. Build and run the doctor app after adding `google-services.json`.
2. Login to the app.
3. Confirm the app prints a non-null FCM token in logs.
4. Confirm the backend receives `POST /api/doctor/update-fcm-token`.
5. Send a test notification from your backend or Firebase Console.
6. Verify:
   - Foreground notification shows a banner.
   - Tap notification navigates to the detail page.
   - The local notifications list stores the entry.

## 9. Common troubleshooting

- `FCM token is null`
  - Check `google-services.json` placement.
  - Ensure `Firebase.initializeApp()` runs before `FirebaseMessaging.instance.getToken()`.
- Notifications not received on Android
  - Confirm `POST_NOTIFICATIONS` permission is allowed.
  - Confirm the app package name matches the Firebase app registration.
- Notification tap navigation not working
  - Confirm `navigatorKey` is set in `MaterialApp`.
  - Confirm `onMessageOpenedApp` and `getInitialMessage` are handled.

## 10. Useful project paths

- Flutter doctor app main: `abident_doctor/flutter_doctor/lib/main.dart`
- Notification service: `abident_doctor/flutter_doctor/lib/src/services/notification_service.dart`
- API service: `abident_doctor/flutter_doctor/lib/src/services/doctor_api_service.dart`
- Backend Firebase config: `abident_backend/config/firebase.js`
- Backend doctor FCM endpoint: `abident_backend/controllers/doctorController.js`

---

This document gives you a complete FCM notification flow for the doctor app, from Firebase credential setup to in-app routing and backend storage. Use it as a reference when building or debugging notifications in the Abident doctor application.
