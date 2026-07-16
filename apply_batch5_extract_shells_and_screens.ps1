$ErrorActionPreference = 'Stop'
$project = 'C:\MotionHR\motionhr_employee'
Set-Location $project

Write-Host '=== Batch 5: Extract All Screens ===' -ForegroundColor Cyan

function Write-Utf8File {
    param([string]$RelativePath, [string]$Content)
    $fullPath = Join-Path $project $RelativePath
    New-Item -ItemType Directory -Force -Path (Split-Path $fullPath -Parent) | Out-Null
    Set-Content -Path $fullPath -Value $Content -Encoding UTF8
    Write-Host "Created: $RelativePath" -ForegroundColor Green
}

# ─────────────────────────────────────────────
# COMMON IMPORTS HEADER
# ─────────────────────────────────────────────
$commonImports = @'
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';

import '../../core/constants.dart';
import '../../core/error_handler.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../services/charter_service.dart';
import '../../services/auth_service.dart';
import '../../services/attendance_service.dart';
import '../../services/request_service.dart';
import '../../services/leave_service.dart';
import '../../widgets/notification_bell_button.dart';
import '../../widgets/app_loading.dart';
import '../../widgets/app_empty.dart';
import '../../widgets/app_snackbar.dart';
'@

# ─────────────────────────────────────────────
# SPLASH SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\auth\splash_screen.dart' @"
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../common/charter_screen.dart';
import '../employee/employee_shell.dart';
import '../manager/manager_shell.dart';
import 'login_screen.dart';
import '../../background_service.dart';

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
    final token = await StorageService.getToken();
    final appMode = await StorageService.getAppMode();

    if (!mounted) return;

    if (token.isNotEmpty) {
      await NotificationService.fetchUnreadCount();

      bool needsCharter = false;
      if (appMode != 'manager') {
        try {
          final res = await http.get(
            Uri.parse('`$kBaseUrl/attendance/api/mobile/charter/'),
            headers: {'Authorization': 'Token `$token'},
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
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => CharterScreen(appMode: appMode)));
      } else if (appMode == 'manager') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ManagerShell()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const EmployeeShell()));
      }
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryDark, kPrimaryColor, kAccentColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 100, color: Colors.white),
              SizedBox(height: 20),
              Text('MotionHR',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              SizedBox(height: 8),
              Text('نظام إدارة الموارد البشرية',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 30),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
"@

# ─────────────────────────────────────────────
# LOGIN SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\auth\login_screen.dart' @"
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../common/charter_screen.dart';
import '../employee/employee_shell.dart';
import '../manager/manager_shell.dart';
import 'change_password_screen.dart';
import '../../background_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  Future<void> _saveFCMToken(String token) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;
      await http.post(
        Uri.parse('\$kBaseUrl/attendance/api/mobile/fcm-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token \$token',
        },
        body: '{"fcm_token":"\$fcmToken"}',
      );
    } catch (_) {}
  }

  Future<void> _login() async {
    if (_userCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'من فضلك ادخل اسم المستخدم وكلمة المرور');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final map = await AuthService.login(
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );

      final token = map['token'] ?? '';
      final appMode = map['app_mode'] ?? 'employee';
      final mustChange = map['must_change_password'] == true;

      _saveFCMToken(token);
      NotificationService.fetchUnreadCount();

      bool needsCharter = false;
      if (appMode != 'manager') {
        try {
          final res = await http.get(
            Uri.parse('\$kBaseUrl/attendance/api/mobile/charter/'),
            headers: {'Authorization': 'Token \$token'},
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

      if (mustChange) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ChangePasswordScreen(forced: true)));
      } else if (needsCharter) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => CharterScreen(appMode: appMode)));
      } else if (appMode == 'manager') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ManagerShell()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const EmployeeShell()));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showForgotPassword() {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('نسيت كلمة المرور'),
          content: const Text('من فضلك تواصل مع مسئول الموارد البشرية لإعادة تعيين كلمة المرور.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسناً'))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
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
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, size: 70, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text('MotionHR',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  const Text('مرحباً بك، سجل دخولك للمتابعة',
                      style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _userCtrl,
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passFocus.requestFocus(),
                          decoration: InputDecoration(
                            labelText: 'اسم المستخدم',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.person, color: kPrimaryColor),
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
                            labelText: 'كلمة المرور',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.lock, color: kPrimaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePass = !_obscurePass),
                            ),
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
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Row(children: [
                              Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700]))),
                            ]),
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                            ),
                            child: _loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    Icon(Icons.login, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('دخول', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  ]),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _showForgotPassword,
                          child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: kPrimaryColor)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('© 2025 MotionHR', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
"@

# ─────────────────────────────────────────────
# CHANGE PASSWORD SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\auth\change_password_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../employee/employee_shell.dart';
import '../manager/manager_shell.dart';
import '../../services/storage_service.dart';

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
  bool _o1 = true, _o2 = true, _o3 = true;
  String? _error;

  Future<void> _change() async {
    if (_newCtrl.text != _confirmCtrl.text) { setState(() => _error = 'كلمة المرور غير متطابقة'); return; }
    if (_newCtrl.text.length < 6) { setState(() => _error = 'كلمة المرور يجب أن تكون 6 أحرف على الأقل'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.changePassword(currentPassword: _currentCtrl.text, newPassword: _newCtrl.text);
      final appMode = await StorageService.getAppMode();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح'), backgroundColor: Colors.green));
      if (appMode == 'manager') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ManagerShell()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const EmployeeShell()));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController c, String label, bool obs, VoidCallback toggle) {
    return TextField(
      controller: c, obscureText: obs,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.lock, color: kPrimaryColor),
        suffixIcon: IconButton(icon: Icon(obs ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: toggle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تغيير كلمة المرور'), backgroundColor: kPrimaryColor, foregroundColor: Colors.white, automaticallyImplyLeading: !widget.forced),
        body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
          if (widget.forced) Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange[200]!)),
            child: Row(children: [Icon(Icons.warning, color: Colors.orange[700]), const SizedBox(width: 12), const Expanded(child: Text('يجب تغيير كلمة المرور قبل استخدام التطبيق', style: TextStyle(color: Colors.orange)))]),
          ),
          const SizedBox(height: 20),
          _field(_currentCtrl, 'كلمة المرور الحالية', _o1, () => setState(() => _o1 = !_o1)),
          const SizedBox(height: 16),
          _field(_newCtrl, 'كلمة المرور الجديدة', _o2, () => setState(() => _o2 = !_o2)),
          const SizedBox(height: 16),
          _field(_confirmCtrl, 'تأكيد كلمة المرور', _o3, () => setState(() => _o3 = !_o3)),
          if (_error != null) ...[const SizedBox(height: 12), Container(width: double.infinity, padding: const EdgeInsets.all(12), color: Colors.red[50], child: Text(_error!, style: const TextStyle(color: Colors.red)))],
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
            onPressed: _loading ? null : _change,
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          )),
        ])),
      ),
    );
  }
}
"@

