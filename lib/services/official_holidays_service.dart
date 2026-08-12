import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class OfficialHolidaysService {
  static const String baseUrl = 'https://jssolutions-eg.com';

  static Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    return ApiClient.buildHeaders(includeContentType: includeContentType);
  }

  // ═══════════════════════════════════════
  // جلب قائمة الإجازات الرسمية
  // ═══════════════════════════════════════
  static Future<List<Map<String, dynamic>>> getHolidays() async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/official-holidays/'),
      headers: await _headers(includeContentType: false),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return List<Map<String, dynamic>>.from(data['holidays'] ?? []);
    }
    throw Exception(data['error'] ?? 'خطأ في جلب الإجازات الرسمية');
  }

  // ═══════════════════════════════════════
  // جلب تفاصيل إجازة رسمية
  // ═══════════════════════════════════════
  static Future<Map<String, dynamic>> getHoliday(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/official-holidays/$id/'),
      headers: await _headers(includeContentType: false),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['holiday'] ?? {});
    }
    throw Exception(data['error'] ?? 'خطأ في جلب تفاصيل الإجازة');
  }

  // ═══════════════════════════════════════
  // إضافة إجازة رسمية جديدة
  // ═══════════════════════════════════════
  static Future<Map<String, dynamic>> createHoliday(
      Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/official-holidays/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if ((res.statusCode == 200 || res.statusCode == 201) &&
        data['success'] == true) {
      return Map<String, dynamic>.from(data['holiday'] ?? {});
    }
    throw Exception(data['error'] ?? 'خطأ في إضافة الإجازة الرسمية');
  }

  // ═══════════════════════════════════════
  // تعديل إجازة رسمية
  // ═══════════════════════════════════════
  static Future<Map<String, dynamic>> updateHoliday(
      int id, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/official-holidays/$id/'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['holiday'] ?? {});
    }
    throw Exception(data['error'] ?? 'خطأ في تعديل الإجازة الرسمية');
  }

  // ═══════════════════════════════════════
  // حذف إجازة رسمية
  // ═══════════════════════════════════════
  static Future<void> deleteHoliday(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/official-holidays/$id/'),
      headers: await _headers(includeContentType: false),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'خطأ في حذف الإجازة الرسمية');
    }
  }
}
