import 'package:http/http.dart' as http;
import 'api_service.dart';

class ApiClient {
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    final authHeaders = await getAuthHeaders();
    final finalHeaders = {...?headers, ...authHeaders};
    return http.get(url, headers: finalHeaders);
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    final authHeaders = await getAuthHeaders(includeContentType: true);
    final finalHeaders = {...?headers, ...authHeaders};
    return http.post(url, headers: finalHeaders, body: body);
  }
}
