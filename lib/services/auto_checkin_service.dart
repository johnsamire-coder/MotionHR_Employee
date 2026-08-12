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

  static Future<void> runSingleBackgroundTick() async {
    await _checkAndProcess();
  }

  // â”€â”€ Token â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('auth_token');
  }

  // â”€â”€ Language â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static String get _lang => LanguageService.currentLanguage;

  // ── بدء المراقبة ───────────────────────────────────────
  static Future<void> startMonitoring() async {
    print('[AUTO CHECK-IN] startMonitoring CALLED | isRunning=$_isRunning');
    if (_isRunning) return;

    // تحقق من الصلاحيات أولاً
    final hasPermission = await _checkPermissions();
    print('[AUTO CHECK-IN] hasPermission=$hasPermission');
    if (!hasPermission) return;

    _isRunning = true;
    _resetDailyState();

    // مزامنة الحالة من السيرفر قبل أول فحص
    await syncStateFromBackend();

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
      print('=== [AUTO CHECK-IN] TICK START ===');
      _resetDailyState();

      final token = await _getToken();
      if (token == null) { print('[AUTO CHECK-IN] No token'); return; }

      await syncStateFromBackend();
      print('[AUTO CHECK-IN] CheckedIn: $_checkedInToday | CheckedOut: $_checkedOutToday');

      final policy = await _getSmartPolicy(token);
      final triggerMode = policy['trigger_mode'] as String;
      print('[AUTO CHECK-IN] Trigger Mode: $triggerMode');
      if (triggerMode == 'manual') return;

      final shiftData = await _getMyShift(token);
      final preWindow = (policy['pre_shift_window'] as int?) ?? 15;
      final withinWindow = _isWithinShiftWindow(shiftData, preWindow);
      print('[AUTO CHECK-IN] Within Shift Window: $withinWindow');
      if (!withinWindow) return;

      final geofence = await _getGeofence(token);
      if (geofence == null) { print('[AUTO CHECK-IN] Geofence is null'); return; }
      
      final position = await _getCurrentPosition();
      if (position == null) { print('[AUTO CHECK-IN] Position is null (GPS off/No perm)'); return; }
      
      final distance = Geolocator.distanceBetween(
        position.latitude, position.longitude,
        geofence['latitude'], geofence['longitude'],
      );
      final radius = (geofence['radius'] ?? 100).toDouble();
      final isInside = distance <= radius;
      
      print('[AUTO CHECK-IN] Distance: ${distance.toStringAsFixed(2)}m | Radius: ${radius}m | Inside: $isInside');

      if (triggerMode == 'auto') {
        if (isInside && !_checkedInToday) {
          print('[AUTO CHECK-IN] 🚀 TRIGGERING CHECK-IN NOW!');
          await _performAutoCheckin(token, position);
        } else if (!isInside && _checkedInToday && !_checkedOutToday) {
          print('[AUTO CHECK-IN] 🚀 TRIGGERING CHECK-OUT NOW!');
          await _performAutoCheckout(token, position);
        } else {
          print('[AUTO CHECK-IN] No action needed (Inside=$isInside, CheckedIn=$_checkedInToday)');
        }
      }
    } catch (e) {
      print('[AUTO CHECK-IN] ❌ ERROR: $e');
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

      final responseText = utf8.decode(res.bodyBytes);
      print('[AUTO CHECK-IN] حالة الرد: ${res.statusCode}');
      print('[AUTO CHECK-IN] محتوى الرد: $responseText');

      Map<String, dynamic> data = {};
      try {
        final decoded = jsonDecode(responseText);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        } else if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}

      final serverMessage = (data['message'] ?? '').toString().trim();
      final status = (data['status'] ?? '').toString().trim();

      if (res.statusCode == 200) {
        _checkedInToday = true;
        final msg = serverMessage.isNotEmpty
            ? serverMessage
            : (_lang == 'ar'
                ? '✅ تم تسجيل حضورك تلقائياً'
                : '✅ Auto check-in recorded');
        onAutoCheckin?.call(msg);
      } else if (status == 'already_checked_in') {
        _checkedInToday = true;
        if (serverMessage.isNotEmpty) {
          onAutoCheckin?.call(serverMessage);
        }
      }
    } catch (e) {
      print('[AUTO CHECK-IN] خطأ داخل تنفيذ الحضور التلقائي: ' + e.toString());
    }
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
    if (shiftData == null) return true;

    try {
      final todayShift = shiftData['today_shift'] is Map
          ? Map<String, dynamic>.from(shiftData['today_shift'])
          : null;
      final firstScheduleItem =
          shiftData['schedule'] is List && (shiftData['schedule'] as List).isNotEmpty
              ? Map<String, dynamic>.from((shiftData['schedule'] as List).first)
              : null;

      final rawStart = (
        shiftData['start_time'] ??
        shiftData['shift_start'] ??
        todayShift?['start_time'] ??
        todayShift?['shift_start'] ??
        firstScheduleItem?['start_time'] ??
        firstScheduleItem?['shift_start'] ??
        ''
      ).toString().trim();

      if (rawStart.isEmpty || rawStart == 'null') {
        print('[AUTO CHECK-IN] لم يتم العثور على وقت بداية الشيفت داخل بيانات الشيفت');
        return false;
      }

      String timeText = rawStart;
      if (timeText.contains('T')) timeText = timeText.split('T').last;
      if (timeText.contains('.')) timeText = timeText.split('.').first;
      timeText = timeText.trim();

      int shiftHour;
      int shiftMinute;

      final match12 = RegExp(r'^(\d{1,2}):(\d{2})\s*([APap][Mm])$').firstMatch(timeText);
      if (match12 != null) {
        shiftHour = int.parse(match12.group(1)!);
        shiftMinute = int.parse(match12.group(2)!);
        final period = match12.group(3)!.toUpperCase();
        if (period == 'PM' && shiftHour < 12) shiftHour += 12;
        if (period == 'AM' && shiftHour == 12) shiftHour = 0;
      } else {
        final match24 = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(timeText);
        if (match24 == null) return false;
        shiftHour = int.parse(match24.group(1)!);
        shiftMinute = int.parse(match24.group(2)!);
      }

      final now = DateTime.now();

      // نجرب اليوم الحالي واليوم السابق (شيفت بعد نص الليل)
      for (int dayOffset in [0, -1]) {
        final baseDay = now.add(Duration(days: dayOffset));
        final shiftStart = DateTime(baseDay.year, baseDay.month, baseDay.day, shiftHour, shiftMinute);
        final allowedFrom = shiftStart.subtract(Duration(minutes: preShiftWindowMinutes));
        final allowedTo = shiftStart.add(const Duration(hours: 4));

        print('[AUTO CHECK-IN] جرب: shiftStart=' + shiftStart.toString() + ' | from=' + allowedFrom.toString() + ' | to=' + allowedTo.toString());

        if (now.isAfter(allowedFrom) && now.isBefore(allowedTo)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('[AUTO CHECK-IN] فشل قراءة وقت الشيفت: ' + e.toString());
      return false;
    }
  }

}
