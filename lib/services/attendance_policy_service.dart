import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class AttendancePolicyService {
  static const String baseUrl = 'https://jssolutions-eg.com';

  static Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    return ApiClient.buildHeaders(includeContentType: includeContentType);
  }

  // ── LIST POLICIES ──
  static Future<List<Map<String, dynamic>>> getPolicies() async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['policies'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب السياسات');
  }

  // ── GET POLICY ──
  static Future<Map<String, dynamic>> getPolicy(int policyId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['policy'];
    }
    throw Exception(data['error'] ?? 'خطأ في جلب السياسة');
  }

  // ── CREATE POLICY ──
  static Future<Map<String, dynamic>> createPolicy(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/'),
      headers: await _headers(),
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
    final res = await http.put(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/'),
      headers: await _headers(),
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
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? 'تم الحذف';
    }
    throw Exception(data['error'] ?? 'فشل الحذف');
  }

  // ── APPROVE POLICY ──
  static Future<Map<String, dynamic>> approvePolicy(int policyId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/approve/'),
      headers: await _headers(),
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
    final body = {
      'assignment_type': assignmentType,
      if (departmentId != null) 'department_id': departmentId,
      if (branchId != null) 'branch_id': branchId,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/assign/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل ربط السياسة');
  }
}
