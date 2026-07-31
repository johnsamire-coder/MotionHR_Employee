import 'package:motionhr_employee/services/api_client.dart';
import 'package:motionhr_employee/services/offline_queue_service.dart';
// lib/services/location_tracking_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationTrackingService {
  static const String baseUrl = 'https://jssolutions-eg.com';
  static Timer? _timer;
  static bool _isRunning = false;

  // ── بدء التتبع كل ساعة ──
  static Future<void> startTracking() async {
    if (_isRunning) return;
    _isRunning = true;

    // أول نقطة فوراً
    await _saveCurrentLocation();

    // ثم كل ساعة
    _timer = Timer.periodic(const Duration(hours: 1), (_) async {
      await _saveCurrentLocation();
    });
  }

  // ── إيقاف التتبع ──
  static void stopTracking() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  static bool get isRunning => _isRunning;

  // ── جيب الموقع الحالي وارسله ──
  static Future<bool> _saveCurrentLocation() async {
    try {
      // تحقق من الصلاحيات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;

      // جيب الموقع
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // جيب اسم المكان
      String address = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).toList();
          address = parts.join(', ');
        }
      } catch (_) {
        address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }

      final now = DateTime.now();
      final shiftDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final payload = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'recorded_at': now.toIso8601String(),
        'shift_date': shiftDate,
        'address': address,
      };

      final url =
          '$baseUrl/attendance/api/mobile/employee/save-location/';

      try {
        // ارسل للسيرفر
        final response = await http.post(
          Uri.parse(url),
          headers: await ApiClient.buildHeaders(includeContentType: true),
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) return true;

        // لو السيرفر رد بخطأ مش هنحفظ في القائمة
        return false;
      } catch (_) {
        // مفيش نت أو timeout — نحفظ في الطابور
        await OfflineQueueService.enqueue(
          actionType: OfflineActionType.sendLocation,
          endpoint: url,
          method: 'POST',
          body: payload,
        );
        return false;
      }
    } catch (_) {
      // لو فشل جيب الموقع نفسه — نحاول نحفظ آخر موقع معروف لو موجود
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          final now = DateTime.now();
          final shiftDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          final url = '$baseUrl/attendance/api/mobile/employee/save-location/';
          await OfflineQueueService.enqueue(
            actionType: OfflineActionType.sendLocation,
            endpoint: url,
            method: 'POST',
            body: {
              'latitude': lastPosition.latitude,
              'longitude': lastPosition.longitude,
              'accuracy': lastPosition.accuracy,
              'recorded_at': now.toIso8601String(),
              'shift_date': shiftDate,
              'address': '',
            },
          );
        }
      } catch (_) {}
      return false;
    }
  }

  // ── جيب تقرير اليوم (للمدير) ──
  static Future<Map<String, dynamic>> getLocationReport({
    required int employeeId,
    required String shiftDate,
  }) async {
    final res = await http.get(
      Uri.parse(
          '$baseUrl/attendance/api/mobile/manager/location-report/?employee_id=$employeeId&shift_date=$shiftDate'),
      headers: await ApiClient.buildHeaders(includeContentType: true),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true) return data;
      throw Exception(data['error'] ?? 'خطأ في جلب التقرير');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }
}
