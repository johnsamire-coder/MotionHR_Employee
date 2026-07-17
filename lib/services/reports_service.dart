import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'https://jssolutions-eg.com';

class ReportsService {
  Future<Map<String, dynamic>> _get(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$kBaseUrl$url'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return Map<String, dynamic>.from(decoded as Map);
    } else {
      throw Exception('Failed to load: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getAttendanceReport({int? year, int? month, int? employeeId}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '/attendance/api/mobile/manager/reports/attendance/?year=$y&month=$m';
    if (employeeId != null) {
      url += '&employee_id=$employeeId';
    }
    return _get(url);
  }

  Future<Map<String, dynamic>> getLateReport({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get('/attendance/api/mobile/manager/reports/late/?year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getAbsenceReport({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get('/attendance/api/mobile/manager/reports/absence/?year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getRequestsReport({int? year, int? month, String? status}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '/attendance/api/mobile/manager/reports/requests/?year=$y&month=$m';
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }
    return _get(url);
  }

  Future<Map<String, dynamic>> getLeavesReport({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get('/attendance/api/mobile/manager/reports/leaves/?year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getWorkHoursReport({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get('/attendance/api/mobile/manager/reports/work-hours/?year=$y&month=$m');
  }
}
