import 'package:motionhr_employee/services/api_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kBase = 'https://jssolutions-eg.com';
const Color _kColor = Color(0xFF382483);

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
 {
  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  // Categories + Types
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCats = true;

  // My Requests
  List<Map<String, dynamic>> _myRequests = [];
  bool _loadingReqs = true;

  bool _didInit = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _loadCategories();
      _loadMyRequests();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCats = true);
    try {
      final res = await http.get(
        Uri.parse('$_kBase/attendance/api/mobile/request-types/'),
        headers: await ApiClient.buildHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final cats = <Map<String, dynamic>>[];
        if (data['categories'] is List) {
          for (final cat in data['categories'] as List) {
            final types = <Map<String, dynamic>>[];
            if (cat['types'] is List) {
              for (final t in cat['types'] as List) {
                types.add({
                  'id': t['id'],
                  'name': (t['name'] ?? '').toString(),
                  'name_en': (t['name_en'] ?? '').toString(),
                  'permission_kind': (t['permission_kind'] ?? 'none').toString(),
                  'requires_amount': t['requires_amount'] ?? false,
                  'requires_date_range': t['requires_date_range'] ?? false,
                  'requires_document': t['requires_document'] ?? false,
                  'requires_approval': t['requires_approval'] ?? true,
                  'form_schema': t['form_schema'] ?? {},
                });
              }
            }
            if (types.isNotEmpty) {
              cats.add({
                'id': cat['id'],
                'name': (cat['name'] ?? '').toString(),
                'name_en': (cat['name_en'] ?? '').toString(),
                'icon': (cat['icon'] ?? 'bi-list').toString(),
                'color': (cat['color'] ?? '#6750A4').toString(),
                'types': types,
              });
            }
          }
        }
        setState(() => _categories = cats);
      }
    } catch (_) {}
    setState(() => _loadingCats = false);
  }

  Future<void> _loadMyRequests() async {
    setState(() => _loadingReqs = true);
    try {
      final res = await http.get(
        Uri.parse('$_kBase/attendance/api/mobile/my-requests/'),
        headers: await ApiClient.buildHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _myRequests = List<Map<String, dynamic>>.from(
            data['requests'] ?? data['items'] ?? [],
          );
        });
      }
    } catch (_) {}
    setState(() => _loadingReqs = false);
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return _kColor;
    }
  }

  IconData _parseIcon(String icon) {
    final map = {
      'bi-clock-history': Icons.access_time,
      'bi-cash-coin': Icons.payments,
      'bi-person-badge': Icons.badge,
      'bi-gear': Icons.settings,
      'bi-chat-square-text': Icons.chat_bubble_outline,
      'assignment': Icons.assignment,
      'payments': Icons.payments,
      'access_time': Icons.access_time,
      'more_horiz': Icons.more_horiz,
    };
    return map[icon] ?? Icons.list_alt;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            _isAr ? 'الطلبات' : 'Requests',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _kColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                _loadCategories();
                _loadMyRequests();
              },
            ),
          ],
        ),
        body: _buildNewRequestTab(),
      ),
    );
  }

  Widget _buildNewRequestTab() {
    if (_loadingCats) {
      return const Center(child: CircularProgressIndicator(color: _kColor));
    }
    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _isAr ? 'لا توجد أنواع طلبات متاحة' : 'No request types available',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _categories.length,
        itemBuilder: (_, i) => _buildCategoryCard(_categories[i]),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat) {
    final color = _parseColor(cat['color'] as String? ?? '#6750A4');
    final icon = _parseIcon(cat['icon'] as String? ?? '');
    final name = _isAr
        ? (cat['name'] as String? ?? '')
        : (cat['name_en'] as String? ?? cat['name'] as String? ?? '');
    final types = cat['types'] as List<Map<String, dynamic>>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          name,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 16),
        ),
        subtitle: Text(
          _isAr
              ? '${types.length} نوع طلب'
              : '${types.length} request type${types.length != 1 ? 's' : ''}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        children: types
            .map((t) => _buildTypeItem(t, color))
            .toList(),
      ),
    );
  }

  Widget _buildTypeItem(Map<String, dynamic> type, Color catColor) {
    final name = _isAr
        ? (type['name'] as String? ?? '')
        : (type['name_en'] as String? ?? type['name'] as String? ?? '');
    final kind = type['permission_kind'] as String? ?? 'none';
    final hasPermission = kind == 'late_arrival' || kind == 'early_leave';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        hasPermission ? Icons.access_time : Icons.description_outlined,
        color: catColor,
        size: 20,
      ),
      title: Text(name, style: const TextStyle(fontSize: 14)),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 14, color: Colors.grey[400]),
      onTap: () => _openRequestForm(type, catColor),
    );
  }

  void _openRequestForm(Map<String, dynamic> type, Color catColor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestFormScreen(
          requestType: type,
          catColor: catColor,
          isAr: _isAr,
          onSubmitted: () {
            _loadMyRequests();
          },
        ),
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    if (_loadingReqs) {
      return const Center(child: CircularProgressIndicator(color: _kColor));
    }
    if (_myRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _isAr ? 'لا توجد طلبات بعد' : 'No requests yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myRequests.length,
        itemBuilder: (_, i) => _buildRequestCard(_myRequests[i]),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> req) {
    final status = req['status'] as String? ?? 'pending';
    final statusColors = {
      'pending': Colors.orange,
      'manager_approved': Color(0xFF382483),
      'hr_approved': Color(0xFF382483),
      'approved': Colors.green,
      'rejected': Colors.red,
      'cancelled': Colors.grey,
    };
    final statusLabels = {
      'pending': _isAr ? 'قيد الانتظار' : 'Pending',
      'manager_approved': _isAr ? 'موافقة المدير' : 'Manager Approved',
      'hr_approved': _isAr ? 'موافقة HR' : 'HR Approved',
      'approved': _isAr ? 'موافق عليه' : 'Approved',
      'rejected': _isAr ? 'مرفوض' : 'Rejected',
      'cancelled': _isAr ? 'ملغي' : 'Cancelled',
    };
    final color = statusColors[status] ?? Colors.grey;
    final label = statusLabels[status] ?? status;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.description_outlined, color: color),
        ),
        title: Text(
          req['subject'] as String? ?? req['title'] as String? ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          req['request_type_name'] as String? ??
              req['type'] as String? ?? '',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            label,
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════
// شاشة فورمة الطلب الديناميكية
// ══════════════════════════════════════════════════════════
class RequestFormScreen extends StatefulWidget {
  final Map<String, dynamic> requestType;
  final Color catColor;
  final bool isAr;
  final VoidCallback? onSubmitted;

  const RequestFormScreen({
    super.key,
    required this.requestType,
    required this.catColor,
    required this.isAr,
    this.onSubmitted,
  });

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final Map<String, TextEditingController> _fieldCtrls = {};
  bool _submitting = false;

  bool get _isAr => widget.isAr;
  Map<String, dynamic> get _type => widget.requestType;
  List<dynamic> get _fields =>
      (_type['form_schema'] as Map<String, dynamic>?)?['fields'] as List? ?? [];

  String get _typeName => _isAr
      ? (_type['name'] as String? ?? '')
      : (_type['name_en'] as String? ?? _type['name'] as String? ?? '');

  String get _permissionKind =>
      (_type['permission_kind'] as String? ?? 'none');

  bool get _isPermission =>
      _permissionKind == 'late_arrival' ||
      _permissionKind == 'early_leave';

  @override
  void initState() {
    super.initState();

    final autoTitle = _isAr
        ? (_type['name'] as String? ?? '')
        : (_type['name_en'] as String? ?? _type['name'] as String? ?? '');
    if (autoTitle.trim().isNotEmpty) {
      _titleCtrl.text = autoTitle.trim();
    }

    for (final field in _fields) {
      if (field is Map) {
        final key = field['key'] as String? ?? '';
        if (key.isNotEmpty) {
          _fieldCtrls[key] = TextEditingController();
        }
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final ctrl in _fieldCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) {
      ctrl.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      ctrl.text =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isAr
            ? 'يرجى كتابة عنوان الطلب'
            : 'Please enter request title'),
      ));
      return;
    }

    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final formData = <String, dynamic>{};
      for (final entry in _fieldCtrls.entries) {
        formData[entry.key] = entry.value.text.trim();
      }

      final body = <String, dynamic>{
        'request_type_id': _type['id'],
        'subject': _titleCtrl.text.trim(),
        'details': formData['reason'] ??
            formData['complaint_details'] ??
            formData['suggestion'] ??
            formData['request_details'] ??
            formData['topic'] ??
            '',
        'form_data': formData,
      };

      if (_isPermission) {
        body['permission_date'] = formData['permission_date'] ?? '';
        body['permission_time'] = formData['permission_time'] ?? '';
        body['duration_hours'] = formData['duration_hours'] ?? '';
      }

      if (_type['requires_amount'] == true) {
        body['amount'] = formData['amount'] ?? '';
      }

      if (_type['requires_date_range'] == true) {
        body['start_date'] = formData['start_date'] ?? '';
        body['end_date'] = formData['end_date'] ?? '';
      }

      final res = await http.post(
        Uri.parse('$_kBase/attendance/api/mobile/submit-request/'),
        headers: await ApiClient.buildHeaders(includeContentType: true),
        body: jsonEncode(body),
      );

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? (res.statusCode == 200 || res.statusCode == 201
              ? (_isAr ? 'تم إرسال الطلب بنجاح' : 'Request submitted successfully')
              : (_isAr ? 'حدث خطأ' : 'An error occurred'))),
          backgroundColor:
              data['success'] == true ? Colors.green : Colors.red,
        ));

        if (data['success'] == true) {
          widget.onSubmitted?.call();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${_isAr ? 'خطأ' : 'Error'}: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            _typeName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: widget.catColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_isPermission) _buildPermissionNote(),
              _buildTitleField(),
              const SizedBox(height: 16),
              ..._fields.map((f) => _buildDynamicField(f)),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionNote() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Text(
        _permissionKind == 'late_arrival'
            ? (_isAr
                ? 'هذا الطلب سيعامل كإذن تأخير ويخصم من رصيد الأذونات بعد الموافقة والاستخدام.'
                : 'This request will be treated as a late arrival permission.')
            : (_isAr
                ? 'هذا الطلب سيعامل كإذن خروج مبكر ويخصم من رصيد الأذونات بعد الموافقة.'
                : 'This request will be treated as an early leave permission.'),
        style: TextStyle(color: Colors.orange[900], fontSize: 13),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleCtrl,
      decoration: InputDecoration(
        labelText: _isAr ? 'عنوان الطلب' : 'Request Title',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: (v) => v == null || v.trim().isEmpty
          ? (_isAr ? 'مطلوب' : 'Required')
          : null,
    );
  }

  Widget _buildDynamicField(dynamic field) {
    if (field is! Map) return const SizedBox.shrink();
    final key = (field['key'] as String? ?? '').trim();
    if (key.isEmpty) return const SizedBox.shrink();

    final label = _isAr
        ? (field['label_ar'] as String? ?? key)
        : (field['label_en'] as String? ?? key);
    final type = (field['type'] as String? ?? 'text').toLowerCase();
    final required = field['required'] == true;
    final ctrl = _fieldCtrls[key] ?? TextEditingController();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _buildFieldByType(
        key: key,
        label: label,
        type: type,
        required: required,
        ctrl: ctrl,
        options: field['options'] as List? ?? [],
        field: field,
      ),
    );
  }

  Widget _buildFieldByType({
    required String key,
    required String label,
    required String type,
    required bool required,
    required TextEditingController ctrl,
    required List options,
    required dynamic field,
  }) {
    switch (type) {
      case 'date':
        return TextFormField(
          controller: ctrl,
          readOnly: true,
          onTap: () => _pickDate(ctrl),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          validator: required && ctrl.text.isEmpty
              ? (_) => _isAr ? 'مطلوب' : 'Required'
              : null,
        );

      case 'time':
        return TextFormField(
          controller: ctrl,
          readOnly: true,
          onTap: () => _pickTime(ctrl),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: const Icon(Icons.access_time),
          ),
          validator: required && ctrl.text.isEmpty
              ? (_) => _isAr ? 'مطلوب' : 'Required'
              : null,
        );

      case 'number':
        return TextFormField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (v) {
            if (required && (v == null || v.trim().isEmpty)) {
              return _isAr ? 'مطلوب' : 'Required';
            }
            if (v != null &&
                v.trim().isNotEmpty &&
                double.tryParse(v.trim()) == null) {
              return _isAr ? 'رقم غير صحيح' : 'Invalid number';
            }
            return null;
          },
        );

      case 'textarea':
        return TextFormField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
            alignLabelWithHint: true,
          ),
          validator: (v) => required && (v == null || v.trim().isEmpty)
              ? (_isAr ? 'مطلوب' : 'Required')
              : null,
        );

      case 'select':
        final optionsList = options
            .map((o) => o is Map ? o : <String, dynamic>{})
            .toList();
        return DropdownButtonFormField<String>(
          initialValue: ctrl.text.isEmpty ? null : ctrl.text,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          items: optionsList.map((o) {
            final val = (o['value'] as String? ?? '');
            final lbl = _isAr
                ? (o['label_ar'] as String? ?? val)
                : (o['label_en'] as String? ?? val);
            return DropdownMenuItem<String>(
              value: val,
              child: Text(lbl),
            );
          }).toList(),
          onChanged: (v) {
            setState(() => ctrl.text = v ?? '');
          },
          validator: (v) => required && (v == null || v.isEmpty)
              ? (_isAr ? 'مطلوب' : 'Required')
              : null,
        );

      case 'boolean':
        return Row(
          children: [
            Checkbox(
              value: ctrl.text == 'true',
              activeColor: widget.catColor,
              onChanged: (v) {
                setState(() => ctrl.text = (v ?? false).toString());
              },
            ),
            Text(label),
          ],
        );

      default:
        return TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: (v) => required && (v == null || v.trim().isEmpty)
              ? (_isAr ? 'مطلوب' : 'Required')
              : null,
        );
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : _submit,
        icon: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.send, color: Colors.white),
        label: Text(
          _isAr ? 'إرسال الطلب' : 'Submit Request',
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.catColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}