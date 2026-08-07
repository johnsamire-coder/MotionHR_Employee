import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_client.dart';

class PermissionsService {
  static const String baseUrl = 'https://jssolutions-eg.com';

  static Future<Map<String, String>> _headers({bool includeContentType = true}) async {
    return ApiClient.buildHeaders(includeContentType: includeContentType);
  }

  // ✅ صلاحيات اليوزر الحالي
  static Future<Map<String, dynamic>> getMyPermissions() async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/permissions/my/'),
      headers: await _headers(includeContentType: false),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'خطأ في جلب صلاحياتي');
  }

  // ✅ الصلاحيات الافتراضية لـ Role
  static Future<Map<String, dynamic>> getDefaultRolePermissions(String role) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/permissions/defaults/?role=$role'),
      headers: await _headers(includeContentType: false),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'خطأ في جلب صلاحيات الدور');
  }

  // ✅ ملخص صلاحيات Target
  static Future<Map<String, dynamic>> getTargetPermissionsSummary({
    required String type,
    required String id,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/permissions/summary/?type=$type&id=$id'),
      headers: await _headers(includeContentType: false),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true) {
      return data;
    }
    throw Exception(data['error'] ?? 'خطأ في جلب ملخص الصلاحيات');
  }

  // ✅ تعديل صلاحيات Target
  static Future<void> setRoleOverride({
    required String targetType,
    required String targetId,
    required List<Map<String, dynamic>> permissions,
  }) async {
    final body = jsonEncode({
      'target_type': targetType,
      'target_id': targetId,
      'permissions': permissions,
    });

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/permissions/override/bulk/'),
      headers: await _headers(),
      body: body,
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode != 200 || data['success'] != true) {
      throw Exception(data['error'] ?? 'فشل حفظ الصلاحيات');
    }
  }
}
