import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportsService {
  static const String _base = 'https://jssolutions-eg.com/attendance';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
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

  Future<Map<String, dynamic>> getAttendanceReport({int? year, int? month, int? employeeId}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '$_base/api/mobile/manager/reports/attendance/?year=$y&month=$m';
    if (employeeId != null) url += '&employee_id=$employeeId';
    return _get(url);
  }

  Future<Map<String, dynamic>> getLateReport({int? year, int? month, int? employeeId}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '$_base/api/mobile/manager/reports/late/?year=$y&month=$m';
    if (employeeId != null) url += '&employee_id=$employeeId';
    return _get(url);
  }

  Future<Map<String, dynamic>> getAbsenceReport({int? year, int? month, int? employeeId}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '$_base/api/mobile/manager/reports/absence/?year=$y&month=$m';
    if (employeeId != null) url += '&employee_id=$employeeId';
    return _get(url);
  }

  Future<Map<String, dynamic>> getRequestsReport({int? year, int? month, int? employeeId, String? status}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '$_base/api/mobile/manager/reports/requests/?year=$y&month=$m';
    if (employeeId != null) url += '&employee_id=$employeeId';
    if (status != null) url += '&status=$status';
    return _get(url);
  }

  Future<Map<String, dynamic>> getLeavesReport({int? year, int? month, int? employeeId, String? status}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '$_base/api/mobile/manager/reports/leaves/?year=$y&month=$m';
    if (employeeId != null) url += '&employee_id=$employeeId';
    if (status != null) url += '&status=$status';
    return _get(url);
  }

  Future<Map<String, dynamic>> getWorkHoursReport({int? year, int? month, int? employeeId}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '$_base/api/mobile/manager/reports/work-hours/?year=$y&month=$m';
    if (employeeId != null) url += '&employee_id=$employeeId';
    return _get(url);
  }
}