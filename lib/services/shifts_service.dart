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
    required int employeeId,
    required int shiftId,
    required String startDate,
    String? endDate,
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
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/shifts/assign/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) && data['success'] == true)
      return data;
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
}
