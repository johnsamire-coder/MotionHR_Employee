import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class DisciplinaryService {
  static const String baseUrl = 'https://motion.jssolutions-eg.com';

  static Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    return ApiClient.buildHeaders(includeContentType: includeContentType);
  }

  // ── قواعد الجزاءات في السياسة ──
  static Future<List<Map<String, dynamic>>> getRules(int policyId) async {
    final res = await http.get(
      Uri.parse(
          '$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/disciplinary-rules/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['rules'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب القواعد');
  }

  static Future<Map<String, dynamic>> addRule(
      int policyId, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(
          '$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/disciplinary-rules/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) &&
        data['success'] == true) {
      return data['rule'];
    }
    throw Exception(data['error'] ?? 'فشل إضافة القاعدة');
  }

  static Future<void> deleteRule(int policyId, int ruleId) async {
    final res = await http.delete(
      Uri.parse(
          '$baseUrl/attendance/api/mobile/manager/attendance-policy/$policyId/disciplinary-rules/$ruleId/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'فشل الحذف');
    }
  }

  // ── جزاءات الموظفين ──
  static Future<List<Map<String, dynamic>>> getActions({
    int? employeeId,
    String? status,
    String? payrollMonth,
  }) async {
    final params = <String, String>{};
    if (employeeId != null) params['employee_id'] = employeeId.toString();
    if (status != null) params['status'] = status;
    if (payrollMonth != null) params['payroll_month'] = payrollMonth;
    final uri = Uri.parse(
            '$baseUrl/attendance/api/mobile/manager/disciplinary/actions/')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['actions'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب الجزاءات');
  }

  static Future<Map<String, dynamic>> addAction(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(
          '$baseUrl/attendance/api/mobile/manager/disciplinary/actions/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) &&
        data['success'] == true) {
      return data['action'];
    }
    throw Exception(data['error'] ?? 'فشل إضافة الجزاء');
  }

  static Future<Map<String, dynamic>> reviewAction(
      int actionId, String decision,
      {String notes = ''}) async {
    final res = await http.post(
      Uri.parse(
          '$baseUrl/attendance/api/mobile/manager/disciplinary/actions/$actionId/review/'),
      headers: await _headers(),
      body: jsonEncode({'decision': decision, 'notes': notes}),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['action'];
    }
    throw Exception(data['error'] ?? 'فشل المراجعة');
  }
}