import os

content = """import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettingsScreen extends StatefulWidget {
  const ReminderSettingsScreen({super.key});
  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {
  bool _isSendingAll = false;

  final List<Map<String, dynamic>> _reminders = [
    {
      'type': 'checkin',
      'title': 'تذكير الحضور',
      'subtitle': 'للموظفين الذين لم يسجلوا حضورهم',
      'time': '10:00 صباحا',
      'icon': 0xe3b0,
      'color': 0xFF4CAF50,
      'locked': false,
      'sending': false,
    },
    {
      'type': 'checkout',
      'title': 'تذكير الانصراف',
      'subtitle': 'للموظفين الذين لم يسجلوا انصرافهم',
      'time': '6:00 مساء',
      'icon': 0xe3b1,
      'color': 0xFFFF9800,
      'locked': false,
      'sending': false,
    },
    {
      'type': 'pending',
      'title': 'الطلبات المعلقة',
      'subtitle': 'طلبات معلقة اكثر من 24 ساعة',
      'time': '11:00 صباحا',
      'icon': 0xf015,
      'color': 0xFF2196F3,
      'locked': false,
      'sending': false,
    },
    {
      'type': 'charter',
      'title': 'موافقات اللائحة',
      'subtitle': 'موظفون لم يوافقوا على اللائحة',
      'time': '9:30 صباحا',
      'icon': 0xe24c,
      'color': 0xFF9C27B0,
      'locked': false,
      'sending': false,
    },
    {
      'type': 'documents',
      'title': 'المستندات المنتهية',
      'subtitle': 'مستندات تنتهي خلال 30 يوم',
      'time': '8:00 صباحا',
      'icon': 0xe2c7,
      'color': 0xFF607D8B,
      'locked': true,
      'sending': false,
    },
  ];

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _sendReminder(String type, int index) async {
    if (_reminders[index]['locked'] == true) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تاكيد الارسال', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('ارسال ${_reminders[index]['title']} الان؟',
            textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('الغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Color(_reminders[index]['color']),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('ارسال', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _reminders[index]['sending'] = true);

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/reminders/send/'),
        headers: {'Authorization': 'Token \$token', 'Content-Type': 'application/json'},
        body: json.encode({'type': type}),
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnack('تم ارسال: ${_reminders[index]['title']} بنجاح', true);
      } else {
        _showSnack('حدث خطا اثناء الارسال', false);
      }
    } catch (_) {
      if (mounted) _showSnack('تعذر الاتصال بالسيرفر', false);
    } finally {
      if (mounted) setState(() => _reminders[index]['sending'] = false);
    }
  }

  Future<void> _sendAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ارسال الكل', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('ارسال جميع التذكيرات الان؟', textAlign: TextAlign.center),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('الغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('ارسال الكل', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _isSendingAll = true);

    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/reminders/send/'),
        headers: {'Authorization': 'Token \$token', 'Content-Type': 'application/json'},
        body: json.encode({'type': 'all'}),
      ).timeout(const Duration(seconds: 60));

      if (!mounted) return;
      if (response.statusCode == 200) {
        _showSnack('تم ارسال جميع التذكيرات بنجاح', true);
      } else {
        _showSnack('حدث خطا', false);
      }
    } catch (_) {
      if (mounted) _showSnack('تعذر الاتصال', false);
    } finally {
      if (mounted) setState(() => _isSendingAll = false);
    }
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(ok ? Icons.check_circle : Icons.error, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: ok ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          title: const Text('التذكيرات التلقائية',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2E7D32),
            child: Column(children: [
              const Row(children: [
                Icon(Icons.notifications_active, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('التذكيرات التلقائية',
                          style: TextStyle(color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('اضغط على اي تذكير لارساله',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ])),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSendingAll ? null : _sendAll,
                  icon: _isSendingAll
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(_isSendingAll ? 'جاري الارسال...' : 'ارسال الكل',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final r = _reminders[index];
                final locked = r['locked'] == true;
                final sending = r['sending'] == true;
                final color = Color(r['color']);

                return GestureDetector(
                  onTap: locked || sending ? null : () => _sendReminder(r['type'], index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: locked ? Colors.grey.shade300 : color.withValues(alpha: 0.25)),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: locked ? Colors.grey.shade200 : color.withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                        child: Icon(
                          IconData(r['icon'], fontFamily: 'MaterialIcons'),
                          color: locked ? Colors.grey : color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(r['title'],
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
                                      color: locked ? Colors.grey : Colors.black87))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                    color: locked ? Colors.grey.shade200 : color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text(locked ? 'قريبا' : 'مفعل',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                                        color: locked ? Colors.grey : color)),
                              ),
                            ]),
                            const SizedBox(height: 4),
                            Text(r['subtitle'],
                                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(r['time'],
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ]),
                            if (locked) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.lock, size: 12, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text('يتطلب المرحلة 6',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ]),
                            ],
                          ])),
                      if (sending)
                        SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: color))
                      else if (locked)
                        Icon(Icons.lock, color: Colors.grey[400], size: 16)
                      else
                        Icon(Icons.arrow_back_ios, color: color.withValues(alpha: 0.5), size: 16),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}
"""

os.makedirs(r'lib\screens\manager', exist_ok=True)
path = r'lib\screens\manager\reminder_settings_screen.dart'
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('File created:', os.path.exists(path))
print('Size:', os.path.getsize(path), 'bytes')