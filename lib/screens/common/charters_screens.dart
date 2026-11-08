// lib/screens/common/charters_screens.dart
//
// لوائح الشركة زي الويب بالظبط:
//   - MyChartersScreen: الموظف (أو المدير لنفسه) بيشوف كل اللوائح اللي تخصه، وبيوافق على كل واحدة لوحدها
//     (زي صفحة "لوائح العمل" في الويب: /api/mobile/charters/my/)
//   - ManageChartersScreen: الـ HR/الأدمن بيدير كل اللوائح (إضافة، تعديل، حذف، لمين، مرفق)
//     (زي صفحة الـ HR في الويب: /api/mobile/manager/charters/)
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_client.dart';
import '../../services/employee_management_service.dart';
import '../../main.dart' show CharterReportScreen;

const String _kBase = 'https://jssolutions-eg.com/attendance/api/mobile';
const Color _kPrimary = Color(0xFF382483);

bool _isAr(BuildContext context) => Localizations.localeOf(context).languageCode == 'ar';

Map<String, dynamic> _decode(http.Response res) {
  try {
    final d = jsonDecode(utf8.decode(res.bodyBytes));
    return d is Map<String, dynamic> ? d : {};
  } catch (_) {
    return {};
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  if (url.isEmpty) return;
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isAr(context) ? 'تعذر فتح الملف' : 'Could not open file')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// الموظف: لوائحي
// ═══════════════════════════════════════════════════════════════
class MyChartersScreen extends StatefulWidget {
  const MyChartersScreen({super.key});
  @override
  State<MyChartersScreen> createState() => _MyChartersScreenState();
}

class _MyChartersScreenState extends State<MyChartersScreen> {
  List<Map<String, dynamic>> _charters = [];
  bool _loading = true;
  int? _acceptingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get(Uri.parse('$_kBase/charters/my/'));
      final data = _decode(res);
      if (res.statusCode == 200) {
        _charters = List<Map<String, dynamic>>.from(
            (data['charters'] as List? ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isAr(context) ? 'فشل تحميل اللوائح' : 'Failed to load regulations')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _accept(int id) async {
    final isAr = _isAr(context);
    setState(() => _acceptingId = id);
    try {
      final res = await ApiClient.post(Uri.parse('$_kBase/charters/$id/accept/'));
      final data = _decode(res);
      if (res.statusCode >= 400 || data['success'] == false) {
        throw Exception(data['error'] ?? (isAr ? 'فشلت الموافقة' : 'Acceptance failed'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم تسجيل موافقتك بنجاح' : 'Your acceptance has been recorded'),
          backgroundColor: Colors.green,
        ));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _acceptingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'لوائح العمل' : 'Work Regulations'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _charters.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Icon(Icons.description_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(isAr ? 'لا توجد لوائح منشورة حالياً' : 'No regulations published yet',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                            isAr
                                ? 'سيقوم قسم الموارد البشرية بنشر اللوائح هنا عند توفرها'
                                : 'HR will publish regulations here when available',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _charters.length,
                      itemBuilder: (_, i) => _card(_charters[i], isAr),
                    ),
            ),
    );
  }

  Widget _card(Map<String, dynamic> c, bool isAr) {
    final accepted = c['accepted'] == true;
    final needs = c['needs_acceptance'] == true;
    final mandatory = c['is_mandatory'] == true;
    final id = c['id'] is int ? c['id'] as int : int.tryParse('${c['id']}') ?? 0;
    final attachment = '${c['attachment_url'] ?? ''}';
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: needs ? Colors.amber.shade400 : Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${c['title'] ?? ''}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (accepted)
                  _badge(isAr ? 'تمت الموافقة' : 'Accepted', Colors.green, Icons.check_circle)
                else if (mandatory)
                  _badge(isAr ? 'بانتظار موافقتك' : 'Awaiting your acceptance', Colors.amber.shade800, null),
              ],
            ),
            if ('${c['introduction'] ?? ''}'.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${c['introduction']}', style: TextStyle(color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 8),
            Text('${c['content'] ?? ''}', style: const TextStyle(height: 1.5)),
            if (attachment.isNotEmpty)
              TextButton.icon(
                onPressed: () => _openUrl(context, attachment),
                icon: const Icon(Icons.download, size: 18),
                label: Text('${c['attachment_name'] ?? ''}'.isNotEmpty
                    ? '${c['attachment_name']}'
                    : (isAr ? 'تحميل المرفق' : 'Download attachment')),
              ),
            if (needs) ...[
              const Divider(),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                  onPressed: _acceptingId == null ? () => _accept(id) : null,
                  icon: _acceptingId == id
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(isAr ? 'أوافق على اللائحة' : 'I Accept'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, IconData? icon) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 3)],
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════
// الـ HR / الأدمن: إدارة اللوائح
// ═══════════════════════════════════════════════════════════════
const _kRoleOptions = [
  {'key': 'employee', 'ar': 'موظف', 'en': 'Employee'},
  {'key': 'manager', 'ar': 'مدير', 'en': 'Manager'},
  {'key': 'hr_manager', 'ar': 'مدير موارد بشرية', 'en': 'HR Manager'},
  {'key': 'company_admin', 'ar': 'صاحب الشركة', 'en': 'Company Admin'},
];

class ManageChartersScreen extends StatefulWidget {
  const ManageChartersScreen({super.key});
  @override
  State<ManageChartersScreen> createState() => _ManageChartersScreenState();
}

class _ManageChartersScreenState extends State<ManageChartersScreen> {
  List<Map<String, dynamic>> _charters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get(Uri.parse('$_kBase/manager/charters/'));
      final data = _decode(res);
      if (res.statusCode == 200) {
        _charters = List<Map<String, dynamic>>.from(
            (data['charters'] as List? ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)));
      } else if (res.statusCode == 403 && mounted) {
        // مدير مش HR: يشوف اللوائح اللي تخصه هو
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyChartersScreen()));
        return;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${data['error'] ?? (_isAr(context) ? 'فشل تحميل البيانات' : 'Failed to load')}')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isAr(context) ? 'فشل تحميل البيانات' : 'Failed to load')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openForm([Map<String, dynamic>? charter]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CharterFormScreen(charter: charter)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    final isAr = _isAr(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حذف اللائحة' : 'Delete regulation'),
        content: Text(isAr ? 'متأكد إنك عايز تحذف "${c['title']}"؟' : 'Delete "${c['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await ApiClient.delete(Uri.parse('$_kBase/manager/charters/${c['id']}/delete/'));
      final data = _decode(res);
      if (res.statusCode >= 400 || data['success'] == false) {
        throw Exception(data['error'] ?? (isAr ? 'فشل الحذف' : 'Delete failed'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr ? 'تم حذف اللائحة' : 'Regulation deleted'), backgroundColor: Colors.green));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'.replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
  }

  // مين وافق ومين لسه على اللائحة دي (للموظفين اللي تخصهم بس)
  Future<void> _report(Map<String, dynamic> c) async {
    final isAr = _isAr(context);
    try {
      final res = await ApiClient.get(
          Uri.parse('$_kBase/manager/charter/acceptances/?charter_id=${c['id']}'));
      final data = _decode(res);
      if (res.statusCode != 200 || data['success'] != true) {
        throw Exception(data['error'] ?? (isAr ? 'فشل تحميل البيانات' : 'Failed to load'));
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CharterReportScreen(
            accepted: (data['accepted']?['employees'] as List?) ?? [],
            pending: (data['pending']?['employees'] as List?) ?? [],
            charterTitle: '${data['charter_title'] ?? c['title'] ?? ''}',
            charterVersion: int.tryParse('${data['charter_version'] ?? c['version'] ?? 1}') ?? 1,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'.replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
  }

  String _targets(Map<String, dynamic> c, bool isAr) {
    final parts = <String>[];
    final roles = (c['target_roles'] as List? ?? []).map((r) {
      final o = _kRoleOptions.firstWhere((x) => x['key'] == r, orElse: () => {'ar': '$r', 'en': '$r'});
      return isAr ? o['ar']! : o['en']!;
    }).toList();
    if (roles.isNotEmpty) parts.add(roles.join('، '));
    final depts = (c['target_department_names'] as List? ?? []).map((e) => '$e').toList();
    if (depts.isNotEmpty) parts.add(depts.join('، '));
    final branches = (c['target_branch_names'] as List? ?? []).map((e) => '$e').toList();
    if (branches.isNotEmpty) parts.add(branches.join('، '));
    return parts.isEmpty ? (isAr ? 'كل الموظفين' : 'All employees') : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'لوائح العمل' : 'Work Regulations'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: Text(isAr ? 'إنشاء لائحة جديدة' : 'New regulation'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _charters.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 120),
                      Icon(Icons.description_outlined, size: 72, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Center(child: Text(isAr ? 'لا توجد لوائح بعد' : 'No regulations yet')),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                      itemCount: _charters.length,
                      itemBuilder: (_, i) {
                        final c = _charters[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Row(children: [
                              Expanded(
                                child: Text('${c['title'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              if (c['is_mandatory'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(isAr ? 'إجباري' : 'Mandatory',
                                      style: TextStyle(fontSize: 11, color: Colors.amber.shade900)),
                                ),
                            ]),
                            subtitle: Text(
                              '${_targets(c, isAr)}\n${isAr ? 'الإصدار' : 'Version'} ${c['version'] ?? 1}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) => v == 'edit'
                                  ? _openForm(c)
                                  : v == 'report'
                                      ? _report(c)
                                      : _delete(c),
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'edit', child: Text(isAr ? 'تعديل' : 'Edit')),
                                PopupMenuItem(
                                    value: 'report', child: Text(isAr ? 'مين وافق ومين لسه' : 'Who accepted')),
                                PopupMenuItem(
                                    value: 'delete',
                                    child: Text(isAr ? 'حذف' : 'Delete',
                                        style: const TextStyle(color: Colors.red))),
                              ],
                            ),
                            onTap: () => _openForm(c),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class CharterFormScreen extends StatefulWidget {
  final Map<String, dynamic>? charter;
  const CharterFormScreen({super.key, this.charter});
  @override
  State<CharterFormScreen> createState() => _CharterFormScreenState();
}

class _CharterFormScreenState extends State<CharterFormScreen> {
  final _titleCtrl = TextEditingController();
  final _introCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _mandatory = true;
  final Set<String> _roles = {};
  final Set<int> _depts = {};
  final Set<int> _branches = {};
  List<Map<String, dynamic>> _deptList = [];
  List<Map<String, dynamic>> _branchList = [];
  PlatformFile? _file;
  bool _saving = false;

  bool get _isEdit => widget.charter != null;

  static Set<int> _ids(dynamic list) =>
      (list as List? ?? []).map((e) => e is int ? e : int.tryParse('$e')).whereType<int>().toSet();

  @override
  void initState() {
    super.initState();
    final c = widget.charter;
    if (c != null) {
      _titleCtrl.text = '${c['title'] ?? ''}';
      _introCtrl.text = '${c['introduction'] ?? ''}';
      _contentCtrl.text = '${c['content'] ?? ''}';
      _mandatory = c['is_mandatory'] != false;
      _roles.addAll((c['target_roles'] as List? ?? []).map((e) => '$e'));
      _depts.addAll(_ids(c['target_departments']));
      _branches.addAll(_ids(c['target_branches']));
    }
    _loadLookups();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _introCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final r = await Future.wait([
        EmployeeManagementService.getDepartments(),
        EmployeeManagementService.getBranches(),
      ]);
      if (mounted) setState(() { _deptList = r[0]; _branchList = r[1]; });
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;
    setState(() => _file = result.files.first);
  }

  Future<void> _save() async {
    final isAr = _isAr(context);
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'العنوان والمحتوى مطلوبين' : 'Title and content are required'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final url = _isEdit
          ? '$_kBase/manager/charters/${widget.charter!['id']}/update/'
          : '$_kBase/manager/charters/create/';
      final req = http.MultipartRequest(_isEdit ? 'PUT' : 'POST', Uri.parse(url));
      req.headers.addAll(await ApiClient.buildHeaders());
      req.fields['title'] = _titleCtrl.text.trim();
      req.fields['introduction'] = _introCtrl.text.trim();
      req.fields['content'] = _contentCtrl.text.trim();
      req.fields['is_mandatory'] = _mandatory ? 'true' : 'false';
      req.fields['target_roles'] = jsonEncode(_roles.toList());
      req.fields['target_departments'] = jsonEncode(_depts.toList());
      req.fields['target_branches'] = jsonEncode(_branches.toList());
      if (_file?.path != null) {
        req.files.add(await http.MultipartFile.fromPath('attachment', _file!.path!, filename: _file!.name));
      }
      final res = await http.Response.fromStream(await req.send());
      final data = _decode(res);
      if (res.statusCode >= 400 || data['success'] == false) {
        throw Exception(data['error'] ?? (isAr ? 'فشل الحفظ' : 'Save failed'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit
              ? (isAr ? 'تم تحديث اللائحة' : 'Regulation updated')
              : (isAr ? 'تم إنشاء اللائحة' : 'Regulation created')),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$e'.replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  Widget _chips<T>(String title, List<MapEntry<T, String>> options, Set<T> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: options
              .map((o) => FilterChip(
                    label: Text(o.value),
                    selected: selected.contains(o.key),
                    onSelected: (v) => setState(() => v ? selected.add(o.key) : selected.remove(o.key)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = _isAr(context);
    final currentAttachment = '${widget.charter?['attachment_name'] ?? ''}';
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? (isAr ? 'تعديل اللائحة' : 'Edit regulation')
            : (isAr ? 'إنشاء لائحة جديدة' : 'New regulation')),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: isAr ? 'العنوان' : 'Title',
              hintText: isAr ? 'مثال: لائحة المديرين' : 'e.g. Managers regulation',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _introCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: isAr ? 'مقدمة (اختياري)' : 'Introduction (optional)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contentCtrl,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: isAr ? 'المحتوى' : 'Content',
              hintText: isAr ? 'بنود اللائحة...' : 'Regulation items...',
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(isAr ? 'إجباري (لازم الموظف يوافق)' : 'Mandatory (employee must accept)'),
            value: _mandatory,
            onChanged: (v) => setState(() => _mandatory = v),
          ),
          Text(
            isAr
                ? 'لو ماختارتش أدوار أو أقسام أو فروع، اللائحة بتطبق على كل الموظفين'
                : 'Leave roles, departments and branches empty to apply to all employees',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          _chips<String>(
            isAr ? 'الأدوار' : 'Roles',
            _kRoleOptions.map((r) => MapEntry(r['key']!, isAr ? r['ar']! : r['en']!)).toList(),
            _roles,
          ),
          if (_deptList.isNotEmpty)
            _chips<int>(
              isAr ? 'الأقسام' : 'Departments',
              _deptList
                  .where((d) => d['id'] is int)
                  .map((d) => MapEntry(d['id'] as int, '${d['name_ar'] ?? d['name'] ?? d['id']}'))
                  .toList(),
              _depts,
            ),
          if (_branchList.isNotEmpty)
            _chips<int>(
              isAr ? 'الفروع' : 'Branches',
              _branchList
                  .where((b) => b['id'] is int)
                  .map((b) => MapEntry(b['id'] as int, '${b['name_ar'] ?? b['name'] ?? b['id']}'))
                  .toList(),
              _branches,
            ),
          const SizedBox(height: 16),
          Text(isAr ? 'ملف مرفق (اختياري)' : 'Attachment (optional)',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(children: [
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(isAr ? 'اختر ملف' : 'Choose file'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _file?.name ?? currentAttachment,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
            ),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => Navigator.pop(context),
                child: Text(isAr ? 'إلغاء' : 'Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isAr ? 'حفظ' : 'Save'),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
