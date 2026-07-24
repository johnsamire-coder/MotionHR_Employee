import 'dart:async';
import 'package:motionhr_employee/l10n/l10n.dart';
import 'dart:convert';
import 'dart:math';

import 'package:geocoding/geocoding.dart';
import 'screens/first_launch_language_screen.dart';
import 'package:flutter/material.dart';
import 'screens/manager/reports/reports_hub_screen.dart';
import 'screens/manager/payroll/payroll_hub_screen.dart';
import 'screens/manager/reminder_settings_screen.dart';
import 'screens/employee/employee_profile_screen.dart';
import 'screens/employee/announcements_screen.dart';
import 'screens/manager/manager_announcements_screen.dart';
import 'screens/manager/attendance_policy_screen.dart';
import 'screens/manager/create_employee_screen.dart';
import 'screens/manager/manager_employees_list_screen.dart';
import 'screens/manager/manager_missions_screen.dart';
import 'screens/manager/shifts/shifts_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/auth_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/biometric_auth_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'background_service.dart';
import 'package:file_picker/file_picker.dart';

import 'screens/employee/item_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/manager/company_info_screen.dart';
import 'screens/manager/organization_tree_screen.dart';
import 'screens/manager/permissions_management_screen.dart';
import 'screens/manager/departments_management_screen.dart';
import 'screens/manager/offboarding_screen.dart';
import 'screens/employee_missions_screen.dart';
import 'widgets/empty_state_widget.dart';
import 'services/language_service.dart';
import 'services/location_tracking_service.dart';
import 'services/auto_checkin_service.dart';


const String kBaseUrl = 'https://jssolutions-eg.com';
const Color kPrimaryColor = Color(0xFF1976D2);
String formatTime12h(dynamic raw) {
  final text = (raw ?? '').toString().trim();
  if (text.isEmpty || text == 'null') return '-';

  String timeText = text;

  if (timeText.contains('T')) {
    timeText = timeText.split('T').last;
  }
  if (timeText.contains(' ')) {
    timeText = timeText.split(' ').last;
  }
  if (timeText.contains('.')) {
    timeText = timeText.split('.').first;
  }

  final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$').firstMatch(timeText);
  if (match == null) return text;

  int hour = int.tryParse(match.group(1)!) ?? 0;
  final minute = match.group(2)!;

  final period = hour >= 12 ? 'PM' : 'AM';
  hour = hour % 12;
  if (hour == 0) hour = 12;

  return '${hour.toString().padLeft(2, '0')}:$minute $period';
}

const Color kPrimaryDark = Color(0xFF0D47A1);
const Color kAccentColor = Color(0xFF42A5F5);
const Color kManagerColor = Color(0xFF6A1B9A);

final FlutterLocalNotificationsPlugin _localNotif =
    FlutterLocalNotificationsPlugin();

final ValueNotifier<int> unreadNotificationsCount = ValueNotifier<int>(0);

Future<void> fetchUnreadCount() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return;
    final res = await http.get(
      Uri.parse('$kBaseUrl/attendance/api/mobile/notifications/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      unreadNotificationsCount.value = data['unread_count'] ?? 0;
    }
  } catch (_) {}
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _localNotif.initialize(
    const InitializationSettings(android: android),
    onDidReceiveNotificationResponse: (_) {},
  );
  await _localNotif
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'motionhr_channel',
          'MotionHR Notifications',
          importance: Importance.max,
        ),
      );
}

Future<void> showLocalNotification(String title, String body) async {
  await _localNotif.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'motionhr_channel',
        'MotionHR Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    ),
  );
}

// ═══════════════════════════════════════════════
// رسائل الصباح - عربي وإنجليزي
// ═══════════════════════════════════════════════
Map<String, Map<String, List<String>>> kMorningMessages = {
  'ar': {
    'male': [
      'صباح الخير يا {name} 🌅 يومك جميل بإذن الله',
      'يومك سعيد يا {name} 😊 يارب يومك طاقة إيجابية',
      'أهلاً يا {name}، جاهز نبدع النهاردة! 🚀',
      'صباح النور يا {name} 🌞 ثقتك مميزة يا مبدع',
      'شغلك النهاردة هيكون سبب في نجاحك يا {name} 💪',
      'أنت جزء مهم من الفريق يا {name}، يوم موفق 🎯',
      'صباح الورد يا {name} 🌹 اعمل يومك أحلى ما يكون',
      'كل خطوة بتاخدها بتقربك من هدفك يا {name} 🏆',
      'صباح الفل يا {name}، نجاح قادم في انتظارك 💼',
      'اجعل يومك مليئًا بالإنجازات يا {name} 🌟',
    ],
    'female': [
      'صباح الخير يا {name} 🌅 يومك جميل بإذن الله',
      'يومك سعيد يا {name} 😊 يارب يومك طاقة إيجابية',
      'أهلاً يا {name}، جاهزة نبدعي النهاردة! 🚀',
      'صباح النور يا {name} 🌞 ثقتك مميزة يا مبدعة',
      'شغلك النهاردة هيكون سبب في نجاحك يا {name} 💪',
      'أنتِ جزء مهم من الفريق يا {name}، يوم موفق 🎯',
      'صباح الورد يا {name} 🌹 اعملي يومك أحلى ما يكون',
      'كل خطوة بتاخديها بتقربك من هدفك يا {name} 🏆',
      'صباح الفل يا {name}، نجاح قادم في انتظارك 💼',
      'اجعلي يومك مليئًا بالإنجازات يا {name} 🌟',
    ],
  },
  'en': {
    'male': [
      'Good morning {name} 🌅 Have a wonderful day!',
      'Happy day {name} 😊 Wishing you positive energy!',
      'Hello {name}, ready to be creative today! 🚀',
      'Good morning {name} 🌞 Your confidence is unique!',
      'Your work today will be the reason for your success {name} 💪',
      'You are an important part of the team {name}, have a great day 🎯',
      'Good morning {name} 🌹 Make your day the best it can be!',
      'Every step you take brings you closer to your goal {name} 🏆',
      'Good morning {name}, success is waiting for you 💼',
      'Make your day full of achievements {name} 🌟',
    ],
    'female': [
      'Good morning {name} 🌅 Have a wonderful day!',
      'Happy day {name} 😊 Wishing you positive energy!',
      'Hello {name}, ready to be creative today! 🚀',
      'Good morning {name} 🌞 Your confidence is unique!',
      'Your work today will be the reason for your success {name} 💪',
      'You are an important part of the team {name}, have a great day 🎯',
      'Good morning {name} 🌹 Make your day the best it can be!',
      'Every step you take brings you closer to your goal {name} 🏆',
      'Good morning {name}, success is waiting for you 💼',
      'Make your day full of achievements {name} 🌟',
    ],
  },
};

// ═══════════════════════════════════════════════
// رسائل المساء - عربي وإنجليزي
// ═══════════════════════════════════════════════
Map<String, Map<String, List<String>>> kEveningMessages = {
  'ar': {
    'male': [
      'شكراً على مجهودك النهاردة يا {name} 🌙 استريح كويس',
      'يوم عمل جميل يا {name}، تستاهل راحة ممتعة 😴',
      'أحسنت يا {name}! اليوم ده كان فيه إنجاز، مساءك سعيد 🌟',
      'شغل رائع النهاردة يا {name}، مساء الخير والراحة 🎉',
      'انتهيت من يوم منتج يا {name}، وقت العافية والراحة 🛌',
      'أنت تستحق الراحة يا {name}، مساءك أحلى 💤',
      'يوم موفق انتهى يا {name}، وقت الاستجمام 🏖',
      'الله يبارك في مجهودك يا {name}، خد قسط من الراحة 🌟',
      'يوم رائع يا {name}، استمر 🎯',
      'مساء الخير يا {name}، تستاهل كل خير 🌞',
    ],
    'female': [
      'شكراً على مجهودك النهاردة يا {name} 🌙 استريحي كويس',
      'يوم عمل جميل يا {name}، تستاهلي راحة ممتعة 😴',
      'أحسنتِ يا {name}! اليوم ده كان فيه إنجاز، مساءك سعيد 🌟',
      'شغل رائع النهاردة يا {name}، مساء الخير والراحة 🎉',
      'انتهيتي من يوم منتج يا {name}، وقت العافية والراحة 🛌',
      'أنتِ تستحقي الراحة يا {name}، مساءك أحلى 💤',
      'يوم موفق انتهى يا {name}، وقت الاستجمام 🏖',
      'الله يبارك في مجهودك يا {name}، خدي قسط من الراحة 🌟',
      'يوم رائع يا {name}، استمري 🎯',
      'مساء الخير يا {name}، تستاهلي كل خير 🌞',
    ],
  },
  'en': {
    'male': [
      'Thank you for your effort today {name} 🌙 Rest well!',
      'Great work day {name}, you deserve a pleasant rest 😴',
      'Well done {name}! Today was full of achievements, good evening 🌟',
      'Great work today {name}, good evening and rest well 🎉',
      'You finished a productive day {name}, time to relax 🛌',
      'You deserve the rest {name}, have a great evening 💤',
      'A successful day ended {name}, time to unwind 🏖',
      'God bless your effort {name}, take some rest 🌟',
      'Great day {name}, keep it up 🎯',
      'Good evening {name}, you deserve all the best 🌞',
    ],
    'female': [
      'Thank you for your effort today {name} 🌙 Rest well!',
      'Great work day {name}, you deserve a pleasant rest 😴',
      'Well done {name}! Today was full of achievements, good evening 🌟',
      'Great work today {name}, good evening and rest well 🎉',
      'You finished a productive day {name}, time to relax 🛌',
      'You deserve the rest {name}, have a great evening 💤',
      'A successful day ended {name}, time to unwind 🏖',
      'God bless your effort {name}, take some rest 🌟',
      'Great day {name}, keep it up 🎯',
      'Good evening {name}, you deserve all the best 🌞',
    ],
  },
};

// ═══════════════════════════════════════════════
// getRandomMessage - يقرأ اللغة ويختار الرسائل المناسبة
// ═══════════════════════════════════════════════
String getRandomMessage(
  Map<String, Map<String, List<String>>> messages,
  String gender,
  String name, {
  String lang = 'ar',
}) {
  final langMap = messages[lang] ?? messages['ar']!;
  final list = langMap[gender] ?? langMap['male']!;
  final msg = list[Random().nextInt(list.length)];
  final fallback = lang == 'ar' ? 'صديقنا' : 'Friend';
  return msg.replaceAll('{name}', name.isEmpty ? fallback : name);
}

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message: ${message.notification?.title}');
}

Future<void> initFirebaseMessaging() async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      print('🔔 Foreground message: ${message.notification?.title}');
      if (message.notification != null) {
        await showLocalNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
        );
        await fetchUnreadCount();
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('👆 User tapped notification: ${message.notification?.title}');
      fetchUnreadCount();
    });

    print('✅ Firebase Messaging initialized');
  } catch (e) {
    print('❌ Firebase Messaging error: $e');
  }
}

Future<void> saveFCMTokenToServer() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) return;

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    final res = await http.post(
      Uri.parse('$kBaseUrl/attendance/api/mobile/fcm-token/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
      body: jsonEncode({
        'fcm_token': fcmToken,
        'preferred_language': LanguageService.currentLocale.value.languageCode,
      }),
    );

    if (res.statusCode == 200) {
      await prefs.setString('fcm_token', fcmToken);
    }
  } catch (_) {}
}

class NotificationBellButton extends StatelessWidget {
  final Color color;
  const NotificationBellButton({super.key, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: unreadNotificationsCount,
      builder: (context, count, _) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(Icons.notifications, color: color),
              tooltip: context.l10n.notifications,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                );
                fetchUnreadCount();
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.loadSavedLanguage();
  try {
    await Firebase.initializeApp();
    await initLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    await initFirebaseMessaging();
  } catch (_) {}
  await configureBackgroundTracking();
  runApp(const MotionHRApp());
}

class MotionHRApp extends StatefulWidget {
  const MotionHRApp({super.key});

