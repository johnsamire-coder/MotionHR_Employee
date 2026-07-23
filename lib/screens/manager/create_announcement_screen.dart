import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

const _kColor = Color(0xFF6C63FF);
const _kBase = 'https://jssolutions-eg.com';

class CreateAnnouncementScreen extends StatefulWidget {
  final Map<String, dynamic>? announcement;

  const CreateAnnouncementScreen({super.key, this.announcement});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  bool get isEditing => widget.announcement != null;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  String _type = 'general';
  String _priority = 'medium';
  String _targetType = 'all';
  bool _requiresConfirmation = false;
  bool _sendPush = true;
  bool _resendNotificationOnEdit = false;
  bool _loading = false;

  List<Map<String, String>> get _types => [
        {'value': 'general', 'label': isAr ? '📢 إعلان عام' : '📢 General'},
        {'value': 'holiday', 'label': isAr ? '🏖️ إجازة رسمية' : '🏖️ Holiday'},
        {'value': 'meeting', 'label': isAr ? '👥 اجتماع' : '👥 Meeting'},
        {'value': 'event', 'label': isAr ? '🎉 فعالية' : '🎉 Event'},
        {'value': 'policy', 'label': isAr ? '📋 سياسة جديدة' : '📋 New Policy'},
        {'value': 'reminder', 'label': isAr ? '🔔 تذكير' : '🔔 Reminder'},
        {'value': 'urgent', 'label': isAr ? '🚨 عاجل' : '🚨 Urgent'},
        {'value': 'celebration', 'label': isAr ? '🎊 مناسبة' : '🎊 Celebration'},
      ];

  List<Map<String, String>> get _priorities => [
        {'value': 'low', 'label': isAr ? 'منخفض' : 'Low'},
        {'value': 'medium', 'label': isAr ? 'متوسط' : 'Medium'},
        {'value': 'high', 'label': isAr ? 'مرتفع' : 'High'},
        {'value': 'urgent', 'label': isAr ? 'عاجل' : 'Urgent'},
      ];

  List<Map<String, String>> get _targets => [
        {'value': 'all', 'label': isAr ? 'كل الموظفين' : 'All Employees'},
        {'value': 'by_department', 'label': isAr ? 'حسب الإدارة' : 'By Department'},
        {'value': 'by_branch', 'label': isAr ? 'حسب الفرع' : 'By Branch'},
      ];

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final ann = widget.announcement!;
      _titleCtrl.text = (ann['title'] ?? '').toString();
      _messageCtrl.text = (ann['message'] ?? '').toString();
      _type = (ann['type'] ?? 'general').toString();
      _priority = (ann['priority'] ?? 'medium').toString();
      _targetType = (ann['target_type'] ?? 'all').toString();
      _requiresConfirmation = ann['requires_confirmation'] == true;
      _sendPush = ann['send_push'] != false;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  String _labelFromList(
    List<Map<String, String>> list,
    String value,
    String fallback,
  ) {
    for (final item in list) {
      if (item['value'] == value) {
        return item['label'] ?? fallback;
      }
    }
    return fallback;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final body = jsonEncode({
        'title': _titleCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'type': _type,
        'priority': _priority,
        'target_type': _targetType,
        'requires_confirmation': _requiresConfirmation,
        'send_push': _sendPush,
        'resend_notification': isEditing ? _resendNotificationOnEdit : false,
      });

      final headers = {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      };

      late http.Response res;

      if (isEditing) {
        res = await http.put(
          Uri.parse(
            '$_kBase/attendance/api/mobile/manager/announcements/${widget.announcement!['id']}/update/',
          ),
          headers: headers,
          body: body,
        );
      } else {
        res = await http.post(
          Uri.parse('$_kBase/attendance/api/mobile/manager/announcements/create/'),
          headers: headers,
          body: body,
        );
      }

      if (!mounted) return;

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode >= 200 && res.statusCode < 300 && data['success'] == true) {
        String message;

        if (isEditing) {
          final resentCount = data['resent_count'] ?? 0;
          if (_resendNotificationOnEdit) {
            message = isAr
                ? 'تم تعديل الإعلان وإعادة الإرسال لـ $resentCount موظف ✅'
                : 'Announcement updated and resent to $resentCount employees ✅';
          } else {
            message = isAr
                ? 'تم تعديل الإعلان بنجاح ✅'
                : 'Announcement updated successfully ✅';
          }
        } else {
          final totalSent = data['total_sent'] ?? 0;
          message = isAr
              ? 'تم نشر الإعلان بنجاح ✅ (اتبعت لـ $totalSent موظف)'
              : 'Announcement published ✅ (sent to $totalSent employees)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (data['error'] ?? data['message'] ?? (isAr ? 'حدث خطأ' : 'Something went wrong')).toString(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'خطأ في الاتصال' : 'Connection error'),
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isEditing
                ? (isAr ? 'تعديل الإعلان' : 'Edit Announcement')
                : (isAr ? 'إنشاء إعلان جديد' : 'Create Announcement'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
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
                              (item) => DropdownMenuItem<String>(
                                value: item['value'],
                                child: Text(item['label'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _type = value ?? 'general');
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
                              (item) => DropdownMenuItem<String>(
                                value: item['value'],
                                child: Text(item['label'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _priority = value ?? 'medium');
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
                              (item) => DropdownMenuItem<String>(
                                value: item['value'],
                                child: Text(item['label'] ?? ''),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() => _targetType = value ?? 'all');
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
                        onChanged: (value) {
                          setState(() => _sendPush = value);
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
                        onChanged: (value) {
                          setState(() => _requiresConfirmation = value);
                        },
                      ),
                      if (isEditing) ...[
                        const Divider(height: 1),
                        SwitchListTile(
                          title: Text(
                            isAr
                                ? 'إعادة إرسال الإشعار بعد التعديل'
                                : 'Resend notification after edit',
                          ),
                          subtitle: Text(
                            isAr
                                ? 'لو فعلتها الموظفون المستهدفون هيوصلهم إشعار جديد'
                                : 'If enabled, targeted employees will receive a new notification',
                          ),
                          secondary: const Icon(Icons.refresh),
                          value: _resendNotificationOnEdit,
                          activeThumbColor: _kColor,
                          onChanged: (value) {
                            setState(() => _resendNotificationOnEdit = value);
                          },
                        ),
                      ],
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
                      Text(
                        '${isAr ? 'النوع' : 'Type'}: ${_labelFromList(_types, _type, _type)}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isAr ? 'الأولوية' : 'Priority'}: ${_labelFromList(_priorities, _priority, _priority)}',
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isAr ? 'المستهدفون' : 'Target'}: ${_labelFromList(_targets, _targetType, _targetType)}',
                      ),
                      if (isEditing) ...[
                        const SizedBox(height: 4),
                        Text(
                          isAr
                              ? 'إعادة الإرسال بعد التعديل: ${_resendNotificationOnEdit ? 'نعم' : 'لا'}'
                              : 'Resend after edit: ${_resendNotificationOnEdit ? 'Yes' : 'No'}',
                        ),
                      ],
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
                    : Icon(isEditing ? Icons.save : Icons.send),
                label: Text(
                  _loading
                      ? (isAr ? 'جاري الحفظ...' : 'Saving...')
                      : isEditing
                          ? (isAr ? 'حفظ التعديلات' : 'Save Changes')
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
