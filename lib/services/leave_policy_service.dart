import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LeavePolicyService {
  static const String baseUrl = 'https://motion.jssolutions-eg.com';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };

  static Future<List<Map<String, dynamic>>> getPolicies() async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/'),
      headers: _headers(token),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['policies'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب السياسات');
  }

  static Future<Map<String, dynamic>> createPolicy(Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data['policy'];
    }
    throw Exception(data['error'] ?? 'فشل إنشاء السياسة');
  }

  static Future<Map<String, dynamic>> updatePolicy(int policyId, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.put(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/$policyId/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['policy'];
    }
    throw Exception(data['error'] ?? 'فشل تعديل السياسة');
  }

  static Future<String> deletePolicy(int policyId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/$policyId/'),
      headers: _headers(token),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? 'تم الحذف';
    }
    throw Exception(data['error'] ?? 'فشل الحذف');
  }

  static Future<Map<String, dynamic>> approvePolicy(int policyId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/$policyId/approve/'),
      headers: _headers(token),
      body: jsonEncode({}),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل الموافقة');
  }

  static Future<List<Map<String, dynamic>>> getBalanceAdjustments({int? employeeId}) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    String url = '$baseUrl/attendance/api/mobile/manager/leave-balance-adjustments/';
    if (employeeId != null) {
      url += '?employee_id=$employeeId';
    }
    final res = await http.get(Uri.parse(url), headers: _headers(token));
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['adjustments'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب التعديلات');
  }

  static Future<Map<String, dynamic>> addBalanceAdjustment(Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-balance-adjustments/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل التعديل');
  }
}
