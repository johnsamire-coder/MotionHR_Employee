$ErrorActionPreference = 'Stop'
$project = 'C:\MotionHR\motionhr_employee'
Set-Location $project

Write-Host '=== Batch 1: Core + Services ===' -ForegroundColor Cyan

function Write-Utf8File {
    param([string]$RelativePath, [string]$Content)
    $fullPath = Join-Path $project $RelativePath
    $parent = Split-Path $fullPath -Parent
    New-Item -ItemType Directory -Force -Path $parent | Out-Null
    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    Write-Host "Created: $RelativePath" -ForegroundColor Green
}

Write-Utf8File 'lib\core\constants.dart' @'
import 'package:flutter/material.dart';

const String kBaseUrl = 'https://jssolutions-eg.com';

const Color kPrimaryColor = Color(0xFF1976D2);
const Color kPrimaryDark  = Color(0xFF0D47A1);
const Color kAccentColor  = Color(0xFF42A5F5);
const Color kManagerColor = Color(0xFF6A1B9A);
'@

Write-Utf8File 'lib\core\app_error.dart' @'
class AppError implements Exception {
  final String message;
  final int? statusCode;
  final dynamic raw;

  AppError(this.message, {this.statusCode, this.raw});

  @override
  String toString() => message;
}
'@

Write-Utf8File 'lib\core\error_handler.dart' @'
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'app_error.dart';

class AppErrorHandler {
  static String parse(dynamic error) {
    if (error is AppError) return error.message;
    if (error is TimeoutException) return 'انتهت مهلة الاتصال بالخادم';
    if (error is SocketException) return 'لا يوجد اتصال بالإنترنت';
    return 'حدث خطأ غير متوقع';
  }

  static void show(BuildContext context, dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(parse(error)),
        backgroundColor: Colors.red,
      ),
    );
  }
}
'@

Write-Utf8File 'lib\services\storage_service.dart' @'
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<SharedPreferences> get _prefs async =>
      SharedPreferences.getInstance();

  static Future<void> setString(String key, String value) async =>
      (await _prefs).setString(key, value);

  static Future<String> getString(String key) async =>
      (await _prefs).getString(key) ?? '';

  static Future<void> setBool(String key, bool value) async =>
      (await _prefs).setBool(key, value);

  static Future<bool> getBool(String key,
          {bool defaultValue = false}) async =>
      (await _prefs).getBool(key) ?? defaultValue;

  static Future<String> getToken() => getString('token');

  static Future<String> getAppMode() async {
    final v = await getString('app_mode');
    return v.isEmpty ? 'employee' : v;
  }

  static Future<void> clear() async => (await _prefs).clear();
}
'@

Write-Utf8File 'lib\core\api_service.dart' @'
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import 'app_error.dart';
import 'constants.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<Map<String, String>> _headers({
    bool auth = true,
    bool json = true,
  }) async {
    final h = <String, String>{};
    if (json) h['Content-Type'] = 'application/json';
    if (auth) {
      final token = await StorageService.getToken();
      if (token.isNotEmpty) h['Authorization'] = 'Token $token';
    }
    return h;
  }

  static dynamic _decode(http.Response r) {
    try { return jsonDecode(r.body); } catch (_) { return {}; }
  }

  static dynamic _handle(http.Response r) {
    final data = _decode(r);
    if (r.statusCode >= 200 && r.statusCode < 300) return data;
    String msg = 'فشل الاتصال بالخادم';
    if (data is Map) {
      msg = (data['message'] ?? data['error'] ?? data['detail'] ?? msg)
          .toString();
    }
    throw AppError(msg, statusCode: r.statusCode, raw: data);
  }

  static Future<dynamic> get(String path, {bool auth = true}) async {
    final r = await http
        .get(Uri.parse('$kBaseUrl$path'),
            headers: await _headers(auth: auth, json: false))
        .timeout(_timeout);
    return _handle(r);
  }

  static Future<dynamic> post(String path,
      {Map<String, dynamic>? body, bool auth = true}) async {
    final r = await http
        .post(Uri.parse('$kBaseUrl$path'),
            headers: await _headers(auth: auth, json: true),
            body: jsonEncode(body ?? {}))
        .timeout(_timeout);
    return _handle(r);
  }

  static Future<dynamic> multipart(
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    bool auth = true,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$kBaseUrl$path'));
    if (auth) {
      final token = await StorageService.getToken();
      if (token.isNotEmpty) req.headers['Authorization'] = 'Token $token';
    }
    if (fields != null) req.fields.addAll(fields);
    if (files != null) req.files.addAll(files);
    final streamed = await req.send().timeout(_timeout);
    final r = await http.Response.fromStream(streamed);
    return _handle(r);
  }
}
'@

