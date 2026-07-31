import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class LeavePolicyService {
  static const String baseUrl = 'https://motion.jssolutions-eg.com';

  static Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    return ApiClient.buildHeaders(includeContentType: includeContentType);
  }

  static Future<List<Map<String, dynamic>>> getPolicies() async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['policies'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب السياسات');
  }

  static Future<Map<String, dynamic>> createPolicy(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data['policy'];
    }
    throw Exception(data['error'] ?? 'فشل إنشاء السياسة');
  }

  static Future<Map<String, dynamic>> updatePolicy(int policyId, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/$policyId/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['policy'];
    }
    throw Exception(data['error'] ?? 'فشل تعديل السياسة');
  }

  static Future<String> deletePolicy(int policyId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/$policyId/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? 'تم الحذف';
    }
    throw Exception(data['error'] ?? 'فشل الحذف');
  }

  static Future<Map<String, dynamic>> approvePolicy(int policyId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/$policyId/approve/'),
      headers: await _headers(),
      body: jsonEncode({}),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل الموافقة');
  }

  static Future<List<Map<String, dynamic>>> getBalanceAdjustments({int? employeeId}) async {
    String url = '$baseUrl/attendance/api/mobile/manager/leave-balance-adjustments/';
    if (employeeId != null) {
      url += '?employee_id=$employeeId';
    }
    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['adjustments'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب التعديلات');
  }

  static Future<Map<String, dynamic>> addBalanceAdjustment(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-balance-adjustments/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل التعديل');
  }

  // الدالة الجديدة تنضاف هنا قبل القوس الأخير
  static Future<List<Map<String, dynamic>>> getLeaveTypes() async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/leave-types/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['leave_types'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب أنواع الإجازات');
  }

  static Future<Map<String, dynamic>> applyPolicyToExistingEmployees({
    int? year,
  }) async {

    final body = <String, dynamic>{};
    if (year != null) body['year'] = year;

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/leave-policy/apply-to-existing/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(data['error'] ?? data['message'] ?? 'فشل تطبيق السياسة على الموظفين الحاليين');
  }
}
