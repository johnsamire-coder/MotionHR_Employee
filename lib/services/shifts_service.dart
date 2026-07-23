import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ShiftsService {
  static const String baseUrl = 'https://jssolutions-eg.com';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };

  // ─────────────────────────────────────────────
  // LIST SHIFTS
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getShifts({String lang = 'ar'}) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/?lang=$lang'),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['shifts'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب الشيفتات');
  }

  // ─────────────────────────────────────────────
  // CREATE SHIFT
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> createShift(Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/create/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل إنشاء الشيفت');
  }

  // ─────────────────────────────────────────────
  // UPDATE SHIFT
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> updateShift(int shiftId, Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.patch(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/$shiftId/update/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) return data;
    throw Exception(data['error'] ?? 'فشل تحديث الشيفت');
  }

  // ─────────────────────────────────────────────
  // DELETE SHIFT
  // ─────────────────────────────────────────────
  static Future<String> deleteShift(int shiftId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/$shiftId/delete/'),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? 'تم الحذف';
    }
    throw Exception(data['error'] ?? 'فشل الحذف');
  }

  // ─────────────────────────────────────────────
  // ASSIGN SHIFT (قد يحتاج موافقة)
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> assignShift({
    required int employeeId,
    required int shiftId,
    required String startDate,
    String? endDate,
    String? reason,
    String lang = 'ar',
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final body = <String, dynamic>{
      'employee_id': employeeId,
      'shift_id': shiftId,
      'start_date': startDate,
      'lang': lang,
    };
    if (endDate != null && endDate.isNotEmpty) body['end_date'] = endDate;
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/assign/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل تعيين الشيفت');
  }

  // ─────────────────────────────────────────────
  // EMPLOYEE SHIFTS
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getEmployeeShifts(int employeeId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/employees/$employeeId/shifts/'),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['assignments'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب شيفتات الموظف');
  }

  // ─────────────────────────────────────────────
  // MY SHIFT
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyShift() async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/my-shift/'),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'خطأ في جلب شيفتك');
  }

  // ─────────────────────────────────────────────
  // SHIFT CHANGE REQUESTS (HR)
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getShiftChangeRequests({String status = 'pending'}) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/change-requests/?status=$status'),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['requests'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب الطلبات');
  }

  static Future<Map<String, dynamic>> handleShiftChangeRequest({
    required int requestId,
    required String action, // approve / reject
    String? rejectionReason,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final body = {
      'action': action,
      if (rejectionReason != null) 'rejection_reason': rejectionReason,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/change-requests/$requestId/action/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل تنفيذ الطلب');
  }

  // ─────────────────────────────────────────────
  // SHIFT OVERRIDE
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> createShiftOverride({
    required int employeeId,
    required int shiftId,
    required String overrideDate,
    String? reason,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final body = {
      'employee_id': employeeId,
      'shift_id': shiftId,
      'override_date': overrideDate,
      if (reason != null) 'reason': reason,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/override/create/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل إنشاء الاستثناء');
  }

  static Future<String> deleteShiftOverride(int overrideId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/override/$overrideId/delete/'),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? 'تم الحذف';
    }
    throw Exception(data['error'] ?? 'فشل حذف الاستثناء');
  }

  // ─────────────────────────────────────────────
  // SHIFT EMPLOYEES
  // ─────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getShiftEmployees(int shiftId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/$shiftId/employees/'),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['employees'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب موظفي الشيفت');
  }

  // ─────────────────────────────────────────────
  // EFFECTIVE SHIFT
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEffectiveShift(int employeeId, {String? date}) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final uri = date != null
        ? '$baseUrl/attendance/api/mobile/manager/employees/$employeeId/effective-shift/?date=$date'
        : '$baseUrl/attendance/api/mobile/manager/employees/$employeeId/effective-shift/';

    final res = await http.get(
      Uri.parse(uri),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'خطأ في جلب الشيفت الفعلي');
  }
}

