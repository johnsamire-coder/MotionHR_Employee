import 'package:motionhr_employee/services/api_client.dart';
// lib/services/work_locations_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WorkLocationsService {
  static const String _base = 'https://jssolutions-eg.com/attendance/api/mobile';

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    return ApiClient.buildHeaders(includeContentType: true);
  }

  // ═══════════════════════════════════════════════════
  // Employee APIs
  // ═══════════════════════════════════════════════════

  /// GET قائمة مواقعي (all / approved / pending / rejected)
  Future<Map<String, dynamic>> getMyLocations({String filter = 'all'}) async {
    final headers = await _headers();
    final url = '$_base/work-locations/?filter=$filter';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Error ${response.statusCode}');
  }

  /// GET أنواع المواقع المتاحة
  Future<List<dynamic>> getLocationTypes() async {
    final headers = await _headers();
    final url = '$_base/work-locations/types/';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['types'] ?? [];
    }
    throw Exception('Error ${response.statusCode}');
  }

  /// POST اقتراح موقع جديد
  Future<Map<String, dynamic>> proposeLocation({
    required String name,
    required String locationType,
    required double latitude,
    required double longitude,
    int radius = 500,
    String description = '',
    String projectCode = '',
    String clientName = '',
    String contactPerson = '',
    String contactPhone = '',
    String? validFrom,
    String? validUntil,
    String notes = '',
  }) async {
    final headers = await _headers();
    final url = '$_base/work-locations/propose/';

    final Map<String, dynamic> body = {
      'name': name,
      'location_type': locationType,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
    if (description.isNotEmpty) body['description'] = description;
    if (projectCode.isNotEmpty) body['project_code'] = projectCode;
    if (clientName.isNotEmpty) body['client_name'] = clientName;
    if (contactPerson.isNotEmpty) body['contact_person'] = contactPerson;
    if (contactPhone.isNotEmpty) body['contact_phone'] = contactPhone;
    if (validFrom != null) body['valid_from'] = validFrom;
    if (validUntil != null) body['valid_until'] = validUntil;
    if (notes.isNotEmpty) body['notes'] = notes;

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201) return data;
    return {'success': false, 'status_code': response.statusCode, ...data};
  }

  /// GET تفاصيل موقع
  Future<Map<String, dynamic>> getLocationDetail(int locationId) async {
    final headers = await _headers();
    final url = '$_base/work-locations/$locationId/';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Error ${response.statusCode}');
  }

  /// DELETE إلغاء طلب معلق
  Future<Map<String, dynamic>> cancelPendingLocation(int locationId) async {
    final headers = await _headers();
    final url = '$_base/work-locations/$locationId/cancel/';
    final response = await http.delete(Uri.parse(url), headers: headers);

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data;
    return {'success': false, ...data};
  }

  // ═══════════════════════════════════════════════════
  // Manager/HR APIs
  // ═══════════════════════════════════════════════════

  /// GET الطلبات المعلقة (للمدير/HR)
  Future<Map<String, dynamic>> getPendingLocations() async {
    final headers = await _headers();
    final url = '$_base/manager/work-locations/pending/';
    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Error ${response.statusCode}');
  }

  /// GET كل مواقع الشركة (للمدير/HR)
  Future<Map<String, dynamic>> getAllLocations({
    String filter = 'all',
    int? employeeId,
  }) async {
    final headers = await _headers();
    var url = '$_base/manager/work-locations/?filter=$filter';
    if (employeeId != null) url += '&employee_id=$employeeId';

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(utf8.decode(response.bodyBytes));
    }
    throw Exception('Error ${response.statusCode}');
  }

  /// POST الموافقة على موقع
  Future<Map<String, dynamic>> approveLocation({
    required int locationId,
    String notes = '',
  }) async {
    final headers = await _headers();
    final url = '$_base/manager/work-locations/$locationId/approve/';
    final body = json.encode({'notes': notes});

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data;
    return {'success': false, ...data};
  }

  /// POST رفض موقع
  Future<Map<String, dynamic>> rejectLocation({
    required int locationId,
    required String reason,
  }) async {
    final headers = await _headers();
    final url = '$_base/manager/work-locations/$locationId/reject/';
    final body = json.encode({'reason': reason});

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    final data = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) return data;
    return {'success': false, ...data};
  }
}
