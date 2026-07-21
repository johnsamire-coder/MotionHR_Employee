// lib/services/auto_checkin_service.dart
// Phase 14: Auto Check-in / Auto Check-out Service
// ظٹط±ط§ظ‚ط¨ ط§ظ„ظ€ Geofence ظˆظٹط³ط¬ظ„ ط§ظ„ط­ط¶ظˆط±/ط§ظ„ط§ظ†طµط±ط§ظپ طھظ„ظ‚ط§ط¦ظٹط§ظ‹

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

  // â”€â”€ ط¨ط¯ط، ط§ظ„ظ…ط±ط§ظ‚ط¨ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> startMonitoring() async {
    if (_isRunning) return;

    // طھط­ظ‚ظ‚ ظ…ظ† ط§ظ„طµظ„ط§ط­ظٹط§طھ ط£ظˆظ„ط§ظ‹
    final hasPermission = await _checkPermissions();
    if (!hasPermission) return;

    _isRunning = true;
    _resetDailyState();

    // ظپط­طµ ظپظˆط±ظٹ ط¹ظ†ط¯ ط§ظ„ط¨ط¯ط،
    await _checkAndProcess();

    // ط«ظ… ظƒظ„ ط¯ظ‚ظٹظ‚طھظٹظ†
    _timer = Timer.periodic(const Duration(minutes: 2), (_) async {
      await _checkAndProcess();
    });
  }

  // â”€â”€ ط¥ظٹظ‚ط§ظپ ط§ظ„ظ…ط±ط§ظ‚ط¨ط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  // â”€â”€ ط¥ط¹ط§ط¯ط© ط¶ط¨ط· ط§ظ„ط­ط§ظ„ط© ط§ظ„ظٹظˆظ…ظٹط© â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static void _resetDailyState() {
    final now = DateTime.now();
    if (_lastCheckTime != null && _lastCheckTime!.day != now.day) {
      _checkedInToday = false;
      _checkedOutToday = false;
    }
    _lastCheckTime = now;
  }

  // â”€â”€ ط§ظ„ظپط­طµ ط§ظ„ط±ط¦ظٹط³ظٹ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> _checkAndProcess() async {
    try {
      _resetDailyState();

      final token = await _getToken();
      if (token == null) return;

      // ط¬ظٹط¨ ط§ظ„ظ€ Geofence ظ…ظ† ط§ظ„ظ€ API
      final geofence = await _getGeofence(token);
      if (geofence == null) return;

      // ط¬ظٹط¨ ط§ظ„ظ…ظˆظ‚ط¹ ط§ظ„ط­ط§ظ„ظٹ
      final position = await _getCurrentPosition();
      if (position == null) return;

      // ط§ط­ط³ط¨ ط§ظ„ظ…ط³ط§ظپط©
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence['latitude'],
        geofence['longitude'],
      );

      final radius = (geofence['radius'] ?? 100).toDouble();
      final isInsideGeofence = distance <= radius;

      // ظ‚ط±ط± ط§ظ„ط¥ط¬ط±ط§ط،
      if (isInsideGeofence && !_checkedInToday) {
        await _performAutoCheckin(token, position);
      } else if (!isInsideGeofence && _checkedInToday && !_checkedOutToday) {
        await _performAutoCheckout(token, position);
      }
    } catch (e) {
      onError?.call(
        _lang == 'ar'
            ? 'ط®ط·ط£ ظپظٹ ط§ظ„ظ…ط±ط§ظ‚ط¨ط© ط§ظ„طھظ„ظ‚ط§ط¦ظٹط©'
            : 'Auto monitoring error',
      );
    }
  }

  // â”€â”€ ط¬ظ„ط¨ ط¥ط¹ط¯ط§ط¯ط§طھ ط§ظ„ظ€ Geofence â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<Map<String, dynamic>?> _getGeofence(String token) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/attendance/api/mobile/manager/geofence/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
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

  // â”€â”€ طھط³ط¬ظٹظ„ ط§ظ„ط­ط¶ظˆط± ط§ظ„طھظ„ظ‚ط§ط¦ظٹ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> _performAutoCheckin(
    String token,
    Position position,
  ) async {
    try {
      final now = DateTime.now();
      final res = await http.post(
        Uri.parse('$_baseUrl/attendance/api/mobile/employee/auto-check-in/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
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
            ? 'âœ… طھظ… طھط³ط¬ظٹظ„ ط­ط¶ظˆط±ظƒ طھظ„ظ‚ط§ط¦ظٹط§ظ‹'
            : 'âœ… Auto check-in recorded';
        onAutoCheckin?.call(msg);
      }
    } catch (_) {}
  }

  // â”€â”€ طھط³ط¬ظٹظ„ ط§ظ„ط§ظ†طµط±ط§ظپ ط§ظ„طھظ„ظ‚ط§ط¦ظٹ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> _performAutoCheckout(
    String token,
    Position position,
  ) async {
    try {
      final now = DateTime.now();
      final res = await http.post(
        Uri.parse('$_baseUrl/attendance/api/mobile/employee/auto-check-out/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
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
            ? 'âœ… طھظ… طھط³ط¬ظٹظ„ ط§ظ†طµط±ط§ظپظƒ طھظ„ظ‚ط§ط¦ظٹط§ظ‹'
            : 'âœ… Auto check-out recorded';
        onAutoCheckout?.call(msg);
      }
    } catch (_) {}
  }

  // â”€â”€ ظپط­طµ ط§ظ„طµظ„ط§ط­ظٹط§طھ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ ط¬ظٹط¨ ط§ظ„ظ…ظˆظ‚ط¹ ط§ظ„ط­ط§ظ„ظٹ â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€ ظپط­طµ ط§ظ„ط­ط§ظ„ط© ط§ظ„ط­ط§ظ„ظٹط© ظ…ظ† ط§ظ„ظ€ Backend â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<Map<String, dynamic>> getCheckinStatus() async {
    final token = await _getToken();
    if (token == null) {
      return {'success': false, 'checked_in': false, 'checked_out': false};
    }

    try {
      final res = await http.get(
        Uri.parse(
            '$_baseUrl/attendance/api/mobile/employee/auto-checkin-status/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}

    return {'success': false, 'checked_in': false, 'checked_out': false};
  }

  // â”€â”€ ظ…ط²ط§ظ…ظ†ط© ط§ظ„ط­ط§ظ„ط© ظ…ط¹ ط§ظ„ظ€ Backend â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static Future<void> syncStateFromBackend() async {
    final status = await getCheckinStatus();
    if (status['success'] == true) {
      _checkedInToday = status['checked_in'] ?? false;
      _checkedOutToday = status['checked_out'] ?? false;
    }
  }
}
