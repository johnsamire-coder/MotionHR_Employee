import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PayrollService {
  static const String _base = 'https://jssolutions-eg.com/attendance';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
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

  Future<Map<String, dynamic>> getSummary({int? year, int? month}) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    return _get('$_base/api/mobile/manager/payroll/summary/?year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getEmployeeDetail({
    required int employeeId,
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    return _get(
        '$_base/api/mobile/manager/payroll/employee/?employee_id=$employeeId&year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getSettings() async {
    return _get('$_base/api/mobile/manager/payroll/settings/');
  }

  Future<Map<String, dynamic>> getMyPayslip({int? year, int? month}) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    return _get('$_base/api/mobile/employee/payslip/?year=$y&month=$m');
  }
}