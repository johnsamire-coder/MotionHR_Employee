// lib/screens/manager/audit_log_screen.dart
//
// سجل التعديلات (زي صفحة "سجل التعديلات" في الويب): مين عمل إيه وإمتى، وقبل وبعد كل تعديل.
//   - سجل البرنامج: لصاحب الشركة بس (فلتر بالفترة واليوزر والعملية والبحث)
//   - سجل موظف: كل التعديلات على موظف معين (لصاحب الشركة والـ HR)
// مع تصدير Excel من السيرفر.
import 'package:flutter/material.dart';

import 'reports/report_common.dart';

const String _kAudit = 'https://jssolutions-eg.com/audit/api';

class AuditLogScreen extends StatefulWidget {
  final int? employeeId;
  const AuditLogScreen({super.key, this.employeeId});
  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  late String _tab = widget.employeeId != null ? 'employee' : 'all';
  DateTime _from = DateTime.now().subtract(const Duration(days: 6));
  DateTime _to = DateTime.now();
  String _q = '';
  String _action = '';
  String? _userId;
  int _page = 1;
  int _total = 0;
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _employees = [];
  late int? _empId = widget.employeeId;
  bool _onlyProfile = false;
  bool _loading = false;
  String _error = '';
  final _qCtrl = TextEditingController();

