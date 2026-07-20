import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

const _kColor = Color(0xFF6C63FF);
const _kBase = 'https://jssolutions-eg.com';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});
  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends State<CreateAnnouncementScreen> {
  bool get isAr =>
      Localizations.localeOf(context).languageCode == 'ar';

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
        {'value': 'holiday', 'label': isAr ? '🏖️ إجازة رسمية' : '🏖️ Holiday'},
        {'value': 'meeting', 'label': isAr ? '👥 اجتماع' : '👥 Meeting'},
        {'value': 'event', 'label': isAr ? '🎉 فعالية' : '🎉 Event'},
        {'value': 'policy', 'label': isAr ? '📋 سياسة جديدة' : '📋 New Policy'},
        {'value': 'reminder', 'label': isAr ? '🔔 تذكير' : '🔔 Reminder'},
        {'value': 'urgent', 'label': '🚨 ${isAr ? 'عاجل' : 'Urgent'}'},
        {'value': 'celebration', 'label': isAr ? '🎊 مناسبة' : '🎊 Celebration'},
      ];

  List<Map<String, String>> get _priorities => [
        {'value': 'low', 'label': isAr ? 'منخفض' : 'Low'},
        {'value': 'medium', 'label': isAr ? 'متوسط' : 'Medium'},
        {'value': 'high', 'label': isAr ? 'مرتفع' : 'High'},
        {'value': 'urgent', 'label': '🚨 ${isAr ? 'عاجل' : 'Urgent'}'},
      ];

  List<Map<String, String>> get _targets => [
        {'value': 'all', 'label': isAr ? 'كل الموظفين' : 'All Employees'},
        {
          'value': 'by_department',
          'label': isAr ? 'حسب الإدارة' : 'By Department'
        },
        {'value': 'by_branch', 'label': isAr ? 'حسب الفرع' : 'By Branch'},
      ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.post(
        Uri.parse(
            '$_kBase/attendance/api/mobile/manager/announcements/create/'),
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
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'تم نشر الإعلان ✅ (أُرسل لـ ${data['total_sent']} موظف)'
              : 'Announcement published ✅ (sent to ${data['total_sent']} employees)'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['error'] ??
              (isAr ? 'حدث خطأ' : 'An error occurred')),
          backgroundColor: Colors.red,
        ));
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'خطأ في الاتصال' : 'Connection error'),
        backgroundColor: Colors.red,
      ));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              isAr ? 'إنشاء إعلان جديد' : 'Create Announcement'),
          backgroundColor: _kColor,
          foregroundColor: Colors.white,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'معلومات الإعلان' : 'Announcement Info',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            labelText:
                                isAr ? 'عنوان الإعلان *' : 'Title *',
                            prefixIcon: const Icon(Icons.title),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? (isAr
                                      ? 'العنوان مطلوب'
                                      : 'Title is required')
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageCtrl,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: isAr
                                ? 'محتوى الإعلان *'
                                : 'Content *',
                            prefixIcon: const Icon(Icons.message),
                            border: const OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? (isAr
                                      ? 'المحتوى مطلوب'
                                      : 'Content is required')
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr
                              ? 'إعدادات الإعلان'
                              : 'Announcement Settings',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _type,
                          decoration: InputDecoration(
                            labelText: isAr
                                ? 'نوع الإعلان'
                                : 'Announcement Type',
                            prefixIcon:
                                const Icon(Icons.category),
                            border: const OutlineInputBorder(),
                          ),
                          items: _types
                              .map((t) => DropdownMenuItem(
                                    value: t['value'],
                                    child: Text(t['label']!),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _type = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _priority,
                          decoration: InputDecoration(
                            labelText:
                                isAr ? 'الأولوية' : 'Priority',
                            prefixIcon: const Icon(Icons.flag),
                            border: const OutlineInputBorder(),
                          ),
                          items: _priorities
                              .map((p) => DropdownMenuItem(
                                    value: p['value'],
                                    child: Text(p['label']!),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _priority = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _targetType,
                          decoration: InputDecoration(
                            labelText:
                                isAr ? 'المستهدفون' : 'Target',
                            prefixIcon:
                                const Icon(Icons.people),
                            border: const OutlineInputBorder(),
                          ),
                          items: _targets
                              .map((t) => DropdownMenuItem(
                                    value: t['value'],
                                    child: Text(t['label']!),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _targetType = v!),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: Text(isAr
                              ? 'إرسال إشعار Push'
                              : 'Send Push Notification'),
                          subtitle: Text(isAr
                              ? 'إشعار فوري على جوال الموظفين'
                              : 'Instant notification on employee phones'),
                          secondary: const Icon(
                              Icons.notifications_active),
                          value: _sendPush,
                          activeColor: _kColor,
                          onChanged: (v) =>
                              setState(() => _sendPush = v),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(isAr
                              ? 'يتطلب تأكيد القراءة'
                              : 'Requires Reading Confirmation'),
                          subtitle: Text(isAr
                              ? 'الموظف لازم يضغط "تأكيد القراءة"'
                              : 'Employee must confirm reading'),
                          secondary: const Icon(
                              Icons.check_circle_outline),
                          value: _requiresConfirmation,
                          activeColor: _kColor,
                          onChanged: (v) => setState(
                              () => _requiresConfirmation = v),
                        ),
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
                  label: Text(_loading
                      ? (isAr ? 'جاري النشر...' : 'Publishing...')
                      : (isAr ? 'نشر الإعلان' : 'Publish')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kColor,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}