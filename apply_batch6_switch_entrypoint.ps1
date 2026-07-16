$ErrorActionPreference = 'Stop'
$project = 'C:\MotionHR\motionhr_employee'
Set-Location $project

Write-Host '=== Batch 6: Switch Entrypoint ===' -ForegroundColor Cyan

function Write-Utf8File {
    param([string]$RelativePath, [string]$Content)
    $fullPath = Join-Path $project $RelativePath
    New-Item -ItemType Directory -Force -Path (Split-Path $fullPath -Parent) | Out-Null
    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    Write-Host "Created: $RelativePath" -ForegroundColor Green
}

# Backup old main.dart
$mainPath = Join-Path $project 'lib\main.dart'
Copy-Item $mainPath (Join-Path $project 'lib\main.dart.bak_before_batch6') -Force
Write-Host 'Backup: lib\main.dart.bak_before_batch6' -ForegroundColor Yellow

# Create app.dart
Write-Utf8File 'lib\app.dart' @'
import 'package:flutter/material.dart';
import 'screens/auth/splash_screen.dart';

class MotionHRApp extends StatelessWidget {
  const MotionHRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotionHR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Arial'),
      locale: const Locale('ar'),
      home: const SplashScreen(),
    );
  }
}
'@

# Create new lean main.dart
Write-Utf8File 'lib\main.dart' @'
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'background_service.dart';
import 'services/notification_service.dart';

final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

Future<void> _initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotif.initialize(
    const InitializationSettings(android: android),
    onDidReceiveNotificationResponse: (_) {},
  );
  await _localNotif
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'motionhr_channel',
          'MotionHR Notifications',
          importance: Importance.max,
        ),
      );
}

Future<void> _showLocalNotification(String title, String body) async {
  await _localNotif.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'motionhr_channel',
        'MotionHR Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

Future<void> _initFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
        alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        await _showLocalNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
        await NotificationService.fetchUnreadCount();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationService.fetchUnreadCount();
    });
  } catch (e) {
    print('Firebase Messaging error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await _initLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await _initFirebaseMessaging();
  } catch (e) {
    print('Firebase init error: $e');
  }

  await configureBackgroundTracking();

  runApp(const MotionHRApp());
}
'@

Write-Host ''
Write-Host '=== Batch 6 Done ===' -ForegroundColor Cyan
Write-Host 'New lean main.dart created.' -ForegroundColor Green
Write-Host 'app.dart created.' -ForegroundColor Green
Write-Host ''
Write-Host 'Now run:' -ForegroundColor White
Write-Host '  flutter run' -ForegroundColor White