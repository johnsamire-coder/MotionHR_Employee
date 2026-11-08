// lib/screens/manager/reports/eos_report_screen.dart
//
// تقرير مكافأة نهاية الخدمة (زي الويب): المكافآت المستحقة للموظفين حتى تاريخ معين،
// مع تصدير Excel و PDF من السيرفر.
import 'package:flutter/material.dart';

import 'report_common.dart';

class EosReportScreen extends StatefulWidget {
  const EosReportScreen({super.key});
  @override
  State<EosReportScreen> createState() => _EosReportScreenState();
}

class _EosReportScreenState extends State<EosReportScreen> {
  DateTime _asOf = DateTime.now();
  Map<String, dynamic>? _data;
  String _error = '';
  bool _loading = true;
  String _search = '';

  bool get isAr => reportIsAr(context);
  String get _q => 'as_of_date=${fmtDate(_asOf)}';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      _data = await getJson(Uri.parse('$kReportsApi/eos/?$_q'),
          fallbackError: isAr ? 'فشل تحميل البيانات' : 'Failed to load');
    } catch (e) {
      _error = '$e'.replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context, initialDate: _asOf, firstDate: DateTime(2000), lastDate: DateTime(DateTime.now().year + 5));
    if (d != null) {
      setState(() => _asOf = d);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = mapList(_data?['results']);
    final summary = Map<String, dynamic>.from(_data?['summary'] as Map? ?? {});
    final q = _search.trim().toLowerCase();
    final shown = q.isEmpty
        ? rows
        : rows.where((r) => '${r['employee_name']} ${r['employee_code']} ${r['department']}'.toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تقرير مكافأة نهاية الخدمة' : 'End of Service Report'),
        backgroundColor: kReportColor,
        foregroundColor: Colors.white,
        actions: [
          exportMenu(context, (k) => downloadAndShare(
                context,
                Uri.parse(k == 'pdf' ? '$kReportsApi/eos/export/pdf/?$_q' : '$kReportsApi/eos/export/?$_q'),
                'eos_${fmtDate(_asOf)}.${k == 'pdf' ? 'pdf' : 'xlsx'}',
              )),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(12), children: [
                    Row(children: [
                      Text(isAr ? 'احتساب حتى تاريخ:' : 'As of:'),
                      const SizedBox(width: 8),
                      ActionChip(
                          avatar: const Icon(Icons.event, size: 18),
                          label: Text(fmtDate(_asOf)),
                          onPressed: _pickDate),
                    ]),
                    Row(children: [
                      statTile(isAr ? 'عدد الموظفين' : 'Employees', fmtNum(summary['employees_count']), kReportColor),
                      statTile(isAr ? 'إجمالي المكافآت' : 'Total EOS',
                          '${fmtNum(summary['total_eos_amount'])} ${isAr ? 'ج' : 'EGP'}', Colors.green.shade700),
                    ]),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: isAr ? 'بحث' : 'Search',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                    if (shown.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(child: Text(isAr ? 'لا توجد بيانات' : 'No data')),
                      ),
                    for (final r in shown)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${r['employee_name'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            '${r['employee_code'] ?? ''} • ${r['department'] ?? ''} • ${r['branch'] ?? ''}\n'
                            '${isAr ? 'تاريخ التعيين' : 'Hired'}: ${r['hire_date'] ?? '—'} • '
                            '${isAr ? 'سنوات الخدمة' : 'Years'}: ${fmtNum(r['years_of_service'])} • '
                            '${isAr ? 'الأساسي' : 'Basic'}: ${fmtNum(r['basic_salary'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: Text('${fmtNum(r['eos_amount'])}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                        ),
                      ),
                  ]),
                ),
    );
  }
}
