import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FlexAdjustmentService {
  static const String baseUrl = "https://motion.jssolutions-eg.com";

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Map<String, String> _headers(String token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Token $token",
    };
  }

  // ✅ 1) List Flex Adjustments
  static Future<List<Map<String, dynamic>>> getFlexAdjustments({
    String status = "pending",
    int? employeeId,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("غير مسجل الدخول");
    }

    String url =
        "$baseUrl/attendance/api/mobile/manager/flex-adjustments/?status=$status";

    if (employeeId != null) {
      url += "&employee_id=$employeeId";
    }

    final res = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && data["success"] == true) {
      return List<Map<String, dynamic>>.from(data["adjustments"]);
    }

    throw Exception(data["error"] ?? "فشل جلب التسويات");
  }

  // ✅ 2) Review (Approve / Reject)
  static Future<String> reviewFlexAdjustment({
    required int adjustmentId,
    required String action, // approve / reject
    String? notes,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("غير مسجل الدخول");
    }

    final body = {
      "action": action,
      if (notes != null && notes.isNotEmpty) "notes": notes,
    };

    final res = await http.post(
      Uri.parse(
          "$baseUrl/attendance/api/mobile/manager/flex-adjustments/$adjustmentId/review/"),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && data["success"] == true) {
      return data["message"] ?? "تمت العملية بنجاح";
    }

    throw Exception(data["error"] ?? "فشل تنفيذ العملية");
  }

  // ✅ 3) Employee Flex Adjustments
  static Future<List<Map<String, dynamic>>> getEmployeeFlexAdjustments(
      int employeeId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("غير مسجل الدخول");
    }

    final res = await http.get(
      Uri.parse(
          "$baseUrl/attendance/api/mobile/manager/employees/$employeeId/flex-adjustments/"),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && data["success"] == true) {
      return List<Map<String, dynamic>>.from(data["adjustments"]);
    }

    throw Exception(data["error"] ?? "فشل جلب تسويات الموظف");
  }
}