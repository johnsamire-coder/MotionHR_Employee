import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class PayrollRunService {
  static const String _base =
      'https://motion.jssolutions-eg.com/attendance/api/mobile/manager';

  static Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    return ApiClient.buildHeaders(includeContentType: includeContentType);
  }

  // ─── List Runs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPayrollRuns({
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;
    final uri = Uri.parse('$_base/payroll/runs/?year=$y&month=$m');
    try {
      final res = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return {'success': false, 'error': 'status_${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── Create Run ────────────────────────────────────────────
  static Future<Map<String, dynamic>> createPayrollRun({
    required int year,
    required int month,
    String? notes,
  }) async {
    final uri = Uri.parse('$_base/payroll/run/create/');
    try {
      final res = await http
          .post(
            uri,
            headers: await _headers(),
            body: jsonEncode({
              'year': year,
              'month': month,
              if (notes != null && notes.isNotEmpty) 'notes': notes,
            }),
          )
          .timeout(const Duration(seconds: 60));
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── Approve Run ───────────────────────────────────────────
  static Future<Map<String, dynamic>> approvePayrollRun(int runId) async {
    final uri = Uri.parse('$_base/payroll/runs/$runId/approve/');
    try {
      final res = await http
          .post(uri, headers: await _headers())
          .timeout(const Duration(seconds: 20));
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── Run Detail + Lines ────────────────────────────────────
  static Future<Map<String, dynamic>> getRunLines(int runId) async {
    final uri = Uri.parse('$_base/payroll/runs/$runId/');
    try {
      final res = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return {'success': false, 'error': 'status_${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── Payslip (من payroll_employee_detail API) ──────────────
  static Future<Map<String, dynamic>> getPayslipData({
    required int employeeId,
    required int year,
    required int month,
  }) async {
    final uri = Uri.parse(
        'https://motion.jssolutions-eg.com/attendance/api/mobile/manager'
        '/payroll/employee/?employee_id=$employeeId&year=$year&month=$month');
    try {
      final res = await http
          .get(uri, headers: await _headers())
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
      return {'success': false, 'error': 'status_${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── Lock Run (placeholder - not implemented yet) ──────────
  static Future<Map<String, dynamic>> lockPayrollRun(int runId) async {
    // TODO: implement lock API in backend
    return {'success': false, 'error': 'not_implemented'};
  }

  // ─── Adjustments (placeholder - not implemented yet) ───────
  static Future<Map<String, dynamic>> getBonusesPenalties({
    required int runId,
    int? employeeId,
  }) async {
    // TODO: implement adjustments API in backend
    return {'success': false, 'adjustments': [], 'error': 'not_implemented'};
  }

  static Future<Map<String, dynamic>> addAdjustment({
    required int runId,
    required int employeeId,
    required String type,
    required double amount,
    required String reason,
  }) async {
    // TODO: implement add adjustment API in backend
    return {'success': false, 'error': 'not_implemented'};
  }

  static Future<Map<String, dynamic>> deleteAdjustment(
      int adjustmentId) async {
    // TODO: implement delete adjustment API in backend
    return {'success': false, 'error': 'not_implemented'};
  }
}
