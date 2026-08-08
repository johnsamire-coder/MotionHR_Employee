import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage_service.dart';

/// Service ???? Branches, Departments, Employees ??? dropdowns
class LookupsService {
  static const String _baseUrl = 'https://jssolutions-eg.com';
  static const String _basePath = '/attendance/api/mobile/manager';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
      'Accept-Language': 'ar',
    };
  }

  /// ??? ?? ??????
  static Future<List<dynamic>> listBranches() async {
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/branches/'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data is List) return data;
      return data['branches'] ?? data['results'] ?? [];
    }
    return [];
  }

  /// ??? ?? ???????
  static Future<List<dynamic>> listDepartments() async {
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/departments/'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data is List) return data;
      return data['departments'] ?? data['results'] ?? [];
    }
    return [];
  }

  /// ??? ????? ?????? ????? (??? multi-select)
  static Future<List<dynamic>> listEmployeesSimple() async {
    final res = await http.get(
      Uri.parse('$_baseUrl$_basePath/employees/simple/'),
      headers: await _headers(),
    );
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (data is List) return data;
      return data['employees'] ?? data['results'] ?? [];
    }
    return [];
  }
}
