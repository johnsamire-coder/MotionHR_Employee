import 'package:motionhr_employee/services/api_client.dart';
// lib/services/field_visits_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FieldVisitsService {
  static const String _base = 'https://jssolutions-eg.com/attendance/api/mobile';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    return ApiClient.buildHeaders(includeContentType: true);
  }

  // 
  // GET قائمة زياراتي
  // 
  Future<Map<String, dynamic>> getMyVisits({String filter = 'today'}) async {
    final headers = await _headers();
    final url = '$_base/field-visits/?filter=$filter';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Error ${response.statusCode}: ${response.body}');
  }

  // 
  // GET أنواع الزيارات المتاحة
  // 
  Future<List<dynamic>> getVisitTypes() async {
    final headers = await _headers();
    final url = '$_base/field-visits/types/';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['types'] ?? [];
    }
    throw Exception('Error ${response.statusCode}');
  }

  // 
  // POST بدء زيارة جديدة
  // 
  Future<Map<String, dynamic>> startVisit({
    required String visitType,
    required String locationName,
    required String purpose,
    required double latitude,
    required double longitude,
    String notes = '',
  }) async {
    final headers = await _headers();
    final url = '$_base/field-visits/start/';
    final body = json.encode({
      'visit_type': visitType,
      'location_name': locationName,
      'purpose': purpose,
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    final data = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 201) {
      return data;
    }
    // نرجع الـ error data كامل عشان نعرض السبب للمستخدم
    return {
      'success': false,
      'status_code': response.statusCode,
      ...data,
    };
  }

  // 
  // GET تفاصيل زيارة (مع نقاط التتبع)
  // 
  Future<Map<String, dynamic>> getVisitDetail(int visitId) async {
    final headers = await _headers();
    final url = '$_base/field-visits/$visitId/';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Error ${response.statusCode}');
  }

  // 
  // POST إنهاء زيارة
  // 
  Future<Map<String, dynamic>> endVisit({
    required int visitId,
    required double latitude,
    required double longitude,
    String notes = '',
  }) async {
    final headers = await _headers();
    final url = '$_base/field-visits/end/$visitId/';
    final body = json.encode({
      'latitude': latitude,
      'longitude': longitude,
      'notes': notes,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    final data = json.decode(utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return data;
    }
    return {
      'success': false,
      'status_code': response.statusCode,
      ...data,
    };
  }
}