# ─────────────────────────────────────────────
# NOTIFICATIONS SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\common\notifications_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../employee/employee_shell.dart';
import '../manager/manager_shell.dart';
import '../manager/manager_charter_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await NotificationService.list();
      setState(() {
        _notifications = data['notifications'] ?? [];
        _unreadCount = data['unread_count'] ?? 0;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _openNotification(dynamic raw) async {
    final n = Map<String, dynamic>.from(raw as Map);
    if (n['id'] != null && n['is_read'] != true) {
      await NotificationService.markOneRead(n['id']);
    }
    final type = (n['notification_type'] ?? '').toString();
    final appMode = await StorageService.getAppMode();
    Widget page;
    switch (type) {
      case 'new_request': case 'new_leave': case 'new_permission':
        page = const ManagerShell(initialIndex: 1); break;
      case 'attendance': case 'check_in': case 'check_out': case 'manager_attendance':
        page = const ManagerShell(initialIndex: 2); break;
      case 'request_approved': case 'request_rejected': case 'leave_approved': case 'leave_rejected':
        page = appMode == 'manager' ? const ManagerShell(initialIndex: 1) : const EmployeeShell(initialIndex: 3); break;
      case 'charter_acceptance':
        page = const ManagerCharterScreen(); break;
      default:
        page = appMode == 'manager' ? const ManagerShell() : const EmployeeShell();
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  IconData _icon(String type) {
    switch (type) {
      case 'new_request': return Icons.assignment;
      case 'new_leave': return Icons.beach_access;
      case 'request_approved': case 'leave_approved': return Icons.check_circle;
      case 'request_rejected': case 'leave_rejected': return Icons.cancel;
      case 'attendance': case 'manager_attendance': return Icons.access_time;
      case 'charter_acceptance': return Icons.description;
      default: return Icons.notifications;
    }
  }

  Color _color(String type) {
    if (type.contains('approved')) return Colors.green;
    if (type.contains('rejected')) return Colors.red;
    if (type.contains('attendance')) return Colors.teal;
    if (type.contains('charter')) return kManagerColor;
    if (type.contains('new_')) return Colors.blue;
    return Colors.grey;
  }

  String _time(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'الآن';
      if (diff.inMinutes < 60) return 'منذ \${diff.inMinutes} دقيقة';
      if (diff.inHours < 24) return 'منذ \${diff.inHours} ساعة';
      return '\${dt.day}/\${dt.month}/\${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الإشعارات\${_unreadCount > 0 ? " (\$_unreadCount)" : ""}'),
          backgroundColor: kPrimaryColor, foregroundColor: Colors.white,
          actions: [
            if (_unreadCount > 0)
              IconButton(icon: const Icon(Icons.done_all), onPressed: () async { await NotificationService.markAllRead(); _load(); }),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notifications.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_off, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('لا توجد إشعارات', style: TextStyle(fontSize: 18, color: Colors.grey))]))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      itemCount: _notifications.length,
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
                        final isRead = n['is_read'] == true;
                        final type = n['notification_type'] ?? 'general';
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          color: isRead ? Colors.white : Colors.blue[50],
                          elevation: isRead ? 1 : 3,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _color(type).withOpacity(0.15),
                              child: Icon(_icon(type), color: _color(type)),
                            ),
                            title: Text(n['title'] ?? '', style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold)),
                            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const SizedBox(height: 4),
                              Text(n['body'] ?? ''),
                              const SizedBox(height: 4),
                              Text(_time(n['created_at'] ?? ''), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            ]),
                            isThreeLine: true,
                            onTap: () => _openNotification(n),
                          ),
                        );
                      },
                    )),
      ),
    );
  }
}
"@

# ─────────────────────────────────────────────
# CHARTER SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\common\charter_screen.dart' @"
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/error_handler.dart';
import '../../services/charter_service.dart';
import '../employee/employee_shell.dart';
import '../manager/manager_shell.dart';

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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await CharterService.getCharter();
      if (data['success'] == true && data['has_charter'] == true) {
        setState(() => _charter = data['charter']);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _openAttachment() async {
    final url = _charter?['attachment_url'] ?? '';
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _accept() async {
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى الموافقة على اللائحة أولاً'), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _submitting = true);
    try {
      final data = await CharterService.acceptCharter();
      if (data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تسجيل موافقتك بنجاح ✅'), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => widget.appMode == 'manager' ? const ManagerShell() : const EmployeeShell()));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? data['error'] ?? 'حدث خطأ')));
      }
    } catch (e) {
      if (mounted) AppErrorHandler.show(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachmentUrl = _charter?['attachment_url'] ?? '';
    final attachmentName = _charter?['attachment_name'] ?? 'الملف المرفق';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('لائحة الشركة'), backgroundColor: kPrimaryColor, foregroundColor: Colors.white, automaticallyImplyLeading: false),
        body: _loading ? const Center(child: CircularProgressIndicator())
            : _charter == null ? const Center(child: Text('لا توجد لائحة حالياً'))
            : Column(children: [
                Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimaryDark, kPrimaryColor]), borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      const Icon(Icons.description, color: Colors.white, size: 48), const SizedBox(height: 8),
                      Text(_charter!['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text('الإصدار \${_charter!['version'] ?? 1}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ])),
                  const SizedBox(height: 16),
                  if (attachmentUrl.isNotEmpty) ...[
                    InkWell(onTap: _openAttachment, child: Container(width: double.infinity, padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple[200]!)),
                      child: Row(children: [
                        Icon(Icons.attach_file, color: Colors.purple[700]), const SizedBox(width: 10),
                        Expanded(child: Text(attachmentName, style: TextStyle(color: Colors.purple[700], fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        Icon(Icons.open_in_new, color: Colors.purple[700], size: 20)]))),
                    const SizedBox(height: 16)],
                  if ((_charter!['introduction'] ?? '').toString().isNotEmpty) ...[
                    Container(width: double.infinity, padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue[200]!)),
                      child: Text(_charter!['introduction'], style: const TextStyle(fontSize: 15, height: 1.6))),
                    const SizedBox(height: 16)],
                  Container(width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
                    child: Text(_charter!['content'] ?? '', style: const TextStyle(fontSize: 15, height: 1.8))),
                  const SizedBox(height: 20)]))),
                Container(padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -4))]),
                  child: Column(children: [
                    CheckboxListTile(value: _agreed, onChanged: (v) => setState(() => _agreed = v ?? false),
                      title: const Text('أقر بأنني قرأت واطلعت على لائحة الشركة وأوافق على جميع بنودها', style: TextStyle(fontSize: 14)),
                      activeColor: kPrimaryColor, controlAffinity: ListTileControlAffinity.leading),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
                      onPressed: (_submitting || !_agreed) ? null : _accept,
                      style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _submitting ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.check_circle), SizedBox(width: 8),
                              Text('أوافق على اللائحة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))])))]))]),
      ),
    );
  }
}
"@

# ─────────────────────────────────────────────
# EMPLOYEE SHELL
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\employee\employee_shell.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/notification_bell_button.dart';
import '../../background_service.dart';
import '../auth/login_screen.dart';
import '../auth/change_password_screen.dart';
import '../common/notifications_screen.dart';
import 'employee_home_screen.dart';
import 'leaves_screen.dart';
import 'requests_screen.dart';
import 'my_items_screen.dart';

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
    NotificationService.fetchUnreadCount();
  }

  List<Widget> get _pages => [
    const EmployeeHomeScreen(),
    const LeavesScreen(),
    const RequestsScreen(),
    const MyItemsScreen(),
  ];

  Future<void> _logout() async {
    await StorageService.clear();
    await stopBackgroundTracking();
    NotificationService.unreadCount.value = 0;
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MotionHR'),
          backgroundColor: kPrimaryColor, foregroundColor: Colors.white,
          actions: [
            NotificationBellButton(notificationsScreenBuilder: (_) => const NotificationsScreen()),
            IconButton(icon: const Icon(Icons.lock), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()))),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: _pages[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index, onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed, selectedItemColor: kPrimaryColor,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.beach_access), label: 'إجازات'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'طلبات'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'طلباتي'),
          ],
        ),
      ),
    );
  }
}
"@

# ─────────────────────────────────────────────
# MANAGER SHELL
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\manager\manager_shell.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/notification_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/notification_bell_button.dart';
import '../auth/login_screen.dart';
import '../common/notifications_screen.dart';
import 'manager_charter_screen.dart';
import 'manager_dashboard.dart';
import 'manager_pending_screen.dart';
import 'manager_attendance_screen.dart';
import 'manager_live_locations_screen.dart';

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
    NotificationService.fetchUnreadCount();
  }

  List<Widget> get _pages => [
    const ManagerDashboard(),
    const ManagerPendingScreen(),
    const ManagerAttendanceScreen(),
    const ManagerLiveLocationsScreen(),
  ];

  Future<void> _logout() async {
    await StorageService.clear();
    NotificationService.unreadCount.value = 0;
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('MotionHR - المدير'),
          backgroundColor: kManagerColor, foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.description), tooltip: 'لائحة الشركة',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerCharterScreen()))),
            NotificationBellButton(notificationsScreenBuilder: (_) => const NotificationsScreen()),
            IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
          ],
        ),
        body: _pages[_index],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _index, onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed, selectedItemColor: kManagerColor,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'الطلبات'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'الحضور'),
            BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'المواقع'),
          ],
        ),
      ),
    );
  }
}
"@