  @override
  State<MotionHRApp> createState() => _MotionHRAppState();
}

class _MotionHRAppState extends State<MotionHRApp> {
  bool _isFirstLaunch = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('first_launch_done') ?? false;
    setState(() {
      _isFirstLaunch = !done;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LanguageService.currentLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'MotionHR',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Arial'),
          locale: locale,
          supportedLocales: const [
            Locale('ar'),
            Locale('en'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: locale.languageCode == 'ar'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox(),
            );
          },
          home: _checking
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : _isFirstLaunch
                  ? FirstLaunchLanguageScreen(
                      onDone: () {
                        setState(() => _isFirstLaunch = false);
                      },
                    )
                  : const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final stayData = await AuthStorageService.checkStayLoggedIn();
    final bool isValidSession = stayData['valid'] == true;
    final String? token = stayData['token'] as String?;
    final appMode = prefs.getString('app_mode') ?? 'employee';

    if (!mounted) return;

    if (isValidSession && token != null && token.isNotEmpty) {
      await prefs.setString('token', token);
      await AuthStorageService.refreshLoginTime();

      saveFCMTokenToServer();
      fetchUnreadCount();
      AutoCheckinService.startMonitoring();

      bool needsCharter = false;
      if (appMode != 'manager') {
        try {
          final res = await http.get(
            Uri.parse('$kBaseUrl/attendance/api/mobile/charter/'),
            headers: {'Authorization': 'Token $token'},
          );

          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            if (data['success'] == true &&
                data['has_charter'] == true &&
                data['needs_acceptance'] == true) {
              needsCharter = true;
            }
          }
        } catch (_) {}
      }

      if (!mounted) return;

      if (needsCharter) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CharterScreen(appMode: appMode),
          ),
        );
      } else if (appMode == 'manager') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ManagerShell()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeShell()),
        );
      }
    } else {
      await prefs.remove('token');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryDark, kPrimaryColor, kAccentColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'MotionHR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'نظام إدارة الموارد البشرية'
                    : 'Human Resources Management System',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passFocus = FocusNode();

  bool _loading = false;
  bool _obscurePass = true;
  String? _error;
  bool _rememberMe = false;
  bool _stayLoggedIn = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAuthData();
    _checkBiometric();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final available = await BiometricAuthService.isBiometricAvailable();
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('biometric_enabled') ?? false;
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
    // لو البصمة مفعلة وفيه token محفوظ → جرب تسجل دخول بالبصمة تلقائياً
    if (available && enabled) {
      final token = await AuthStorageService.getSavedToken();
      if (token != null && token.isNotEmpty) {
        // نستخدم اللغة المحفوظة بدلاً من context (لأننا في initState)
        final lang = LanguageService.currentLocale.value.languageCode;
        final reason = lang == 'ar'
            ? 'سجّل دخولك بالبصمة'
            : 'Log in with biometrics';
        final auth = await BiometricAuthService.authenticate(reason: reason);
        if (auth && mounted) {
          _navigateByToken(token);
        }
      }
    }
  }

  Future<void> _navigateByToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final appMode = prefs.getString('app_mode') ?? 'employee';
    if (!mounted) return;
    if (appMode == 'manager') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const EmployeeShell()),
      );
    }
  }

  Future<void> _loginWithBiometric() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى تسجيل الدخول مرة واحدة أولاً لتفعيل البصمة'
                : 'Please log in once first to enable biometric login',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final reason = isAr ? 'سجّل دخولك بالبصمة' : 'Log in with biometrics';
    final auth = await BiometricAuthService.authenticate(reason: reason);
    if (auth && mounted) {
      _navigateByToken(token);
    }
  }

  Future<void> _loadSavedAuthData() async {
    final rememberData = await AuthStorageService.getRememberMe();
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _rememberMe = rememberData['rememberMe'] ?? false;
      _stayLoggedIn = prefs.getBool('stay_logged_in') ?? false;
      _userCtrl.text = rememberData['username'] ?? '';
      _passCtrl.text = rememberData['password'] ?? '';
    });
  }

  Future<void> _login() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = isAr
          ? 'من فضلك ادخل اسم المستخدم وكلمة المرور'
          : 'Please enter username and password');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/attendance/api/mobile/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _userCtrl.text.trim(),
          'password': _passCtrl.text,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', data['token']);
        await prefs.setString('auth_token', data['token']); // للبصمة

        String username = data['username'] ?? '';
        String fullName = data['full_name'] ?? '';
        String companyName = data['company_name'] ?? '';
        String firstName = data['first_name'] ?? '';
        String gender = data['gender'] ?? 'male';

        if (data['employee'] is Map) {
          fullName = fullName.isEmpty
              ? (data['employee']['name'] ?? '')
              : fullName;
          companyName = companyName.isEmpty
              ? (data['employee']['company'] ?? '')
              : companyName;
          firstName = firstName.isEmpty
              ? (data['employee']['first_name'] ?? '')
              : firstName;
          gender = gender == 'male' && data['employee']['gender'] != null
              ? data['employee']['gender']
              : gender;
        }

        if (firstName.isEmpty && fullName.isNotEmpty) {
          firstName = fullName.split(' ').first;
        }

        await prefs.setString('username', username);
        await prefs.setString('full_name', fullName);
        await prefs.setString('company_name', companyName);
        await prefs.setString('first_name', firstName);
        await prefs.setString('gender', gender);
        await prefs.setString('role', data['role'] ?? 'employee');
        await prefs.setString('app_mode', data['app_mode'] ?? 'employee');

        await AuthStorageService.saveRememberMe(
          username: _userCtrl.text.trim(),
          password: _passCtrl.text,
          rememberMe: _rememberMe,
        );

        await AuthStorageService.saveStayLoggedIn(
          stayLoggedIn: _stayLoggedIn,
          token: data['token'],
        );
        await AuthStorageService.saveToken(data['token']);
        // لو البصمة متاحة → فعّلها تلقائياً بعد أول دخول ناجح
        if (_biometricAvailable) {
          final prefs2 = await SharedPreferences.getInstance();
          await prefs2.setBool('biometric_enabled', true);
        }

        saveFCMTokenToServer();
        fetchUnreadCount();
        AutoCheckinService.startMonitoring();

        final mustChange = data['must_change_password'] == true;
        final appMode = data['app_mode'] ?? 'employee';

        bool needsCharter = false;
        if (appMode != 'manager') {
          try {
            final charterRes = await http.get(
              Uri.parse('$kBaseUrl/attendance/api/mobile/charter/'),
              headers: {'Authorization': 'Token ${data['token']}'},
            );
            if (charterRes.statusCode == 200) {
              final charterData = jsonDecode(charterRes.body);
              if (charterData['success'] == true &&
                  charterData['has_charter'] == true &&
                  charterData['needs_acceptance'] == true) {
                needsCharter = true;
              }
            }
          } catch (_) {}
        }

        if (!mounted) return;

        if (mustChange) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const ChangePasswordScreen(forced: true),
            ),
          );
        } else if (needsCharter) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CharterScreen(appMode: appMode),
            ),
          );
        } else if (appMode == 'manager') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ManagerShell()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeShell()),
          );
        }
      } else {
        final isAr = Localizations.localeOf(context).languageCode == 'ar';
        setState(() => _error = data['message'] ??
            (isAr ? 'بيانات الدخول غير صحيحة' : 'Invalid login credentials'));
      }
    } catch (e) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      setState(() => _error = isAr ? 'خطأ في الاتصال بالخادم' : 'Server connection error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showForgotPassword() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(context.l10n.forgotPassword),
          content: Text(
            isAr
                ? 'من فضلك تواصل مع مسئول الموارد البشرية لإعادة تعيين كلمة المرور الخاصة بك.'
                : 'Please contact your HR manager to reset your password.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.ok),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryDark, kPrimaryColor, kAccentColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // ── زر تغيير اللغة ──
                  Align(
                    alignment: isAr
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PopupMenuButton<String>(
                        icon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 10),
                            const Icon(Icons.language,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 6),
                          ],
                        ),
                        onSelected: (value) async {
                          await LanguageService.changeLanguage(value);
                          if (context.mounted) setState(() {});
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'ar',
                            child: Row(
                              children: [
                                const Text('🇸🇦 ',
                                    style: TextStyle(fontSize: 18)),
                                Text(context.l10n.arabic),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'en',
                            child: Row(
                              children: [
                                const Text('🇬🇧 ',
                                    style: TextStyle(fontSize: 18)),
                                const Text('English'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on,
                        size: 70, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MotionHR',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'مرحباً بك، سجل دخولك للمتابعة'
                        : 'Welcome, please log in to continue',
                    style: const TextStyle(
                        fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _userCtrl,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passFocus.requestFocus(),
                          decoration: InputDecoration(
                            labelText: context.l10n.username,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.person,
                                color: kPrimaryColor),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passCtrl,
                          focusNode: _passFocus,
                          obscureText: _obscurePass,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: context.l10n.password,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.lock,
                                color: kPrimaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePass = !_obscurePass),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: kPrimaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      context.l10n.rememberMe,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: kPrimaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_biometricAvailable)
                                Row(
                                  children: [
                                    const Icon(Icons.fingerprint,
                                        color: kPrimaryColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isAr
                                            ? 'الدخول بالبصمة'
                                            : 'Biometric Login',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: _biometricEnabled,
                                      activeColor: kPrimaryColor,
                                      onChanged: (value) async {
                                        if (value) {
                                          final lang = LanguageService
                                              .currentLocale
                                              .value
                                              .languageCode;
                                          final reason = lang == 'ar'
                                              ? 'تأكيد تفعيل الدخول بالبصمة'
                                              : 'Confirm biometric login activation';
                                          final authenticated =
                                              await BiometricAuthService
                                                  .authenticate(
                                                      reason: reason);
                                          if (!authenticated ||
                                              !mounted) return;
                                        }
                                        final prefs =
                                            await SharedPreferences
                                                .getInstance();
                                        await prefs.setBool(
                                            'biometric_enabled', value);
                                        if (mounted) {
                                          setState(() {
                                            _biometricEnabled = value;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              const Divider(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                      Icons.verified_user_outlined,
                                      color: kPrimaryColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.l10n.stayLoggedIn,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          isAr
                                              ? 'يبقى الحساب مفتوحاً حتى 72 ساعة'
                                              : 'Account stays open for up to 72 hours',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _stayLoggedIn,
                                    activeColor: kPrimaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _stayLoggedIn = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: Colors.red[700])),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.login,
                                          color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        isAr ? 'دخول' : 'Login',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // زر البصمة
                        if (_biometricAvailable && _biometricEnabled)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _loginWithBiometric,
                                icon: const Icon(Icons.fingerprint,
                                    size: 28, color: kPrimaryColor),
                                label: Text(
                                  isAr
                                      ? 'دخول بالبصمة'
                                      : 'Biometric Login',
                                  style: const TextStyle(
                                    color: kPrimaryColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: kPrimaryColor, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        TextButton(
                          onPressed: _showForgotPassword,
                          child: Text(
                            isAr
                                ? 'نسيت كلمة المرور؟'
                                : 'Forgot password?',
                            style:
                                const TextStyle(color: kPrimaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '© 2025 MotionHR',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  final bool forced;
  const ChangePasswordScreen({super.key, this.forced = false});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _obscure3 = true;
  String? _error;

  Future<void> _changePassword() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _error = context.l10n.passwordMismatch);
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() => _error = context.l10n.passwordTooShort);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await http.post(
        Uri.parse('$kBaseUrl/attendance/api/mobile/change-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'current_password': _currentCtrl.text,
          'new_password': _newCtrl.text,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }
        final appMode = prefs.getString('app_mode') ?? 'employee';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.passwordChanged),
            backgroundColor: Colors.green,
          ),
        );
        if (appMode == 'manager') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ManagerShell()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EmployeeShell()),
          );
        }
      } else {
        setState(() => _error = data['message'] ??
            (isAr ? 'فشل تغيير كلمة المرور' : 'Failed to change password'));
      }
    } catch (e) {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      setState(() =>
          _error = isAr ? 'خطأ في الاتصال' : 'Connection error');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _pf(
      TextEditingController c, String l, bool o, VoidCallback t) {
    return TextField(
      controller: c,
      obscureText: o,
      decoration: InputDecoration(
        labelText: l,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.lock, color: kPrimaryColor),
        suffixIcon: IconButton(
          icon: Icon(
            o ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: t,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.changePassword),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !widget.forced,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (widget.forced)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAr
                              ? 'يجب تغيير كلمة المرور قبل استخدام التطبيق'
                              : 'You must change your password before using the app',
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              _pf(
                _currentCtrl,
                context.l10n.currentPassword,
                _obscure1,
                () => setState(() => _obscure1 = !_obscure1),
              ),
              const SizedBox(height: 16),
              _pf(
                _newCtrl,
                context.l10n.newPassword,
                _obscure2,
                () => setState(() => _obscure2 = !_obscure2),
              ),
              const SizedBox(height: 16),
              _pf(
                _confirmCtrl,
                context.l10n.confirmPassword,
                _obscure3,
                () => setState(() => _obscure3 = !_obscure3),
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red[50],
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Text(
                          isAr ? 'حفظ' : 'Save',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmployeeShell extends StatefulWidget {
  final int initialIndex;
  const EmployeeShell({super.key, this.initialIndex = 0});

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    fetchUnreadCount();
  }

  List<Widget> get _pages => [
        const EmployeeHomeScreen(),
        const LeavesScreen(),
        const RequestsScreen(),
        const EmployeeMissionsScreen(),
        const MyItemsScreen(),
      ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await AuthStorageService.clearAll();
    await stopBackgroundTracking();
    unreadNotificationsCount.value = 0;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MotionHR'),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          actions: [
            const NotificationBellButton(),
            IconButton(
              icon: const Icon(Icons.campaign),
              tooltip: context.l10n.announcements,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AnnouncementsScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.person),
              tooltip: context.l10n.profile,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EmployeeProfileScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.lock),
              tooltip: context.l10n.changePassword,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: context.l10n.settings,
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: context.l10n.logout,
              onPressed: _logout,
            ),
          ],
        ),
        body: _pages[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: kPrimaryColor,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home), label: context.l10n.home),
            BottomNavigationBarItem(
                icon: const Icon(Icons.beach_access),
                label: context.l10n.leaves),
            BottomNavigationBarItem(
                icon: const Icon(Icons.assignment),
                label: context.l10n.requests),
            BottomNavigationBarItem(
                icon: const Icon(Icons.task_alt),
                label: context.l10n.myMissions),
            BottomNavigationBarItem(
                icon: const Icon(Icons.list_alt),
                label: context.l10n.myRequests),
          ],
        ),
      ),
    );
  }
}

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  String _fullName = '';
  String _companyName = '';
  String _firstName = '';
  String _gender = 'male';
  Map<String, dynamic>? _status;
  bool _loading = false;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  String? _motivationMessage;
  bool _isEveningMessage = false;

  final List<String> _arabicDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس',
    'الجمعة', 'السبت', 'الأحد',
  ];

  final List<String> _englishDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  final List<String> _arabicMonths = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  final List<String> _englishMonths = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _fullName = prefs.getString('full_name') ?? '';
    _companyName = prefs.getString('company_name') ?? '';
    _firstName = prefs.getString('first_name') ?? '';
    _gender = prefs.getString('gender') ?? 'male';
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/attendance/api/mobile/status/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _status = jsonDecode(res.body));
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _attendanceAction(String action) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _loading = true);
    try {
      await requestLocationPermissionsForTracking();
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      // routing ??? ??? ??????
      final String attendanceUrl;
      final Map<String, dynamic> attendanceBody;

      if (action == 'partial_checkout') {
        attendanceUrl = '$kBaseUrl/attendance/api/mobile/employee/partial-checkout/';
        attendanceBody = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      } else if (action == 'resume_checkin') {
        attendanceUrl = '$kBaseUrl/attendance/api/mobile/employee/resume-checkin/';
        attendanceBody = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      } else {
        attendanceUrl = '$kBaseUrl/attendance/api/mobile/attendance/';
        attendanceBody = {
          'action': action,
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      }

      final res = await http.post(
        Uri.parse(attendanceUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token'
        },
        body: jsonEncode(attendanceBody),
      );
      debugPrint('ATTENDANCE STATUS: ${res.statusCode}');
      debugPrint('ATTENDANCE BODY: ${res.body}');
      final data = jsonDecode(res.body);
      final success = data['success'] == true;
      if (mounted) {
        if (success) {
          fetchUnreadCount();
          final lang =
              LanguageService.currentLocale.value.languageCode;
          if (action == 'check_in') {
            setState(() {
              _motivationMessage = getRandomMessage(
                  kMorningMessages, _gender, _firstName,
                  lang: lang);
              _isEveningMessage = false;
            });
            LocationTrackingService.startTracking();
          } else if (action == 'check_out') {
            setState(() {
              _motivationMessage = getRandomMessage(
                  kEveningMessages, _gender, _firstName,
                  lang: lang);
              _isEveningMessage = true;
            });
            LocationTrackingService.stopTracking();
          }
          _showMotivationDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAr
                    ? (data['message_ar'] ??
                        data['message'] ??
                        data['detail'] ??
                        'حدث خطأ')
                    : (data['message_en'] ??
                        data['message'] ??
                        data['detail'] ??
                        'An error occurred'),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      await _loadData();    } catch (e) {
      debugPrint('ATTENDANCE ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'خطأ: $e' : 'Error: $e',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showMotivationDialog() {
    if (_motivationMessage == null) return;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  _isEveningMessage
                      ? Icons.nightlight_round
                      : Icons.wb_sunny,
                  size: 60,
                  color:
                      _isEveningMessage ? Colors.indigo : Colors.orange),
              const SizedBox(height: 16),
              Text(
                _isEveningMessage
                    ? (isAr ? 'مع السلامة' : 'Goodbye')
                    : (isAr ? 'أهلاً بيك' : 'Welcome'),
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _isEveningMessage
                        ? Colors.indigo
                        : Colors.orange),
              ),
              const SizedBox(height: 12),
              Text(
                _motivationMessage!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isAr ? 'شكراً' : 'Thanks',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formattedDate(bool isAr) {
    if (isAr) {
      final dayName = _arabicDays[_now.weekday - 1];
      final monthName = _arabicMonths[_now.month];
      return '$dayName، ${_now.day} $monthName ${_now.year}';
    } else {
      final dayName = _englishDays[_now.weekday - 1];
      final monthName = _englishMonths[_now.month];
      return '$dayName, ${_now.day} $monthName ${_now.year}';
    }
  }

  String get _formattedTime {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  int _calculateRemainingSeconds() {
    if (_status == null) return 0;
    final timestamp = _status!['shift_end_timestamp'];
    if (timestamp != null) {
      try {
        final endTime = DateTime.parse(timestamp).toLocal();
        final diff = endTime.difference(_now).inSeconds;
        return diff > 0 ? diff : 0;
      } catch (_) {}
    }
    return (_status!['remaining_seconds'] ?? 0) as int;
  }

  String _formatCountdown(int seconds) {
    if (seconds <= 0) return '00:00:00';
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  double _progressValue() {
    if (_status == null) return 0.0;
    final total = (_status!['shift_duration_seconds'] ?? 0) as int;
    if (total <= 0) return 0.0;
    final remaining = _calculateRemainingSeconds();
    final elapsed = total - remaining;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final checkedIn = _status?['checked_in'] == true;
    final checkedOut = _status?['checked_out'] == true;
    final canCheckOut = _status?['can_check_out'] == true;
    final hasEarlyLeave = _status?['has_early_leave_permission'] == true;
    final shiftName = _status?['shift_name'] ?? '';
    final shiftStart = _status?['shift_start'] ?? '';
    final shiftEnd = _status?['shift_end'] ?? '';
    final allowPartialCheckout = _status?['allow_partial_checkout'] == true;
    final canPartialCheckout = _status?['can_partial_checkout'] == true;
    final canResume = _status?['can_resume'] == true;
    final sessionsToday = (_status?['sessions_today'] ?? 0) as int;
    final remainingSecs = _calculateRemainingSeconds();
    final displayName = _firstName.isNotEmpty
        ? _firstName
        : (_fullName.isEmpty ? (isAr ? 'بك' : 'there') : _fullName);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [kPrimaryDark, kPrimaryColor],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: kPrimaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person,
                          color: kPrimaryColor, size: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(
                          isAr
                              ? 'أهلاً يا $displayName'
                              : 'Hello, $displayName',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                        if (_companyName.isNotEmpty)
                          Text(_companyName,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                      ])),
                ]),
                const Divider(color: Colors.white24, height: 24),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.l10n.date,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                            Text(_formattedDate(isAr),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold)),
                          ]),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(context.l10n.time,
                                style: const TextStyle(
                                    color: Colors.white60, fontSize: 12)),
                            Text(_formattedTime,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1)),
                          ]),
                    ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (shiftName.toString().isNotEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.schedule, color: kPrimaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                      '${isAr ? 'شيفت' : 'Shift'}: $shiftName ($shiftStart - $shiftEnd)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )),
                  ])),
            ),
          const SizedBox(height: 16),
          if (checkedIn && !checkedOut)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    canCheckOut ? Colors.green[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: canCheckOut
                        ? Colors.green[200]!
                        : Colors.blue[200]!),
              ),
              child: Column(children: [
                Row(children: [
                  Icon(
                      canCheckOut ? Icons.check_circle : Icons.timer,
                      color:
                          canCheckOut ? Colors.green : kPrimaryColor),
                  const SizedBox(width: 8),
                  Text(
                    canCheckOut
                        ? (isAr
                            ? 'الشيفت خلص، تقدر تنصرف'
                            : 'Shift ended, you can check out')
                        : (isAr
                            ? 'باقي على الانصراف'
                            : 'Remaining until check-out'),
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: canCheckOut
                            ? Colors.green
                            : kPrimaryColor),
                  ),
                ]),
                const SizedBox(height: 12),
                Text(
                  _formatCountdown(remainingSecs),
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color:
                          canCheckOut ? Colors.green : kPrimaryColor,
                      letterSpacing: 2),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: _progressValue(),
                      minHeight: 12,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(
                          canCheckOut ? Colors.green : kPrimaryColor)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(_progressValue() * 100).toInt()}%'
                  ' ${isAr ? 'من الشيفت' : 'of shift'}',
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 12),
                ),
                if (hasEarlyLeave) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            isAr
                                ? 'عندك إذن خروج مبكر 🕐'
                                : 'You have an early leave permission 🕐',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                        ]),
                  ),
                ],
              ]),
            ),
          const SizedBox(height: 20),
          if (checkedOut)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green[200]!)),
              child: Column(children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 60),
                const SizedBox(height: 10),
                Text(
                  isAr
                      ? 'تم تسجيل الحضور والانصراف'
                      : 'Attendance and check-out recorded',
                  style: const TextStyle(
                      fontSize: 18,
                      color: Colors.green,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr ? 'أحسنت العمل اليوم 👏' : 'Great work today 👏',
                  style: const TextStyle(color: Colors.green),
                ),
              ]),
            )
          else
            Row(children: [
              Expanded(
                  child: SizedBox(
                      height: 110,
                      child: ElevatedButton(
                        onPressed: (_loading || checkedIn)
                            ? null
                            : () => _attendanceAction('check_in'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: checkedIn
                                ? Colors.grey[400]
                                : Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: checkedIn ? 0 : 4,
                            disabledBackgroundColor: Colors.grey[400],
                            disabledForegroundColor: Colors.white),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(checkedIn
                                  ? Icons.check_circle
                                  : Icons.login,
                                  size: 40),
                              const SizedBox(height: 6),
                              Text(
                                checkedIn
                                    ? (isAr ? 'تم الحضور 🕐' : 'Checked In 🕐')
                                    : context.l10n.checkIn,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                      ))),
              const SizedBox(width: 12),
              Expanded(
                  child: SizedBox(
                      height: 110,
                      child: ElevatedButton(
                        onPressed: (_loading ||
                                !checkedIn ||
                                (!canCheckOut && !hasEarlyLeave))
                            ? null
                            : () => _attendanceAction('check_out'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                (!checkedIn || (!canCheckOut && !hasEarlyLeave))
                                    ? Colors.grey[400]
                                    : Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation:
                                (!checkedIn || (!canCheckOut && !hasEarlyLeave))
                                    ? 0
                                    : 4,
                            disabledBackgroundColor: Colors.grey[400],
                            disabledForegroundColor: Colors.white),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  (!checkedIn ||
                                          (!canCheckOut && !hasEarlyLeave))
                                      ? Icons.lock
                                      : Icons.logout,
                                  size: 40),
                              const SizedBox(height: 6),
                              Text(
                                !checkedIn
                                    ? context.l10n.checkOut
                                    : (canCheckOut || hasEarlyLeave
                                        ? context.l10n.checkOut
                                        : (isAr ? 'مقفول' : 'Locked')),
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                      ))),
            ]),
          const SizedBox(height: 12),

          // ?? ????? ?????? ?????? ??????? ??
          if (allowPartialCheckout && checkedIn && !checkedOut) ...[
            if (canPartialCheckout)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () => _attendanceAction('partial_checkout'),
                  icon: const Icon(Icons.exit_to_app),
                  label: Text(
                    isAr ? '???? ???? (????? ??????)' : 'Partial Checkout (I will return)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            if (canResume)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : () => _attendanceAction('resume_checkin'),
                  icon: const Icon(Icons.login),
                  label: Text(
                    isAr ? '???? ????? (???? ${sessionsToday + 1})' : 'Resume Work (Session ${sessionsToday + 1})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            if (sessionsToday > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.teal, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isAr
                          ? '????? ????? ?????: $sessionsToday'
                          : 'Work sessions today: $sessionsToday',
                      style: const TextStyle(color: Colors.teal, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 20),
          if (_status?['check_in_time'] != null &&
              (_status?['check_in_time'] ?? '').toString().isNotEmpty)
            Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.login, color: Colors.green)),
                  title: Text(context.l10n.checkInTime),
                  subtitle: Text(
		      formatTime12h(_status?['check_in_time']),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
          if (_status?['check_out_time'] != null &&
              (_status?['check_out_time'] ?? '').toString().isNotEmpty)
            Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8)),
                      child:
                          const Icon(Icons.logout, color: Colors.orange)),
                  title: Text(context.l10n.checkOutTime),
                  subtitle: Text(
  		      formatTime12h(_status?['check_out_time']),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )),
          const SizedBox(height: 20),
          SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen())),
                icon: const Icon(Icons.history),
                label: Text(
                  isAr ? 'سجل الأيام السابقة' : 'Previous Days History',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: kPrimaryColor,
                    side: const BorderSide(color: kPrimaryColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              )),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
          Uri.parse('$kBaseUrl/attendance/api/mobile/history/'),
          headers: {'Authorization': 'Token $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() =>
            _items = data['items'] ?? data['history'] ?? []);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
              title: Text(isAr ? 'سجل الأيام' : 'Days History'),
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(
                      child: Text(isAr ? 'لا يوجد سجل' : 'No history found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return Card(
                            child: ListTile(
                                leading: const Icon(Icons.calendar_today,
                                    color: kPrimaryColor),
                                title: Text(item['date'] ?? ''),
                                subtitle: Text(
                                  isAr
                                      ? 'حضور: ${item['check_in'] ?? '-'}  |  انصراف: ${item['check_out'] ?? '-'}'
                                      : 'Check-in: ${item['check_in'] ?? '-'}  |  Check-out: ${item['check_out'] ?? '-'}',
                                )));
                      }),
        ));
  }
}
String localizedTypeName(String name, bool isAr) {
  final n = name.trim();

  if (isAr) return n;

  switch (n) {
    case 'إجازة سنوية':
      return 'Annual Leave';
    case 'إجازة مرضية':
      return 'Sick Leave';
    case 'إجازة طارئة':
      return 'Emergency Leave';
    case 'إجازة بدون مرتب':
    case 'إجازة بدون أجر':
      return 'Unpaid Leave';
    case 'أخرى':
      return 'Other';
    case 'إذن تأخير':
      return 'Late Permission';
    case 'إذن انصراف مبكر':
      return 'Early Leave Permission';
    case 'إذن خروج':
      return 'Exit Permission';
    case 'طلب إداري':
      return 'Administrative Request';
    case 'طلب شهادة':
      return 'Certificate Request';
    case 'شهادة راتب':
      return 'Salary Certificate';
    case 'خطاب رسمي':
      return 'Official Letter';
    case 'تعديل بيانات':
      return 'Data Update';
    case 'طلب مكافأة':
      return 'Bonus Request';
    case 'سلفة':
      return 'Loan';
    case 'بدل / مصروفات':
      return 'Allowance / Expenses';
    case 'طلب آخر':
      return 'Other Request';
    default:
      return n;
  }
}

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});
  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  List<dynamic> _types = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  int _orderKey(Map t) {
    final category = (t['category'] ?? '').toString().toLowerCase();
    final name = (t['name'] ?? '').toString();
    if (category == 'annual' || name.contains('سنوية')) return 1;
    if (category == 'casual' ||
        category == 'emergency' ||
        name.contains('عارضة') ||
        name.contains('طارئة')) return 2;
    if (category == 'sick' ||
        name.contains('مرضية') ||
        name.contains('مرضي')) return 3;
    return 4;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
          Uri.parse('$kBaseUrl/attendance/api/mobile/leave-types/'),
          headers: {'Authorization': 'Token $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> list =
            data['leave_types'] ?? data['types'] ?? [];
        list = list.where((t) {
          final c = (t['category'] ?? '').toString().toLowerCase();
          final n = (t['name'] ?? '').toString();
          return c != 'paternity' && !n.contains('أبوة');
        }).toList();
        list.sort((a, b) => _orderKey(a).compareTo(_orderKey(b)));
        setState(() => _types = list);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(
        isAr ? 'أنواع الإجازات والأرصدة' : 'Leave Types and Balances',
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 10),
      ..._types.map((t) {
        final balance = t['balance'] is Map
            ? (t['balance']['remaining'] ?? 0)
            : (t['balance'] ?? 0);
        return Card(
            child: ListTile(
                leading:
                    const Icon(Icons.beach_access, color: kPrimaryColor),
                title: Text(localizedTypeName((t['name'] ?? '').toString(), isAr)),
                subtitle: Text(
                  isAr
                      ? 'الرصيد المتبقي: $balance يوم'
                      : 'Remaining balance: $balance day(s)',
                )));
      }),
      const SizedBox(height: 20),
      SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        LeaveRequestScreen(types: _types))),
            icon: const Icon(Icons.add),
            label: Text(
              isAr ? 'تقديم طلب إجازة' : 'Submit Leave Request',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          )),
    ]);
  }
}

