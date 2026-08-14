import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, String>> getAuthHeaders({bool includeContentType = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final jwtAccess = prefs.getString('jwt_access') ?? '';
  final oldToken = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';

  final Map<String, String> headers = {};

  if (includeContentType) {
    headers['Content-Type'] = 'application/json';
  }

  headers['Accept'] = 'application/json';

  if (jwtAccess.isNotEmpty) {
    final jwtValue = jwtAccess.startsWith('Bearer ') ? jwtAccess : 'Bearer $jwtAccess';
    headers['Authorization'] = jwtValue;
  } else if (oldToken.isNotEmpty) {
    final tokenValue = oldToken.startsWith('Token ') ? oldToken : 'Token $oldToken';
    headers['Authorization'] = tokenValue;
  }

  return headers;
}
