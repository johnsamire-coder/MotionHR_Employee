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

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

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

      // ارسل للسيرفر
      final token = await _getToken();
      if (token == null) return false;

      final now = DateTime.now();
      final shiftDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await http.post(
        Uri.parse('$baseUrl/attendance/api/mobile/employee/save-location/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'recorded_at': now.toIso8601String(),
          'shift_date': shiftDate,
          'address': address,
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ── جيب تقرير اليوم (للمدير) ──
  static Future<Map<String, dynamic>> getLocationReport({
    required int employeeId,
    required String shiftDate,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/location-report/?employee_id=$employeeId&shift_date=$shiftDate'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true) return data;
      throw Exception(data['error'] ?? 'خطأ في جلب التقرير');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }
}