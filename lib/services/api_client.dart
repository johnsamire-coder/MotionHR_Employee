import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

const String _kRefreshUrl =
    'https://jssolutions-eg.com/attendance/api/mobile/jwt/refresh/';

class ApiClient {
  // يمنع تعدد محاولات التجديد في نفس اللحظة لو كذا طلب فشلوا مع بعض
  static Future<bool>? _refreshFuture;

  // يفك تشفير الـ JWT ويرجّع وقت الانتهاء (exp) بالثواني، أو null لو فشل
  static int? _jwtExpiry(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1];
      payload = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64.decode(payload));
      final data = jsonDecode(decoded);
      return data['exp'] as int?;
    } catch (_) {
      return null;
    }
  }

  // يجدد التوكن استباقيًا لو منتهي أو قرّب ينتهي (أقل من دقيقة)، عشان أي مكان بيستخدم
  // buildHeaders() ياخد توكن سليم دايمًا، حتى لو بعتين الطلب بـ http.get مباشرة
  static Future<void> _ensureFreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtAccess = prefs.getString('jwt_access') ?? '';
    if (jwtAccess.isEmpty) return;
    final exp = _jwtExpiry(jwtAccess);
    if (exp == null) return;
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (exp - nowSeconds < 60) {
      await _refreshToken();
    }
  }

  static Future<Map<String, String>> buildHeaders({
    bool includeContentType = false,
    Map<String, String>? extraHeaders,
  }) async {
    await _ensureFreshToken();

    final result = <String, String>{
      ...?extraHeaders,
    };

    final authHeaders = await getAuthHeaders(
      includeContentType: includeContentType,
    );

    if (authHeaders.containsKey('Accept') && !result.containsKey('Accept')) {
      result['Accept'] = authHeaders['Accept']!;
    }

    if (authHeaders.containsKey('Content-Type') &&
        !result.containsKey('Content-Type')) {
      result['Content-Type'] = authHeaders['Content-Type']!;
    }

    if (authHeaders.containsKey('Authorization')) {
      result['Authorization'] = authHeaders['Authorization']!;
    }

    return result;
  }

  static Future<bool> _refreshToken() {
    if (_refreshFuture != null) {
      return _refreshFuture!;
    }
    _refreshFuture = _doRefresh();
    return _refreshFuture!.whenComplete(() {
      _refreshFuture = null;
    });
  }

  static Future<bool> _doRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('jwt_refresh') ?? '';
      if (refreshToken.isEmpty) return false;

      final res = await http.post(
        Uri.parse(_kRefreshUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);
      final newAccess = data['access'];
      if (newAccess == null || newAccess.toString().isEmpty) return false;

      await prefs.setString('jwt_access', newAccess.toString());
      final newRefresh = data['refresh'];
      if (newRefresh != null && newRefresh.toString().isNotEmpty) {
        await prefs.setString('jwt_refresh', newRefresh.toString());
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<http.Response> _withAutoRefresh(
    Future<http.Response> Function() attempt,
  ) async {
    final firstResponse = await attempt();
    if (firstResponse.statusCode != 401) {
      return firstResponse;
    }
    final refreshed = await _refreshToken();
    if (!refreshed) {
      return firstResponse;
    }
    return attempt();
  }

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) {
    return _withAutoRefresh(() async {
      return http.get(
        url,
        headers: await buildHeaders(extraHeaders: headers),
      );
    });
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _withAutoRefresh(() async {
      return http.post(
        url,
        headers: await buildHeaders(
          includeContentType: true,
          extraHeaders: headers,
        ),
        body: body,
      );
    });
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _withAutoRefresh(() async {
      return http.put(
        url,
        headers: await buildHeaders(
          includeContentType: true,
          extraHeaders: headers,
        ),
        body: body,
      );
    });
  }

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _withAutoRefresh(() async {
      return http.patch(
        url,
        headers: await buildHeaders(
          includeContentType: true,
          extraHeaders: headers,
        ),
        body: body,
      );
    });
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) {
    return _withAutoRefresh(() async {
      return http.delete(
        url,
        headers: await buildHeaders(
          includeContentType: true,
          extraHeaders: headers,
        ),
        body: body,
      );
    });
  }

  static Future<http.MultipartRequest> multipartRequest(
    String method,
    Uri url, {
    Map<String, String>? headers,
  }) async {
    final request = http.MultipartRequest(method, url);
    request.headers.addAll(
      await buildHeaders(extraHeaders: headers),
    );
    return request;
  }
}