# ─────────────────────────────────────────────
# MANAGER DASHBOARD
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\manager\manager_dashboard.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/request_service.dart';
import 'manager_pending_screen.dart';
import 'manager_attendance_screen.dart';
import 'manager_live_locations_screen.dart';
import 'manager_geofence_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  int _pending = 0, _present = 0, _fieldWorkers = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r1 = await RequestService.getManagerPending();
      final pr = ((r1['pending_requests'] as List?) ?? []).length;
      final pl = ((r1['pending_leaves'] as List?) ?? []).length;
      final pg = ((r1['pending'] as List?) ?? []).length;
      final tp = r1['total_pending'];
      _pending = tp is num ? tp.toInt() : pr + pl + pg;

      final r2 = await RequestService.getManagerAttendance();
      final items = ((r2['items'] as List?) ?? (r2['attendance'] as List?) ?? []);
      final total = r2['total'];
      _present = total is num ? total.toInt() : items.length;

      final r3 = await RequestService.getManagerLiveLocations();
      _fieldWorkers = ((r3['locations'] as List?) ?? []).length;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Widget _card(String title, String value, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 40, color: color)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          ])),
          const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 16),
        ]))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Padding(padding: EdgeInsets.only(bottom: 16), child: Text('لوحة التحكم', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
      _card('الطلبات المعلقة', '\$_pending', Icons.pending_actions, Colors.orange,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerPendingScreen()))),
      const SizedBox(height: 12),
      _card('الحضور اليوم', '\$_present', Icons.people, Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerAttendanceScreen()))),
      const SizedBox(height: 12),
      _card('الموظفين الميدانيين', '\$_fieldWorkers', Icons.location_on, kManagerColor,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerLiveLocationsScreen()))),
      const SizedBox(height: 12),
      _card('نطاق موقع الشركة', 'إعدادات', Icons.fence, Colors.teal,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagerGeofenceScreen()))),
    ]));
  }
}
"@

# ─────────────────────────────────────────────
# MANAGER PENDING SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\manager\manager_pending_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/notification_service.dart';
import '../../services/request_service.dart';

class ManagerPendingScreen extends StatefulWidget {
  const ManagerPendingScreen({super.key});

  @override
  State<ManagerPendingScreen> createState() => _ManagerPendingScreenState();
}

class _ManagerPendingScreenState extends State<ManagerPendingScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await RequestService.getManagerPending();
      setState(() => _items = [
        ...List.from(data['pending_requests'] ?? []),
        ...List.from(data['pending_leaves'] ?? []),
        ...List.from(data['pending'] ?? []),
      ]);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _action(dynamic item, String action) async {
    try {
      final data = await RequestService.managerAction(id: item['id'], type: item['type'], action: action);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'تم')));
      NotificationService.fetchUnreadCount();
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('لا توجد طلبات معلقة'));
    return RefreshIndicator(onRefresh: _load, child: ListView.builder(
      itemCount: _items.length,
      itemBuilder: (_, i) {
        final item = _items[i];
        return Card(margin: const EdgeInsets.all(8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['employee_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(item['subject'] ?? item['type_name'] ?? item['leave_type'] ?? item['title'] ?? ''),
          Text(item['details'] ?? item['description'] ?? item['reason'] ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: ElevatedButton.icon(onPressed: () => _action(item, 'approve'), icon: const Icon(Icons.check), label: const Text('موافقة'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(onPressed: () => _action(item, 'reject'), icon: const Icon(Icons.close), label: const Text('رفض'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white))),
          ])])));
      },
    ));
  }
}
"@

# ─────────────────────────────────────────────
# MANAGER ATTENDANCE SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\manager\manager_attendance_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/request_service.dart';

class ManagerAttendanceScreen extends StatefulWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  State<ManagerAttendanceScreen> createState() => _ManagerAttendanceScreenState();
}

class _ManagerAttendanceScreenState extends State<ManagerAttendanceScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await RequestService.getManagerAttendance();
      setState(() => _items = data['items'] ?? data['attendance'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('لا يوجد سجلات حضور اليوم'));
    return RefreshIndicator(onRefresh: _load, child: ListView.builder(itemCount: _items.length, itemBuilder: (_, i) {
      final item = _items[i];
      return Card(child: ListTile(
        leading: const Icon(Icons.person, color: kManagerColor),
        title: Text(item['employee_name'] ?? item['name'] ?? ''),
        subtitle: Text('حضور: \${item['check_in'] ?? item['check_in_time'] ?? '-'}  |  انصراف: \${item['check_out'] ?? item['check_out_time'] ?? '-'}'),
      ));
    }));
  }
}
"@

# ─────────────────────────────────────────────
# MANAGER LIVE LOCATIONS SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\manager\manager_live_locations_screen.dart' @"
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../services/request_service.dart';

class ManagerLiveLocationsScreen extends StatefulWidget {
  const ManagerLiveLocationsScreen({super.key});

  @override
  State<ManagerLiveLocationsScreen> createState() => _ManagerLiveLocationsScreenState();
}

class _ManagerLiveLocationsScreenState extends State<ManagerLiveLocationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;
  bool _showMap = true;
  Timer? _timer;

  @override
  void initState() { super.initState(); _load(); _timer = Timer.periodic(const Duration(minutes: 2), (_) => _load()); }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _load() async {
    try {
      final data = await RequestService.getManagerLiveLocations();
      setState(() => _items = data['locations'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _openMap(double lat, double lng) async {
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=\$lat,\$lng');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.location_off, size: 80, color: Colors.grey[400]),
      const SizedBox(height: 16),
      const Text('لا توجد مواقع لحظية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('تحديث')),
    ]));
    return Column(children: [
      Padding(padding: const EdgeInsets.all(8), child: Row(children: [
        Expanded(child: ElevatedButton.icon(onPressed: () => setState(() => _showMap = true), icon: const Icon(Icons.map), label: const Text('خريطة'),
            style: ElevatedButton.styleFrom(backgroundColor: _showMap ? kManagerColor : Colors.grey, foregroundColor: Colors.white))),
        const SizedBox(width: 8),
        Expanded(child: ElevatedButton.icon(onPressed: () => setState(() => _showMap = false), icon: const Icon(Icons.list), label: const Text('قائمة'),
            style: ElevatedButton.styleFrom(backgroundColor: !_showMap ? kManagerColor : Colors.grey, foregroundColor: Colors.white))),
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
      markers.add(Marker(point: LatLng(lat, lng), width: 40, height: 40, child: const Icon(Icons.location_on, color: Colors.red, size: 40)));
    }
    final center = markers.isNotEmpty ? markers.first.point : const LatLng(30.0444, 31.2357);
    return FlutterMap(options: MapOptions(initialCenter: center, initialZoom: 13), children: [
      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.motionhr.app'),
      MarkerLayer(markers: markers),
    ]);
  }

  Widget _buildList() {
    return ListView.builder(itemCount: _items.length, itemBuilder: (_, i) {
      final item = _items[i];
      final lat = (item['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (item['longitude'] as num?)?.toDouble() ?? 0;
      return Card(child: ListTile(
        leading: const Icon(Icons.person_pin_circle, color: Colors.red),
        title: Text(item['employee_name'] ?? ''),
        subtitle: Text(item['address'] ?? '\$lat, \$lng'),
        trailing: IconButton(icon: const Icon(Icons.map, color: kPrimaryColor), onPressed: () => _openMap(lat, lng)),
      ));
    });
  }
}
"@

# ─────────────────────────────────────────────
# MANAGER GEOFENCE SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\manager\manager_geofence_screen.dart' @"
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../background_service.dart';

class ManagerGeofenceScreen extends StatefulWidget {
  const ManagerGeofenceScreen({super.key});

  @override
  State<ManagerGeofenceScreen> createState() => _ManagerGeofenceScreenState();
}

class _ManagerGeofenceScreenState extends State<ManagerGeofenceScreen> {
  bool _loading = true, _saving = false;
  double? _lat, _lng;
  final _radiusCtrl = TextEditingController(text: '100');
  bool _enabled = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await ApiService.get('/attendance/api/mobile/geofence/');
      if (data['success'] == true && data['geofence'] != null) {
        final g = data['geofence'];
        setState(() {
          _lat = (g['latitude'] as num?)?.toDouble();
          _lng = (g['longitude'] as num?)?.toDouble();
          _radiusCtrl.text = (g['radius'] ?? 100).toString();
          _enabled = g['enabled'] ?? false;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _getLocation() async {
    setState(() => _saving = true);
    try {
      await requestLocationPermissionsForTracking();
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديد موقعك الحالي'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: \$e'), backgroundColor: Colors.red));
    } finally { setState(() => _saving = false); }
  }

  Future<void> _save() async {
    if (_lat == null || _lng == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى تحديد الموقع أولاً'), backgroundColor: Colors.orange)); return; }
    final radius = int.tryParse(_radiusCtrl.text) ?? 100;
    if (radius < 10 || radius > 5000) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('النطاق يجب أن يكون بين 10 و 5000 متر'), backgroundColor: Colors.orange)); return; }
    setState(() => _saving = true);
    try {
      final data = await ApiService.post('/attendance/api/mobile/geofence/set/', body: {'latitude': _lat, 'longitude': _lng, 'radius': radius, 'enabled': _enabled});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'تم'), backgroundColor: data['success'] == true ? Colors.green : Colors.red));
      if (data['success'] == true) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally { setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('نطاق موقع الشركة'), backgroundColor: kManagerColor, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[200]!)),
          child: const Row(children: [Icon(Icons.info_outline, color: Colors.blue), SizedBox(width: 8), Expanded(child: Text('حدد موقع الشركة عشان الموظفين ما يقدروش يسجلوا حضور من برة النطاق ده.', style: TextStyle(fontSize: 13)))])),
        const SizedBox(height: 16),
        Card(elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('موقع الشركة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_lat != null && _lng != null)
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('خط العرض: \${_lat!.toStringAsFixed(6)}'), Text('خط الطول: \${_lng!.toStringAsFixed(6)}')]))
          else Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
              child: const Text('لم يحدد موقع بعد', style: TextStyle(color: Colors.orange))),
          const SizedBox(height: 12),
          SizedBox(height: 50, child: ElevatedButton.icon(onPressed: _saving ? null : _getLocation, icon: const Icon(Icons.my_location), label: const Text('استخدم موقعي الحالي'),
              style: ElevatedButton.styleFrom(backgroundColor: kManagerColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ]))),
        const SizedBox(height: 16),
        Card(elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('نصف قطر النطاق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
          TextField(controller: _radiusCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المسافة بالمتر', border: OutlineInputBorder(), suffixText: 'متر')),
        ]))),
        const SizedBox(height: 16),
        Card(elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SwitchListTile(title: const Text('تفعيل النطاق الجغرافي', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_enabled ? 'مفعل' : 'معطل'), value: _enabled, activeColor: kManagerColor, onChanged: (v) => setState(() => _enabled = v))),
        const SizedBox(height: 20),
        SizedBox(height: 56, child: ElevatedButton.icon(onPressed: _saving ? null : _save, icon: const Icon(Icons.save), label: const Text('حفظ الإعدادات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      ])),
    ));
  }
}
"@