Write-Utf8File 'lib\services\notification_service.dart' @'
import 'package:flutter/material.dart';
import '../core/api_service.dart';

class NotificationService {
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static Future<void> fetchUnreadCount() async {
    try {
      final data =
          await ApiService.get('/attendance/api/mobile/notifications/');
      unreadCount.value = data['unread_count'] ?? 0;
    } catch (_) {}
  }

  static Future<Map<String, dynamic>> list() async {
    final data =
        await ApiService.get('/attendance/api/mobile/notifications/');
    unreadCount.value = data['unread_count'] ?? 0;
    return Map<String, dynamic>.from(data);
  }

  static Future<void> markAllRead() async {
    await ApiService.post(
        '/attendance/api/mobile/notifications/mark-read/');
    await fetchUnreadCount();
  }

  static Future<void> markOneRead(int id) async {
    await ApiService.post(
        '/attendance/api/mobile/notifications/mark-read/',
        body: {'id': id});
    await fetchUnreadCount();
  }
}
'@

Write-Utf8File 'lib\services\charter_service.dart' @'
import 'package:http/http.dart' as http;
import '../core/api_service.dart';

class CharterService {
  static Future<Map<String, dynamic>> getCharter() async =>
      Map<String, dynamic>.from(
          await ApiService.get('/attendance/api/mobile/charter/'));

  static Future<Map<String, dynamic>> acceptCharter() async =>
      Map<String, dynamic>.from(
          await ApiService.post('/attendance/api/mobile/charter/accept/'));

  static Future<Map<String, dynamic>> getAcceptances() async =>
      Map<String, dynamic>.from(await ApiService.get(
          '/attendance/api/mobile/manager/charter/acceptances/'));

  static Future<Map<String, dynamic>> updateCharter({
    required String title,
    required String introduction,
    required String content,
    http.MultipartFile? attachment,
    bool removeAttachment = false,
  }) async {
    final files = <http.MultipartFile>[];
    if (attachment != null) files.add(attachment);
    return Map<String, dynamic>.from(await ApiService.multipart(
      '/attendance/api/mobile/manager/charter/update/',
      fields: {
        'title': title,
        'introduction': introduction,
        'content': content,
        if (removeAttachment) 'remove_attachment': 'true',
      },
      files: files,
    ));
  }
}
'@

Write-Utf8File 'lib\services\auth_service.dart' @'
import '../core/api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final map = Map<String, dynamic>.from(await ApiService.post(
      '/attendance/api/mobile/login/',
      auth: false,
      body: {'username': username, 'password': password},
    ));

    await StorageService.setString('token', map['token'] ?? '');
    await StorageService.setString('username', map['username'] ?? '');
    await StorageService.setString('full_name', map['full_name'] ?? '');
    await StorageService.setString(
        'company_name', map['company_name'] ?? '');
    await StorageService.setString('first_name', map['first_name'] ?? '');
    await StorageService.setString('gender', map['gender'] ?? 'male');
    await StorageService.setString('role', map['role'] ?? 'employee');
    await StorageService.setString(
        'app_mode', map['app_mode'] ?? 'employee');

    if (map['employee'] is Map) {
      final emp = map['employee'] as Map;
      if ((map['full_name'] ?? '').isEmpty)
        await StorageService.setString(
            'full_name', emp['name']?.toString() ?? '');
      if ((map['company_name'] ?? '').isEmpty)
        await StorageService.setString(
            'company_name', emp['company']?.toString() ?? '');
      if ((map['first_name'] ?? '').isEmpty)
        await StorageService.setString(
            'first_name', emp['first_name']?.toString() ?? '');
    }

    return map;
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final map = Map<String, dynamic>.from(await ApiService.post(
      '/attendance/api/mobile/change-password/',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    ));
    if ((map['token'] ?? '').toString().isNotEmpty)
      await StorageService.setString('token', map['token']);
    return map;
  }

  static Future<void> logout() => StorageService.clear();
}
'@

