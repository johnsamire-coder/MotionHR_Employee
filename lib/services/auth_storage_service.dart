import 'package:shared_preferences/shared_preferences.dart';

class AuthStorageService {
  static const String _keyUsername = 'saved_username';
  static const String _keyPassword = 'saved_password';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyStayLoggedIn = 'stay_logged_in';
  static const String _keyLastLoginTime = 'last_login_time';
  static const String _keyAuthToken = 'auth_token';
  static const int _stayLoggedInHours = 72;

  // حفظ بيانات تذكرني
  static Future<void> saveRememberMe({
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, rememberMe);
    if (rememberMe) {
      await prefs.setString(_keyUsername, username);
      await prefs.setString(_keyPassword, password);
    } else {
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyPassword);
    }
  }

  // جلب بيانات تذكرني
  static Future<Map<String, dynamic>> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'rememberMe': prefs.getBool(_keyRememberMe) ?? false,
      'username': prefs.getString(_keyUsername) ?? '',
      'password': prefs.getString(_keyPassword) ?? '',
    };
  }
  // حفظ حالة البقاء مسجلاً
  static Future<void> saveStayLoggedIn({
    required bool stayLoggedIn,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // احتفظ دائماً بالتوكن للبصمة
    await prefs.setString(_keyAuthToken, token);

    await prefs.setBool(_keyStayLoggedIn, stayLoggedIn);

    if (stayLoggedIn) {
      await prefs.setInt(
        _keyLastLoginTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    } else {
      // عند إلغاء stay logged in امسح وقت الجلسة فقط
      // لكن لا تمسح auth_token لأن البصمة تعتمد عليه
      await prefs.remove(_keyLastLoginTime);
    }
  }

  // فحص لو البقاء مسجلاً شغال وصالح
  static Future<Map<String, dynamic>> checkStayLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final stayLoggedIn = prefs.getBool(_keyStayLoggedIn) ?? false;
    if (!stayLoggedIn) return {'valid': false, 'token': null};

    final token = prefs.getString(_keyAuthToken);
    if (token == null || token.isEmpty) return {'valid': false, 'token': null};

    final lastLoginTime = prefs.getInt(_keyLastLoginTime) ?? 0;
    final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
    final diff = DateTime.now().difference(lastLogin);

    if (diff.inHours >= _stayLoggedInHours) {
      // انتهت الـ 72 ساعة - امسح
      await clearStayLoggedIn();
      return {'valid': false, 'token': null};
    }

    return {'valid': true, 'token': token};
  }
  // مسح البقاء مسجلاً
  static Future<void> clearStayLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastLoginTime);
    await prefs.setBool(_keyStayLoggedIn, false);
    // لا تمسح auth_token هنا لأن البصمة تعتمد عليه
  }

  // تحديث وقت آخر استخدام (كل مرة بيفتح التطبيق)
  static Future<void> refreshLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final stayLoggedIn = prefs.getBool(_keyStayLoggedIn) ?? false;
    if (stayLoggedIn) {
      await prefs.setInt(
        _keyLastLoginTime,
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }
  // مسح كل حاجة عند الخروج
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyLastLoginTime);
    await prefs.setBool(_keyStayLoggedIn, false);
    // ⚠️ biometric_enabled محتاج يفضل موجود عشان البصمة تشتغل بعد الـ Logout
    // لكن نعمل flag إن التوكن اتمسح وهيحتاج login عادي مرة واحدة
    await prefs.setBool('biometric_needs_reauth', true);
    // تذكرني يفضل محفوظ حتى بعد الخروج
  }

    // احصل على التوكن المحفوظ
  static Future<String?> getSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_keyAuthToken);
    if (token == null || token.isEmpty) {
      token = prefs.getString('token');
    }
    return (token == null || token.isEmpty) ? null : token;
  }

  // حفظ التوكن بشكل متزامن
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
    await prefs.setString('token', token);
  }
}