class LeaveRequestScreen extends StatefulWidget {
  final List<dynamic> types;
  const LeaveRequestScreen({super.key, required this.types});
  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  String? _selectedValue;
  final _otherCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _loading = false;
  bool get _isOther => _selectedValue == 'other';

  Future<void> _pickDate(TextEditingController c) async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate:
            DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null)
      c.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_selectedValue == null ||
        _startCtrl.text.isEmpty ||
        _endCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'يرجى ملء جميع الحقول'
              : 'Please fill all fields')));
      return;
    }
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final body = <String, dynamic>{
        'start_date': _startCtrl.text,
        'end_date': _endCtrl.text,
        'reason': _isOther
            ? '${isAr ? 'نوع آخر' : 'Other type'}: ${_otherCtrl.text}\n${_reasonCtrl.text}'
            : _reasonCtrl.text
      };
      if (!_isOther) body['leave_type_id'] = _selectedValue;
      final res = await http.post(
          Uri.parse('$kBaseUrl/attendance/api/mobile/leave-request/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token'
          },
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? context.l10n.done)));
        if (data['success'] == true) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${isAr ? 'خطأ' : 'Error'}: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
              title: Text(isAr ? 'طلب إجازة' : 'Leave Request'),
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white),
          body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                        labelText: context.l10n.leaveType,
                        border: const OutlineInputBorder()),
                    value: _selectedValue,
                    items: [
                      ...widget.types
                          .where((t) {
                            final c = (t['category'] ?? '')
                                .toString()
                                .toLowerCase();
                            final n = (t['name'] ?? '').toString();
                            return c != 'paternity' &&
                                !n.contains('أبوة');
                          })
                          .map((t) => DropdownMenuItem<String>(
                              value: t['id'].toString(),
                              child: Text(localizedTypeName((t['name'] ?? '').toString(), isAr)))),
                      DropdownMenuItem<String>(
                          value: 'other',
                          child: Text(isAr ? 'أخرى' : 'Other')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedValue = v)),
                if (_isOther) ...[
                  const SizedBox(height: 16),
                  TextField(
                      controller: _otherCtrl,
                      decoration: InputDecoration(
                          labelText: isAr
                              ? 'اذكر نوع الإجازة'
                              : 'Specify leave type',
                          border: const OutlineInputBorder()))
                ],
                const SizedBox(height: 16),
                TextField(
                    controller: _startCtrl,
                    readOnly: true,
                    onTap: () => _pickDate(_startCtrl),
                    decoration: InputDecoration(
                        labelText: context.l10n.fromDate,
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            const Icon(Icons.calendar_today))),
                const SizedBox(height: 16),
                TextField(
                    controller: _endCtrl,
                    readOnly: true,
                    onTap: () => _pickDate(_endCtrl),
                    decoration: InputDecoration(
                        labelText: context.l10n.toDate,
                        border: const OutlineInputBorder(),
                        suffixIcon:
                            const Icon(Icons.calendar_today))),
                const SizedBox(height: 16),
                TextField(
                    controller: _reasonCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: isAr ? 'السبب' : 'Reason',
                        border: const OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white),
                        child: _loading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                isAr
                                    ? 'إرسال الطلب'
                                    : 'Submit Request',
                                style: const TextStyle(fontSize: 18),
                              ))),
              ])),
        ));
  }
}

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});
  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<dynamic> _types = [];
  bool _loading = true;
  String? _selectedValue;
  final _otherCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _permissionDateCtrl = TextEditingController();
  final _permissionTimeCtrl = TextEditingController();
  final _durationHoursCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  bool _submitting = false;
  bool get _isOther => _selectedValue == 'other';

  Map<String, dynamic>? get _selectedType {
    try {
      return _types
          .cast<Map<String, dynamic>>()
          .firstWhere((t) => t['id'].toString() == _selectedValue);
    } catch (_) {
      return null;
    }
  }

  bool get _isStudentCertificate {
    final t = _selectedType;
    final s = ((t?['name'] ?? '') + ' ' + (t?['name_ar'] ?? ''))
        .toString()
        .toLowerCase();
    return s.contains('student') ||
        s.contains('طالب') ||
        s.contains('قيد');
  }

  bool get _isLoan {
    final t = _selectedType;
    if (_isStudentCertificate) return false;
    return t?['requires_amount'] == true;
  }

  String get _permissionKind {
    final t = _selectedType;
    final explicit = (t?['permission_kind'] ?? '').toString().trim();
    if (explicit == 'late' || explicit == 'late_arrival') return 'late_arrival';
    if (explicit == 'early_leave' || explicit == 'exit') return 'early_leave';
    return 'none';
  }

  bool get _isPermissionRequest => _permissionKind != 'none';

  bool get _requiresDateRange {
    final t = _selectedType;
    return t?['requires_date_range'] == true;
  }

  bool get _requiresDocument {
    final t = _selectedType;
    return t?['requires_document'] == true;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/attendance/api/mobile/request-types/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic> flatTypes = [];

        bool isLeaveLike(Map<String, dynamic> item) {
          final name = (item['name'] ?? '').toString().toLowerCase();
          final category = (item['category'] ?? '').toString().toLowerCase();

          return category.contains('leave') ||
              category.contains('vacation') ||
              category.contains('annual') ||
              category.contains('casual') ||
              category.contains('sick') ||
              category.contains('emergency') ||
              name.contains('اجاز') ||
              name.contains('إجاز') ||
              name.contains('سنوي') ||
              name.contains('عارض') ||
              name.contains('طارئ') ||
              name.contains('مرضي') ||
              name.contains('بدون مرتب') ||
              name.contains('annual') ||
              name.contains('casual') ||
              name.contains('sick') ||
              name.contains('emergency') ||
              name.contains('leave') ||
              name.contains('vacation');
        }

        if (data['categories'] is List) {
          for (final cat in data['categories']) {
            if (cat['types'] is List) {
              for (final t in cat['types']) {
                final item = {
                  'id': t['id'],
                  'name': t['name'],
                  'category': cat['name'],
                  'permission_kind': t['permission_kind'] ?? 'none',
                  'requires_amount': t['requires_amount'] ?? false,
                  'requires_date_range': t['requires_date_range'] ?? false,
                  'requires_document': t['requires_document'] ?? false,
                };

                if (!isLeaveLike(item)) {
                  flatTypes.add(item);
                }
              }
            }
          }
        } else if (data['types'] is List) {
          flatTypes = (data['types'] as List)
              .map((t) => {
                    'id': t['id'],
                    'name': t['name'],
                    'category': t['category'] ?? '',
                    'permission_kind': t['permission_kind'] ?? 'none',
                    'requires_amount': t['requires_amount'] ?? false,
                    'requires_date_range': t['requires_date_range'] ?? false,
                    'requires_document': t['requires_document'] ?? false,
                  })
              .where((item) => !isLeaveLike(Map<String, dynamic>.from(item)))
              .toList();
        }

        setState(() => _types = flatTypes);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickDate(TextEditingController c) async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null)
      c.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      _permissionTimeCtrl.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _submit() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_selectedValue == null || _titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'يرجى اختيار النوع وكتابة العنوان'
              : 'Please choose type and enter title')));
      return;
    }
    if (_requiresDateRange &&
        (_startDateCtrl.text.trim().isEmpty ||
            _endDateCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'يرجى إدخال تاريخ البداية والنهاية'
              : 'Please enter start and end dates')));
      return;
    }
    if (_requiresDateRange) {
      final start = DateTime.tryParse(_startDateCtrl.text.trim());
      final end = DateTime.tryParse(_endDateCtrl.text.trim());
      if (start != null && end != null && end.isBefore(start)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr
                ? 'تاريخ النهاية يجب أن يكون بعد البداية'
                : 'End date must be after start date')));
        return;
      }
    }
    if (_isLoan && _amountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'يرجى إدخال المبلغ المطلوب'
              : 'Please enter the requested amount')));
      return;
    }
    if (_isPermissionRequest &&
        (_permissionDateCtrl.text.trim().isEmpty ||
            _permissionTimeCtrl.text.trim().isEmpty ||
            _durationHoursCtrl.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'يرجى إدخال تاريخ ووقت ومدة الإذن'
              : 'Please enter permission date, time and duration')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _isOther
            ? '${isAr ? 'نوع آخر' : 'Other type'}: ${_otherCtrl.text.trim()}\n${_descCtrl.text.trim()}'
            : _descCtrl.text.trim(),
      };
      if (!_isOther) body['request_type_id'] = _selectedValue;
      if (_isLoan && _amountCtrl.text.trim().isNotEmpty) {
        body['amount'] = _amountCtrl.text.trim();
      }
      if (_requiresDateRange) {
        body['start_date'] = _startDateCtrl.text.trim();
        body['end_date'] = _endDateCtrl.text.trim();
      }
      if (_isPermissionRequest) {
        body['permission_date'] = _permissionDateCtrl.text.trim();
        body['permission_time'] = _permissionTimeCtrl.text.trim();
        body['duration_hours'] = _durationHoursCtrl.text.trim();
      }
      final res = await http.post(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/submit-request/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token'
          },
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? context.l10n.done)));
        if (data['success'] == true) {
          _titleCtrl.clear();
          _descCtrl.clear();
          _otherCtrl.clear();
          _amountCtrl.clear();
          _permissionDateCtrl.clear();
          _permissionTimeCtrl.clear();
          _durationHoursCtrl.clear();
          setState(() => _selectedValue = null);
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${isAr ? 'حدث خطأ' : 'An error occurred'}: $e')));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(
            isAr ? 'تقديم طلب' : 'Submit Request',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
              decoration: InputDecoration(
                  labelText: context.l10n.requestType,
                  border: const OutlineInputBorder()),
              value: _selectedValue,
              items: [
                ..._types.map((t) => DropdownMenuItem<String>(
                    value: t['id'].toString(),
                    child: Text(localizedTypeName((t['name'] ?? '').toString(), isAr)))),
                DropdownMenuItem<String>(
                    value: 'other',
                    child: Text(isAr ? 'أخرى' : 'Other')),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedValue = v;
                  _amountCtrl.clear();
                  _permissionDateCtrl.clear();
                  _permissionTimeCtrl.clear();
                  _durationHoursCtrl.clear();
                });
              }),
          if (_requiresDateRange) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _startDateCtrl,
              readOnly: true,
              onTap: () => _pickDate(_startDateCtrl),
              decoration: InputDecoration(
                labelText: isAr ? 'من تاريخ' : 'From date',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _endDateCtrl,
              readOnly: true,
              onTap: () => _pickDate(_endDateCtrl),
              decoration: InputDecoration(
                labelText: isAr ? 'إلى تاريخ' : 'To date',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
          ],
          if (_isPermissionRequest) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200)),
              child: Text(
                _permissionKind == 'late_arrival'
                    ? (isAr
                        ? 'هذا الطلب سيعامل كإذن تأخير ويخصم من رصيد الأذونات بعد الموافقة والاستخدام.'
                        : 'This request will be treated as a late arrival permission and deducted after approval and use.')
                    : (isAr
                        ? 'هذا الطلب سيعامل كإذن خروج مبكر ويخصم من رصيد الأذونات بعد الموافقة والاستخدام.'
                        : 'This request will be treated as an early leave permission and deducted after approval and use.'),
                style: TextStyle(color: Colors.orange[900]),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
                controller: _permissionDateCtrl,
                readOnly: true,
                onTap: () => _pickDate(_permissionDateCtrl),
                decoration: InputDecoration(
                    labelText: isAr ? 'تاريخ الإذن' : 'Permission date',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today))),
            const SizedBox(height: 16),
            TextField(
                controller: _permissionTimeCtrl,
                readOnly: true,
                onTap: _pickTime,
                decoration: InputDecoration(
                    labelText: _permissionKind == 'late_arrival'
                        ? (isAr
                            ? 'وقت الحضور المتوقع'
                            : 'Expected arrival time')
                        : (isAr
                            ? 'وقت الخروج المطلوب'
                            : 'Requested departure time'),
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.access_time))),
            const SizedBox(height: 16),
            TextField(
                controller: _durationHoursCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: isAr ? 'عدد الساعات' : 'Number of hours',
                    border: const OutlineInputBorder(),
                    suffixText: isAr ? 'ساعة' : 'hr')),
          ],
          if (_isLoan) ...[
            const SizedBox(height: 16),
            TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText:
                        isAr ? 'المبلغ المطلوب' : 'Requested amount',
                    border: const OutlineInputBorder(),
                    suffixText: isAr ? 'جنيه' : 'EGP')),
          ],
          if (_isOther) ...[
            const SizedBox(height: 16),
            TextField(
                controller: _otherCtrl,
                decoration: InputDecoration(
                    labelText:
                        isAr ? 'اذكر نوع الطلب' : 'Specify request type',
                    border: const OutlineInputBorder())),
          ],
          const SizedBox(height: 16),
          TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                  labelText:
                      isAr ? 'عنوان الطلب' : 'Request title',
                  border: const OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(
              controller: _descCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                  labelText: isAr
                      ? 'التفاصيل / السبب'
                      : 'Details / Reason',
                  border: const OutlineInputBorder())),
          const SizedBox(height: 20),
          SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white),
                  child: _submitting
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Text(context.l10n.send,
                          style: const TextStyle(fontSize: 18)))),
        ]));
  }
}