# ─────────────────────────────────────────────
# MANAGER CHARTER SCREEN + CHARTER REPORT
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\manager\manager_charter_screen.dart' @"
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/error_handler.dart';
import '../../services/charter_service.dart';
import 'charter_report_screen.dart';

class ManagerCharterScreen extends StatefulWidget {
  const ManagerCharterScreen({super.key});

  @override
  State<ManagerCharterScreen> createState() => _ManagerCharterScreenState();
}

class _ManagerCharterScreenState extends State<ManagerCharterScreen> {
  Map<String, dynamic>? _charter;
  List<dynamic> _accepted = [], _pending = [];
  bool _loading = true, _saving = false, _showEdit = false;
  String _attachmentUrl = '', _attachmentName = '';
  PlatformFile? _pickedAttachment;
  bool _removeCurrentAttachment = false;

  final _titleCtrl = TextEditingController();
  final _introCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _titleCtrl.dispose(); _introCtrl.dispose(); _contentCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r1 = await CharterService.getCharter();
      if (r1['has_charter'] == true) {
        _charter = r1['charter'];
        _titleCtrl.text = _charter!['title'] ?? '';
        _introCtrl.text = _charter!['introduction'] ?? '';
        _contentCtrl.text = _charter!['content'] ?? '';
        _attachmentUrl = _charter!['attachment_url'] ?? '';
        _attachmentName = _charter!['attachment_name'] ?? '';
      }
      final r2 = await CharterService.getAcceptances();
      _accepted = r2['accepted']?['employees'] ?? [];
      _pending = r2['pending']?['employees'] ?? [];
    } catch (_) {}
    if (mounted) setState(() { _pickedAttachment = null; _removeCurrentAttachment = false; _loading = false; });
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowMultiple: false, allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg']);
    if (result == null || result.files.isEmpty) return;
    setState(() { _pickedAttachment = result.files.first; _removeCurrentAttachment = false; });
  }

  Future<void> _openAttachment() async {
    if (_attachmentUrl.isEmpty) return;
    final uri = Uri.parse(_attachmentUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('العنوان والمحتوى مطلوبان'), backgroundColor: Colors.orange)); return;
    }
    setState(() => _saving = true);
    try {
      http.MultipartFile? file;
      if (_pickedAttachment != null && _pickedAttachment!.path != null) {
        file = await http.MultipartFile.fromPath('attachment', _pickedAttachment!.path!, filename: _pickedAttachment!.name);
      }
      final data = await CharterService.updateCharter(
        title: _titleCtrl.text.trim(), introduction: _introCtrl.text.trim(), content: _contentCtrl.text.trim(),
        attachment: file, removeAttachment: _removeCurrentAttachment,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'تم'), backgroundColor: data['success'] == true ? Colors.green : Colors.red));
        if (data['success'] == true) { setState(() => _showEdit = false); await _load(); }
      }
    } catch (e) {
      if (mounted) AppErrorHandler.show(context, e);
    } finally { if (mounted) setState(() => _saving = false); }
  }

  String _formatDate(String iso) {
    try { final dt = DateTime.parse(iso).toLocal(); return '\${dt.day}/\${dt.month}/\${dt.year} \${dt.hour}:\${dt.minute.toString().padLeft(2, '0')}'; } catch (_) { return ''; }
  }

  Widget _statCard(String label, int count, Color color, IconData icon) {
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [Icon(icon, color: color, size: 32), const SizedBox(height: 8), Text('\$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)), Text(label, style: TextStyle(color: color, fontSize: 13))]));
  }

  Widget _buildInfoView() {
    return RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
      if (_charter != null) ...[
        Container(width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimaryDark, kManagerColor]), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [const Icon(Icons.description, color: Colors.white, size: 40), const SizedBox(height: 8),
            Text(_charter!['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('الإصدار \${_charter!['version'] ?? 1}', style: const TextStyle(color: Colors.white70))])),
        const SizedBox(height: 12),
        if (_attachmentUrl.isNotEmpty) ...[
          InkWell(onTap: _openAttachment, child: Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple[200]!)),
            child: Row(children: [Icon(Icons.attach_file, color: Colors.purple[700]), const SizedBox(width: 10),
              Expanded(child: Text(_attachmentName.isNotEmpty ? _attachmentName : 'الملف المرفق', style: TextStyle(color: Colors.purple[700]), overflow: TextOverflow.ellipsis)),
              Icon(Icons.open_in_new, color: Colors.purple[700], size: 18)]))),
          const SizedBox(height: 12)],
        Row(children: [
          Expanded(child: ElevatedButton.icon(onPressed: () => setState(() => _showEdit = true), icon: const Icon(Icons.edit), label: const Text('تعديل اللائحة'),
              style: ElevatedButton.styleFrom(backgroundColor: kManagerColor, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
          const SizedBox(width: 8),
          Expanded(child: ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CharterReportScreen(accepted: _accepted, pending: _pending, charterTitle: _charter?['title'] ?? '', charterVersion: _charter?['version'] ?? 1))),
            icon: const Icon(Icons.print), label: const Text('تقرير الموافقات'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, minimumSize: const Size(0, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))))),
        ]),
      ] else ...[
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange[200]!)),
          child: const Column(children: [Icon(Icons.warning, color: Colors.orange, size: 40), SizedBox(height: 8), Text('لا توجد لائحة بعد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))])),
        const SizedBox(height: 12),
        ElevatedButton.icon(onPressed: () => setState(() => _showEdit = true), icon: const Icon(Icons.add), label: const Text('إنشاء لائحة جديدة'),
            style: ElevatedButton.styleFrom(backgroundColor: kManagerColor, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      ],
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: _statCard('وافقوا', _accepted.length, Colors.green, Icons.check_circle)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('لم يوافقوا', _pending.length, Colors.orange, Icons.pending)),
      ]),
      const SizedBox(height: 16),
      if (_accepted.isNotEmpty) ...[
        const Text('✅ وافقوا على اللائحة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)), const SizedBox(height: 8),
        ..._accepted.map((emp) => Card(color: Colors.green[50], child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white, size: 18)),
          title: Text(emp['name'] ?? emp['username'] ?? ''),
          subtitle: Text(_formatDate(emp['accepted_at'] ?? ''), style: const TextStyle(fontSize: 12))))),
        const SizedBox(height: 16)],
      if (_pending.isNotEmpty) ...[
        const Text('⏳ لم يوافقوا بعد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)), const SizedBox(height: 8),
        ..._pending.map((emp) => Card(color: Colors.orange[50], child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.schedule, color: Colors.white, size: 18)),
          title: Text(emp['name'] ?? emp['username'] ?? ''),
          subtitle: const Text('في انتظار الموافقة', style: TextStyle(fontSize: 12)))))],
    ]));
  }

  Widget _buildEditView() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue[200]!)),
        child: const Row(children: [Icon(Icons.info, color: Colors.blue), SizedBox(width: 8), Expanded(child: Text('أي تعديل في المحتوى أو الملف سيطلب موافقة الموظفين مجدداً', style: TextStyle(fontSize: 13)))])),
      const SizedBox(height: 16),
      TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'عنوان اللائحة *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title))),
      const SizedBox(height: 16),
      TextField(controller: _introCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'المقدمة (اختياري)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.short_text))),
      const SizedBox(height: 16),
      TextField(controller: _contentCtrl, maxLines: 12, decoration: const InputDecoration(labelText: 'محتوى اللائحة *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.article), hintText: '1- البند الأول\n2- البند الثاني')),
      const SizedBox(height: 16),
      // Current Attachment
      if (_attachmentUrl.isNotEmpty) ...[
        Align(alignment: Alignment.centerRight, child: Text('الملف الحالي', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]))),
        const SizedBox(height: 8),
        Container(width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _removeCurrentAttachment ? Colors.red[50] : Colors.purple[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: _removeCurrentAttachment ? Colors.red[200]! : Colors.purple[200]!)),
          child: Column(children: [
            Row(children: [
              Icon(Icons.attach_file, color: _removeCurrentAttachment ? Colors.red : Colors.purple),
              const SizedBox(width: 8),
              Expanded(child: Text(_attachmentName, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, color: _removeCurrentAttachment ? Colors.red : Colors.purple[700], decoration: _removeCurrentAttachment ? TextDecoration.lineThrough : TextDecoration.none))),
              IconButton(onPressed: _openAttachment, icon: const Icon(Icons.open_in_new)),
            ]),
            CheckboxListTile(value: _removeCurrentAttachment, onChanged: (v) => setState(() => _removeCurrentAttachment = v ?? false),
              title: const Text('حذف الملف الحالي عند الحفظ'), controlAffinity: ListTileControlAffinity.leading, contentPadding: EdgeInsets.zero),
          ])),
        const SizedBox(height: 16)],
      // New Attachment
      Align(alignment: Alignment.centerRight, child: Text('ملف جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]))),
      const SizedBox(height: 8),
      if (_pickedAttachment != null)
        Container(width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green[200]!)),
          child: Row(children: [
            const Icon(Icons.insert_drive_file, color: Colors.green), const SizedBox(width: 8),
            Expanded(child: Text(_pickedAttachment!.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold))),
            IconButton(onPressed: () => setState(() => _pickedAttachment = null), icon: const Icon(Icons.close, color: Colors.red)),
          ]))
      else Container(width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue[200]!)),
          child: const Text('لم يتم اختيار ملف جديد\nالمسموح: PDF / Word / PNG / JPG — الحد الأقصى 10 MB', style: TextStyle(height: 1.5))),
      const SizedBox(height: 8),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _pickAttachment, icon: const Icon(Icons.upload_file), label: const Text('اختيار ملف PDF / Word / صورة'))),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: OutlinedButton(onPressed: () => setState(() => _showEdit = false), style: OutlinedButton.styleFrom(minimumSize: const Size(0, 50)), child: const Text('إلغاء'))),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton(onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: kManagerColor, foregroundColor: Colors.white, minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('حفظ اللائحة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
      ]),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('إدارة لائحة الشركة'), backgroundColor: kManagerColor, foregroundColor: Colors.white,
        actions: [IconButton(icon: Icon(_showEdit ? Icons.visibility : Icons.edit), onPressed: () => setState(() => _showEdit = !_showEdit))]),
      body: _loading ? const Center(child: CircularProgressIndicator()) : _showEdit ? _buildEditView() : _buildInfoView(),
    ));
  }
}
"@

