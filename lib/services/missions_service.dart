import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'auth_storage_service.dart';

class MissionsService {
  static const String _baseUrl =
      'https://jssolutions-eg.com/attendance/api/mobile';

  static Future<Map<String, String>> _headers() async {
    final token = await AuthStorageService.getSavedToken();
    return {
      'Authorization': 'Token $token',
      'Content-Type': 'application/json',
    };
  }

  // ─────────────────────────────────────────────
  // MANAGER APIs
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> getManagerMissions({
    String? statusFilter,
    String? priorityFilter,
    String? dateFilter,
  }) async {
    final headers = await _headers();
    final params = <String, String>{};
    if (statusFilter != null) params['status'] = statusFilter;
    if (priorityFilter != null) params['priority'] = priorityFilter;
    if (dateFilter != null) params['date'] = dateFilter;

    final uri = Uri.parse('$_baseUrl/manager/missions/')
        .replace(queryParameters: params.isNotEmpty ? params : null);

    final response = await http.get(uri, headers: headers);
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> createMission({
    required String title,
    String description = '',
    String priority = 'normal',
    required String plannedStartTime,
    required String plannedEndTime,
    String locationName = '',
    double? locationLat,
    double? locationLng,
    String clientName = '',
    String clientPhone = '',
    String clientCompany = '',
    String clientPosition = '',
    String clientEmail = '',
    String clientAddress = '',
    List<Map<String, dynamic>> assignees = const [],
  }) async {
    final headers = await _headers();
    final body = {
      'title': title,
      'description': description,
      'priority': priority,
      'planned_start_time': plannedStartTime,
      'planned_end_time': plannedEndTime,
      'location_name': locationName,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
      'client_name': clientName,
      'client_phone': clientPhone,
      'client_company': clientCompany,
      'client_position': clientPosition,
      'client_email': clientEmail,
      'client_address': clientAddress,
      'assignees': assignees,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/manager/missions/create/'),
      headers: headers,
      body: json.encode(body),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> getMissionDetail(int missionId) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl/manager/missions/$missionId/'),
      headers: headers,
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> cancelMission(int missionId) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl/manager/missions/$missionId/cancel/'),
      headers: headers,
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> forceCancelMission(
    int missionId,
    String reason,
  ) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl/manager/missions/$missionId/force-cancel/'),
      headers: headers,
      body: json.encode({'reason': reason}),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> reassignEmployee(
    int missionId, {
    required int oldEmployeeId,
    required int newEmployeeId,
    String reason = '',
  }) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl/manager/missions/$missionId/reassign/'),
      headers: headers,
      body: json.encode({
        'old_employee_id': oldEmployeeId,
        'new_employee_id': newEmployeeId,
        'reason': reason,
      }),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> getPendingRequests() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl/manager/missions/pending-requests/'),
      headers: headers,
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> respondToRequest(
    int requestId,
    String action, {
    String notes = '',
  }) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl/manager/missions/requests/$requestId/respond/'),
      headers: headers,
      body: json.encode({'action': action, 'notes': notes}),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> getWithdrawRequests() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl/manager/missions/withdraw-requests/'),
      headers: headers,
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> respondToWithdraw(
    int assignmentId,
    String action, {
    String notes = '',
  }) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse(
          '$_baseUrl/manager/missions/withdraw-requests/$assignmentId/respond/'),
      headers: headers,
      body: json.encode({'action': action, 'notes': notes}),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> getFeedbackDashboard() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl/manager/missions/feedback-dashboard/'),
      headers: headers,
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  // ─────────────────────────────────────────────
  // EMPLOYEE APIs
  // ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> getMyMissions({
    String filter = 'all',
  }) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl/employee/missions/?filter=$filter'),
      headers: headers,
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> respondToMission(
    int assignmentId,
    String action, {
    String reason = '',
  }) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse(
          '$_baseUrl/employee/missions/assignments/$assignmentId/respond/'),
      headers: headers,
      body: json.encode({'action': action, 'reason': reason}),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> startMission(
    int assignmentId, {
    double? lat,
    double? lng,
  }) async {
    final headers = await _headers();
    final body = <String, dynamic>{};
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;

    final response = await http.post(
      Uri.parse('$_baseUrl/employee/missions/assignments/$assignmentId/start/'),
      headers: headers,
      body: json.encode(body),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> endMission(
    int assignmentId, {
    double? lat,
    double? lng,
    String notes = '',
  }) async {
    final headers = await _headers();
    final body = <String, dynamic>{'notes': notes};
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;

    final response = await http.post(
      Uri.parse('$_baseUrl/employee/missions/assignments/$assignmentId/end/'),
      headers: headers,
      body: json.encode(body),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> updateLocation(
    int assignmentId, {
    required double lat,
    required double lng,
    String label = 'موقع جديد',
  }) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse(
          '$_baseUrl/employee/missions/assignments/$assignmentId/update-location/'),
      headers: headers,
      body: json.encode({'lat': lat, 'lng': lng, 'label': label}),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> uploadAttachment(
    int assignmentId,
    File file, {
    String caption = '',
  }) async {
    final token = await AuthStorageService.getSavedToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
          '$_baseUrl/employee/missions/assignments/$assignmentId/upload/'),
    );
    request.headers['Authorization'] = 'Token $token';
    request.fields['caption'] = caption;
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('image', 'jpeg'),
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> requestMission({
    required String title,
    String description = '',
    String priority = 'normal',
    required String plannedStartTime,
    required String plannedEndTime,
    String locationName = '',
    double? locationLat,
    double? locationLng,
    String clientName = '',
    String clientPhone = '',
  }) async {
    final headers = await _headers();
    final body = {
      'title': title,
      'description': description,
      'priority': priority,
      'planned_start_time': plannedStartTime,
      'planned_end_time': plannedEndTime,
      'location_name': locationName,
      if (locationLat != null) 'location_lat': locationLat,
      if (locationLng != null) 'location_lng': locationLng,
      'client_name': clientName,
      'client_phone': clientPhone,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/employee/missions/request/'),
      headers: headers,
      body: json.encode(body),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> withdrawFromMission(
    int assignmentId,
    String reason,
  ) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse(
          '$_baseUrl/employee/missions/assignments/$assignmentId/withdraw/'),
      headers: headers,
      body: json.encode({'reason': reason}),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> submitFeedback(
    int missionId, {
    required int interestRating,
    required int dealProbability,
    required String clientStatus,
    String clientNeeds = '',
    double? estimatedBudget,
    String? expectedDecisionDate,
    String interestedIn = '',
    bool needsFollowup = false,
    String? followupDate,
    String preferredContact = '',
    int? followupOwnerId,
    String followupNotes = '',
    bool contractSigned = false,
    double? dealValue,
    String internalNotes = '',
    String warnings = '',
  }) async {
    final headers = await _headers();
    final body = <String, dynamic>{
      'interest_rating': interestRating,
      'deal_probability': dealProbability,
      'client_status': clientStatus,
      'client_needs': clientNeeds,
      if (estimatedBudget != null) 'estimated_budget': estimatedBudget,
      if (expectedDecisionDate != null)
        'expected_decision_date': expectedDecisionDate,
      'interested_in': interestedIn,
      'needs_followup': needsFollowup,
      if (followupDate != null) 'followup_date': followupDate,
      'preferred_contact': preferredContact,
      if (followupOwnerId != null) 'followup_owner_id': followupOwnerId,
      'followup_notes': followupNotes,
      'contract_signed': contractSigned,
      if (dealValue != null) 'deal_value': dealValue,
      'internal_notes': internalNotes,
      'warnings': warnings,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/missions/$missionId/feedback/submit/'),
      headers: headers,
      body: json.encode(body),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> getFeedbackDetail(int missionId) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('$_baseUrl/missions/$missionId/feedback/'),
      headers: headers,
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> addFeedbackNote(
    int missionId,
    String note,
  ) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('$_baseUrl/missions/$missionId/feedback/add-note/'),
      headers: headers,
      body: json.encode({'note': note}),
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<Map<String, dynamic>> getLocationTimeline(
      int assignmentId) async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/employee/missions/assignments/$assignmentId/locations/'),
      headers: headers,
    );
    return json.decode(utf8.decode(response.bodyBytes));
  }
}