class MyItemsScreen extends StatelessWidget {
  const MyItemsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Column(children: [
          Builder(builder: (context) {
            final isAr =
                Localizations.localeOf(context).languageCode == 'ar';
            return TabBar(
                labelColor: kPrimaryColor,
                indicatorColor: kPrimaryColor,
                tabs: [
                  Tab(text: isAr ? 'طلباتي' : 'My Requests'),
                  Tab(text: isAr ? 'إجازاتي' : 'My Leaves'),
                ]);
          }),
          Expanded(
              child: TabBarView(children: [
            _MyList(endpoint: 'my-requests', keyName: 'requests'),
            _MyList(endpoint: 'my-leaves', keyName: 'leaves'),
          ])),
        ]));
  }
}

class _MyList extends StatefulWidget {
  final String endpoint;
  final String keyName;
  const _MyList({required this.endpoint, required this.keyName});
  @override
  State<_MyList> createState() => _MyListState();
}

class _MyListState extends State<_MyList> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/${widget.endpoint}/'),
          headers: {'Authorization': 'Token $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _items = data[widget.keyName] ?? []);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Color _statusColor(String s) {
    if (s.contains('موافق') || s.toLowerCase().contains('approved'))
      return Colors.green;
    if (s.contains(context.l10n.rejectMission) ||
        s.toLowerCase().contains('reject')) return Colors.red;
    if (s.contains(context.l10n.cancelled) ||
        s.toLowerCase().contains('cancel')) return Colors.grey;
    return Colors.orange;
  }

  bool _canCancel(dynamic item) {
    final status = (item['status'] ?? '').toString();
    return status == 'pending' || status == 'manager_approved';
  }
  String _statusLabel(dynamic item, bool isAr) {
    final statusCode = (item['status'] ?? '').toString().toLowerCase();
    final statusDisplay = (item['status_display'] ?? '').toString();

    switch (statusCode) {
      case 'pending':
        return isAr ? 'قيد الانتظار' : 'Pending';
      case 'manager_approved':
      case 'approved':
        return isAr ? 'موافق عليه' : 'Approved';
      case 'rejected':
      case 'manager_rejected':
        return isAr ? 'مرفوض' : 'Rejected';
      case 'cancelled':
        return isAr ? 'ملغي' : 'Cancelled';
      case 'completed':
        return isAr ? 'مكتمل' : 'Completed';
      default:
        if (isAr) {
          return statusDisplay.isNotEmpty ? statusDisplay : statusCode;
        }

        if (statusDisplay.contains('قيد') || statusDisplay.contains('انتظار')) {
          return 'Pending';
        }
        if (statusDisplay.contains('موافق')) {
          return 'Approved';
        }
        if (statusDisplay.contains('مرفوض') || statusDisplay.contains('رفض')) {
          return 'Rejected';
        }
        if (statusDisplay.contains('ملغ')) {
          return 'Cancelled';
        }
        if (statusDisplay.contains('مكتمل')) {
          return 'Completed';
        }

        return statusDisplay.isNotEmpty ? statusDisplay : statusCode;
    }
  }

  Future<void> _cancelItem(dynamic item) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'إلغاء الطلب' : 'Cancel Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isAr
                  ? 'هل أنت متأكد من إلغاء هذا الطلب؟'
                  : 'Are you sure you want to cancel this request?'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText:
                      isAr ? 'سبب الإلغاء' : 'Cancellation reason',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'تراجع' : 'Back'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              child: Text(
                isAr ? 'إلغاء الطلب' : 'Cancel Request',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final id = item['id'];
    final isLeave = widget.keyName == 'leaves';
    final url = isLeave
        ? '$kBaseUrl/attendance/api/mobile/my-leaves/$id/cancel/'
        : '$kBaseUrl/attendance/api/mobile/my-requests/$id/cancel/';
    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token'
        },
        body: jsonEncode({'reason': reasonCtrl.text.trim()}),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ??
              (data['success'] == true
                  ? (isAr ? 'تم الإلغاء' : 'Cancelled successfully')
                  : (isAr ? 'حدث خطأ' : 'An error occurred'))),
          backgroundColor:
              data['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (data['success'] == true) _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${isAr ? 'خطأ' : 'Error'}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty)
      return Center(child: Text(context.l10n.noRequests));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          final rawStatus =
              (item['status'] ?? item['status_display'] ?? '').toString();
          final status = _statusLabel(item, isAr);
          final isLeaveTab = widget.keyName == 'leaves';
          final canCancel = _canCancel(item);
          return Card(
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemDetailScreen(
                        item: Map<String, dynamic>.from(item),
                        itemType:
                            isLeaveTab ? 'leave_request' : 'request',
                      ),
                    ));
                _load();
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] ??
                                item['leave_type'] ??
                                item['type'] ??
                                '-',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                _statusColor(rawStatus).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(status,
                              style: TextStyle(
                                  color: _statusColor(rawStatus),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        ),
                      ],
                    ),
                    if ((item['date'] ?? item['created_at'] ?? '')
                        .toString()
                        .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                            item['date'] ?? item['created_at'] ?? '',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ),
                    if (canCancel) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _cancelItem(item),
                            icon: const Icon(Icons.cancel_outlined,
                                size: 16, color: Colors.red),
                            label: Text(
                              isAr
                                  ? 'إلغاء الطلب'
                                  : 'Cancel Request',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/notifications/'),
          headers: {'Authorization': 'Token $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _notifications = data['notifications'] ?? [];
          _unreadCount = data['unread_count'] ?? 0;
        });
        unreadNotificationsCount.value = _unreadCount;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      await http.post(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/notifications/mark-read/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token'
          });
      _load();
    } catch (_) {}
  }

  Future<void> _markOneRead(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      await http.post(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/notifications/mark-read/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token'
          },
          body: jsonEncode({'id': id}));
      _load();
    } catch (_) {}
  }

  Future<void> _openNotification(dynamic raw) async {
    final n = Map<String, dynamic>.from(raw as Map);
    if (n['id'] != null && n['is_read'] != true)
      await _markOneRead(n['id']);
    final type = (n['notification_type'] ?? '').toString();
    final prefs = await SharedPreferences.getInstance();
    final appMode = prefs.getString('app_mode') ?? 'employee';
    Widget page;
    switch (type) {
      case 'new_request':
      case 'new_leave':
      case 'new_permission':
        page = const ManagerShell(initialIndex: 1);
        break;
      case 'attendance':
      case 'check_in':
      case 'check_out':
      case 'partial_checkout':
      case 'resume_checkin':
      case 'manager_attendance':
        page = const ManagerShell(initialIndex: 2);
        break;
      case 'request_approved':
      case 'request_rejected':
      case 'leave_approved':
      case 'leave_rejected':
        page = appMode == 'manager'
            ? const ManagerShell(initialIndex: 1)
            : const EmployeeShell(initialIndex: 3);
        break;
      case 'charter_acceptance':
        page = const ManagerCharterScreen();
        break;
      default:
        page = appMode == 'manager'
            ? const ManagerShell(initialIndex: 0)
            : const EmployeeShell(initialIndex: 0);
    }
    if (!mounted) return;
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'new_request':
        return Icons.assignment;
      case 'new_leave':
        return Icons.beach_access;
      case 'request_approved':
      case 'leave_approved':
        return Icons.check_circle;
      case 'request_rejected':
      case 'leave_rejected':
        return Icons.cancel;
      case 'geofence_violation':
        return Icons.warning;
      case 'attendance':
      case 'manager_attendance':
        return Icons.access_time;
      case 'charter_acceptance':
        return Icons.description;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    if (type.contains('approved')) return Colors.green;
    if (type.contains('rejected')) return Colors.red;
    if (type.contains('geofence')) return Colors.orange;
    if (type.contains('new_')) return Colors.blue;
    if (type.contains('attendance')) return Colors.teal;
    if (type.contains('charter')) return kManagerColor;
    return Colors.grey;
  }

  String _formatTime(String iso, bool isAr) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return isAr ? 'الآن' : 'Just now';
      if (diff.inMinutes < 60)
        return isAr
            ? 'منذ ${diff.inMinutes} دقيقة'
            : '${diff.inMinutes} min ago';
      if (diff.inHours < 24)
        return isAr
            ? 'منذ ${diff.inHours} ساعة'
            : '${diff.inHours} hr ago';
      if (diff.inDays < 7)
        return isAr
            ? 'منذ ${diff.inDays} يوم'
            : '${diff.inDays} day(s) ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              isAr
                  ? 'الإشعارات${_unreadCount > 0 ? " ($_unreadCount)" : ""}'
                  : 'Notifications${_unreadCount > 0 ? " ($_unreadCount)" : ""}',
            ),
            backgroundColor: kPrimaryColor,
            foregroundColor: Colors.white,
            actions: [
              if (_unreadCount > 0)
                IconButton(
                  icon: const Icon(Icons.done_all),
                  tooltip: isAr
                      ? 'تعليم الكل كمقروءة'
                      : 'Mark all as read',
                  onPressed: _markAllRead,
                )
            ],
          ),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                          Icon(Icons.notifications_off,
                              size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            isAr
                                ? 'لا توجد إشعارات'
                                : 'No notifications',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey),
                          ),
                        ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (_, i) {
                            final n = _notifications[i];
                            final isRead = n['is_read'] == true;
                            final type =
                                n['notification_type'] ?? 'general';
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              color: isRead
                                  ? Colors.white
                                  : Colors.blue[50],
                              elevation: isRead ? 1 : 3,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _typeColor(type)
                                      .withOpacity(0.15),
                                  child: Icon(_typeIcon(type),
                                      color: _typeColor(type)),
                                ),
                                title: Text(n['title'] ?? '',
                                    style: TextStyle(
                                        fontWeight: isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold)),
                                subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(n['body'] ?? ''),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(
                                            n['created_at'] ?? '',
                                            isAr),
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500]),
                                      ),
                                    ]),
                                isThreeLine: true,
                                onTap: () => _openNotification(n),
                              ),
                            );
                          })),
        ));
  }
}

