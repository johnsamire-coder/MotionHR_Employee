import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage_service.dart';

class PenaltyRuleService {
  static const String _baseUrl  = 'https://jssolutions-eg.com';
  static const String _basePath = '/attendance/api/mobile/manager/rules/penalty';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': 'ar',
    };
  }

  /// قائمة قواعد الجزاءات
  static Future<List<dynamic>> listRules() async {
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data is List) return data;
      return data['rules'] ?? data['results'] ?? [];
    }
    throw Exception('Failed to load penalty rules: ${res.statusCode}');
  }

  /// تفاصيل قاعدة واحدة
  static Future<Map<String, dynamic>> getRule(int id) async {
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/$id/'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      return data['rule'] ?? data;
    }
    throw Exception('Failed to load rule: ${res.statusCode}');
  }

  /// إنشاء قاعدة جديدة
  static Future<Map<String, dynamic>> createRule(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/'),
      headers: await _headers(),
      body: json.encode(data),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    throw Exception('Failed to create: ${res.body}');
  }

  /// تعديل قاعدة
  static Future<Map<String, dynamic>> updateRule(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$_baseUrl$_basePath/$id/'),
      headers: await _headers(),
      body: json.encode(data),
    );
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    throw Exception('Failed to update: ${res.body}');
  }

  /// حذف قاعدة
  static Future<bool> deleteRule(int id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl$_basePath/$id/'),
      headers: await _headers(),
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }
}
