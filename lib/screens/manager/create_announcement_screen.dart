import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

const kPrimaryColor = Color(0xFF6C63FF);
const kBaseUrl = 'https://jssolutions-eg.com';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
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

  final List<Map<String, String>> _types = [
    {'value': 'general', 'label': '📢 إعلان عام'},
    {'value': 'holiday', 'label': '🏖️ إجازة رسمية'},
    {'value': 'meeting', 'label': '👥 اجتماع'},
    {'value': 'event', 'label': '🎉 فعالية'},
    {'value': 'policy', 'label': '📋 سياسة جديدة'},
    {'value': 'reminder', 'label': '🔔 تذكير'},
    {'value': 'urgent', 'label': '🚨 عاجل'},
    {'value': 'celebration', 'label': '🎊 مناسبة'},
  ];

  final List<Map<String, String>> _priorities = [
    {'value': 'low', 'label': 'منخفض'},
    {'value': 'medium', 'label': 'متوسط'},
    {'value': 'high', 'label': 'مرتفع'},
    {'value': 'urgent', 'label': '🚨 عاجل'},
  ];

  final List<Map<String, String>> _targets = [
    {'value': 'all', 'label': 'كل الموظفين'},
    {'value': 'by_department', 'label': 'حسب الإدارة'},
    {'value': 'by_branch', 'label': 'حسب الفرع'},
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final res = await http.post(
        Uri.parse('$kBaseUrl/attendance/api/mobile/manager/announcements/create/'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نشر الإعلان ✅ (أُرسل لـ ${data['total_sent']} موظف)'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final data = jsonDecode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? isAr ? 'حدث خطأ' : 'An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الاتصال'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _loading = false);
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
    return Scaffold(
      appBar: AppBar(
        title: Text('إنشاء إعلان جديد'),
        backgroundColor: kPrimaryColor,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات الإعلان',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'عنوان الإعلان *',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _messageCtrl,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'محتوى الإعلان *',
                          prefixIcon: Icon(Icons.message),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'المحتوى مطلوب' : null,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعدادات الإعلان',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _type,
                        decoration: InputDecoration(
                          labelText: 'نوع الإعلان',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: _types.map((t) => DropdownMenuItem(
                          value: t['value'],
                          child: Text(t['label']!),
                        )).toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: InputDecoration(
                          labelText: 'الأولوية',
                          prefixIcon: Icon(Icons.flag),
                          border: OutlineInputBorder(),
                        ),
                        items: _priorities.map((p) => DropdownMenuItem(
                          value: p['value'],
                          child: Text(p['label']!),
                        )).toList(),
                        onChanged: (v) => setState(() => _priority = v!),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _targetType,
                        decoration: InputDecoration(
                          labelText: 'المستهدفون',
                          prefixIcon: Icon(Icons.people),
                          border: OutlineInputBorder(),
                        ),
                        items: _targets.map((t) => DropdownMenuItem(
                          value: t['value'],
                          child: Text(t['label']!),
                        )).toList(),
                        onChanged: (v) => setState(() => _targetType = v!),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text('إرسال إشعار Push'),
                        subtitle: Text('إشعار فوري على جوال الموظفين'),
                        secondary: Icon(Icons.notifications_active),
                        value: _sendPush,
                        activeColor: kPrimaryColor,
                        onChanged: (v) => setState(() => _sendPush = v),
                      ),
                      Divider(height: 1),
                      SwitchListTile(
                        title: Text('يتطلب تأكيد القراءة'),
                        subtitle: Text('الموظف لازم يضغط "تأكيد القراءة"'),
                        secondary: Icon(Icons.check_circle_outline),
                        value: _requiresConfirmation,
                        activeColor: kPrimaryColor,
                        onChanged: (v) => setState(() => _requiresConfirmation = v),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.send),
                label: Text(_loading ? 'جاري النشر...' : 'نشر الإعلان'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}