Write-Utf8File 'lib\screens\manager\charter_report_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';

class CharterReportScreen extends StatelessWidget {
  final List<dynamic> accepted, pending;
  final String charterTitle;
  final int charterVersion;

  const CharterReportScreen({super.key, required this.accepted, required this.pending, required this.charterTitle, required this.charterVersion});

  String _fmt(String iso) { try { final dt = DateTime.parse(iso).toLocal(); return '\${dt.day}/\${dt.month}/\${dt.year} \${dt.hour}:\${dt.minute.toString().padLeft(2, '0')}'; } catch (_) { return ''; } }
  String _now() { final dt = DateTime.now(); return '\${dt.day}/\${dt.month}/\${dt.year} \${dt.hour}:\${dt.minute.toString().padLeft(2, '0')}'; }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('تقرير الموافقات'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(width: double.infinity, padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.teal, kPrimaryColor]), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [const Icon(Icons.description, color: Colors.white, size: 40), const SizedBox(height: 8),
            Text(charterTitle, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            Text('الإصدار \$charterVersion', style: const TextStyle(color: Colors.white70)),
            Text('تاريخ التقرير: \${_now()}', style: const TextStyle(color: Colors.white60, fontSize: 12))])),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green[200]!)),
            child: Column(children: [const Icon(Icons.check_circle, color: Colors.green, size: 32), const SizedBox(height: 8), Text('\${accepted.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)), const Text('وافقوا', style: TextStyle(color: Colors.green))]))),
          const SizedBox(width: 12),
          Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange[200]!)),
            child: Column(children: [const Icon(Icons.pending, color: Colors.orange, size: 32), const SizedBox(height: 8), Text('\${pending.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)), const Text('لم يوافقوا', style: TextStyle(color: Colors.orange))]))),
        ]),
        const SizedBox(height: 20),
        if (accepted.isNotEmpty) ...[
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green[700], borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
            child: Text('وافقوا على اللائحة (\${accepted.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          Container(decoration: BoxDecoration(border: Border.all(color: Colors.green[200]!), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
            child: Column(children: accepted.asMap().entries.map((e) {
              final i = e.key; final emp = e.value;
              return Container(
                decoration: BoxDecoration(color: i.isEven ? Colors.green[50] : Colors.white, border: i < accepted.length - 1 ? Border(bottom: BorderSide(color: Colors.green[100]!)) : null),
                child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: Colors.green[100], child: Text('\${i + 1}', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(emp['name'] ?? emp['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    if ((emp['accepted_at'] ?? '').isNotEmpty) Text('وافق في: \${_fmt(emp['accepted_at'])}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    if ((emp['ip_address'] ?? '').isNotEmpty) Text('IP: \${emp['ip_address']}', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                  ])),
                  const Icon(Icons.verified, color: Colors.green, size: 20)])));
            }).toList())),
          const SizedBox(height: 20)],
        if (pending.isNotEmpty) ...[
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange[700], borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
            child: Text('لم يوافقوا بعد (\${pending.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
          Container(decoration: BoxDecoration(border: Border.all(color: Colors.orange[200]!), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10))),
            child: Column(children: pending.asMap().entries.map((e) {
              final i = e.key; final emp = e.value;
              return Container(
                decoration: BoxDecoration(color: i.isEven ? Colors.orange[50] : Colors.white, border: i < pending.length - 1 ? Border(bottom: BorderSide(color: Colors.orange[100]!)) : null),
                child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: Colors.orange[100], child: Text('\${i + 1}', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold, fontSize: 12))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(emp['name'] ?? emp['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold))),
                  const Icon(Icons.schedule, color: Colors.orange, size: 20)])));
            }).toList())),
          const SizedBox(height: 20)],
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
          child: Text('تم إنشاء هذا التقرير بواسطة نظام MotionHR\nتاريخ الطباعة: \${_now()}', style: TextStyle(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center)),
        const SizedBox(height: 20),
      ]),
    ));
  }
}
"@