class CharterScreen extends StatefulWidget {
  final String appMode;
  const CharterScreen({super.key, required this.appMode});
  @override
  State<CharterScreen> createState() => _CharterScreenState();
}

class _CharterScreenState extends State<CharterScreen> {
  Map<String, dynamic>? _charter;
  bool _loading = true;
  bool _submitting = false;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
          Uri.parse('$kBaseUrl/attendance/api/mobile/charter/'),
          headers: {'Authorization': 'Token $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['has_charter'] == true)
          setState(() => _charter = data['charter']);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _openAttachment() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final url = _charter?['attachment_url'] ?? '';
    if (url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri))
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                isAr ? 'تعذر فتح الملف' : 'Could not open file')));
    }
  }

  Future<void> _accept() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'يرجى الموافقة على اللائحة أولاً'
              : 'Please agree to the charter first'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await http.post(
          Uri.parse('$kBaseUrl/attendance/api/mobile/charter/accept/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token'
          });
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr
                ? 'تم تسجيل موافقتك بنجاح ✅'
                : 'Your agreement has been recorded ✅'),
            backgroundColor: Colors.green));
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => widget.appMode == 'manager'
                    ? const ManagerShell()
                    : const EmployeeShell()));
      } else {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(data['message'] ??
                  data['error'] ??
                  (isAr ? 'حدث خطأ' : 'An error occurred'))));
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                isAr ? 'خطأ في الاتصال' : 'Connection error')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final attachmentUrl = _charter?['attachment_url'] ?? '';
    final attachmentName =
        _charter?['attachment_name'] ?? (isAr ? 'الملف المرفق' : 'Attached file');
    return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
              title: Text(isAr ? 'لائحة الشركة' : 'Company Charter'),
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _charter == null
                  ? Center(
                      child: Text(isAr
                          ? 'لا توجد لائحة حالياً'
                          : 'No charter available'))
                  : Column(children: [
                      Expanded(
                          child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        width: double.infinity,
                                        padding:
                                            const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                            gradient:
                                                const LinearGradient(
                                                    colors: [
                                                  kPrimaryDark,
                                                  kPrimaryColor
                                                ]),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    12)),
                                        child: Column(children: [
                                          const Icon(Icons.description,
                                              color: Colors.white,
                                              size: 48),
                                          const SizedBox(height: 8),
                                          Text(
                                            _charter!['title'] ??
                                                (isAr
                                                    ? 'لائحة الشركة'
                                                    : 'Company Charter'),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight:
                                                    FontWeight.bold),
                                          ),
                                          Text(
                                            '${isAr ? 'الإصدار' : 'Version'} ${_charter!['version'] ?? 1}',
                                            style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13),
                                          ),
                                        ])),
                                    const SizedBox(height: 16),
                                    if (attachmentUrl.isNotEmpty) ...[
                                      InkWell(
                                          onTap: _openAttachment,
                                          child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.all(
                                                      14),
                                              decoration: BoxDecoration(
                                                  color: Colors
                                                      .purple[50],
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(10),
                                                  border: Border.all(
                                                      color: Colors
                                                          .purple[200]!)),
                                              child: Row(children: [
                                                Icon(Icons.attach_file,
                                                    color: Colors
                                                        .purple[700]),
                                                const SizedBox(
                                                    width: 10),
                                                Expanded(
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                      Text(
                                                        isAr
                                                            ? 'الملف المرفق'
                                                            : 'Attached File',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .purple[
                                                                    700],
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      Text(
                                                          attachmentName,
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .purple[
                                                                      500],
                                                              fontSize:
                                                                  12),
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis),
                                                    ])),
                                                Icon(Icons.open_in_new,
                                                    color: Colors
                                                        .purple[700],
                                                    size: 20),
                                              ]))),
                                      const SizedBox(height: 16),
                                    ],
                                    if ((_charter!['introduction'] ??
                                            '')
                                        .toString()
                                        .isNotEmpty) ...[
                                      Container(
                                          width: double.infinity,
                                          padding:
                                              const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                              border: Border.all(
                                                  color:
                                                      Colors.blue[200]!)),
                                          child: Text(
                                              _charter!['introduction'],
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  height: 1.6))),
                                      const SizedBox(height: 16),
                                    ],
                                    Container(
                                        width: double.infinity,
                                        padding:
                                            const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10),
                                            border: Border.all(
                                                color:
                                                    Colors.grey[300]!),
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 8)
                                            ]),
                                        child: Text(
                                            _charter!['content'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                height: 1.8))),
                                    const SizedBox(height: 20),
                                  ]))),
                      Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, -4))
                              ]),
                          child: Column(children: [
                            CheckboxListTile(
                                value: _agreed,
                                onChanged: (v) =>
                                    setState(() => _agreed = v ?? false),
                                title: Text(
                                  isAr
                                      ? 'أقر بأنني قرأت واطلعت على لائحة الشركة وأوافق على جميع بنودها'
                                      : 'I acknowledge that I have read the company charter and agree to all its terms',
                                  style:
                                      const TextStyle(fontSize: 14),
                                ),
                                activeColor: kPrimaryColor,
                                controlAffinity:
                                    ListTileControlAffinity.leading),
                            const SizedBox(height: 8),
                            SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                    onPressed: (_submitting || !_agreed)
                                        ? null
                                        : _accept,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimaryColor,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    12))),
                                    child: _submitting
                                        ? const CircularProgressIndicator(
                                            color: Colors.white)
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                  Icons.check_circle),
                                              const SizedBox(width: 8),
                                              Text(
                                                isAr
                                                    ? 'أوافق على اللائحة'
                                                    : 'I Agree to the Charter',
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ])))
                          ])),
                    ]),
        ));
  }
}

