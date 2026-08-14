import 'dart:convert';
import 'package:motionhr_employee/services/api_client.dart';

class FlexAdjustmentService {
  static const String baseUrl = "https://jssolutions-eg.com";

  // 1) List Flex Adjustments
  static Future<List<Map<String, dynamic>>> getFlexAdjustments({
    String status = "pending",
    int? employeeId,
  }) async {
    String url =
        "$baseUrl/attendance/api/mobile/manager/flex-adjustments/?status=$status";

    if (employeeId != null) {
      url += "&employee_id=$employeeId";
    }

    final res = await ApiClient.get(Uri.parse(url));
    final data = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && data["success"] == true) {
      return List<Map<String, dynamic>>.from(data["adjustments"]);
    }

    throw Exception(data["error"] ?? "فشل جلب التسويات");
  }

  // 2) Review (Approve / Reject)
  static Future<String> reviewFlexAdjustment({
    required int adjustmentId,
    required String action,
    String? notes,
  }) async {
    final body = {
      "action": action,
      if (notes != null && notes.isNotEmpty) "notes": notes,
    };

    final res = await ApiClient.post(
      Uri.parse(
        "$baseUrl/attendance/api/mobile/manager/flex-adjustments/$adjustmentId/review/",
      ),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && data["success"] == true) {
      return data["message"] ?? "تمت العملية بنجاح";
    }

    throw Exception(data["error"] ?? "فشل تنفيذ العملية");
  }

  // 3) Employee Flex Adjustments
  static Future<List<Map<String, dynamic>>> getEmployeeFlexAdjustments(
    int employeeId,
  ) async {
    final res = await ApiClient.get(
      Uri.parse(
        "$baseUrl/attendance/api/mobile/manager/employees/$employeeId/flex-adjustments/",
      ),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && data["success"] == true) {
      return List<Map<String, dynamic>>.from(data["adjustments"]);
    }

    throw Exception(data["error"] ?? "فشل جلب تسويات الموظف");
  }
}
