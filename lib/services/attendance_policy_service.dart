import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AttendancePolicyService {
  static const String baseUrl = 'https://jssolutions-eg.com';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };

  // ── LIST POLICIES ──
  static Future<List<Map<String, dynamic>>> getPolicies() async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/'),
      headers: _headers(token),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['policies'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب السياسات');
  }

  // ── GET POLICY ──
  static Future<Map<String, dynamic>> getPolicy(int policyId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/'),
      headers: _headers(token),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['policy'];
    }
    throw Exception(data['error'] ?? 'خطأ في جلب السياسة');
  }

  // ── CREATE POLICY ──
  static Future<Map<String, dynamic>> createPolicy(Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل إنشاء السياسة');
  }

  // ── UPDATE POLICY ──
  static Future<Map<String, dynamic>> updatePolicy(int policyId, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.put(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل تعديل السياسة');
  }

  // ── DELETE POLICY ──
  static Future<String> deletePolicy(int policyId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/'),
      headers: _headers(token),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? 'تم الحذف';
    }
    throw Exception(data['error'] ?? 'فشل الحذف');
  }

  // ── APPROVE POLICY ──
  static Future<Map<String, dynamic>> approvePolicy(int policyId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/approve/'),
      headers: _headers(token),
      body: jsonEncode({}),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل الموافقة');
  }

  // ── ASSIGN POLICY ──
  static Future<Map<String, dynamic>> assignPolicy({
    required int policyId,
    required String assignmentType,
    int? departmentId,
    int? branchId,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final body = {
      'assignment_type': assignmentType,
      if (departmentId != null) 'department_id': departmentId,
      if (branchId != null) 'branch_id': branchId,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/assign/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل ربط السياسة');
  }
}
