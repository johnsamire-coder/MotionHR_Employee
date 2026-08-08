import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage_service.dart';

class ManualEntriesService {
  static const String _baseUrl  = 'https://jssolutions-eg.com';
  static const String _basePath = '/attendance/api/mobile/manager/entries';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': 'ar',
    };
  }

  // ══════════════════════════════════════════
  // Summary
  // ══════════════════════════════════════════
  static Future<Map<String, dynamic>> getSummary() async {
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/summary/'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    throw Exception('Failed to load summary');
  }

  // ══════════════════════════════════════════
  // PENALTY
  // ══════════════════════════════════════════
  static Future<List<dynamic>> listPenalties({Map<String, String>? filters}) async {
    final query = filters != null ? Uri(queryParameters: filters).query : '';
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/penalty/${query.isNotEmpty ? "?$query" : ""}'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data is List) return data;
      return data['entries'] ?? data['results'] ?? [];
    }
    throw Exception('Failed to load penalties');
  }

  static Future<Map<String, dynamic>> createPenalty(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/penalty/'),
      headers: await _headers(),
      body: json.encode(data),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    throw Exception('Failed to create penalty: ${res.body}');
  }

  static Future<Map<String, dynamic>> approvePenalty(int id, {String notes = ''}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/penalty/$id/approve/'),
      headers: await _headers(),
      body: json.encode({'notes': notes}),
    );
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes));
    throw Exception('Failed to approve');
  }

  static Future<Map<String, dynamic>> rejectPenalty(int id, {String reason = ''}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/penalty/$id/reject/'),
      headers: await _headers(),
      body: json.encode({'reason': reason}),
    );
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes));
    throw Exception('Failed to reject');
  }

  // ══════════════════════════════════════════
  // BONUS
  // ══════════════════════════════════════════
  static Future<List<dynamic>> listBonuses({Map<String, String>? filters}) async {
    final query = filters != null ? Uri(queryParameters: filters).query : '';
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/bonus/${query.isNotEmpty ? "?$query" : ""}'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data is List) return data;
      return data['entries'] ?? data['results'] ?? [];
    }
    throw Exception('Failed to load bonuses');
  }

  static Future<Map<String, dynamic>> createBonus(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/bonus/'),
      headers: await _headers(),
      body: json.encode(data),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    throw Exception('Failed to create bonus: ${res.body}');
  }

  static Future<Map<String, dynamic>> approveBonus(int id, {String notes = ''}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/bonus/$id/approve/'),
      headers: await _headers(),
      body: json.encode({'notes': notes}),
    );
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes));
    throw Exception('Failed to approve');
  }

  static Future<Map<String, dynamic>> rejectBonus(int id, {String reason = ''}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/bonus/$id/reject/'),
      headers: await _headers(),
      body: json.encode({'reason': reason}),
    );
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes));
    throw Exception('Failed to reject');
  }

  // ══════════════════════════════════════════
  // ALLOWANCE
  // ══════════════════════════════════════════
  static Future<List<dynamic>> listAllowances({Map<String, String>? filters}) async {
    final query = filters != null ? Uri(queryParameters: filters).query : '';
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/allowance/${query.isNotEmpty ? "?$query" : ""}'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data is List) return data;
      return data['entries'] ?? data['results'] ?? [];
    }
    throw Exception('Failed to load allowances');
  }

  static Future<Map<String, dynamic>> createAllowance(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/allowance/'),
      headers: await _headers(),
      body: json.encode(data),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    throw Exception('Failed to create allowance: ${res.body}');
  }

  static Future<Map<String, dynamic>> approveAllowance(int id, {String notes = ''}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/allowance/$id/approve/'),
      headers: await _headers(),
      body: json.encode({'notes': notes}),
    );
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes));
    throw Exception('Failed to approve');
  }

  static Future<Map<String, dynamic>> rejectAllowance(int id, {String reason = ''}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/allowance/$id/reject/'),
      headers: await _headers(),
      body: json.encode({'reason': reason}),
    );
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes));
    throw Exception('Failed to reject');
  }
}
