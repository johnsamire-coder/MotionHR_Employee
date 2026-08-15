import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_storage_service.dart';

class HierarchyService {
  static const String _baseUrl =
      'https://jssolutions-eg.com/attendance/api/mobile/manager';

  static Future<Map<String, dynamic>> getHierarchyTree() async {
    final token = await AuthStorageService.getSavedToken();
    if (token == null) throw Exception('No token');

    final res = await http.get(
      Uri.parse('$_baseUrl/hierarchy-tree/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed: ${res.statusCode}');
  }
}
