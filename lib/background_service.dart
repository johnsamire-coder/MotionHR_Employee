import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kLocationApiUrl =
    'https://jssolutions-eg.com/attendance/api/mobile/location/';

Future<void> configureBackgroundTracking() async {
  try {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: backgroundServiceOnStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: true,
        initialNotificationTitle: 'MotionHR',
        initialNotificationContent: 'جاري تشغيل خدمات التطبيق',
        foregroundServiceNotificationId: 1001,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: backgroundServiceOnStart,
        onBackground: onIosBackground,
      ),
    );
  } catch (_) {}
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void backgroundServiceOnStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('stopService').listen((event) async {
      await service.stopSelf();
    });

    service.on('setAsForeground').listen((event) async {
      await service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) async {
      await service.setAsBackgroundService();
    });
  }

  Timer.periodic(const Duration(minutes: 2), (timer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackingEnabled = prefs.getBool('tracking_enabled') ?? false;
      final token = prefs.getString('token') ?? '';

      if (!trackingEnabled || token.isEmpty) return;

      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationEnabled) return;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await http.post(
        Uri.parse(kLocationApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        }),
      );

      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await service.setForegroundNotificationInfo(
            title: 'MotionHR',
            content: 'جاري تشغيل خدمات التطبيق',
          );
        }
      }
    } catch (_) {}
  });
}

Future<void> startBackgroundTrackingIfNeeded() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final trackingEnabled = prefs.getBool('tracking_enabled') ?? false;

    if (!trackingEnabled) return;

    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();

    if (!isRunning) {
      await service.startService();
    }
  } catch (_) {}
}

Future<void> stopBackgroundTracking() async {
  try {
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke('stopService');
    }
  } catch (_) {}
}

Future<void> saveTrackingFlag(bool trackingEnabled) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('tracking_enabled', trackingEnabled);
}

Future<void> requestLocationPermissionsForTracking() async {
  try {
    final locationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!locationEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }
  } catch (_) {}
}