# ─────────────────────────────────────────────
# EMPLOYEE HOME SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\employee\employee_home_screen.dart' @"
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants.dart';
import '../../services/storage_service.dart';
import '../../services/notification_service.dart';
import '../../services/attendance_service.dart';
import '../../background_service.dart';
import 'history_screen.dart';

Map<String, List<String>> kMorningMessages = {
  'male': ['صباح الخير يا {name} 🌅 يومك جميل بإذن الله', 'أهلاً يا {name}، جاهز نبدع النهاردة! 🚀', 'شغلك النهاردة هيكون سبب في نجاحك يا {name} 💪'],
  'female': ['صباح الخير يا {name} 🌅 يومك جميل بإذن الله', 'أهلاً يا {name}، جاهزة نبدعي النهاردة! 🚀', 'شغلك النهاردة هيكون سبب في نجاحك يا {name} 💪'],
};

Map<String, List<String>> kEveningMessages = {
  'male': ['شكراً على مجهودك النهاردة يا {name} 🌙 استريح كويس', 'يوم عمل جميل يا {name}، تستاهل راحة ممتعة 😴'],
  'female': ['شكراً على مجهودك النهاردة يا {name} 🌙 استريحي كويس', 'يوم عمل جميل يا {name}، تستاهلي راحة ممتعة 😴'],
};

String _getMsg(Map<String, List<String>> msgs, String gender, String name) {
  final list = msgs[gender] ?? msgs['male']!;
  return list[Random().nextInt(list.length)].replaceAll('{name}', name.isEmpty ? 'صديقنا' : name);
}

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  String _firstName = '', _companyName = '', _gender = 'male';
  Map<String, dynamic>? _status;
  bool _loading = false;
  Timer? _clockTimer;
  DateTime _now = DateTime.now();
  String? _motivationMessage;
  bool _isEvening = false;

  final List<String> _days = ['الاثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت','الأحد'];
  final List<String> _months = ['','يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];

  @override
  void initState() { super.initState(); _loadData(); _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() => _now = DateTime.now()); }); }

  @override
  void dispose() { _clockTimer?.cancel(); super.dispose(); }

  Future<void> _loadData() async {
    _firstName = await StorageService.getString('first_name');
    _companyName = await StorageService.getString('company_name');
    _gender = await StorageService.getString('gender');
    if (_gender.isEmpty) _gender = 'male';
    try { final data = await AttendanceService.getStatus(); if (mounted) setState(() => _status = data); } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _attendanceAction(String action) async {
    setState(() => _loading = true);
    try {
      await requestLocationPermissionsForTracking();
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final data = await AttendanceService.action(action: action, latitude: pos.latitude, longitude: pos.longitude);
      if (data['success'] == true) {
        NotificationService.fetchUnreadCount();
        setState(() {
          _motivationMessage = _getMsg(action == 'check_in' ? kMorningMessages : kEveningMessages, _gender, _firstName);
          _isEvening = action == 'check_out';
        });
        _showDialog();
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'حدث خطأ'), backgroundColor: Colors.orange, duration: const Duration(seconds: 5)));
      }
      await _loadData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: \$e'), backgroundColor: Colors.red));
    } finally { setState(() => _loading = false); }
  }

  void _showDialog() {
    if (_motivationMessage == null) return;
    showDialog(context: context, builder: (_) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(_isEvening ? Icons.nightlight_round : Icons.wb_sunny, size: 60, color: _isEvening ? Colors.indigo : Colors.orange),
        const SizedBox(height: 16),
        Text(_isEvening ? 'مع السلامة' : 'أهلاً بيك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _isEvening ? Colors.indigo : Colors.orange)),
        const SizedBox(height: 12),
        Text(_motivationMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('شكراً', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))],
    )));
  }

  String get _date { final d = _days[_now.weekday - 1]; final m = _months[_now.month]; return '\$d، \${_now.day} \$m \${_now.year}'; }
  String get _time { return '\${_now.hour.toString().padLeft(2,'0')}:\${_now.minute.toString().padLeft(2,'0')}:\${_now.second.toString().padLeft(2,'0')}'; }

  int _remaining() {
    if (_status == null) return 0;
    final ts = _status!['shift_end_timestamp'];
    if (ts != null) { try { final d = DateTime.parse(ts).toLocal().difference(_now).inSeconds; return d > 0 ? d : 0; } catch (_) {} }
    return (_status!['remaining_seconds'] ?? 0) as int;
  }

  String _countdown(int s) { if (s <= 0) return '00:00:00'; return '\${(s~/3600).toString().padLeft(2,'0')}:\${((s%3600)~/60).toString().padLeft(2,'0')}:\${(s%60).toString().padLeft(2,'0')}'; }

  double _progress() {
    final total = (_status?['shift_duration_seconds'] ?? 0) as int;
    if (total <= 0) return 0.0;
    return ((total - _remaining()) / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final checkedIn = _status?['checked_in'] == true;
    final checkedOut = _status?['checked_out'] == true;
    final canCheckOut = _status?['can_check_out'] == true;
    final hasEarly = _status?['has_early_leave_permission'] == true;
    final shiftName = _status?['shift_name'] ?? '';
    final shiftStart = _status?['shift_start'] ?? '';
    final shiftEnd = _status?['shift_end'] ?? '';
    final rem = _remaining();
    final displayName = _firstName.isNotEmpty ? _firstName : 'بك';

    return RefreshIndicator(onRefresh: _loadData, child: ListView(padding: const EdgeInsets.all(16), children: [
      Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [kPrimaryDark, kPrimaryColor], begin: Alignment.topRight, end: Alignment.bottomLeft), borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(radius: 24, backgroundColor: Colors.white, child: Icon(Icons.person, color: kPrimaryColor, size: 30)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('أهلاً يا \$displayName', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              if (_companyName.isNotEmpty) Text(_companyName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ])),
          ]),
          const Divider(color: Colors.white24, height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('التاريخ', style: TextStyle(color: Colors.white60, fontSize: 12)), Text(_date, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('الوقت', style: TextStyle(color: Colors.white60, fontSize: 12)), Text(_time, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1))]),
          ]),
        ])),
      const SizedBox(height: 16),
      if (shiftName.toString().isNotEmpty)
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
          const Icon(Icons.schedule, color: kPrimaryColor), const SizedBox(width: 8),
          Expanded(child: Text('شيفت: \$shiftName (\$shiftStart - \$shiftEnd)', style: const TextStyle(fontWeight: FontWeight.bold))),
        ]))),
      const SizedBox(height: 16),
      if (checkedIn && !checkedOut)
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: canCheckOut ? Colors.green[50] : Colors.blue[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: canCheckOut ? Colors.green[200]! : Colors.blue[200]!)),
          child: Column(children: [
            Row(children: [Icon(canCheckOut ? Icons.check_circle : Icons.timer, color: canCheckOut ? Colors.green : kPrimaryColor), const SizedBox(width: 8), Text(canCheckOut ? 'الشيفت خلص، تقدر تنصرف' : 'باقي على الانصراف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: canCheckOut ? Colors.green : kPrimaryColor))]),
            const SizedBox(height: 12),
            Text(_countdown(rem), style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: canCheckOut ? Colors.green : kPrimaryColor, letterSpacing: 2)),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _progress(), minHeight: 12, backgroundColor: Colors.grey[300], valueColor: AlwaysStoppedAnimation(canCheckOut ? Colors.green : kPrimaryColor))),
            const SizedBox(height: 6),
            Text('\${(_progress() * 100).toInt()}% من الشيفت', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            if (hasEarly) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.info, size: 16, color: Colors.orange), SizedBox(width: 4), Text('عندك إذن خروج مبكر 🕐', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))]))],
          ])),
      const SizedBox(height: 20),
      if (checkedOut)
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green[200]!)),
          child: const Column(children: [Icon(Icons.check_circle, color: Colors.green, size: 60), SizedBox(height: 10), Text('تم تسجيل الحضور والانصراف', style: TextStyle(fontSize: 18, color: Colors.green, fontWeight: FontWeight.bold)), SizedBox(height: 8), Text('أحسنت العمل اليوم 👏', style: TextStyle(color: Colors.green))]))
      else Row(children: [
        Expanded(child: SizedBox(height: 110, child: ElevatedButton(onPressed: (_loading || checkedIn) ? null : () => _attendanceAction('check_in'),
          style: ElevatedButton.styleFrom(backgroundColor: checkedIn ? Colors.grey[400] : Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: checkedIn ? 0 : 4, disabledBackgroundColor: Colors.grey[400], disabledForegroundColor: Colors.white),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(checkedIn ? Icons.check_circle : Icons.login, size: 40), const SizedBox(height: 6), Text(checkedIn ? 'تم الحضور 🕐' : 'تسجيل الحضور', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))])))),
        const SizedBox(width: 12),
        Expanded(child: SizedBox(height: 110, child: ElevatedButton(onPressed: (_loading || !checkedIn || (!canCheckOut && !hasEarly)) ? null : () => _attendanceAction('check_out'),
          style: ElevatedButton.styleFrom(backgroundColor: (!checkedIn || (!canCheckOut && !hasEarly)) ? Colors.grey[400] : Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: (!checkedIn || (!canCheckOut && !hasEarly)) ? 0 : 4, disabledBackgroundColor: Colors.grey[400], disabledForegroundColor: Colors.white),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon((!checkedIn || (!canCheckOut && !hasEarly)) ? Icons.lock : Icons.logout, size: 40), const SizedBox(height: 6), Text(!checkedIn ? 'تسجيل الانصراف' : (canCheckOut || hasEarly ? 'تسجيل الانصراف' : 'مقفول'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))])))),
      ]),
      const SizedBox(height: 20),
      if (_status?['check_in_time'] != null && (_status?['check_in_time'] ?? '').toString().isNotEmpty)
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.login, color: Colors.green)), title: const Text('وقت الحضور'), subtitle: Text('\${_status?['check_in_time']}', style: const TextStyle(fontWeight: FontWeight.bold)))),
      if (_status?['check_out_time'] != null && (_status?['check_out_time'] ?? '').toString().isNotEmpty)
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.logout, color: Colors.orange)), title: const Text('وقت الانصراف'), subtitle: Text('\${_status?['check_out_time']}', style: const TextStyle(fontWeight: FontWeight.bold)))),
      const SizedBox(height: 20),
      SizedBox(height: 50, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())), icon: const Icon(Icons.history), label: const Text('سجل الأيام السابقة', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: kPrimaryColor, side: const BorderSide(color: kPrimaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]));
  }
}
"@

