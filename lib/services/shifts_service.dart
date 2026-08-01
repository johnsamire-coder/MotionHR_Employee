import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class ShiftsService {
  static const String baseUrl = 'https://jssolutions-eg.com';

  static Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    return ApiClient.buildHeaders(includeContentType: includeContentType);
  }

  // ── LIST SHIFTS ──
  static Future<List<Map<String, dynamic>>> getShifts({String lang = 'ar'}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/?lang=$lang'),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['shifts'] ?? []);
      }
      throw Exception(data['error'] ?? 'خطأ في جلب الشيفتات');
    }

    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── CREATE SHIFT ──
  static Future<Map<String, dynamic>> createShift(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/create/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }

    throw Exception(data['error'] ?? 'فشل إنشاء الشيفت');
  }

  // ── UPDATE SHIFT ──
  static Future<Map<String, dynamic>> updateShift(int shiftId, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/$shiftId/update/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['error'] ?? 'فشل تحديث الشيفت');
  }

  // ── DELETE SHIFT ──
  static Future<String> deleteShift(int shiftId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/$shiftId/delete/'),
      headers: await _headers(),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? 'تم الحذف';
    }

    throw Exception(data['error'] ?? 'فشل الحذف');
  }

  // ── ASSIGN SHIFT ──
  static Future<Map<String, dynamic>> assignShift({
    int? employeeId,
    int? departmentId,
    int? branchId,
    List<int>? employeeIds,
    List<int>? departmentIds,
    List<int>? branchIds,
    List<int>? excludedEmployeeIds,
    bool assignToCompany = false,
    required int shiftId,
    required String startDate,
    String? endDate,
    String? reason,
    String lang = 'ar',
  }) async {
final allEmployeeIds = <int>{
      if (employeeId != null) employeeId,
      ...?employeeIds,
    }.toList();

    final allDepartmentIds = <int>{
      if (departmentId != null) departmentId,
      ...?departmentIds,
    }.toList();

    final allBranchIds = <int>{
      if (branchId != null) branchId,
      ...?branchIds,
    }.toList();

    final allExcludedEmployeeIds = <int>{
      ...?excludedEmployeeIds,
    }.toList();

    final body = <String, dynamic>{
      'shift_id': shiftId,
      'start_date': startDate,
      'lang': lang,
      'assign_to_company': assignToCompany,
    };

    if (allEmployeeIds.isNotEmpty) {
      body['employee_ids'] = allEmployeeIds;
    }
    if (allDepartmentIds.isNotEmpty) {
      body['department_ids'] = allDepartmentIds;
    }
    if (allBranchIds.isNotEmpty) {
      body['branch_ids'] = allBranchIds;
    }
    if (allExcludedEmployeeIds.isNotEmpty) {
      body['excluded_employee_ids'] = allExcludedEmployeeIds;
    }

    if (endDate != null && endDate.isNotEmpty) {
      body['end_date'] = endDate;
    }
    if (reason != null && reason.isNotEmpty) {
      body['reason'] = reason;
    }

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/assign/'),
      headers: await _headers(),
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
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/$shiftId/employees/'),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['employees'] ?? []);
      }
      throw Exception(data['error'] ?? 'خطأ في جلب موظفي الشيفت');
    }

    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── EMPLOYEE SHIFTS ──
  static Future<List<Map<String, dynamic>>> getEmployeeShifts(int employeeId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/employees/$employeeId/shifts/'),
      headers: await _headers(),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['assignments'] ?? []);
      }
      throw Exception(data['error'] ?? 'خطأ في جلب شيفتات الموظف');
    }

    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── MY SHIFT ──
  static Future<Map<String, dynamic>> getMyShift() async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/my-shift/'),
      headers: await _headers(),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['error'] ?? 'خطأ في جلب شيفتك');
  }

  // ── SHIFT CHANGE REQUESTS ──
  static Future<List<Map<String, dynamic>>> getShiftChangeRequests({
    String status = 'pending',
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/change-requests/?status=$status'),
      headers: await _headers(),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['requests'] ?? []);
    }

    throw Exception(data['error'] ?? 'خطأ في جلب الطلبات');
  }

  // ── HANDLE SHIFT CHANGE REQUEST ──
  static Future<Map<String, dynamic>> handleShiftChangeRequest({
    required int requestId,
    required String action,
    String? rejectionReason,
  }) async {
final body = {
      'action': action,
      if (rejectionReason != null && rejectionReason.isNotEmpty)
        'rejection_reason': rejectionReason,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/change-requests/$requestId/action/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['error'] ?? 'فشل تنفيذ الطلب');
  }

  // ── GET SHIFT OVERRIDES LIST ──
  static Future<List<Map<String, dynamic>>> getShiftOverrides({
    bool showPast = false,
    int? employeeId,
    String lang = 'ar',
  }) async {

    var url = '\$baseUrl/attendance/api/mobile/manager/shifts/overrides/?lang=\$lang&show_past=\${showPast ? "true" : "false"}';
    if (employeeId != null) url += '&employee_id=\$employeeId';

    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = jsonDecode(utf8.decode(res.bodyBytes));

    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['overrides'] ?? []);
    }
    throw Exception(data['error'] ?? 'فشل جلب الاستثناءات');
  }

  // ── SHIFT OVERRIDE ──
  static Future<Map<String, dynamic>> createShiftOverride({
    required int employeeId,
    required int shiftId,
    required String overrideDate,
    String? reason,
  }) async {
final body = {
      'employee_id': employeeId,
      'shift_id': shiftId,
      'override_date': overrideDate,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/override/create/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }

    throw Exception(data['error'] ?? 'فشل إنشاء الاستثناء');
  }

  // ── DELETE SHIFT OVERRIDE ──
  static Future<String> deleteShiftOverride(int overrideId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/override/$overrideId/delete/'),
      headers: await _headers(),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data['message'] ?? 'تم الحذف';
    }

    throw Exception(data['error'] ?? 'فشل حذف الاستثناء');
  }

  // ── EFFECTIVE SHIFT ──
  static Future<Map<String, dynamic>> getEffectiveShift(int employeeId, {String? date}) async {
    final uri = date != null
        ? '$baseUrl/attendance/api/mobile/manager/employees/$employeeId/effective-shift/?date=$date'
        : '$baseUrl/attendance/api/mobile/manager/employees/$employeeId/effective-shift/';

    final res = await http.get(
      Uri.parse(uri),
      headers: await _headers(),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }

    throw Exception(data['error'] ?? 'خطأ في جلب الشيفت الفعلي');
  }

  // جلب استثناءات الشيفتات (الأخيرة 24)
  static Future<List<Map<String, dynamic>>> getShiftAssignments({int? shiftId}) async {
    final uri = shiftId != null
        ? '$baseUrl/attendance/api/mobile/manager/shifts/assignments/?shift_id=$shiftId'
        : '$baseUrl/attendance/api/mobile/manager/shifts/assignments/';

    final res = await http.get(
      Uri.parse(uri),
      headers: await _headers(),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['assignments'] ?? []);
    }

    throw Exception(data['error'] ?? 'فشل حذف الاستثناء');
  }

  static Future<bool> deleteAssignment(int assignmentId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/assignments/$assignmentId/delete/'),
      headers: await _headers(),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return res.statusCode == 200 && data['success'] == true;
  }

  static Future<bool> updateAssignment(int assignmentId, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/assignments/$assignmentId/update/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return res.statusCode == 200 && data['success'] == true;
  }
  // ── ROTATION APIs ──
  static Future<List<Map<String, dynamic>>> getRotations() async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/rotations/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['rotations'] ?? []);
    }
    throw Exception(data['error'] ?? 'فشل جلب التناوبات');
  }

  static Future<Map<String, dynamic>> createRotation({
    required String name,
    required int cycleLengthDays,
    required String startDate,
    required List<Map<String, dynamic>> slots,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/rotations/'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'cycle_length_days': cycleLengthDays,
        'start_date': startDate,
        'slots': slots,
      }),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل إنشاء التناوب');
  }

  static Future<bool> deleteRotation(int rotationId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/rotations/$rotationId/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return res.statusCode == 200 && data['success'] == true;
  }

  static Future<Map<String, dynamic>> assignRotation({
    required int rotationId,
    required String assignmentType,
    required String startDate,
    String? endDate,
    int? employeeId,
    int? departmentId,
    int? branchId,
  }) async {
    final body = <String, dynamic>{
      'assignment_type': assignmentType,
      'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (employeeId != null) 'employee_id': employeeId,
      if (departmentId != null) 'department_id': departmentId,
      if (branchId != null) 'branch_id': branchId,
    };
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/rotations/$rotationId/assign/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'فشل تعيين التناوب');
  }

  static Future<List<Map<String, dynamic>>> getRotationAssignments(int rotationId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/rotations/$rotationId/assignments/'),
      headers: await _headers(),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['assignments'] ?? []);
    }
    throw Exception(data['error'] ?? 'فشل جلب التعيينات');
  }
    // ── LEAVE RECALL APIs ──
  static Future<Map<String, dynamic>> createLeaveRecall({
    required int employeeId,
    required String recallDate,
    required String reason,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/leave-recall/create/'),
      headers: await _headers(),
      body: jsonEncode({
        'employee_id': employeeId,
        'recall_date': recallDate,
        'reason': reason,
      }),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true) {
      return data;
    }
    throw Exception(data['message'] ?? 'فشل إنشاء طلب الاستدعاء');
  }

  static Future<List<Map<String, dynamic>>> getLeaveRecalls({String? status}) async {
    var url = '$baseUrl/attendance/api/mobile/leave-recall/list/';
    if (status != null) url += '?status=$status';
    final res = await http.get(Uri.parse(url), headers: await _headers());
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['recalls'] ?? []);
    }
    throw Exception(data['message'] ?? 'فشل جلب الاستدعاءات');
  }

  static Future<Map<String, dynamic>> reviewLeaveRecall({
    required int recallId,
    required String action,
    String? notes,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/leave-recall/$recallId/review/'),
      headers: await _headers(),
      body: jsonEncode({
        'action': action,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['message'] ?? 'فشل مراجعة طلب الاستدعاء');
  }
}