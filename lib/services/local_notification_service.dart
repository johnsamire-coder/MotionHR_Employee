import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Function(Map<String, dynamic>)? onNotificationTap;

  static Future<void> init({
    Function(Map<String, dynamic>)? onTap,
  }) async {
    onNotificationTap = onTap;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            final data = jsonDecode(payload) as Map<String, dynamic>;
            onNotificationTap?.call(data);
          } catch (_) {
            onNotificationTap?.call({'type': payload});
          }
        }
      },
    );

    await _plugin
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

  static Future<void> show(
    String title,
    String body, {
    Map<String, dynamic>? data,
  }) async {
    String? payload;
    if (data != null) {
      try {
        payload = jsonEncode(data);
      } catch (_) {}
    }
    await _plugin.show(
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
      payload: payload,
    );
  }

  static Future<void> showSyncSuccess(String actionType) async {
    final messages = <String, Map<String, String>>{
      'checkIn': {
        'title': 'تم تسجيل الحضور ✅',
        'body': 'تم مزامنة تسجيل حضورك بنجاح',
      },
      'checkOut': {
        'title': 'تم تسجيل الانصراف ✅',
        'body': 'تم مزامنة تسجيل انصرافك بنجاح',
      },
      'partialCheckout': {
        'title': 'تم الخروج الجزئي ✅',
        'body': 'تم مزامنة خروجك الجزئي بنجاح',
      },
      'resumeCheckin': {
        'title': 'تم استئناف العمل ✅',
        'body': 'تم مزامنة استئناف عملك بنجاح',
      },
      'sendLocation': {
        'title': 'تم إرسال الموقع ✅',
        'body': 'تم مزامنة موقعك بنجاح',
      },
    };

    final msg = messages[actionType];
    if (msg != null) {
      await show(msg['title']!, msg['body']!);
    }
  }
}