  bool get isAr => reportIsAr(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLookups();
      _load();
    });
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    try {
      final f = await getJson(Uri.parse('$_kAudit/filters/'));
      _users = mapList(f['users']);
    } catch (_) {}
    try {
      final e = await getJson(Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/employees/?page_size=2000'));
      _employees = mapList(e['results'] ?? e['employees']);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Map<String, String> get _logsParams => {
        'date_from': fmtDate(_from),
        'date_to': fmtDate(_to),
        'page': '$_page',
        'page_size': '100',
        if (_q.trim().isNotEmpty) 'q': _q.trim(),
        if (_userId != null) 'user_id': _userId!,
        if (_action.isNotEmpty) 'action': _action,
      };

  Future<void> _load() async {
    if (_tab == 'employee' && _empId == null) {
      setState(() { _rows = []; _error = ''; });
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      if (_tab == 'all') {
        final d = await getJson(Uri.parse('$_kAudit/logs/').replace(queryParameters: _logsParams),
            fallbackError: isAr ? 'فشل تحميل السجل' : 'Failed to load log');
        _rows = mapList(d['logs']);
        _total = asNum(d['total']).toInt();
      } else {
        final d = await getJson(
            Uri.parse('$_kAudit/employee/$_empId/').replace(queryParameters: {if (_onlyProfile) 'only_profile': '1'}),
            fallbackError: isAr ? 'فشل تحميل سجل الموظف' : 'Failed to load employee log');
        _rows = mapList(d['history']);
        _total = _rows.length;
      }
    } catch (e) {
      _rows = [];
      _error = '$e'.replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _export() {
    if (_tab == 'all') {
      final p = Map<String, String>.from(_logsParams)..['export'] = 'xlsx';
      downloadAndShare(context, Uri.parse('$_kAudit/logs/').replace(queryParameters: p),
          'audit_${fmtDate(_from)}_${fmtDate(_to)}.xlsx');
    } else if (_empId != null) {
      downloadAndShare(
          context,
          Uri.parse('$_kAudit/employee/$_empId/').replace(
              queryParameters: {'export': 'xlsx', if (_onlyProfile) 'only_profile': '1'}),
          'employee_${_empId}_history.xlsx');
    }
  }

  Future<void> _range() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (r != null) {
      setState(() { _from = r.start; _to = r.end; _page = 1; });
      _load();
    }
  }

  Color _actionColor(String a) => switch (a) {
        'create' => Colors.green.shade700,
        'delete' => Colors.red.shade700,
        'login' => Colors.blue.shade700,
        _ => Colors.orange.shade800,
      };

  @override
  Widget build(BuildContext context) {
    final pages = (_total / 100).ceil();
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'سجل التعديلات' : 'Audit Log'),
        backgroundColor: kReportColor,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.download), tooltip: 'Excel', onPressed: _export)],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(children: [
            for (final t in const ['all', 'employee'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: SizedBox(
                      width: double.infinity,
                      child: Text(
                          t == 'all' ? (isAr ? 'سجل البرنامج' : 'Program log') : (isAr ? 'سجل موظف' : 'Employee log'),
                          textAlign: TextAlign.center),
                    ),
                    selected: _tab == t,
                    onSelected: (_) {
                      setState(() { _tab = t; _rows = []; _page = 1; });
                      _load();
                    },
                  ),
                ),
              ),
          ]),
        ),
        if (_tab == 'all')
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(children: [
              Row(children: [
                ActionChip(
                    avatar: const Icon(Icons.date_range, size: 18),
                    label: Text('${fmtDate(_from)} → ${fmtDate(_to)}', style: const TextStyle(fontSize: 12)),
                    onPressed: _range),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _action,
                    decoration: InputDecoration(labelText: isAr ? 'العملية' : 'Action', isDense: true, border: const OutlineInputBorder()),
                    items: [
                      DropdownMenuItem(value: '', child: Text(isAr ? 'الكل' : 'All')),
                      DropdownMenuItem(value: 'create', child: Text(isAr ? 'إضافة' : 'Create')),
                      DropdownMenuItem(value: 'update', child: Text(isAr ? 'تعديل' : 'Update')),
                      DropdownMenuItem(value: 'delete', child: Text(isAr ? 'حذف' : 'Delete')),
                      DropdownMenuItem(value: 'login', child: Text(isAr ? 'تسجيل دخول' : 'Login')),
                      DropdownMenuItem(value: 'action', child: Text(isAr ? 'إجراء' : 'Action')),
                    ],
                    onChanged: (v) {
                      setState(() { _action = v ?? ''; _page = 1; });
                      _load();
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: _userId,
                    decoration: InputDecoration(labelText: isAr ? 'اليوزر' : 'User', isDense: true, border: const OutlineInputBorder()),
                    items: [
                      DropdownMenuItem<String?>(value: null, child: Text(isAr ? 'الكل' : 'All')),
                      ..._users.map((u) => DropdownMenuItem<String?>(
                          value: '${u['user_id']}',
                          child: Text('${u['user_name'] ?? ''}'.isNotEmpty ? '${u['user_name']}' : '${u['username'] ?? ''}',
                              overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) {
                      setState(() { _userId = v; _page = 1; });
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: _qCtrl,
                    decoration: InputDecoration(
                      hintText: isAr ? 'اسم موظف أو يوزر...' : 'Employee or user...',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() { _q = _qCtrl.text; _page = 1; });
                          _load();
                        },
                      ),
                    ),
                    onSubmitted: (v) {
                      setState(() { _q = v; _page = 1; });
                      _load();
                    },
                  ),
                ),
              ]),
            ]),
          ),
        if (_tab == 'employee')
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(children: [
              DropdownButtonFormField<int?>(
                isExpanded: true,
                value: _employees.any((e) => e['id'] == _empId) ? _empId : null,
                decoration: InputDecoration(labelText: isAr ? 'اختار موظف' : 'Choose employee', isDense: true, border: const OutlineInputBorder()),
                items: _employees.where((e) => e['id'] is int).map((e) => DropdownMenuItem<int?>(
                    value: e['id'] as int,
                    child: Text('${e['full_name'] ?? e['name'] ?? ''} (${e['employee_code'] ?? ''})', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) {
                  setState(() => _empId = v);
                  _load();
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _onlyProfile,
                title: Text(isAr ? 'بيانات الموظف بس (المرتب والاسم والتليفون...)' : 'Employee data only'),
                onChanged: (v) {
                  setState(() => _onlyProfile = v ?? false);
                  _load();
                },
              ),
            ]),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _rows.isEmpty
                          ? ListView(children: [
                              const SizedBox(height: 80),
                              Center(child: Text(_tab == 'employee' && _empId == null
                                  ? (isAr ? 'اختار موظف' : 'Choose an employee')
                                  : (isAr ? 'مفيش تعديلات في الفترة دي' : 'No changes in this period'))),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _rows.length + (_tab == 'all' && pages > 1 ? 1 : 0),
                              itemBuilder: (_, i) {
                                if (i == _rows.length) {
                                  return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    TextButton(
                                      onPressed: _page > 1 ? () { setState(() => _page--); _load(); } : null,
                                      child: Text(isAr ? 'السابق' : 'Previous'),
                                    ),
                                    Text('$_page / $pages'),
                                    TextButton(
                                      onPressed: _page < pages ? () { setState(() => _page++); _load(); } : null,
                                      child: Text(isAr ? 'التالي' : 'Next'),
                                    ),
                                  ]);
                                }
                                final r = _rows[i];
                                final changes = mapList(r['changes']);
                                final c = _actionColor('${r['action'] ?? ''}');
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Row(children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                          child: Text('${r['action_display'] ?? r['action'] ?? ''}', style: TextStyle(fontSize: 11, color: c)),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text('${r['model_label'] ?? ''} • ${r['object_repr'] ?? ''}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${r['date'] ?? ''} ${r['time'] ?? ''} • ${'${r['user_name'] ?? ''}'.isNotEmpty ? r['user_name'] : (r['username'] ?? (isAr ? 'غير معروف' : 'Unknown'))}'
                                        '${'${r['source_display'] ?? ''}'.isNotEmpty ? ' • ${r['source_display']}' : ''}'
                                        '${_tab == 'all' && '${r['employee_name'] ?? ''}'.isNotEmpty ? ' • ${isAr ? 'الموظف' : 'Employee'}: ${r['employee_name']}' : ''}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                      ),
                                      for (final ch in changes)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text.rich(TextSpan(children: [
                                            TextSpan(text: '${ch['label'] ?? ch['field'] ?? ''}: ',
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                                            TextSpan(text: '${'${ch['old'] ?? ''}'.isEmpty ? '—' : ch['old']}',
                                                style: TextStyle(fontSize: 12, color: Colors.red.shade700, decoration: TextDecoration.lineThrough)),
                                            TextSpan(text: isAr ? '  ←  ' : '  →  ', style: const TextStyle(fontSize: 12)),
                                            TextSpan(text: '${'${ch['new'] ?? ''}'.isEmpty ? '—' : ch['new']}',
                                                style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                                          ])),
                                        ),
                                      if ('${r['note'] ?? ''}'.trim().isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text('${isAr ? 'ملاحظة' : 'Note'}: ${r['note']}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        ),
                                    ]),
                                  ),
                                );
                              },
                            ),
                    ),
        ),
      ]),
    );
  }
}
