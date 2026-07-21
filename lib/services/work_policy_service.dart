import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorkPolicyService {
  static const String _base = 'https://jssolutions-eg.com/attendance';

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('auth_token') ?? '';
  }

  static Future<Map<String, dynamic>> getPolicy() async {
    final token = await _getToken();
    try {
      final res = await http.get(
        Uri.parse('$_base/api/mobile/manager/work-policy/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      }
    } catch (_) {}
    return {
      'work_sunday': true,
      'work_monday': true,
      'work_tuesday': true,
      'work_wednesday': true,
      'work_thursday': true,
      'work_friday': false,
      'work_saturday': true,
      'is_24_7': false,
    };
  }

  static Future<bool> savePolicy(Map<String, dynamic> policy) async {
    final token = await _getToken();
    try {
      final res = await http.post(
        Uri.parse('$_base/api/mobile/manager/work-policy/save/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(policy),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}