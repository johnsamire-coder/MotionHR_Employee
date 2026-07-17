import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrlPayroll = 'https://jssolutions-eg.com';

class PayrollService {
  Future<Map<String, dynamic>> _get(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$kBaseUrlPayroll$url'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return Map<String, dynamic>.from(decoded as Map);
    } else {
      throw Exception('Failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getSummary({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get('/attendance/api/mobile/manager/payroll/summary/?year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getEmployeeDetail({
    required int employeeId,
    int? year,
    int? month,
  }) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get('/attendance/api/mobile/manager/payroll/employee/?employee_id=$employeeId&year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getSettings() async {
    return _get('/attendance/api/mobile/manager/payroll/settings/');
  }
}
