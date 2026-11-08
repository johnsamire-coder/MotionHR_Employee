// lib/screens/manager/hr_leaves_screen.dart
//
// إدارة الإجازات لكل الموظفين (زي صفحة "الإجازات" للـ HR في الويب):
// فلتر بالحالة والشهر، إحصائيات، بحث، موافقة ورفض، إضافة إجازة من الـ HR، وتصدير Excel و PDF.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/api_client.dart';

const String _kBase = 'https://jssolutions-eg.com/attendance/api/mobile';
const Color _kPrimary = Color(0xFF382483);

const _monthsAr = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
const _monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

Map<String, dynamic> _decode(List<int> bytes) {
  try {
    final d = jsonDecode(utf8.decode(bytes));
    return d is Map<String, dynamic> ? d : {};
  } catch (_) {
    return {};
  }
}

class HrLeavesScreen extends StatefulWidget {
  const HrLeavesScreen({super.key});
  @override
  State<HrLeavesScreen> createState() => _HrLeavesScreenState();
}

class _HrLeavesScreenState extends State<HrLeavesScreen> {
  String _status = 'pending';
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String _search = '';
  List<Map<String, dynamic>> _leaves = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;
  int? _busyId;
  bool _exporting = false;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  // نفس فلاتر الويب: المعلق من كل الفترات، الكل في السنة، والباقي في الشهر
  Map<String, String> get _params {
    if (_status == 'pending') return {'status': 'pending', 'all_pending': '1'};
    if (_status == 'all') return {'status': 'all', 'year': '$_year'};
    return {'status': _status, 'year': '$_year', 'month': '$_month'};
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uri = Uri.parse('$_kBase/manager/leaves/list/').replace(queryParameters: _params);
      final res = await ApiClient.get(uri);
      final data = _decode(res.bodyBytes);
      if (res.statusCode != 200 || data['success'] == false) {
        throw Exception(data['error'] ?? (isAr ? 'فشل تحميل الإجازات' : 'Failed to load leaves'));
      }
      _leaves = (data['leaves'] as List? ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      _stats = Map<String, dynamic>.from(data['stats'] as Map? ?? {});
    } catch (e) {
      _leaves = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return _leaves;
    return _leaves.where((l) =>
        '${l['employee_name'] ?? ''}'.toLowerCase().contains(q) ||
        '${l['department'] ?? ''}'.toLowerCase().contains(q) ||
        '${l['leave_type'] ?? ''}'.toLowerCase().contains(q)).toList();
  }

  Future<void> _decide(Map<String, dynamic> l, String action) async {
    var notes = '';
    if (action == 'reject') {
      final ctrl = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'سبب الرفض:' : 'Rejection reason:'),
          content: TextField(controller: ctrl, autofocus: true, maxLines: 2),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAr ? 'رفض' : 'Reject')),
          ],
        ),
      );
      notes = ctrl.text.trim();
      if (ok != true || notes.isEmpty) return;
    }
    setState(() => _busyId = l['id'] as int?);
    try {
      final res = await ApiClient.post(
        Uri.parse('$_kBase/manager/action/'),
        body: jsonEncode({'type': 'leave', 'id': l['id'], 'action': action, 'notes': notes}),
      );
      final data = _decode(res.bodyBytes);
      if (res.statusCode >= 400 || data['success'] == false) {
        throw Exception(data['message'] ?? data['error'] ?? (isAr ? 'فشلت العملية' : 'Action failed'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${data['message'] ?? (action == 'approve' ? (isAr ? 'تمت الموافقة' : 'Approved') : (isAr ? 'تم الرفض' : 'Rejected'))}'),
          backgroundColor: Colors.green,
        ));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'.replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _busyId = null);
  }

  Future<void> _export(String kind) async {
    setState(() => _exporting = true);
    try {
      final uri = Uri.parse('$_kBase/manager/leaves/export/$kind/').replace(queryParameters: _params);
      final res = await ApiClient.get(uri);
      if (res.statusCode != 200) throw Exception();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/leaves.${kind == 'excel' ? 'xlsx' : 'pdf'}');
      await file.writeAsBytes(res.bodyBytes, flush: true);
      await Share.shareXFiles([XFile(file.path)], text: isAr ? 'تقرير الإجازات' : 'Leaves report');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr ? 'فشل التصدير' : 'Export failed'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _pickMonth() async {
    int y = _year, m = _month;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => setS(() => y--), icon: const Icon(Icons.chevron_left)),
            Text('$y'),
            IconButton(onPressed: () => setS(() => y++), icon: const Icon(Icons.chevron_right)),
          ]),
          content: _status == 'all'
              ? Text(isAr ? 'كل شهور السنة' : 'Whole year', textAlign: TextAlign.center)
              : Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(12, (i) => ChoiceChip(
                        label: Text(isAr ? _monthsAr[i] : _monthsEn[i]),
                        selected: m == i + 1,
                        onSelected: (_) => setS(() => m = i + 1),
                      )),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAr ? 'تأكيد' : 'OK')),
          ],
        ),
      ),
    );
    if (ok == true) {
      setState(() { _year = y; _month = m; });
      _load();
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved': return isAr ? 'مقبول' : 'Approved';
      case 'rejected': return isAr ? 'مرفوض' : 'Rejected';
      case 'cancelled': return isAr ? 'ملغي' : 'Cancelled';
      default: return isAr ? 'معلق' : 'Pending';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved': return Colors.green.shade700;
      case 'rejected': return Colors.red.shade700;
      case 'cancelled': return Colors.grey.shade600;
      default: return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الإجازات' : 'Leaves'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        actions: [
          if (_exporting)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              onSelected: _export,
              itemBuilder: (_) => [
                PopupMenuItem(value: 'excel', child: Text(isAr ? 'تصدير Excel' : 'Export Excel')),
                PopupMenuItem(value: 'pdf', child: Text(isAr ? 'تصدير PDF' : 'Export PDF')),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(isAr ? 'إضافة إجازة' : 'Add Leave'),
        onPressed: () async {
          final saved = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => const HrAddLeaveScreen()));
          if (saved == true) _load();
        },
      ),
      body: Column(
        children: [
          // الحالة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                for (final s in const ['pending', 'approved', 'rejected', 'all'])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6),
                    child: ChoiceChip(
                      label: Text(s == 'all' ? (isAr ? 'الكل' : 'All') : _statusLabel(s)),
                      selected: _status == s,
                      onSelected: (_) {
                        setState(() => _status = s);
                        _load();
                      },
                    ),
                  ),
                if (_status != 'pending')
                  ActionChip(
                    avatar: const Icon(Icons.calendar_month, size: 18),
                    label: Text(_status == 'all'
                        ? '$_year'
                        : '${isAr ? _monthsAr[_month - 1] : _monthsEn[_month - 1]} $_year'),
                    onPressed: _pickMonth,
                  ),
              ],
            ),
          ),
          // الإحصائيات
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              _stat(isAr ? 'الإجمالي' : 'Total', _stats['total'], _kPrimary),
              _stat(isAr ? 'المقبولة' : 'Approved', _stats['approved'], Colors.green.shade700),
              _stat(isAr ? 'المعلقة' : 'Pending', _stats['pending'], Colors.orange.shade800),
              _stat(isAr ? 'المرفوضة' : 'Rejected', _stats['rejected'], Colors.red.shade700),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: isAr ? 'بحث بالموظف / القسم / النوع' : 'Search employee / department / type',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: list.isEmpty
                        ? ListView(children: [
                            const SizedBox(height: 100),
                            Center(child: Text(isAr ? 'لا توجد إجازات مطابقة للفلتر' : 'No leaves match the filter')),
                          ])
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                            itemCount: list.length,
                            itemBuilder: (_, i) => _card(list[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, dynamic v, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text('${v ?? 0}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ]),
        ),
      );

  Widget _card(Map<String, dynamic> l) {
    final s = '${l['status'] ?? 'pending'}';
    final c = _statusColor(s);
    final busy = _busyId == l['id'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('${l['employee_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(_statusLabel(s), style: TextStyle(fontSize: 12, color: c)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              [l['department'], l['leave_type']].where((e) => '${e ?? ''}'.isNotEmpty).join(' • '),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              '${isAr ? 'من' : 'From'} ${l['from_date'] ?? '-'}  ${isAr ? 'إلى' : 'to'} ${l['to_date'] ?? '-'}'
              '  •  ${l['days'] ?? '-'} ${isAr ? 'أيام' : 'days'}',
              style: const TextStyle(fontSize: 13),
            ),
            if ('${l['reason'] ?? ''}'.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${l['reason']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ),
            if (s == 'pending') ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: busy ? null : () => _decide(l, 'reject'),
                  child: Text(isAr ? 'رفض' : 'Reject'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: busy ? null : () => _decide(l, 'approve'),
                  child: busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isAr ? 'موافقة' : 'Approve'),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// إضافة إجازة من الـ HR (زي "إضافة إجازة" في الويب)
// ═══════════════════════════════════════════════════════════════
class HrAddLeaveScreen extends StatefulWidget {
  const HrAddLeaveScreen({super.key});
  @override
  State<HrAddLeaveScreen> createState() => _HrAddLeaveScreenState();
}

class _HrAddLeaveScreenState extends State<HrAddLeaveScreen> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _substitutes = [];
  int? _employeeId;
  int? _typeId;
  String? _substituteId;
  DateTime? _start;
  DateTime? _end;
  String _status = 'approved';
  final _reasonCtrl = TextEditingController();
  bool _saving = false;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  static List<Map<String, dynamic>> _list(Map<String, dynamic> d, List<String> keys) {
    for (final k in keys) {
      if (d[k] is List) {
        return (d[k] as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      }
    }
    return [];
  }

  Future<void> _loadLookups() async {
    try {
      final r = await Future.wait([
        ApiClient.get(Uri.parse('$_kBase/manager/employees/?page_size=500')),
        ApiClient.get(Uri.parse('$_kBase/leave-types/')),
        ApiClient.get(Uri.parse('$_kBase/leave-substitutes/')),
      ]);
      var types = _list(_decode(r[1].bodyBytes), ['leave_types', 'results']);
      if (r[1].statusCode != 200) {
        final r2 = await ApiClient.get(Uri.parse('$_kBase/hr/leave-types/'));
        types = _list(_decode(r2.bodyBytes), ['leave_types', 'results']);
      }
      if (!mounted) return;
      setState(() {
        _employees = _list(_decode(r[0].bodyBytes), ['results', 'employees']);
        _types = types;
        _substitutes = _list(_decode(r[2].bodyBytes), ['substitutes', 'results', 'employees']);
      });
    } catch (_) {}
  }

  String? get _empGender {
    final e = _employees.firstWhere((e) => e['id'] == _employeeId, orElse: () => {});
    final g = '${e['gender'] ?? ''}'.toLowerCase();
    if (g == 'male' || g == 'ذكر') return 'male';
    if (g == 'female' || g == 'أنثى') return 'female';
    return null;
  }

  // نفس فلتر الويب: نوع الإجازة الخاص بالستات مايظهرش لموظف راجل والعكس
  List<Map<String, dynamic>> get _filteredTypes => _types.where((t) {
        final r = '${t['gender_restriction'] ?? 'all'}'.toLowerCase();
        if (r == 'female' && _empGender == 'male') return false;
        if (r == 'male' && _empGender == 'female') return false;
        return true;
      }).toList();

  String _fmt(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate(bool start) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: (start ? _start : _end) ?? _start ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (d == null) return;
    setState(() {
      if (start) {
        _start = d;
        if (_end != null && _end!.isBefore(d)) _end = d;
      } else {
        _end = d;
      }
    });
  }

  Future<void> _submit() async {
    if (_employeeId == null || _typeId == null || _start == null || _end == null || _reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'كل الحقول مطلوبة' : 'All fields required')));
      return;
    }
    final type = _types.firstWhere((t) => t['id'] == _typeId, orElse: () => {});
    if ('${type['category'] ?? ''}' == 'sick' && _status == 'approved' && (_substituteId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'الإجازة المرضية تحتاج تحديد موظف بديل' : 'Sick leave requires a substitute employee')));
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await ApiClient.post(
        Uri.parse('$_kBase/hr/create-leave/'),
        body: jsonEncode({
          'employee_id': _employeeId,
          'leave_type_id': _typeId,
          'start_date': _fmt(_start),
          'end_date': _fmt(_end),
          'reason': _reasonCtrl.text.trim(),
          'status': _status,
          if ((_substituteId ?? '').isNotEmpty) 'substitute_employee_id': _substituteId,
        }),
      );
      final data = _decode(res.bodyBytes);
      if (res.statusCode >= 400 || data['success'] == false) {
        throw Exception(data['message'] ?? data['error'] ?? (isAr ? 'فشلت العملية' : 'Failed'));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${data['message'] ?? (isAr ? 'تم بنجاح' : 'Success')}'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'.replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  InputDecoration _dec(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إضافة إجازة' : 'Add Leave'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _employeeId,
            decoration: _dec(isAr ? 'الموظف *' : 'Employee *'),
            items: _employees
                .where((e) => e['id'] is int)
                .map((e) => DropdownMenuItem(
                      value: e['id'] as int,
                      child: Text('${e['full_name'] ?? e['name'] ?? ''}${'${e['employee_code'] ?? ''}'.isNotEmpty ? ' (${e['employee_code']})' : ''}',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() { _employeeId = v; _typeId = null; }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            isExpanded: true,
            value: _typeId,
            decoration: _dec(isAr ? 'نوع الإجازة *' : 'Leave Type *'),
            items: _filteredTypes
                .where((t) => t['id'] is int)
                .map((t) => DropdownMenuItem(value: t['id'] as int, child: Text('${t['name'] ?? ''}')))
                .toList(),
            onChanged: (v) => setState(() => _typeId = v),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(true),
                icon: const Icon(Icons.event),
                label: Text(_start == null ? (isAr ? 'من *' : 'From *') : _fmt(_start)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(false),
                icon: const Icon(Icons.event),
                label: Text(_end == null ? (isAr ? 'إلى *' : 'To *') : _fmt(_end)),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(controller: _reasonCtrl, decoration: _dec(isAr ? 'السبب *' : 'Reason *')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _substituteId,
            decoration: _dec(isAr ? 'الموظف البديل (مطلوب للمرضية)' : 'Substitute Employee (Required for Sick)'),
            items: [
              DropdownMenuItem<String>(value: null, child: Text(isAr ? 'بدون' : 'None')),
              ..._substitutes.map((s) => DropdownMenuItem<String>(
                    value: '${s['id']}',
                    child: Text('${s['name'] ?? ''}${'${s['department'] ?? ''}'.isNotEmpty ? ' - ${s['department']}' : ''}',
                        overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (v) => setState(() => _substituteId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _status,
            decoration: _dec(isAr ? 'الحالة' : 'Status'),
            items: [
              DropdownMenuItem(value: 'approved', child: Text(isAr ? 'موافق عليها' : 'Approved')),
              DropdownMenuItem(value: 'pending', child: Text(isAr ? 'معلقة' : 'Pending')),
            ],
            onChanged: (v) => setState(() => _status = v ?? 'approved'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(46)),
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isAr ? 'إضافة' : 'Add'),
          ),
        ],
      ),
    );
  }
}
