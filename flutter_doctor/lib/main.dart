import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'src/layouts/doctor_shell.dart';
import 'src/pages/auth/doctor_login_page.dart';
import 'src/pages/splash_screen.dart';
import 'src/services/doctor_auth_storage.dart';
import 'src/services/notification_service.dart';
import 'src/services/notification_store.dart';
import 'src/styles/app_theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FirebaseBackground] message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificationStore.init();
    await NotificationService.init();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (error) {
    debugPrint('Firebase initialization error: $error');
  }

  runApp(const DoctorApp());
}

class DoctorApp extends StatelessWidget {
  const DoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Abident Doctor',
      theme: AppTheme.light,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final authCheckFuture = DoctorAuthStorage.isLoggedIn();

    return FutureBuilder<bool>(
      future: authCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SplashScreen(
            authCheckFuture: authCheckFuture,
          );
        }

        if (snapshot.data == true) {
          return const DoctorShell();
        }

        return const DoctorLoginPage();
      },
    );
  }
}