Write-Utf8File 'lib\services\attendance_service.dart' @'
import '../core/api_service.dart';

class AttendanceService {
  static Future<Map<String, dynamic>> getStatus() async =>
      Map<String, dynamic>.from(
          await ApiService.get('/attendance/api/mobile/status/'));

  static Future<Map<String, dynamic>> action({
    required String action,
    required double latitude,
    required double longitude,
  }) async =>
      Map<String, dynamic>.from(await ApiService.post(
        '/attendance/api/mobile/attendance/',
        body: {
          'action': action,
          'latitude': latitude,
          'longitude': longitude,
        },
      ));

  static Future<Map<String, dynamic>> getHistory() async =>
      Map<String, dynamic>.from(
          await ApiService.get('/attendance/api/mobile/history/'));
}
'@

Write-Utf8File 'lib\services\request_service.dart' @'
import '../core/api_service.dart';

class RequestService {
  static Future<Map<String, dynamic>> getRequestTypes() async =>
      Map<String, dynamic>.from(await ApiService.get(
          '/attendance/api/mobile/request-types/'));

  static Future<Map<String, dynamic>> submitRequest(
          Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await ApiService.post(
          '/attendance/api/mobile/submit-request/',
          body: body));

  static Future<Map<String, dynamic>> getMyRequests() async =>
      Map<String, dynamic>.from(
          await ApiService.get('/attendance/api/mobile/my-requests/'));

  static Future<Map<String, dynamic>> getManagerPending() async =>
      Map<String, dynamic>.from(await ApiService.get(
          '/attendance/api/mobile/manager/pending/'));

  static Future<Map<String, dynamic>> managerAction({
    required int id,
    required String type,
    required String action,
  }) async =>
      Map<String, dynamic>.from(await ApiService.post(
        '/attendance/api/mobile/manager/action/',
        body: {'id': id, 'type': type, 'action': action},
      ));

  static Future<Map<String, dynamic>> getManagerAttendance() async =>
      Map<String, dynamic>.from(await ApiService.get(
          '/attendance/api/mobile/manager/attendance/'));

  static Future<Map<String, dynamic>> getManagerLiveLocations() async =>
      Map<String, dynamic>.from(await ApiService.get(
          '/attendance/api/mobile/manager/live-locations/'));
}
'@

Write-Utf8File 'lib\services\leave_service.dart' @'
import '../core/api_service.dart';

class LeaveService {
  static Future<Map<String, dynamic>> getLeaveTypes() async =>
      Map<String, dynamic>.from(
          await ApiService.get('/attendance/api/mobile/leave-types/'));

  static Future<Map<String, dynamic>> submitLeave(
          Map<String, dynamic> body) async =>
      Map<String, dynamic>.from(await ApiService.post(
          '/attendance/api/mobile/leave-request/',
          body: body));

  static Future<Map<String, dynamic>> getMyLeaves() async =>
      Map<String, dynamic>.from(
          await ApiService.get('/attendance/api/mobile/my-leaves/'));
}
'@

Write-Host ''
Write-Host '=== Batch 1 Done ===' -ForegroundColor Cyan
Write-Host 'Created: lib/core/ and lib/services/' -ForegroundColor Green
Write-Host 'main.dart was NOT modified.' -ForegroundColor Yellow