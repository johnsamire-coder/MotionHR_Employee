import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage_service.dart';

class EosPolicyService {
  static const String _baseUrl = 'https://jssolutions-eg.com';
  static const String _basePath = '/attendance/api/mobile/manager/eos';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Accept-Language': 'ar',
    };
  }

  /// ??? ?? ????????
  static Future<List<dynamic>> listPolicies() async {
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/policies/'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data is List) return data;
      return data['results'] ?? [];
    }
    throw Exception('Failed to load EOS policies');
  }

  /// ??? ?????? ?????
  static Future<Map<String, dynamic>> getPolicy(int id) async {
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/policies/$id/'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      return data['policy'] ?? data;
    }
    throw Exception('Failed to load policy');
  }

  /// ????? ????? ?????
  static Future<Map<String, dynamic>> createPolicy(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/policies/'),
      headers: await _headers(),
      body: json.encode(data),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    throw Exception('Failed to create policy: ${res.body}');
  }

  /// ????? ?????
  static Future<Map<String, dynamic>> updatePolicy(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$_baseUrl$_basePath/policies/$id/'),
      headers: await _headers(),
      body: json.encode(data),
    );
    if (res.statusCode == 200) {
      return json.decode(utf8.decode(res.bodyBytes));
    }
    throw Exception('Failed to update policy: ${res.body}');
  }

  /// ??? ?????
  static Future<bool> deletePolicy(int id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl$_basePath/policies/$id/'),
      headers: await _headers(),
    );
    return res.statusCode == 200 || res.statusCode == 204;
  }

  /// ????? ?????? ????? ??????
  static Future<Map<String, dynamic>> calculate({
    required double yearsOfService,
    required double monthlySalary,
    String terminationReason = 'termination',
    int? policyId,
  }) async {
    final body = <String, dynamic>{
      'years_of_service': yearsOfService,
      'monthly_salary': monthlySalary,
      'termination_reason': terminationReason,
    };
    if (policyId != null) body['policy_id'] = policyId;

    final res = await http.post(
      Uri.parse('$_baseUrl$_basePath/calculate/'),
      headers: await _headers(),
      body: json.encode(body),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      return data['result'] ?? data;
    }
    throw Exception('Calculation failed: ${res.body}');
  }
}