class ManagerCharterScreen extends StatefulWidget {
  const ManagerCharterScreen({super.key});

  @override
  State<ManagerCharterScreen> createState() =>
      _ManagerCharterScreenState();
}

class _ManagerCharterScreenState extends State<ManagerCharterScreen> {
  Map<String, dynamic>? _charter;
  List<dynamic> _accepted = [];
  List<dynamic> _pending = [];
  bool _loading = true;
  bool _saving = false;
  bool _showEdit = false;

  String _attachmentUrl = '';
  String _attachmentName = '';
  PlatformFile? _pickedAttachment;
  bool _removeCurrentAttachment = false;

  final _titleCtrl = TextEditingController();
  final _introCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _introCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final r1 = await http.get(
        Uri.parse('$kBaseUrl/attendance/api/mobile/charter/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (r1.statusCode == 200) {
        final data = jsonDecode(r1.body);
        if (data['has_charter'] == true) {
          _charter = data['charter'];
          _titleCtrl.text = _charter!['title'] ?? '';
          _introCtrl.text = _charter!['introduction'] ?? '';
          _contentCtrl.text = _charter!['content'] ?? '';
          _attachmentUrl = _charter!['attachment_url'] ?? '';
          _attachmentName = _charter!['attachment_name'] ?? '';
        }
      }

      final r2 = await http.get(
        Uri.parse(
            '$kBaseUrl/attendance/api/mobile/manager/charter/acceptances/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (r2.statusCode == 200) {
        final data = jsonDecode(r2.body);
        _accepted = data['accepted']?['employees'] ?? [];
        _pending = data['pending']?['employees'] ?? [];
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _pickedAttachment = null;
        _removeCurrentAttachment = false;
        _loading = false;
      });
    }
  }

  Future<void> _pickAttachment() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.path == null || file.path!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isAr
                    ? 'تعذر قراءة الملف المختار'
                    : 'Could not read the selected file')),
          );
        }
        return;
      }

      setState(() {
        _pickedAttachment = file;
        _removeCurrentAttachment = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isAr
                  ? 'خطأ في اختيار الملف: $e'
                  : 'Error selecting file: $e')),
        );
      }
    }
  }

  Future<void> _openAttachment() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_attachmentUrl.isEmpty) return;
    try {
      final uri = Uri.parse(_attachmentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  isAr ? 'تعذر فتح الملف' : 'Could not open file')),
        );
      }
    }
  }

  Future<void> _save() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_titleCtrl.text.trim().isEmpty ||
        _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr
              ? 'العنوان والمحتوى مطلوبان'
              : 'Title and content are required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            '$kBaseUrl/attendance/api/mobile/manager/charter/update/'),
      );

      request.headers['Authorization'] = 'Token $token';
      request.fields['title'] = _titleCtrl.text.trim();
      request.fields['introduction'] = _introCtrl.text.trim();
      request.fields['content'] = _contentCtrl.text.trim();

      if (_removeCurrentAttachment) {
        request.fields['remove_attachment'] = 'true';
      }

      if (_pickedAttachment != null &&
          _pickedAttachment!.path != null &&
          _pickedAttachment!.path!.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'attachment',
            _pickedAttachment!.path!,
            filename: _pickedAttachment!.name,
          ),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  data['error'] ??
                  (isAr ? 'تمت العملية' : 'Operation completed'),
            ),
            backgroundColor:
                data['success'] == true ? Colors.green : Colors.red,
          ),
        );
      }

      if (data['success'] == true) {
        setState(() {
          _showEdit = false;
          _pickedAttachment = null;
          _removeCurrentAttachment = false;
        });
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr
                ? 'خطأ في الاتصال: $e'
                : 'Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showReport() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CharterReportScreen(
          accepted: _accepted,
          pending: _pending,
          charterTitle: _charter?['title'] ??
              (isAr ? 'لائحة الشركة' : 'Company Charter'),
          charterVersion: _charter?['version'] ?? 1,
        ),
      ),
    );
  }

  Widget _statCard(
      String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label,
              style: TextStyle(color: color, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  Widget _buildInfoView() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_charter != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [kPrimaryDark, kManagerColor],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(Icons.description,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    _charter!['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${isAr ? 'الإصدار' : 'Version'} ${_charter!['version'] ?? 1}',
                    style:
                        const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_attachmentUrl.isNotEmpty) ...[
              InkWell(
                onTap: _openAttachment,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: Colors.purple[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file,
                          color: Colors.purple[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _attachmentName.isNotEmpty
                              ? _attachmentName
                              : (isAr
                                  ? 'الملف المرفق'
                                  : 'Attached file'),
                          style: TextStyle(
                              color: Colors.purple[700]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.open_in_new,
                          color: Colors.purple[700], size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _showEdit = true),
                    icon: const Icon(Icons.edit),
                    label: Text(isAr
                        ? 'تعديل اللائحة'
                        : 'Edit Charter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kManagerColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showReport,
                    icon: const Icon(Icons.print),
                    label: Text(isAr
                        ? 'تقرير الموافقات'
                        : 'Approvals Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning,
                      color: Colors.orange, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    isAr ? 'لا توجد لائحة بعد' : 'No charter yet',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAr
                        ? 'اضغط تعديل لإنشاء لائحة جديدة'
                        : 'Press edit to create a new charter',
                    style:
                        const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showEdit = true),
              icon: const Icon(Icons.add),
              label: Text(isAr
                  ? 'إنشاء لائحة جديدة'
                  : 'Create New Charter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kManagerColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  isAr ? 'وافقوا' : 'Agreed',
                  _accepted.length,
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard(
                  isAr ? 'لم يوافقوا' : 'Not Agreed',
                  _pending.length,
                  Colors.orange,
                  Icons.pending,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_accepted.isNotEmpty) ...[
            Text(
              isAr ? '✅ وافقوا على اللائحة' : '✅ Agreed to Charter',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ..._accepted.map(
              (emp) => Card(
                color: Colors.green[50],
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check,
                        color: Colors.white, size: 18),
                  ),
                  title: Text(emp['name'] ?? emp['username'] ?? ''),
                  subtitle: Text(
                    _formatDate(emp['accepted_at'] ?? ''),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_pending.isNotEmpty) ...[
            Text(
              isAr ? '⏳ لم يوافقوا بعد' : '⏳ Not Agreed Yet',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            ..._pending.map(
              (emp) => Card(
                color: Colors.orange[50],
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.schedule,
                        color: Colors.white, size: 18),
                  ),
                  title: Text(emp['name'] ?? emp['username'] ?? ''),
                  subtitle: Text(
                    isAr
                        ? 'في انتظار الموافقة'
                        : 'Waiting for approval',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
          if (_accepted.isEmpty && _pending.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  isAr ? 'لا يوجد موظفين بعد' : 'No employees yet',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentAttachmentCard() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_attachmentUrl.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(isAr
            ? 'لا يوجد ملف مرفق حاليًا'
            : 'No attachment currently'),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _removeCurrentAttachment
            ? Colors.red[50]
            : Colors.purple[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _removeCurrentAttachment
              ? Colors.red[200]!
              : Colors.purple[200]!,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.attach_file,
                color: _removeCurrentAttachment
                    ? Colors.red
                    : Colors.purple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _attachmentName.isNotEmpty
                      ? _attachmentName
                      : (isAr ? 'الملف الحالي' : 'Current file'),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _removeCurrentAttachment
                        ? Colors.red
                        : Colors.purple[700],
                    decoration: _removeCurrentAttachment
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openAttachment,
                icon: const Icon(Icons.open_in_new),
                tooltip: isAr ? 'فتح الملف' : 'Open file',
              ),
            ],
          ),
          CheckboxListTile(
            value: _removeCurrentAttachment,
            onChanged: (v) {
              setState(() {
                _removeCurrentAttachment = v ?? false;
              });
            },
            title: Text(isAr
                ? 'حذف الملف الحالي عند الحفظ'
                : 'Delete current file on save'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPickedAttachmentCard() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_pickedAttachment == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Text(
          isAr
              ? 'لم يتم اختيار ملف جديد بعد\nالمسموح: PDF / Word / PNG / JPG — الحد الأقصى 10 MB'
              : 'No new file selected yet\nAllowed: PDF / Word / PNG / JPG — Max 10 MB',
          style: const TextStyle(height: 1.5),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _pickedAttachment!.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            onPressed: () =>
                setState(() => _pickedAttachment = null),
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip:
                isAr ? 'إلغاء الملف المختار' : 'Cancel selected file',
          ),
        ],
      ),
    );
  }

  Widget _buildEditView() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr
                        ? 'أي تعديل في المحتوى أو الملف المرفق سيطلب من الموظفين الموافقة مجددًا'
                        : 'Any change in content or attachment will require employees to agree again',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText:
                  isAr ? 'عنوان اللائحة *' : 'Charter title *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _introCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: isAr
                  ? 'المقدمة (اختياري)'
                  : 'Introduction (optional)',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.short_text),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentCtrl,
            maxLines: 12,
            decoration: InputDecoration(
              labelText:
                  isAr ? 'محتوى اللائحة *' : 'Charter content *',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.article),
              hintText: isAr
                  ? '1- البند الأول\n2- البند الثاني\n3- البند الثالث'
                  : '1- First clause\n2- Second clause\n3- Third clause',
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment:
                isAr ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              isAr ? 'الملف الحالي' : 'Current File',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildCurrentAttachmentCard(),
          const SizedBox(height: 16),
          Align(
            alignment:
                isAr ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              isAr ? 'ملف جديد' : 'New File',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPickedAttachmentCard(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickAttachment,
              icon: const Icon(Icons.upload_file),
              label: Text(
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'اختيار ملف PDF / Word / صورة'
                    : 'Choose PDF / Word / Image file',
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showEdit = false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                  ),
                  child: Text(context.l10n.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kManagerColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white)
                      : Text(
                          Localizations.localeOf(context)
                                      .languageCode ==
                                  'ar'
                              ? 'حفظ اللائحة'
                              : 'Save Charter',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr
              ? 'إدارة لائحة الشركة'
              : 'Company Charter Management'),
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: Icon(_showEdit ? Icons.visibility : Icons.edit),
              tooltip: _showEdit
                  ? (isAr ? 'عرض' : 'View')
                  : context.l10n.edit,
              onPressed: () =>
                  setState(() => _showEdit = !_showEdit),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _showEdit
                ? _buildEditView()
                : _buildInfoView(),
      ),
    );
  }
}

class CharterReportScreen extends StatelessWidget {
  final List<dynamic> accepted;
  final List<dynamic> pending;
  final String charterTitle;
  final int charterVersion;
  const CharterReportScreen({
    super.key,
    required this.accepted,
    required this.pending,
    required this.charterTitle,
    required this.charterVersion,
  });

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  String _formatNow() {
    final dt = DateTime.now();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
              title: Text(
                  isAr ? 'تقرير الموافقات' : 'Approvals Report'),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Colors.teal, kPrimaryColor]),
                  borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                const Icon(Icons.description,
                    color: Colors.white, size: 40),
                const SizedBox(height: 8),
                Text(charterTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                Text(
                  '${isAr ? 'الإصدار' : 'Version'} $charterVersion',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isAr ? 'تاريخ التقرير' : 'Report date'}: ${_formatNow()}',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 12),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.green[200]!)),
                      child: Column(children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 32),
                        const SizedBox(height: 8),
                        Text('${accepted.length}',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                        Text(
                          isAr ? 'وافقوا' : 'Agreed',
                          style:
                              const TextStyle(color: Colors.green),
                        ),
                      ]))),
              const SizedBox(width: 12),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.orange[200]!)),
                      child: Column(children: [
                        const Icon(Icons.pending,
                            color: Colors.orange, size: 32),
                        const SizedBox(height: 8),
                        Text('${pending.length}',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange)),
                        Text(
                          isAr ? 'لم يوافقوا' : 'Not Agreed',
                          style: const TextStyle(
                              color: Colors.orange),
                        ),
                      ]))),
            ]),
            const SizedBox(height: 20),
            if (accepted.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10))),
                child: Row(children: [
                  const Icon(Icons.check_circle,
                      color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${isAr ? 'وافقوا على اللائحة' : 'Agreed to Charter'} (${accepted.length})',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ]),
              ),
              Container(
                decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.green[200]!),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10))),
                child: Column(
                    children: accepted.asMap().entries.map((entry) {
                  final i = entry.key;
                  final emp = entry.value;
                  return Container(
                    decoration: BoxDecoration(
                        color: i.isEven
                            ? Colors.green[50]
                            : Colors.white,
                        border: i < accepted.length - 1
                            ? Border(
                                bottom: BorderSide(
                                    color: Colors.green[100]!))
                            : null),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.green[100],
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                Text(
                                    emp['name'] ??
                                        emp['username'] ??
                                        '',
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.bold)),
                                if ((emp['accepted_at'] ?? '')
                                    .isNotEmpty)
                                  Text(
                                    '${isAr ? 'وافق في' : 'Agreed on'}: ${_formatDate(emp['accepted_at'])}',
                                    style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12),
                                  ),
                                if ((emp['ip_address'] ?? '')
                                    .isNotEmpty)
                                  Text('IP: ${emp['ip_address']}',
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11)),
                              ])),
                          const Icon(Icons.verified,
                              color: Colors.green, size: 20),
                        ])),
                  );
                }).toList()),
              ),
              const SizedBox(height: 20),
            ],
            if (pending.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10))),
                child: Row(children: [
                  const Icon(Icons.pending, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    '${isAr ? 'لم يوافقوا بعد' : 'Not Agreed Yet'} (${pending.length})',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ]),
              ),
              Container(
                decoration: BoxDecoration(
                    border:
                        Border.all(color: Colors.orange[200]!),
                    borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10))),
                child: Column(
                    children: pending.asMap().entries.map((entry) {
                  final i = entry.key;
                  final emp = entry.value;
                  return Container(
                    decoration: BoxDecoration(
                        color: i.isEven
                            ? Colors.orange[50]
                            : Colors.white,
                        border: i < pending.length - 1
                            ? Border(
                                bottom: BorderSide(
                                    color: Colors.orange[100]!))
                            : null),
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.orange[100],
                              child: Text('${i + 1}',
                                  style: TextStyle(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  emp['name'] ??
                                      emp['username'] ??
                                      '',
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.bold))),
                          const Icon(Icons.schedule,
                              color: Colors.orange, size: 20),
                        ])),
                  );
                }).toList()),
              ),
            ],
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!)),
              child: Text(
                isAr
                    ? 'تم إنشاء هذا التقرير بواسطة نظام MotionHR\nتاريخ الطباعة: ${_formatNow()}'
                    : 'This report was generated by MotionHR System\nPrint date: ${_formatNow()}',
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ));
  }
}

