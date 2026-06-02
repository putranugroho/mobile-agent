// lib/main.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'pages/login_page.dart';
import 'services/notification_service.dart';
import 'services/session_guard.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('BACKGROUND NOTIFICATION: ${message.messageId}');
}

Future<void> setupFirebaseMessaging() async {
  final messaging = FirebaseMessaging.instance;

  // iOS permission request; Android 13+ handled via NotificationService
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Ensure foreground notifications are shown as banners on iOS too
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  final token = await messaging.getToken();
  debugPrint('🔥 FCM TOKEN: $token');

  // Foreground: FCM delivers to app but does NOT auto-show notification on Android
  // We must display it manually via flutter_local_notifications
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('🔔 Foreground message: ${message.messageId}');
    final title = message.notification?.title ?? message.data['title'] ?? 'Notifikasi';
    final body = message.notification?.body ?? message.data['body'] ?? '';
    NotificationService.showNotification(title: title, body: body);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (!kIsWeb) {
      await Firebase.initializeApp();
      await NotificationService.initialize();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      await setupFirebaseMessaging();
    } else {
      debugPrint('🌐 Running on Web: Firebase Messaging skipped');
    }
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Mobile Agent',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0F3D2E)), useMaterial3: true),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return SessionGuard(navigatorKey: appNavigatorKey, child: child ?? const SizedBox.shrink());
      },
    );
  }
}
