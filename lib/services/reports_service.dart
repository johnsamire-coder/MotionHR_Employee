// lib/services/reports_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReportsService {
  static const String _base = 'https://jssolutions-eg.com/attendance';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    };
  }

  String _buildUrl(String endpoint, {
    int? year,
    int? month,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? employeeId,
  }) {
    final now = DateTime.now();
    final y = year ?? dateFrom?.year ?? now.year;
    final m = month ?? dateFrom?.month ?? now.month;

    var url = '$_base/$endpoint/?year=$y&month=$m';
    if (employeeId != null) url += '&employee_id=$employeeId';
    return url;
  }

  Future<Map<String, dynamic>> _get(String url) async {
    final headers = await _headers();
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  // ─── Attendance Report ───────────────────────────
  Future<Map<String, dynamic>> getAttendanceReport({
    int? year,
    int? month,
    int? employeeId,
  }) async {
    final url = _buildUrl(
      'api/mobile/manager/reports/attendance',
      year: year,
      month: month,
      employeeId: employeeId,
    );
    return _get(url);
  }

  // ─── Late Report ─────────────────────────────────
  Future<Map<String, dynamic>> getLateReport({
    int? year,
    int? month,
    int? employeeId,
  }) async {
    final url = _buildUrl(
      'api/mobile/manager/reports/late',
      year: year,
      month: month,
      employeeId: employeeId,
    );
    return _get(url);
  }

  // ─── Absence Report ──────────────────────────────
  Future<Map<String, dynamic>> getAbsenceReport({
    int? year,
    int? month,
    int? employeeId,
  }) async {
    final url = _buildUrl(
      'api/mobile/manager/reports/absence',
      year: year,
      month: month,
      employeeId: employeeId,
    );
    return _get(url);
  }

  // ─── Requests Report ─────────────────────────────
  Future<Map<String, dynamic>> getRequestsReport({
    int? year,
    int? month,
  }) async {
    final url = _buildUrl(
      'api/mobile/manager/reports/requests',
      year: year,
      month: month,
    );
    return _get(url);
  }

  // ─── Leaves Report ───────────────────────────────
  Future<Map<String, dynamic>> getLeavesReport({
    int? year,
    int? month,
  }) async {
    final url = _buildUrl(
      'api/mobile/manager/reports/leaves',
      year: year,
      month: month,
    );
    return _get(url);
  }

  // ─── Work Hours Report ───────────────────────────
  Future<Map<String, dynamic>> getWorkHoursReport({
    int? year,
    int? month,
    int? employeeId,
  }) async {
    final url = _buildUrl(
      'api/mobile/manager/reports/work-hours',
      year: year,
      month: month,
      employeeId: employeeId,
    );
    return _get(url);
  }
}