# ─────────────────────────────────────────────
# HISTORY SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\employee\history_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/attendance_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final data = await AttendanceService.getHistory(); setState(() => _items = data['history'] ?? []); } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('سجل الأيام'), backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty ? const Center(child: Text('لا يوجد سجل'))
          : ListView.builder(padding: const EdgeInsets.all(8), itemCount: _items.length, itemBuilder: (_, i) {
              final item = _items[i];
              return Card(child: ListTile(leading: const Icon(Icons.calendar_today, color: kPrimaryColor), title: Text(item['date'] ?? ''), subtitle: Text('حضور: \${item['check_in'] ?? '-'}  |  انصراف: \${item['check_out'] ?? '-'}')));
            }),
    ));
  }
}
"@

# ─────────────────────────────────────────────
# LEAVES SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\employee\leaves_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/leave_service.dart';
import 'leave_request_screen.dart';

class LeavesScreen extends StatefulWidget {
  const LeavesScreen({super.key});

  @override
  State<LeavesScreen> createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> {
  List<dynamic> _types = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  int _order(Map t) {
    final c = (t['category'] ?? '').toString().toLowerCase(); final n = (t['name'] ?? '').toString();
    if (c == 'annual' || n.contains('سنوية')) return 1;
    if (c == 'casual' || c == 'emergency' || n.contains('عارضة') || n.contains('طارئة')) return 2;
    if (c == 'sick' || n.contains('مرضية') || n.contains('مرضي')) return 3;
    return 4;
  }

  Future<void> _load() async {
    try {
      final data = await LeaveService.getLeaveTypes();
      List<dynamic> list = data['leave_types'] ?? data['types'] ?? [];
      list = list.where((t) { final c = (t['category'] ?? '').toString().toLowerCase(); final n = (t['name'] ?? '').toString(); return c != 'paternity' && !n.contains('أبوة'); }).toList();
      list.sort((a, b) => _order(a).compareTo(_order(b)));
      setState(() => _types = list);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('أنواع الإجازات والأرصدة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
      ..._types.map((t) { final balance = t['balance'] is Map ? (t['balance']['remaining'] ?? 0) : (t['balance'] ?? 0); return Card(child: ListTile(leading: const Icon(Icons.beach_access, color: kPrimaryColor), title: Text(t['name'] ?? ''), subtitle: Text('الرصيد المتبقي: \$balance يوم'))); }),
      const SizedBox(height: 20),
      SizedBox(height: 52, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaveRequestScreen(types: _types))), icon: const Icon(Icons.add), label: const Text('تقديم طلب إجازة', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
    ]);
  }
}
"@

# ─────────────────────────────────────────────
# LEAVE REQUEST SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\employee\leave_request_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/leave_service.dart';

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
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) c.text = '\${d.year}-\${d.month.toString().padLeft(2,'0')}-\${d.day.toString().padLeft(2,'0')}';
  }

  Future<void> _submit() async {
    if (_selectedValue == null || _startCtrl.text.isEmpty || _endCtrl.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء جميع الحقول'))); return; }
    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{'start_date': _startCtrl.text, 'end_date': _endCtrl.text, 'reason': _isOther ? 'نوع آخر: \${_otherCtrl.text}\n\${_reasonCtrl.text}' : _reasonCtrl.text};
      if (!_isOther) body['leave_type_id'] = _selectedValue;
      final data = await LeaveService.submitLeave(body);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'تم'))); if (data['success'] == true) Navigator.pop(context); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); }
    finally { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: AppBar(title: const Text('طلب إجازة'), backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
        DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'نوع الإجازة', border: OutlineInputBorder()), value: _selectedValue,
          items: [...widget.types.where((t) { final c = (t['category'] ?? '').toString().toLowerCase(); final n = (t['name'] ?? '').toString(); return c != 'paternity' && !n.contains('أبوة'); }).map((t) => DropdownMenuItem<String>(value: t['id'].toString(), child: Text(t['name'] ?? ''))),
            const DropdownMenuItem<String>(value: 'other', child: Text('أخرى'))],
          onChanged: (v) => setState(() => _selectedValue = v)),
        if (_isOther) ...[const SizedBox(height: 16), TextField(controller: _otherCtrl, decoration: const InputDecoration(labelText: 'اذكر نوع الإجازة', border: OutlineInputBorder()))],
        const SizedBox(height: 16),
        TextField(controller: _startCtrl, readOnly: true, onTap: () => _pickDate(_startCtrl), decoration: const InputDecoration(labelText: 'من تاريخ', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today))),
        const SizedBox(height: 16),
        TextField(controller: _endCtrl, readOnly: true, onTap: () => _pickDate(_endCtrl), decoration: const InputDecoration(labelText: 'إلى تاريخ', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today))),
        const SizedBox(height: 16),
        TextField(controller: _reasonCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'السبب', border: OutlineInputBorder())),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _loading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
            child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال الطلب', style: TextStyle(fontSize: 18)))),
      ])),
    ));
  }
}
"@

