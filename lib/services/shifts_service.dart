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

  // ── LIST SHIFTS ──
  static Future<List<Map<String, dynamic>>> getShifts({String lang = 'ar'}) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/?lang=$lang'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true)
        return List<Map<String, dynamic>>.from(data['shifts'] ?? []);
      throw Exception(data['error'] ?? 'خطأ في جلب الشيفتات');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── CREATE SHIFT ──
  static Future<Map<String, dynamic>> createShift(Map<String, dynamic> body) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/create/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true)
      return data;
    throw Exception(data['error'] ?? 'فشل إنشاء الشيفت');
  }

  // ── UPDATE SHIFT ──
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

  // ── DELETE SHIFT ──
  static Future<String> deleteShift(int shiftId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/$shiftId/delete/'),
      headers: _headers(token),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true)
      return data['message'] ?? 'تم الحذف';
    throw Exception(data['error'] ?? 'فشل الحذف');
  }

  // ── ASSIGN SHIFT ──
  static Future<Map<String, dynamic>> assignShift({
    int? employeeId,
    int? departmentId,
    int? branchId,
    bool assignToCompany = false,
    required int shiftId,
    required String startDate,
    String? endDate,
    String? reason,
    String lang = 'ar',
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    String assignmentType = 'employee';
    final body = <String, dynamic>{
      'shift_id': shiftId,
      'start_date': startDate,
      'lang': lang,
    };

    if (assignToCompany == true) {
      assignmentType = 'company';
    } else if (departmentId != null) {
      assignmentType = 'department';
      body['department_id'] = departmentId;
    } else if (branchId != null) {
      assignmentType = 'branch';
      body['branch_id'] = branchId;
    } else if (employeeId != null) {
      assignmentType = 'employee';
      body['employee_id'] = employeeId;
    } else {
      throw Exception('لازم تختار موظف أو قسم أو فرع أو الشركة كلها');
    }

    body['assignment_type'] = assignmentType;

    if (endDate != null && endDate.isNotEmpty) {
      body['end_date'] = endDate;
    }
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }

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
  // ── SHIFT EMPLOYEES ──
  static Future<List<Map<String, dynamic>>> getShiftEmployees(int shiftId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/$shiftId/employees/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true)
        return List<Map<String, dynamic>>.from(data['employees'] ?? []);
      throw Exception(data['error'] ?? 'خطأ');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── EMPLOYEE SHIFTS ──
  static Future<List<Map<String, dynamic>>> getEmployeeShifts(int employeeId) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/employees/$employeeId/shifts/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true)
        return List<Map<String, dynamic>>.from(data['assignments'] ?? []);
      throw Exception(data['error'] ?? 'خطأ');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }


  // MY SHIFT
  static Future<Map<String, dynamic>> getMyShift() async {
    final token = await _getToken();
    if (token == null) throw Exception('??? ???? ??????');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/my-shift/'),
      headers: _headers(token),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? '??? ?? ??? ?????');
  }

  // SHIFT CHANGE REQUESTS
  static Future<List<Map<String, dynamic>>> getShiftChangeRequests({String status = 'pending'}) async {
    final token = await _getToken();
    if (token == null) throw Exception('??? ???? ??????');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/change-requests/?status=$status'),
      headers: _headers(token),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['requests'] ?? []);
    }
    throw Exception(data['error'] ?? '??? ?? ??? ???????');
  }

  // HANDLE SHIFT CHANGE REQUEST
  static Future<Map<String, dynamic>> handleShiftChangeRequest({
    required int requestId,
    required String action,
    String? rejectionReason,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('??? ???? ??????');

    final body = {
      'action': action,
      if (rejectionReason != null && rejectionReason.isNotEmpty)
        'rejection_reason': rejectionReason,
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
    throw Exception(data['error'] ?? '??? ????? ?????');
  }

  // SHIFT OVERRIDE
  static Future<Map<String, dynamic>> createShiftOverride({
    required int employeeId,
    required int shiftId,
    required String overrideDate,
    String? reason,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('??? ???? ??????');

    final body = {
      'employee_id': employeeId,
      'shift_id': shiftId,
      'override_date': overrideDate,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
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
    throw Exception(data['error'] ?? '??? ????? ?????????');
  }

  // DELETE SHIFT OVERRIDE
  static Future<String> deleteShiftOverride(int overrideId) async {
    final token = await _getToken();
    if (token == null) throw Exception('??? ???? ??????');

    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/override/$overrideId/delete/'),
      headers: _headers(token),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? '?? ?????';
    }
    throw Exception(data['error'] ?? '??? ??? ?????????');
  }

  // EFFECTIVE SHIFT
  static Future<Map<String, dynamic>> getEffectiveShift(int employeeId, {String? date}) async {
    final token = await _getToken();
    if (token == null) throw Exception('??? ???? ??????');

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
    throw Exception(data['error'] ?? '??? ?? ??? ?????? ??????');
  }

}
