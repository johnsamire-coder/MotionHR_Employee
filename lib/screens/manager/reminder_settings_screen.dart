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
  bool _isSendingAll = false;
  final Map<String, bool> _sendingMap = {};

  List<Map<String, dynamic>> _buildReminders(bool isAr) {
    return [
      {
        'type': 'checkin',
        'title': isAr ? 'تذكير الحضور' : 'Check-in Reminder',
        'subtitle': isAr
            ? 'للموظفين الذين لم يسجلوا حضورهم'
            : 'For employees who have not checked in yet',
        'time': isAr ? '10:00 صباحًا' : '10:00 AM',
        'icon': Icons.login,
        'color': const Color(0xFF4CAF50),
        'locked': false,
      },
      {
        'type': 'checkout',
        'title': isAr ? 'تذكير الانصراف' : 'Check-out Reminder',
        'subtitle': isAr
            ? 'للموظفين الذين لم يسجلوا انصرافهم'
            : 'For employees who have not checked out yet',
        'time': isAr ? '6:00 مساءً' : '6:00 PM',
        'icon': Icons.logout,
        'color': const Color(0xFFFF9800),
        'locked': false,
      },
      {
        'type': 'pending',
        'title': isAr ? 'الطلبات المعلقة' : 'Pending Requests',
        'subtitle': isAr
            ? 'طلبات معلقة أكثر من 24 ساعة'
            : 'Requests pending for more than 24 hours',
        'time': isAr ? '11:00 صباحًا' : '11:00 AM',
        'icon': Icons.pending_actions,
        'color': const Color(0xFF2196F3),
        'locked': false,
      },
      {
        'type': 'charter',
        'title': isAr ? 'موافقات اللائحة' : 'Charter Acceptances',
        'subtitle': isAr
            ? 'موظفون لم يوافقوا على اللائحة'
            : 'Employees who have not accepted the charter',
        'time': isAr ? '9:30 صباحًا' : '9:30 AM',
        'icon': Icons.fact_check,
        'color': const Color(0xFF9C27B0),
        'locked': false,
      },
      {
        'type': 'documents',
        'title': isAr ? 'المستندات المنتهية' : 'Expired Documents',
        'subtitle': isAr
            ? 'مستندات تنتهي خلال 30 يوم'
            : 'Documents expiring within 30 days',
        'time': isAr ? '8:00 صباحًا' : '8:00 AM',
        'icon': Icons.folder_open,
        'color': const Color(0xFF607D8B),
        'locked': true,
      },
    ];
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _sendReminder(Map<String, dynamic> reminder) async {
    if (reminder['locked'] == true) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final type = reminder['type'] as String;
    final title = reminder['title'] as String;
    final color = reminder['color'] as Color;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAr ? 'تأكيد الإرسال' : 'Confirm Send',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isAr ? 'إرسال $title الآن؟' : 'Send $title now?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isAr ? 'إرسال' : 'Send',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _sendingMap[type] = true);

    try {
      final token = await _getToken();
      final response = await http
          .post(
            Uri.parse(
              'https://jssolutions-eg.com/attendance/api/mobile/manager/reminders/trigger/',
            ),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'type': type}),
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnack(
          isAr
              ? 'تم إرسال: $title بنجاح'
              : 'Sent: $title successfully',
          true,
        );
      } else {
        _showSnack(
          isAr
              ? 'حدث خطأ أثناء الإرسال'
              : 'An error occurred while sending',
          false,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnack(
          isAr ? 'تعذر الاتصال بالسيرفر' : 'Could not connect to the server',
          false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sendingMap[type] = false);
      }
    }
  }

  Future<void> _sendAll() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAr ? 'إرسال الكل' : 'Send All',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isAr ? 'إرسال جميع التذكيرات الآن؟' : 'Send all reminders now?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              isAr ? 'إلغاء' : 'Cancel',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              isAr ? 'إرسال الكل' : 'Send All',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSendingAll = true);

    try {
      final token = await _getToken();
      final response = await http
          .post(
            Uri.parse(
              'https://jssolutions-eg.com/attendance/api/mobile/manager/reminders/trigger/',
            ),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({'type': 'all'}),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSnack(
          isAr
              ? 'تم إرسال جميع التذكيرات بنجاح'
              : 'All reminders sent successfully',
          true,
        );
      } else {
        _showSnack(
          isAr ? 'حدث خطأ أثناء الإرسال' : 'An error occurred while sending',
          false,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnack(
          isAr ? 'تعذر الاتصال بالسيرفر' : 'Could not connect to the server',
          false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingAll = false);
      }
    }
  }

  void _showSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(ok ? Icons.check_circle : Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final reminders = _buildReminders(isAr);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          title: Text(
            isAr ? 'التذكيرات التلقائية' : 'Automatic Reminders',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF2E7D32),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAr
                                  ? 'التذكيرات التلقائية'
                                  : 'Automatic Reminders',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              isAr
                                  ? 'اضغط على أي تذكير لإرساله'
                                  : 'Tap any reminder to send it',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSendingAll ? null : _sendAll,
                      icon: _isSendingAll
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      label: Text(
                        _isSendingAll
                            ? (isAr ? 'جارٍ الإرسال...' : 'Sending...')
                            : (isAr ? 'إرسال الكل' : 'Send All'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white24,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final r = reminders[index];
                  final type = r['type'] as String;
                  final locked = r['locked'] == true;
                  final sending = _sendingMap[type] == true;
                  final color = r['color'] as Color;
                  final icon = r['icon'] as IconData;

                  return GestureDetector(
                    onTap: locked || sending ? null : () => _sendReminder(r),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: locked
                              ? Colors.grey.shade300
                              : color.withOpacity(0.25),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: locked
                                  ? Colors.grey.shade200
                                  : color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: locked ? Colors.grey : color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r['title'] as String,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: locked
                                              ? Colors.grey
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: locked
                                            ? Colors.grey.shade200
                                            : color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        locked
                                            ? (isAr
                                                ? 'قريبًا'
                                                : 'Coming Soon')
                                            : (isAr ? 'مفعّل' : 'Active'),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              locked ? Colors.grey : color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  r['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      r['time'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                if (locked) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        size: 12,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAr
                                            ? 'يتطلب المرحلة 6'
                                            : 'Requires Phase 6',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (sending)
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: color,
                              ),
                            )
                          else if (locked)
                            Icon(Icons.lock, color: Colors.grey[400], size: 16)
                          else
                            Icon(
                              isAr
                                  ? Icons.arrow_back_ios_new
                                  : Icons.arrow_forward_ios,
                              color: color.withOpacity(0.5),
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}