class ManagerGeofenceScreen extends StatefulWidget {
  const ManagerGeofenceScreen({super.key});
  @override
  State<ManagerGeofenceScreen> createState() =>
      _ManagerGeofenceScreenState();
}

class _ManagerGeofenceScreenState
    extends State<ManagerGeofenceScreen> {
  Map<String, dynamic>? _geofence;
  bool _loading = true;
  bool _saving = false;
  double? _currentLat;
  double? _currentLng;
  final _radiusCtrl = TextEditingController(text: '100');
  bool _enabled = true;
  String? _locationName;


  @override
  void initState() {
    super.initState();
    _loadGeofence();
  }
Future<void> _loadGeofence() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  try {
    final res = await http.get(
      Uri.parse('$kBaseUrl/attendance/api/mobile/geofence/'),
      headers: {'Authorization': 'Token $token'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      if (data['success'] == true && data['geofence'] != null) {
        final geofence = data['geofence'];
        final lat = (geofence['latitude'] as num?)?.toDouble();
        final lng = (geofence['longitude'] as num?)?.toDouble();
        String? locationName = geofence['location_name']?.toString();

        if ((locationName == null || locationName.isEmpty) &&
            lat != null &&
            lng != null) {
          try {
            final placemarks = await placemarkFromCoordinates(lat, lng);
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              final parts = <String>[
                if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
                if ((p.subLocality ?? '').trim().isNotEmpty)
                  p.subLocality!.trim(),
                if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
              ];
              locationName = parts.join(', ');
            }
          } catch (_) {}
        }

        if (!mounted) return;
        setState(() {
          _geofence = geofence;
          _currentLat = lat;
          _currentLng = lng;
          _radiusCtrl.text = (geofence['radius'] ?? 100).toString();
          _enabled = geofence['enabled'] ?? false;
          _locationName = locationName;
        });
      }
    }
  } catch (_) {}

  if (mounted) {
    setState(() => _loading = false);
  }
}Future<void> _getCurrentLocation() async {
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  setState(() => _saving = true);

  try {
    await requestLocationPermissionsForTracking();

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String? locationName;
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
          if ((p.subLocality ?? '').trim().isNotEmpty)
            p.subLocality!.trim(),
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
        ];
        locationName = parts.join(', ');
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _currentLat = position.latitude;
      _currentLng = position.longitude;
      _locationName = locationName;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr ? 'تم تحديد موقعك الحالي 🕐' : 'Current location set 🕐',
        ),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${isAr ? 'خطأ' : 'Error'}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}
  Future<void> _saveGeofence() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_currentLat == null || _currentLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'يرجى تحديد الموقع أولاً'
              : 'Please set location first'),
          backgroundColor: Colors.orange));
      return;
    }
    final radius = int.tryParse(_radiusCtrl.text) ?? 100;
    if (radius < 10 || radius > 5000) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'النطاق يجب أن يكون بين 10 و 5000 متر'
              : 'Radius must be between 10 and 5000 meters'),
          backgroundColor: Colors.orange));
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final res = await http.post(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/geofence/set/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token'
          },
          body: jsonEncode({
            'latitude': _currentLat,
            'longitude': _currentLng,
            'radius': radius,
            'enabled': _enabled,
          }));
      final data = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? context.l10n.done),
            backgroundColor: data['success'] == true
                ? Colors.green
                : Colors.red));
        if (data['success'] == true) _loadGeofence();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('${isAr ? 'خطأ' : 'Error'}: $e'),
            backgroundColor: Colors.red));
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_loading)
      return const Center(child: CircularProgressIndicator());
    return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
              title: Text(isAr
                  ? 'نطاق موقع الشركة'
                  : 'Company Geofence'),
              backgroundColor: kManagerColor,
              foregroundColor: Colors.white),
          body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.blue[200]!)),
                        child: Row(children: [
                          const Icon(Icons.info_outline,
                              color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(
                            isAr
                                ? 'حدد موقع الشركة عشان الموظفين ما يقدروش يسجلوا حضور من برة النطاق ده. الموظف الميداني مستثنى.'
                                : 'Set the company location so employees cannot check in from outside this area. Field workers are excluded.',
                            style: const TextStyle(fontSize: 13),
                          )),
                        ])),
                    const SizedBox(height: 20),
                    Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.location_on,
                                        color: kManagerColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAr
                                          ? 'موقع الشركة'
                                          : 'Company Location',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.bold),
                                    ),
                                  ]),
                                  const SizedBox(height: 12),
                                  if (_currentLat != null &&
                                      _currentLng != null)
                                    Container(
                                        padding:
                                            const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius:
                                                BorderRadius.circular(
                                                    8)),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Row(children: [
                                                const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 20),
                                                const SizedBox(
                                                    width: 6),
                                                Text(
                                                  isAr
                                                      ? 'محدد'
                                                      : 'Set',
                                                  style: TextStyle(
                                                      color: Colors
                                                          .green[700],
                                                      fontWeight:
                                                          FontWeight
                                                              .bold),
                                                ),
                                              ]),
                                              const SizedBox(height: 6),
                                              Text(
  _locationName != null && _locationName!.isNotEmpty
      ? _locationName!
      : '${isAr ? 'خط العرض' : 'Lat'}: ${_currentLat!.toStringAsFixed(4)}, ${isAr ? 'خط الطول' : 'Lng'}: ${_currentLng!.toStringAsFixed(4)}',
  style: const TextStyle(fontSize: 13),
),
                                            ]))
                                  else
                                    Container(
                                        padding:
                                            const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: Colors.orange[50],
                                            borderRadius:
                                                BorderRadius.circular(
                                                    8)),
                                        child: Row(children: [
                                          const Icon(Icons.warning,
                                              color: Colors.orange,
                                              size: 20),
                                          const SizedBox(width: 6),
                                          Text(
                                            isAr
                                                ? 'لم يحدد موقع بعد'
                                                : 'Location not set yet',
                                            style: const TextStyle(
                                                color: Colors.orange),
                                          ),
                                        ])),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                      height: 50,
                                      child: ElevatedButton.icon(
                                          onPressed: _saving
                                              ? null
                                              : _getCurrentLocation,
                                          icon: const Icon(
                                              Icons.my_location),
                                          label: Text(
                                            isAr
                                                ? 'استخدم موقعي الحالي'
                                                : 'Use my current location',
                                            style: const TextStyle(
                                                fontSize: 16),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  kManagerColor,
                                              foregroundColor:
                                                  Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(
                                                              12))))),
                                  const SizedBox(height: 8),
                                  Text(
                                    isAr
                                        ? '💡 قف في مكان الشركة واضغط الزر ده'
                                        : '💡 Stand at the company location and press the button',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                ]))),
                    const SizedBox(height: 16),
                    Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(
                                        Icons.radio_button_checked,
                                        color: kManagerColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAr
                                          ? 'نصف قطر النطاق'
                                          : 'Geofence Radius',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                              FontWeight.bold),
                                    ),
                                  ]),
                                  const SizedBox(height: 12),
                                  TextField(
                                      controller: _radiusCtrl,
                                      keyboardType:
                                          TextInputType.number,
                                      decoration: InputDecoration(
                                          labelText: isAr
                                              ? 'المسافة بالمتر'
                                              : 'Distance in meters',
                                          border:
                                              const OutlineInputBorder(),
                                          suffixText:
                                              isAr ? 'متر' : 'm',
                                          hintText: '100')),
                                  const SizedBox(height: 8),
                                  Text(
                                    isAr
                                        ? '💡 مثال: 100 متر = الموظف لازم يكون قريب من الشركة في نطاق 100 متر'
                                        : '💡 Example: 100m = employee must be within 100 meters of the company',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey),
                                  ),
                                ]))),
                    const SizedBox(height: 16),
                    Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: SwitchListTile(
                            title: Text(
                              isAr
                                  ? 'تفعيل النطاق الجغرافي'
                                  : 'Enable Geofence',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(_enabled
                                ? (isAr
                                    ? 'مفعل - سيتم رفض الحضور من خارج النطاق'
                                    : 'Enabled - attendance outside area will be rejected')
                                : (isAr
                                    ? 'معطل - سيتم قبول الحضور من أي مكان'
                                    : 'Disabled - attendance accepted from anywhere')),
                            value: _enabled,
                            activeColor: kManagerColor,
                            onChanged: (v) =>
                                setState(() => _enabled = v))),
                    const SizedBox(height: 20),
                    SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                            onPressed: _saving ? null : _saveGeofence,
                            icon: _saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : const Icon(Icons.save),
                            label: Text(
                              isAr
                                  ? 'حفظ الإعدادات'
                                  : 'Save Settings',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12))))),
                  ])),
        ));
  }
}

