import 'package:http/http.dart' as http;
import 'api_service.dart';

class ApiClient {
  static Future<Map<String, String>> buildHeaders({
    bool includeContentType = false,
    Map<String, String>? extraHeaders,
  }) async {
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

  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) async {
    return http.get(
      url,
      headers: await buildHeaders(extraHeaders: headers),
    );
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.post(
      url,
      headers: await buildHeaders(
        includeContentType: true,
        extraHeaders: headers,
      ),
      body: body,
    );
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.put(
      url,
      headers: await buildHeaders(
        includeContentType: true,
        extraHeaders: headers,
      ),
      body: body,
    );
  }

  static Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.patch(
      url,
      headers: await buildHeaders(
        includeContentType: true,
        extraHeaders: headers,
      ),
      body: body,
    );
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    return http.delete(
      url,
      headers: await buildHeaders(
        includeContentType: true,
        extraHeaders: headers,
      ),
      body: body,
    );
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
