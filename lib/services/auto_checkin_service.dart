import 'package:motionhr_employee/services/api_client.dart';
// lib/services/auto_checkin_service.dart
// Phase 14: Auto Check-in / Auto Check-out Service
// يراقب الـ Geofence ويسجل الحضور/الانصراف تلقائياً

import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'language_service.dart';

class AutoCheckinService {
  static const String _baseUrl = 'https://jssolutions-eg.com';

  // â”€â”€ State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Timer? _timer;
  static bool _isRunning = false;
  static bool _checkedInToday = false;
  static bool _checkedOutToday = false;
  static DateTime? _lastCheckTime;

  // â”€â”€ Callbacks â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Function(String message)? onAutoCheckin;
  static Function(String message)? onAutoCheckout;
  static Function(String error)? onError;

  // â”€â”€ Getters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static bool get isRunning => _isRunning;
  static bool get checkedInToday => _checkedInToday;

  // â”€â”€ Token â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('auth_token');
  }

  // â”€â”€ Language â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String get _lang => LanguageService.currentLanguage;

  // ── بدء المراقبة ───────────────────────────────────────
  static Future<void> startMonitoring() async {
    if (_isRunning) return;

    // تحقق من الصلاحيات أولاً
    final hasPermission = await _checkPermissions();
    if (!hasPermission) return;

    _isRunning = true;
    _resetDailyState();

    // فحص فوري عند البدء
    await _checkAndProcess();

    // ثم كل دقيقتين
    _timer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _checkAndProcess();
    });
  }

  // ── إيقاف المراقبة ─────────────────────────────────────
  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  // ── إعادة ضبط الحالة اليومية ───────────────────────────
  static void _resetDailyState() {
    final now = DateTime.now();
    if (_lastCheckTime != null && _lastCheckTime!.day != now.day) {
      _checkedInToday = false;
      _checkedOutToday = false;
    }
    _lastCheckTime = now;
  }

  // ── الفحص الرئيسي ──────────────────────────────────────
  static Future<void> _checkAndProcess() async {
    try {
      _resetDailyState();

      final token = await _getToken();
      if (token == null) return;

      // جيب الـ Smart Policy
      final policy = await _getSmartPolicy(token);
      final triggerMode = policy['trigger_mode'] as String;

      // لو يدوي: مانعملش أي حاجة تلقائية
      if (triggerMode == 'manual') return;

      // جيب الشيفت وتحقق من النافذة
      final shiftData = await _getMyShift(token);
      final preWindow = (policy['pre_shift_window'] as int?) ?? 15;
      final withinWindow = _isWithinShiftWindow(shiftData, preWindow);

      // لو برا نافذة الشيفت: مانعملش حاجة
      if (!withinWindow) return;

      // جيب الـ Geofence من الـ API
      final geofence = await _getGeofence(token);
      if (geofence == null) return;

      // جيب الموقع الحالي
      final position = await _getCurrentPosition();
      if (position == null) {
        // لو الموقع مش متاح
        if (!_checkedInToday) {
          onError?.call(
            _lang == 'ar'
                ? 'يرجى تفعيل الموقع لإتمام تسجيل الحضور والانصراف'
                : 'Please enable location to complete attendance registration',
          );
        }
        return;
      }

      // احسب المسافة
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence['latitude'],
        geofence['longitude'],
      );

      final radius = (geofence['radius'] ?? 100).toDouble();
      final isInsideGeofence = distance <= radius;

      // تصرف حسب الـ mode
      if (triggerMode == 'auto') {
        // تسجيل تلقائي كامل
        if (isInsideGeofence && !_checkedInToday) {
          await _performAutoCheckin(token, position);
        } else if (!isInsideGeofence && _checkedInToday && !_checkedOutToday) {
          await _performAutoCheckout(token, position);
        }
      } else if (triggerMode == 'notification') {
        // إشعار فقط - مش تسجيل تلقائي
        if (isInsideGeofence && !_checkedInToday) {
          onAutoCheckin?.call(
            _lang == 'ar'
                ? 'أنت داخل موقع العمل، يمكنك تسجيل الحضور الآن'
                : 'You are at work location, you can check in now',
          );
        }
      }
    } catch (e) {
      onError?.call(
        _lang == 'ar'
            ? 'خطأ في المراقبة'
            : 'Monitoring error',
      );
    }
  }

  // ── جلب إعدادات الـ Geofence ───────────────────────────
  static Future<Map<String, dynamic>?> _getGeofence(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/attendance/api/mobile/manager/geofence/'),
        headers: await ApiClient.buildHeaders(includeContentType: true),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data['success'] == true && data['geofence'] != null) {
          return data['geofence'];
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── تسجيل الحضور التلقائي ──────────────────────────────
  static Future<void> _performAutoCheckin(
    String token,
    Position position,
  ) async {
    try {
      final now = DateTime.now();
      final res = await http.post(
        Uri.parse('$_baseUrl/attendance/api/mobile/employee/auto-check-in/'),
        headers: await ApiClient.buildHeaders(includeContentType: true),
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': now.toIso8601String(),
          'lang': _lang,
          'source': 'auto',
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        _checkedInToday = true;
        final msg = _lang == 'ar'
            ? '✅ تم تسجيل حضورك تلقائياً'
            : 'âœ… Auto check-in recorded';
        onAutoCheckin?.call(msg);
      }
    } catch (_) {}
  }

  // ── تسجيل الانصراف التلقائي ────────────────────────────
  static Future<void> _performAutoCheckout(
    String token,
    Position position,
  ) async {
    try {
      final now = DateTime.now();
      final res = await http.post(
        Uri.parse('$_baseUrl/attendance/api/mobile/employee/auto-check-out/'),
        headers: await ApiClient.buildHeaders(includeContentType: true),
        body: jsonEncode({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': now.toIso8601String(),
          'lang': _lang,
          'source': 'auto',
        }),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        _checkedOutToday = true;
        final msg = _lang == 'ar'
            ? '✅ تم تسجيل انصرافك تلقائياً'
            : 'âœ… Auto check-out recorded';
        onAutoCheckout?.call(msg);
      }
    } catch (_) {}
  }

  // ── فحص الصلاحيات ──────────────────────────────────────
  static Future<bool> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  // ── جيب الموقع الحالي ──────────────────────────────────
  static Future<Position?> _getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (_) {
      return null;
    }
  }

  // ── فحص الحالة الحالية من الـ Backend ──────────────────
  static Future<Map<String, dynamic>> getCheckinStatus() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'checked_in': false, 'checked_out': false};
    }

    try {
      final res = await http.get(
        Uri.parse(
            '$_baseUrl/attendance/api/mobile/employee/auto-checkin-status/'),
        headers: await ApiClient.buildHeaders(includeContentType: true),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}

    return {'success': false, 'checked_in': false, 'checked_out': false};
  }

  // ── مزامنة الحالة مع الـ Backend ───────────────────────
  static Future<void> syncStateFromBackend() async {
    final status = await getCheckinStatus();
    if (status['success'] == true) {
      _checkedInToday = status['checked_in'] ?? false;
      _checkedOutToday = status['checked_out'] ?? false;
    }
  }

  // ── جلب سياسة الحضور الذكي ─────────────────────────────
  static Future<Map<String, dynamic>> _getSmartPolicy(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/attendance/api/mobile/manager/work-policy/'),
        headers: await ApiClient.buildHeaders(includeContentType: true),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return {
          'trigger_mode': data['attendance_trigger_mode'] ?? 'notification',
          'pre_shift_window': data['pre_shift_checkin_window'] ?? 15,
          'require_live_location': data['require_live_location'] ?? true,
          'location_loss_action': data['location_loss_action'] ?? 'alert_only',
          'location_loss_grace_minutes': data['location_loss_grace_minutes'] ?? 5,
        };
      }
    } catch (_) {}
    return {
      'trigger_mode': 'notification',
      'pre_shift_window': 15,
      'require_live_location': true,
      'location_loss_action': 'alert_only',
      'location_loss_grace_minutes': 5,
    };
  }

  // ── جلب الشيفت الحالي للموظف ────────────────────────────
  static Future<Map<String, dynamic>?> _getMyShift(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/attendance/api/mobile/employee/my-shift/'),
        headers: await ApiClient.buildHeaders(includeContentType: true),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return null;
  }

  // ── التحقق من نافذة الشيفت ──────────────────────────────
  static bool _isWithinShiftWindow(
    Map<String, dynamic>? shiftData,
    int preShiftWindowMinutes,
  ) {
    if (shiftData == null) return true; // لو مفيش شيفت، نسمح

    try {
      final startTimeStr = shiftData['start_time'] as String?;
      if (startTimeStr == null) return true;

      final parts = startTimeStr.split(':');
      final shiftHour = int.parse(parts[0]);
      final shiftMinute = int.parse(parts[1]);

      final now = DateTime.now();
      final shiftStart = DateTime(now.year, now.month, now.day, shiftHour, shiftMinute);
      final allowedFrom = shiftStart.subtract(Duration(minutes: preShiftWindowMinutes));
      final allowedTo = shiftStart.add(const Duration(hours: 4)); // حد أقصى 4 ساعات بعد الشيفت

      return now.isAfter(allowedFrom) && now.isBefore(allowedTo);
    } catch (_) {
      return true;
    }
  }

}
