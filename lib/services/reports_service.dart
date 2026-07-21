import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportsService {
  static const String _base = 'https://jssolutions-eg.com/attendance';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> _get(String url) async {
    final headers = await _headers();
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Error ${response.statusCode}');
  }

  String _buildUrl(
    String path, {
    required int year,
    required int month,
    int? employeeId,
    String? status,
  }) {
    final params = <String, String>{
      'year': '$year',
      'month': '$month',
    };
    if (employeeId != null) params['employee_id'] = '$employeeId';
    if (status != null && status.isNotEmpty) params['status'] = status;
    return '$_base/api/mobile/manager/reports/$path/?${Uri(queryParameters: params).query}';
  }

  Future<Map<String, dynamic>> getAttendanceReport({
    int? year,
    int? month,
    int? employeeId,
  }) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get(_buildUrl('attendance', year: y, month: m, employeeId: employeeId));
  }

  Future<Map<String, dynamic>> getLateReport({
    int? year,
    int? month,
    int? employeeId,
  }) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get(_buildUrl('late', year: y, month: m, employeeId: employeeId));
  }

  Future<Map<String, dynamic>> getAbsenceReport({
    int? year,
    int? month,
    int? employeeId,
  }) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get(_buildUrl('absence', year: y, month: m, employeeId: employeeId));
  }

  Future<Map<String, dynamic>> getRequestsReport({
    int? year,
    int? month,
    int? employeeId,
    String? status,
  }) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get(_buildUrl(
      'requests',
      year: y,
      month: m,
      employeeId: employeeId,
      status: status,
    ));
  }

  Future<Map<String, dynamic>> getLeavesReport({
    int? year,
    int? month,
    int? employeeId,
    String? status,
  }) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get(_buildUrl(
      'leaves',
      year: y,
      month: m,
      employeeId: employeeId,
      status: status,
    ));
  }

  Future<Map<String, dynamic>> getWorkHoursReport({
    int? year,
    int? month,
    int? employeeId,
  }) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get(_buildUrl('work-hours', year: y, month: m, employeeId: employeeId));
  }
}