# ─────────────────────────────────────────────
# REQUESTS SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\employee\requests_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/request_service.dart';

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
  final _permDateCtrl = TextEditingController();
  final _permTimeCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  bool _submitting = false;

  bool get _isOther => _selectedValue == 'other';

  Map<String, dynamic>? get _selectedType {
    try { return _types.cast<Map<String, dynamic>>().firstWhere((t) => t['id'].toString() == _selectedValue); } catch (_) { return null; }
  }

  bool get _isLoan { final n = (_selectedType?['name'] ?? '').toString(); return n.contains('سلفة') || _selectedValue == '2'; }

  String get _permKind {
    final exp = (_selectedType?['permission_kind'] ?? '').toString();
    if (exp.isNotEmpty && exp != 'none') return exp;
    final n = (_selectedType?['name'] ?? '').toString();
    if (n.contains('إذن تأخير')) return 'late_arrival';
    if (n.contains('إذن خروج') || n.contains('خروج مبكر')) return 'early_leave';
    return 'none';
  }

  bool get _isPerm => _permKind == 'late_arrival' || _permKind == 'early_leave';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final data = await RequestService.getRequestTypes();
      List<dynamic> flat = [];
      if (data['categories'] is List) { for (final cat in data['categories']) { if (cat['types'] is List) { for (final t in cat['types']) { flat.add({'id': t['id'], 'name': t['name'], 'category': cat['name'], 'permission_kind': t['permission_kind'] ?? 'none'}); } } } }
      else if (data['types'] is List) { flat = (data['types'] as List).map((t) => {'id': t['id'], 'name': t['name'], 'category': t['category'] ?? '', 'permission_kind': t['permission_kind'] ?? 'none'}).toList(); }
      setState(() => _types = flat);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickDate(TextEditingController c) async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 30)), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (d != null) c.text = '\${d.year}-\${d.month.toString().padLeft(2,'0')}-\${d.day.toString().padLeft(2,'0')}';
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) { _permTimeCtrl.text = '\${t.hour.toString().padLeft(2,'0')}:\${t.minute.toString().padLeft(2,'0')}'; setState(() {}); }
  }

  Future<void> _submit() async {
    if (_selectedValue == null || _titleCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار النوع وكتابة العنوان'))); return; }
    if (_isLoan && _amountCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ السلفة'))); return; }
    if (_isPerm && (_permDateCtrl.text.isEmpty || _permTimeCtrl.text.isEmpty || _durationCtrl.text.isEmpty)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال تاريخ ووقت ومدة الإذن'))); return; }
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{'title': _titleCtrl.text.trim(), 'description': _isOther ? 'نوع آخر: \${_otherCtrl.text.trim()}\n\${_descCtrl.text.trim()}' : _descCtrl.text.trim()};
      if (!_isOther) body['request_type_id'] = _selectedValue;
      if (_isLoan && _amountCtrl.text.isNotEmpty) body['amount'] = _amountCtrl.text.trim();
      if (_isPerm) { body['permission_date'] = _permDateCtrl.text.trim(); body['permission_time'] = _permTimeCtrl.text.trim(); body['duration_hours'] = _durationCtrl.text.trim(); }
      final data = await RequestService.submitRequest(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data['message'] ?? 'تم')));
        if (data['success'] == true) { _titleCtrl.clear(); _descCtrl.clear(); _otherCtrl.clear(); _amountCtrl.clear(); _permDateCtrl.clear(); _permTimeCtrl.clear(); _durationCtrl.clear(); setState(() => _selectedValue = null); }
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red)); }
    finally { setState(() => _submitting = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
      const Text('تقديم طلب', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 20),
      DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'نوع الطلب', border: OutlineInputBorder()), value: _selectedValue,
        items: [..._types.map((t) => DropdownMenuItem<String>(value: t['id'].toString(), child: Text(t['name'] ?? ''))), const DropdownMenuItem<String>(value: 'other', child: Text('أخرى'))],
        onChanged: (v) { setState(() { _selectedValue = v; _amountCtrl.clear(); _permDateCtrl.clear(); _permTimeCtrl.clear(); _durationCtrl.clear(); }); }),
      if (_isPerm) ...[
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
          child: Text(_permKind == 'late_arrival' ? 'هذا الطلب سيعامل كإذن تأخير.' : 'هذا الطلب سيعامل كإذن خروج مبكر.', style: TextStyle(color: Colors.orange[900]))),
        const SizedBox(height: 16),
        TextField(controller: _permDateCtrl, readOnly: true, onTap: () => _pickDate(_permDateCtrl), decoration: const InputDecoration(labelText: 'تاريخ الإذن', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today))),
        const SizedBox(height: 16),
        TextField(controller: _permTimeCtrl, readOnly: true, onTap: _pickTime, decoration: InputDecoration(labelText: _permKind == 'late_arrival' ? 'وقت الحضور المتوقع' : 'وقت الخروج المطلوب', border: const OutlineInputBorder(), suffixIcon: const Icon(Icons.access_time))),
        const SizedBox(height: 16),
        TextField(controller: _durationCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'عدد الساعات', border: OutlineInputBorder(), suffixText: 'ساعة')),
      ],
      if (_isLoan) ...[const SizedBox(height: 16), TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'المبلغ المطلوب', border: OutlineInputBorder(), suffixText: 'جنيه'))],
      if (_isOther) ...[const SizedBox(height: 16), TextField(controller: _otherCtrl, decoration: const InputDecoration(labelText: 'اذكر نوع الطلب', border: OutlineInputBorder()))],
      const SizedBox(height: 16),
      TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الطلب', border: OutlineInputBorder())),
      const SizedBox(height: 16),
      TextField(controller: _descCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'التفاصيل / السبب', border: OutlineInputBorder())),
      const SizedBox(height: 20),
      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _submitting ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
          child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('إرسال', style: TextStyle(fontSize: 18)))),
    ]));
  }
}
"@

# ─────────────────────────────────────────────
# MY ITEMS SCREEN
# ─────────────────────────────────────────────
Write-Utf8File 'lib\screens\employee\my_items_screen.dart' @"
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/request_service.dart';
import '../../services/leave_service.dart';

class MyItemsScreen extends StatelessWidget {
  const MyItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Column(children: [
      const TabBar(labelColor: kPrimaryColor, indicatorColor: kPrimaryColor, tabs: [Tab(text: 'طلباتي'), Tab(text: 'إجازاتي')]),
      Expanded(child: TabBarView(children: [const _MyRequests(), const _MyLeaves()])),
    ]));
  }
}

class _MyRequests extends StatefulWidget {
  const _MyRequests();

  @override
  State<_MyRequests> createState() => _MyRequestsState();
}

class _MyRequestsState extends State<_MyRequests> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final data = await RequestService.getMyRequests(); setState(() => _items = data['requests'] ?? []); } catch (_) {}
    setState(() => _loading = false);
  }

  Color _statusColor(String s) {
    if (s.contains('موافق') || s.toLowerCase().contains('approved')) return Colors.green;
    if (s.contains('رفض') || s.toLowerCase().contains('reject')) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('لا يوجد طلبات'));
    return RefreshIndicator(onRefresh: _load, child: ListView.builder(itemCount: _items.length, itemBuilder: (_, i) {
      final item = _items[i]; final status = (item['status_display'] ?? item['status'] ?? '').toString();
      return Card(margin: const EdgeInsets.all(8), child: ListTile(title: Text(item['title'] ?? item['type'] ?? '-'), subtitle: Text(item['date'] ?? item['created_at'] ?? ''),
          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold)))));
    }));
  }
}

class _MyLeaves extends StatefulWidget {
  const _MyLeaves();

  @override
  State<_MyLeaves> createState() => _MyLeavesState();
}

class _MyLeavesState extends State<_MyLeaves> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { final data = await LeaveService.getMyLeaves(); setState(() => _items = data['leaves'] ?? []); } catch (_) {}
    setState(() => _loading = false);
  }

  Color _statusColor(String s) {
    if (s.contains('موافق') || s.toLowerCase().contains('approved')) return Colors.green;
    if (s.contains('رفض') || s.toLowerCase().contains('reject')) return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('لا يوجد إجازات'));
    return RefreshIndicator(onRefresh: _load, child: ListView.builder(itemCount: _items.length, itemBuilder: (_, i) {
      final item = _items[i]; final status = (item['status_display'] ?? item['status'] ?? '').toString();
      return Card(margin: const EdgeInsets.all(8), child: ListTile(title: Text(item['leave_type'] ?? item['type'] ?? '-'), subtitle: Text(item['date'] ?? item['created_at'] ?? ''),
          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _statusColor(status).withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: Text(status, style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold)))));
    }));
  }
}
"@

Write-Host ''
Write-Host '=== Batch 5 Done ===' -ForegroundColor Cyan
Write-Host 'All screens extracted successfully.' -ForegroundColor Green
Write-Host 'Next: Run apply_batch6_switch_entrypoint.ps1' -ForegroundColor Yellow