class ManagerShell extends StatefulWidget {
  final int initialIndex;
  const ManagerShell({super.key, this.initialIndex = 0});
  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    fetchUnreadCount();
  }

  List<Widget> get _pages => [
        const ManagerDashboard(),
        const ManagerPendingScreen(),
        const ManagerAttendanceScreen(),
        const ManagerLiveLocationsScreen(),
      ];

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await AuthStorageService.clearAll();
    unreadNotificationsCount.value = 0;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(
              title: Text(isAr
                  ? 'MotionHR - المدير'
                  : 'MotionHR - Manager'),
              backgroundColor: kManagerColor,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.description),
                  tooltip:
                      isAr ? 'لائحة الشركة' : 'Company Charter',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const ManagerCharterScreen())),
                ),
                const NotificationBellButton(),
                IconButton(
                    icon: const Icon(Icons.settings),
                    tooltip: context.l10n.settings,
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()))),
                IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _logout),
              ]),
          body: _pages[_index],
          bottomNavigationBar: BottomNavigationBar(
              currentIndex: _index,
              onTap: (i) => setState(() => _index = i),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: kManagerColor,
              items: [
                BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard),
                    label: context.l10n.home),
                BottomNavigationBarItem(
                    icon: const Icon(Icons.pending_actions),
                    label: context.l10n.requests),
                BottomNavigationBarItem(
                    icon: const Icon(Icons.people),
                    label: isAr ? 'الحضور' : 'Attendance'),
                BottomNavigationBarItem(
                    icon: const Icon(Icons.location_on),
                    label: isAr ? 'المواقع' : 'Locations'),
              ]),
        ));
  }
}

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});
  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _pending = 0, _present = 0, _fieldWorkers = 0;
  bool _loading = true;
  String _firstName = '';
  String _companyName = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _load();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _firstName = prefs.getString('first_name') ??
          prefs.getString('full_name') ??
          '';
      _companyName = prefs.getString('company_name') ?? '';
    });
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final r1 = await http.get(
        Uri.parse(
            '$kBaseUrl/attendance/api/mobile/manager/pending/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (r1.statusCode == 200) {
        final d = jsonDecode(r1.body);
        final pr =
            ((d['pending_requests'] as List?) ?? []).length;
        final pl =
            ((d['pending_leaves'] as List?) ?? []).length;
        final pg = ((d['pending'] as List?) ?? []).length;
        final tp = d['total_pending'];
        _pending =
            tp is num ? tp.toInt() : pr + pl + pg;
      }
      final r2 = await http.get(
        Uri.parse(
            '$kBaseUrl/attendance/api/mobile/manager/attendance/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (r2.statusCode == 200) {
        final d = jsonDecode(r2.body);
        final items = ((d['items'] as List?) ??
            (d['attendance'] as List?) ??
            []);
        final total = d['total'];
        _present =
            total is num ? total.toInt() : items.length;
      }
      final r3 = await http.get(
        Uri.parse(
            '$kBaseUrl/attendance/api/mobile/manager/live-locations/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (r3.statusCode == 200) {
        final d = jsonDecode(r3.body);
        _fieldWorkers =
            ((d['locations'] as List?) ?? []).length;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final now = DateTime.now();
    final days = isAr
        ? ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت']
        : ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final months = isAr
        ? ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر']
        : ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final dateStr = isAr
        ? '${days[now.weekday % 7]}، ${now.day} ${months[now.month - 1]} ${now.year}'
        : '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';
    final displayName = _firstName.isNotEmpty
        ? _firstName
        : (isAr ? 'المدير' : 'Manager');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A148C),
                  Color(0xFF7B1FA2),
                  Color(0xFF9C27B0)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding:
                const EdgeInsets.fromLTRB(20, 48, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dashboard,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'أهلاً يا $displayName 👋'
                                : 'Hello, $displayName 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_companyName.isNotEmpty)
                            Text(
                              _companyName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        dateStr,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white))
                    : Row(
                        children: [
                          _statCard(
                              isAr ? 'معلقة' : 'Pending',
                              '$_pending',
                              Icons.pending_actions,
                              Colors.orangeAccent),
                          const SizedBox(width: 10),
                          _statCard(
                              isAr
                                  ? 'حاضر اليوم'
                                  : 'Present Today',
                              '$_present',
                              Icons.how_to_reg,
                              Colors.greenAccent),
                          const SizedBox(width: 10),
                          _statCard(
                              isAr ? 'ميداني' : 'Field',
                              '$_fieldWorkers',
                              Icons.location_on,
                              Colors.lightBlueAccent),
                        ],
                      ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: Text(
              isAr ? 'الإدارة السريعة' : 'Quick Management',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _gridCard(
                    isAr ? 'الطلبات المعلقة' : 'Pending Requests',
                    Icons.pending_actions,
                    Colors.orange,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManagerPendingScreen())),
                    badge: _pending),
                _gridCard(
                    isAr ? 'الحضور اليوم' : "Today's Attendance",
                    Icons.how_to_reg,
                    Colors.green,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManagerAttendanceScreen()))),
                _gridCard(
                    isAr ? 'المواقع المباشرة' : 'Live Locations',
                    Icons.location_on,
                    const Color(0xFF7B1FA2),
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManagerLiveLocationsScreen()))),
                _gridCard(
                    isAr ? 'الموظفين' : 'Employees',
                    Icons.people,
                    Colors.indigo,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManagerEmployeesListScreen()))),
                _gridCard(
                    context.l10n.addEmployee,
                    Icons.person_add,
                    Colors.deepOrange,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const CreateEmployeeScreen()))),
                _gridCard(
                    isAr ? 'الشيفتات' : 'Shifts',
                    Icons.schedule,
                    const Color(0xFF00838F),
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftsScreen()))),
                _gridCard(
                    context.l10n.missions,
                    Icons.assignment,
                    const Color(0xFF6C3FC5),
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManagerMissionsScreen()))),
                _gridCard(
                    context.l10n.announcements,
                    Icons.campaign,
                    Colors.deepPurple,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManagerAnnouncementsScreen()))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: Text(
              isAr ? 'الأدوات' : 'Tools',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _gridCard(
                    context.l10n.reports,
                    Icons.analytics,
                    Colors.teal,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ReportsHubScreen()))),
                _gridCard(
                    context.l10n.payroll,
                    Icons.account_balance_wallet,
                    Colors.green,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PayrollHubScreen()))),
                _gridCard(
                    isAr ? 'سياسات الحضور والخصم' : 'Attendance Policies',
                    Icons.policy,
                    const Color(0xFF1565C0),
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const AttendancePolicyScreen()))),
                _gridCard(
                    context.l10n.reminders,
                    Icons.notifications_active,
                    Colors.blueGrey,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ReminderSettingsScreen()))),
                _gridCard(
                    isAr ? 'نطاق الجيو' : 'Geofence',
                    Icons.fence,
                    Colors.cyan,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManagerGeofenceScreen()))),
                _gridCard(
                    isAr ? 'لائحة الشركة' : 'Company Charter',
                    Icons.description,
                    Colors.brown,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ManagerCharterScreen()))),
                _gridCard(
                    context.l10n.organizationTree,
                    Icons.account_tree,
                    const Color(0xFF00695C),
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const OrganizationTreeScreen()))),
                _gridCard(
                    isAr ? 'إدارة الأقسام' : 'Departments',
                    Icons.apartment,
                    const Color(0xFF0D47A1),
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const DepartmentsManagementScreen()))),
                _gridCard(
                    isAr ? 'إنهاء الخدمة' : 'Offboarding',
                    Icons.person_remove,
                    Colors.red,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const OffboardingScreen()))),
                _gridCard(
                    context.l10n.companyInfo,
                    Icons.business,
                    Colors.pink,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const CompanyInfoScreen()))),
                _gridCard(
                    isAr ? 'الصلاحيات' : 'Permissions',
                    Icons.admin_panel_settings,
                    const Color(0xFF1A56DB),
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const PermissionsManagementScreen()))),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridCard(String title, IconData icon, Color color,
      VoidCallback onTap,
      {int? badge}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 3,
      shadowColor: color.withValues(alpha: 0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (badge != null && badge > 0)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                      minWidth: 24, minHeight: 24),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ManagerPendingScreen extends StatefulWidget {
  const ManagerPendingScreen({super.key});
  @override
  State<ManagerPendingScreen> createState() =>
      _ManagerPendingScreenState();
}

class _ManagerPendingScreenState extends State<ManagerPendingScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/manager/pending/'),
          headers: {'Authorization': 'Token $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _items = [
              ...List.from(data['pending_requests'] ?? []),
              ...List.from(data['pending_leaves'] ?? []),
              ...List.from(data['pending'] ?? []),
            ]);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _showRejectDialog(dynamic item) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Row(children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            Text(isAr ? 'سبب الرفض' : 'Rejection Reason'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isAr
                  ? 'يرجى كتابة سبب الرفض (إجباري)'
                  : 'Please enter the rejection reason (required)'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      isAr ? 'اكتب السبب هنا...' : 'Write reason here...',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white),
              child: Text(
                  isAr ? 'تأكيد الرفض' : 'Confirm Rejection'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && reasonCtrl.text.trim().isNotEmpty) {
      await _action(item, 'reject', notes: reasonCtrl.text.trim());
    }
    reasonCtrl.dispose();
  }

  Future<void> _action(dynamic item, String action,
      {String notes = ''}) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final body = {
        'id': item['id'],
        'type': item['type'],
        'action': action,
      };
      if (notes.isNotEmpty) body['notes'] = notes;
      final res = await http.post(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/manager/action/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token'
          },
          body: jsonEncode(body));
      final data = jsonDecode(res.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? context.l10n.done)));
        fetchUnreadCount();
      }
      _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${isAr ? 'حدث خطأ' : 'An error occurred'}: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return EmptyStateWidget(
        title: isAr ? 'لا توجد طلبات معلقة' : 'No Pending Requests',
        description: isAr
            ? 'ممتاز! كل الطلبات تمت مراجعتها.\nستظهر هنا أي طلبات جديدة تحتاج موافقتك.'
            : 'Great! All requests have been reviewed.\nNew requests requiring your approval will appear here.',
        icon: Icons.check_circle_outline,
        iconColor: Colors.green,
      );
    }
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['employee_name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(item['subject'] ??
                                item['type_name'] ??
                                item['leave_type'] ??
                                item['title'] ??
                                ''),
                            Text(
                                item['details'] ??
                                    item['description'] ??
                                    item['reason'] ??
                                    '',
                                style:
                                    const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                  child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _action(item, 'approve'),
                                      icon: const Icon(Icons.check),
                                      label: Text(isAr
                                          ? 'موافقة'
                                          : 'Approve'),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor:
                                              Colors.white))),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _showRejectDialog(item),
                                      icon: const Icon(Icons.close),
                                      label: Text(
                                          context.l10n.rejectMission),
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor:
                                              Colors.white))),
                            ])
                          ])));
            }));
  }
}

class ManagerAttendanceScreen extends StatefulWidget {
  const ManagerAttendanceScreen({super.key});
  @override
  State<ManagerAttendanceScreen> createState() =>
      _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState
    extends State<ManagerAttendanceScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/manager/attendance/'),
          headers: {'Authorization': 'Token $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() =>
            _items = data['items'] ?? data['attendance'] ?? []);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return EmptyStateWidget(
        title: isAr ? 'لا يوجد سجلات حضور' : 'No Attendance Records',
        description: isAr
            ? 'لم يسجل أي موظف حضور اليوم.\nستظهر السجلات هنا فور تسجيل الحضور.'
            : 'No employee has checked in today.\nRecords will appear here once attendance is registered.',
        icon: Icons.event_busy_outlined,
        iconColor: const Color(0xFF6A1B9A),
      );
    }
    return RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              return Card(
                  child: ListTile(
                      leading: const Icon(Icons.person,
                          color: kManagerColor),
                      title: Text(item['employee_name'] ??
                          item['name'] ??
                          ''),
                      subtitle: Text(
                        isAr
                            ? 'حضور: ${item['check_in'] ?? item['check_in_time'] ?? '-'}  |  انصراف: ${item['check_out'] ?? item['check_out_time'] ?? '-'}'
                            : 'Check-in: ${item['check_in'] ?? item['check_in_time'] ?? '-'}  |  Check-out: ${item['check_out'] ?? item['check_out_time'] ?? '-'}',
                      )));
            }));
  }
}

class ManagerLiveLocationsScreen extends StatefulWidget {
  const ManagerLiveLocationsScreen({super.key});
  @override
  State<ManagerLiveLocationsScreen> createState() =>
      _ManagerLiveLocationsScreenState();
}

class _ManagerLiveLocationsScreenState
    extends State<ManagerLiveLocationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _showMap = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
          Uri.parse(
              '$kBaseUrl/attendance/api/mobile/manager/live-locations/'),
          headers: {'Authorization': 'Token $token'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _items = data['items'] ?? []);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _openMap(double lat, double lng) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url))
      await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return EmptyStateWidget(
        title: isAr ? 'لا توجد مواقع لحظية' : 'No Live Locations',
        description: isAr
            ? 'لعرض المواقع، تأكد من:\n• وجود موظفين ميدانيين\n• تفعيل التتبع لهم\n• تشغيل تطبيقاتهم'
            : 'To view locations, make sure:\n• Field employees exist\n• Tracking is enabled\n• Their apps are running',
        icon: Icons.location_off_outlined,
        iconColor: Colors.orange,
        onRefresh: _load,
      );
    }
    return Column(children: [
      Padding(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showMap = true),
                    icon: const Icon(Icons.map),
                    label: Text(isAr ? 'خريطة' : 'Map'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _showMap ? kManagerColor : Colors.grey,
                        foregroundColor: Colors.white))),
            const SizedBox(width: 8),
            Expanded(
                child: ElevatedButton.icon(
                    onPressed: () => setState(() => _showMap = false),
                    icon: const Icon(Icons.list),
                    label: Text(isAr ? 'قائمة' : 'List'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor:
                            !_showMap ? kManagerColor : Colors.grey,
                        foregroundColor: Colors.white))),
          ])),
      Expanded(child: _showMap ? _buildMap() : _buildList()),
    ]);
  }

  Widget _buildMap() {
    final markers = <Marker>[];
    for (final item in _items) {
      final lat = (item['latitude'] as num?)?.toDouble();
      final lng = (item['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      markers.add(Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on,
              color: Colors.red, size: 40)));
    }
    final center = markers.isNotEmpty
        ? markers.first.point
        : const LatLng(30.0444, 31.2357);
    return FlutterMap(
        options: MapOptions(
            initialCenter: center, initialZoom: 13),
        children: [
          TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.motionhr.app'),
          MarkerLayer(markers: markers),
        ]);
  }

  Widget _buildList() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final item = _items[i];
          final lat =
              (item['latitude'] as num?)?.toDouble() ?? 0;
          final lng =
              (item['longitude'] as num?)?.toDouble() ?? 0;
          return Card(
              child: ListTile(
                  leading: const Icon(Icons.person_pin_circle,
                      color: Colors.red),
                  title: Text(item['employee_name'] ?? ''),
                  subtitle:
                      Text(item['address'] ?? '$lat, $lng'),
                  trailing: IconButton(
                      icon: const Icon(Icons.map,
                          color: kPrimaryColor),
                      onPressed: () => _openMap(lat, lng))));
        });
  }
}









