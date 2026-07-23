import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

const _kColor = Color(0xFF6C63FF);
const _kBase = 'https://jssolutions-eg.com';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String _type = 'general';
  String _priority = 'medium';
  String _targetType = 'all';
  bool _requiresConfirmation = false;
  bool _sendPush = true;
  bool _loading = false;

  List<Map<String, String>> get _types => [
        {'value': 'general', 'label': isAr ? '📢 إعلان عام' : '📢 General'},
        {'value': 'holiday', 'label': isAr ? '🎌 إجازة رسمية' : '🎌 Holiday'},
        {'value': 'meeting', 'label': isAr ? '👥 اجتماع' : '👥 Meeting'},
        {'value': 'event', 'label': isAr ? '🎉 فعالية' : '🎉 Event'},
        {'value': 'policy', 'label': isAr ? '📋 سياسة جديدة' : '📋 New Policy'},
        {'value': 'reminder', 'label': isAr ? '🔔 تذكير' : '🔔 Reminder'},
        {'value': 'urgent', 'label': isAr ? '🚨 عاجل' : '🚨 Urgent'},
        {
          'value': 'celebration',
          'label': isAr ? '🎊 مناسبة' : '🎊 Celebration'
        },
      ];

  List<Map<String, String>> get _priorities => [
        {'value': 'low', 'label': isAr ? 'منخفض' : 'Low'},
        {'value': 'medium', 'label': isAr ? 'متوسط' : 'Medium'},
        {'value': 'high', 'label': isAr ? 'مرتفع' : 'High'},
        {'value': 'urgent', 'label': isAr ? 'عاجل' : 'Urgent'},
      ];

  List<Map<String, String>> get _targets => [
        {'value': 'all', 'label': isAr ? 'كل الموظفين' : 'All Employees'},
        {
          'value': 'by_department',
          'label': isAr ? 'حسب الإدارة' : 'By Department',
        },
        {
          'value': 'by_branch',
          'label': isAr ? 'حسب الفرع' : 'By Branch',
        },
      ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final token = await AuthStorageService.getSavedToken() ?? '';

    try {
      final res = await http.post(
        Uri.parse('$_kBase/attendance/api/mobile/manager/announcements/create/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': _titleCtrl.text.trim(),
          'message': _messageCtrl.text.trim(),
          'type': _type,
          'priority': _priority,
          'target_type': _targetType,
          'requires_confirmation': _requiresConfirmation,
          'send_push': _sendPush,
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 201 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr
                  ? 'تم نشر الإعلان بنجاح ✅ (اتبعت لـ ${data['total_sent'] ?? 0} موظف)'
                  : 'Announcement published successfully ✅ (sent to ${data['total_sent'] ?? 0} employees)',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['error'] ??
                  data['message'] ??
                  (isAr ? 'حدث خطأ أثناء نشر الإعلان' : 'Failed to publish announcement'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'خطأ في الاتصال' : 'Connection error',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String _typeLabel() {
    final item = _types.firstWhere(
      (e) => e['value'] == _type,
      orElse: () => _types.first,
    );
    return item['label'] ?? _type;
  }

  String _priorityLabel() {
    final item = _priorities.firstWhere(
      (e) => e['value'] == _priority,
      orElse: () => _priorities[1],
    );
    return item['label'] ?? _priority;
  }

  String _targetLabel() {
    final item = _targets.firstWhere(
      (e) => e['value'] == _targetType,
      orElse: () => _targets.first,
    );
    return item['label'] ?? _targetType;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'إنشاء إعلان جديد' : 'Create Announcement'),
          backgroundColor: _kColor,
          foregroundColor: Colors.white,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'معلومات الإعلان' : 'Announcement Info',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          labelText: isAr ? 'عنوان الإعلان *' : 'Title *',
                          prefixIcon: const Icon(Icons.title),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return isAr ? 'العنوان مطلوب' : 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _messageCtrl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: isAr ? 'محتوى الإعلان *' : 'Content *',
                          prefixIcon: const Icon(Icons.message),
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return isAr ? 'المحتوى مطلوب' : 'Content is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'إعدادات الإعلان' : 'Announcement Settings',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration: InputDecoration(
                          labelText: isAr ? 'نوع الإعلان' : 'Announcement Type',
                          prefixIcon: const Icon(Icons.category),
                          border: const OutlineInputBorder(),
                        ),
                        items: _types
                            .map(
                              (t) => DropdownMenuItem<String>(
                                value: t['value'],
                                child: Text(t['label'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _type = v ?? 'general');
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _priority,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الأولوية' : 'Priority',
                          prefixIcon: const Icon(Icons.flag),
                          border: const OutlineInputBorder(),
                        ),
                        items: _priorities
                            .map(
                              (p) => DropdownMenuItem<String>(
                                value: p['value'],
                                child: Text(p['label'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _priority = v ?? 'medium');
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _targetType,
                        decoration: InputDecoration(
                          labelText: isAr ? 'المستهدفون' : 'Target',
                          prefixIcon: const Icon(Icons.people),
                          border: const OutlineInputBorder(),
                        ),
                        items: _targets
                            .map(
                              (t) => DropdownMenuItem<String>(
                                value: t['value'],
                                child: Text(t['label'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          setState(() => _targetType = v ?? 'all');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          isAr ? 'إرسال إشعار فوري' : 'Send Push Notification',
                        ),
                        subtitle: Text(
                          isAr
                              ? 'إشعار فوري على موبايل الموظفين'
                              : 'Instant notification on employee phones',
                        ),
                        secondary: const Icon(Icons.notifications_active),
                        value: _sendPush,
                        activeThumbColor: _kColor,
                        onChanged: (v) {
                          setState(() => _sendPush = v);
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: Text(
                          isAr
                              ? 'يتطلب تأكيد القراءة'
                              : 'Requires Reading Confirmation',
                        ),
                        subtitle: Text(
                          isAr
                              ? 'الموظف لازم يؤكد إنه قرأ الإعلان'
                              : 'Employee must confirm reading',
                        ),
                        secondary: const Icon(Icons.check_circle_outline),
                        value: _requiresConfirmation,
                        activeThumbColor: _kColor,
                        onChanged: (v) {
                          setState(() => _requiresConfirmation = v);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: const Color(0xFFF6F2FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: _kColor.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'ملخص سريع' : 'Quick Summary',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _kColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${isAr ? 'النوع' : 'Type'}: ${_typeLabel()}'),
                      const SizedBox(height: 4),
                      Text('${isAr ? 'الأولوية' : 'Priority'}: ${_priorityLabel()}'),
                      const SizedBox(height: 4),
                      Text('${isAr ? 'المستهدفون' : 'Target'}: ${_targetLabel()}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  _loading
                      ? (isAr ? 'جاري النشر...' : 'Publishing...')
                      : (isAr ? 'نشر الإعلان' : 'Publish Announcement'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}