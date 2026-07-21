import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage_service.dart';

class PayrollRunService {
  static const String _base = 'https://jssolutions-eg.com/api';

  static Future<String?> _getToken() async {
    return AuthStorageService.getSavedToken();
  }

  static Map<String, String> _headers(String token) => {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

  // ─── List Runs ─────────────────────────────
  static Future<Map<String, dynamic>> getPayrollRuns({
    int? year,
    int? month,
  }) async {
    final token = await _getToken();
    if (token == null) return {'error': 'no_token'};
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final uri = Uri.parse('$_base/payroll/runs/?year=$y&month=$m');
    try {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return {'error': 'status_${res.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Create Run ────────────────────────────
  static Future<Map<String, dynamic>> createPayrollRun({
    required int year,
    required int month,
  }) async {
    final token = await _getToken();
    if (token == null) return {'error': 'no_token'};
    final uri = Uri.parse('$_base/payroll/runs/create/');
    try {
      final res = await http
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({'year': year, 'month': month}),
          )
          .timeout(const Duration(seconds: 30));
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Approve Run ───────────────────────────
  static Future<Map<String, dynamic>> approvePayrollRun(int runId) async {
    final token = await _getToken();
    if (token == null) return {'error': 'no_token'};
    final uri = Uri.parse('$_base/payroll/runs/$runId/approve/');
    try {
      final res = await http
          .post(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Lock Run ──────────────────────────────
  static Future<Map<String, dynamic>> lockPayrollRun(int runId) async {
    final token = await _getToken();
    if (token == null) return {'error': 'no_token'};
    final uri = Uri.parse('$_base/payroll/runs/$runId/lock/');
    try {
      final res = await http
          .post(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Run Lines ─────────────────────────────
  static Future<Map<String, dynamic>> getRunLines(int runId) async {
    final token = await _getToken();
    if (token == null) return {'error': 'no_token'};
    final uri = Uri.parse('$_base/payroll/runs/$runId/lines/');
    try {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return {'error': 'status_${res.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Adjustments ───────────────────────────
  static Future<Map<String, dynamic>> getBonusesPenalties({
    required int runId,
    int? employeeId,
  }) async {
    final token = await _getToken();
    if (token == null) return {'error': 'no_token'};
    var url = '$_base/payroll/runs/$runId/adjustments/';
    if (employeeId != null) url += '?employee_id=$employeeId';
    final uri = Uri.parse(url);
    try {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return {'error': 'status_${res.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addAdjustment({
    required int runId,
    required int employeeId,
    required String type,
    required double amount,
    required String reason,
  }) async {
    final token = await _getToken();
    if (token == null) return {'error': 'no_token'};
    final uri = Uri.parse('$_base/payroll/runs/$runId/adjustments/add/');
    try {
      final res = await http
          .post(
            uri,
            headers: _headers(token),
            body: jsonEncode({
              'employee_id': employeeId,
              'type': type,
              'amount': amount,
              'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 15));
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteAdjustment(int adjustmentId) async {
    final token = await _getToken();
    if (token == null) return {'error': 'no_token'};
    final uri = Uri.parse('$_base/payroll/adjustments/$adjustmentId/delete/');
    try {
      final res = await http
          .delete(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ─── Payslip ───────────────────────────────
  static Future<Map<String, dynamic>> getPayslipData({
    required int employeeId,
    required int year,
    required int month,
  }) async {
    final token = await _getToken();
    if (token == null) return {'error': 'no_token'};
    final uri = Uri.parse(
        '$_base/payroll/payslip/?employee_id=$employeeId&year=$year&month=$month');
    try {
      final res = await http
          .get(uri, headers: _headers(token))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return {'error': 'status_${res.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
