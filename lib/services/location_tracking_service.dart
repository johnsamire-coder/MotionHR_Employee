import 'package:motionhr_employee/services/api_client.dart';
import 'package:motionhr_employee/services/offline_queue_service.dart';
import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LocationTrackingService {
  static const String baseUrl = 'https://jssolutions-eg.com';
  static Timer? _hourlyTimer;
  static Timer? _geofenceTimer;
  static bool _isRunning = false;

  // ── بدء التتبع (كل 5 دقائق للجيوفنس + كل ساعة للمسار العام) ──
  static Future<void> startTracking() async {
    if (_isRunning) return;
    _isRunning = true;

    // إرسال فحص الجيوفنس والمسار فوراً عند البدء
    await _sendGeofencePing();
    await _saveCurrentLocation();

    // مؤقت فحص النطاق الجغرافي كل 5 دقائق
    _geofenceTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await _sendGeofencePing();
    });

    // مؤقت تقرير المسار العام كل ساعة
    _hourlyTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      await _saveCurrentLocation();
    });
  }

  // ── إيقاف التتبع عند الانصراف ──
  static void stopTracking() {
    _geofenceTimer?.cancel();
    _geofenceTimer = null;
    _hourlyTimer?.cancel();
    _hourlyTimer = null;
    _isRunning = false;
  }

  static bool get isRunning => _isRunning;

  // ── إرسال فحص الجيوفنس للسيرفر (كل 5 دقائق) ──
  static Future<void> _sendGeofencePing() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final url = '$baseUrl/attendance/api/mobile/geofence-ping/';
      final payload = {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      await http.post(
        Uri.parse(url),
        headers: await ApiClient.buildHeaders(includeContentType: true),
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      // تجاهل أخطاء الشبكة المؤقتة في فحص الجيوفنس
    }
  }

  // ── جيب الموقع الحالي وارسله للمسار العام ──
  static Future<bool> _saveCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

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

      final url = '$baseUrl/attendance/api/mobile/employee/save-location/';

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: await ApiClient.buildHeaders(includeContentType: true),
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) return true;
        return false;
      } catch (_) {
        await OfflineQueueService.enqueue(
          actionType: OfflineActionType.sendLocation,
          endpoint: url,
          method: 'POST',
          body: payload,
        );
        return false;
      }
    } catch (_) {
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
          '$baseUrl/attendance/api/mobile/manager/reports/location-tracking/?date=$shiftDate'),
      headers: await ApiClient.buildHeaders(includeContentType: true),
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true) {
        final employees = (data['employees'] as List?) ?? [];
        for (final e in employees) {
          if (e is Map && e['employee_id'] == employeeId) {
            final logs = (e['logs'] as List?) ?? [];
            final points = <Map<String, dynamic>>[];
            for (final lg in logs) {
              final m = Map<String, dynamic>.from(lg as Map);
              points.add({
                'id': points.length + 1,
                'latitude': m['lat'],
                'longitude': m['lng'],
                'accuracy': m['accuracy'] ?? 0,
                'recorded_at': m['timestamp']?.toString() ?? '',
                'point_index': points.length + 1,
                'address': m['address'] ?? '',
              });
            }
            return {
              'success': true,
              'employee': {
                'id': employeeId,
                'name': e['employee_name']?.toString() ?? '',
              },
              'shift_date': shiftDate,
              'total_points': points.length,
              'points': points,
            };
          }
        }
        return {
          'success': true,
          'employee': {'id': employeeId, 'name': ''},
          'shift_date': shiftDate,
          'total_points': 0,
          'points': <Map<String, dynamic>>[],
        };
      }
      throw Exception(data['error'] ?? 'خطأ في جلب التقرير');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }
}
