import os

dart_code = r"""
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});
  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  static const String baseUrl = 'https://jssolutions-eg.com';
  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _reminders = [];
  String _timezone = '';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') ?? '';
  }

  Future<void> _loadSettings() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse('/attendance/api/mobile/manager/reminders/settings/'),
        headers: {'Authorization': 'Token '},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _reminders = List<Map<String, dynamic>>.from(data['reminders'] ?? []);
          _timezone = data['timezone'] ?? '';
          _loading = false;
        });
      } else {
        setState(() { _error = 'خطأ في تحميل الإعدادات'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _triggerReminder(String type, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الإرسال'),
        content: Text('إرسال تذكير:  الآن؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
            child: const Text('إرسال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() { _sending = true; });
    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse('/attendance/api/mobile/manager/reminders/trigger/'),
        headers: {'Authorization': 'Token ', 'Content-Type': 'application/json'},
        body: jsonEncode({'type': type}),
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.statusCode == 200 ? 'تم إرسال:  بنجاح' : data['error'] ?? 'فشل'),
        backgroundColor: res.statusCode == 200 ? Colors.green : Colors.red,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: '), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() { _sending = false; });
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'checkin':   return Icons.login_rounded;
      case 'checkout':  return Icons.logout_rounded;
      case 'pending':   return Icons.pending_actions_rounded;
      case 'charter':   return Icons.description_rounded;
      case 'documents': return Icons.folder_open_rounded;
      default:          return Icons.notifications_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'checkin':   return Colors.green;
      case 'checkout':  return Colors.orange;
      case 'pending':   return Colors.blue;
      case 'charter':   return Colors.purple;
      case 'documents': return Colors.grey;
      default:          return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        appBar: AppBar(
          title: const Text('التذكيرات التلقائية',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1976D2),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _loadSettings),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty ? _buildError() : _buildBody(),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 64, color: Colors.red),
      const SizedBox(height: 16),
      Text(_error, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _loadSettings, child: const Text('إعادة المحاولة')),
    ]));
  }

  Widget _buildBody() {
    return Column(children: [
      _buildHeader(),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: _reminders.length,
          itemBuilder: (ctx, i) => _buildCard(_reminders[i]),
        ),
      ),
    ]);
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1976D2).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1976D2).withOpacity(0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.schedule_rounded, color: Color(0xFF1976D2), size: 36),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('التذكيرات التلقائية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('المنطقة الزمنية: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const Text('اضغط على أي تذكير لإرساله يدوياً',
              style: TextStyle(fontSize: 11, color: Colors.grey)),
        ])),
        _sending
            ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2))
            : ElevatedButton(
                onPressed: () => _triggerReminder('all', 'جميع التذكيرات'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('إرسال الكل', style: TextStyle(fontSize: 12)),
              ),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> rem) {
    final type = rem['type'] as String? ?? '';
    final enabled = rem['enabled'] as bool? ?? false;
    final color = _getColor(type);
    final note = rem['note'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: enabled ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: enabled ? BorderSide(color: color.withOpacity(0.3)) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled && !_sending ? () => _triggerReminder(type, rem['name'] ?? type) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: enabled ? color.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_getIcon(type), color: enabled ? color : Colors.grey, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(rem['name'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                        color: enabled ? Colors.black87 : Colors.grey)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(enabled ? 'مفعّل' : 'قريباً',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                          color: enabled ? color : Colors.grey)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(rem['description'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(rem['schedule'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ]),
              if (note != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.info_outline, size: 13, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(child: Text(note, style: const TextStyle(fontSize: 11, color: Colors.orange))),
                ]),
              ],
            ])),
            if (enabled)
              Icon(Icons.send_rounded, color: color.withOpacity(0.6), size: 20)
            else
              Icon(Icons.lock_outline_rounded, color: Colors.grey[400], size: 20),
          ]),
        ),
      ),
    );
  }
}
""".lstrip()

path = r'lib\screens\manager\reminders\reminder_settings_screen.dart'
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, 'w', encoding='utf-8') as f:
    f.write(dart_code)
print('Done:', path)
