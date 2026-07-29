import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> getAuthHeaders({bool includeContentType = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final jwtAccess = prefs.getString('jwt_access') ?? '';
  final oldToken = prefs.getString('token') ?? '';

  final Map<String, String> headers = {};

  if (includeContentType) {
    headers['Content-Type'] = 'application/json';
  }

  headers['Accept'] = 'application/json';

  if (jwtAccess.isNotEmpty) {
    headers['Authorization'] = 'Bearer $jwtAccess';
  } else if (oldToken.isNotEmpty) {
    headers['Authorization'] = 'Token $oldToken';
  }

  return headers;
}
