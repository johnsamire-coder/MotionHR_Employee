// lib/screens/manager/reports/overtime_report_screen.dart
//
// تقرير الأوفر تايم (زي الويب): لكل موظف الساعات الفعلية والمحسوبة والمدفوعة والمبلغ،
// والتفاصيل يوم بيوم، وفلتر "ليهم / مالهمش أوفر تايم"، وتصدير Excel من السيرفر.
import 'package:flutter/material.dart';

import '../../../widgets/report_month_picker.dart';
import 'report_common.dart';

class OvertimeReportScreen extends StatefulWidget {
  const OvertimeReportScreen({super.key});
  @override
  State<OvertimeReportScreen> createState() => _OvertimeReportScreenState();
}

class _OvertimeReportScreenState extends State<OvertimeReportScreen> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  Map<String, dynamic>? _data;
  String _error = '';
  bool _loading = true;
  String _filter = 'all'; // all | eligible | not
  String _search = '';

  bool get isAr => reportIsAr(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      _data = await getJson(Uri.parse('$kReportsApi/overtime/?year=$_year&month=$_month'));
    } catch (e) {
      _error = '$e'.replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickMonth() async {
    final r = await showReportMonthPicker(context, initialYear: _year, initialMonth: _month);
    if (r != null) {
      setState(() { _year = r.year; _month = r.month; });
      _load();
    }
  }

  String _h(dynamic v) => '${fmtNum(v)} ${isAr ? 'س' : 'h'}';

  @override
  Widget build(BuildContext context) {
    final emps = mapList(_data?['employees']);
    final totals = Map<String, dynamic>.from(_data?['totals'] as Map? ?? {});
    final q = _search.trim().toLowerCase();
    final shown = emps.where((e) {
      if (_filter == 'eligible' && e['eligible'] != true) return false;
      if (_filter == 'not' && e['eligible'] == true) return false;
      return q.isEmpty || '${e['employee_name']} ${e['employee_code'] ?? ''}'.toLowerCase().contains(q);
    }).toList();
    final eligibleCount = emps.where((e) => asNum(e['overtime_hours']) > 0).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تقرير الأوفر تايم' : 'Overtime Report'),
        backgroundColor: kReportColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Excel',
            onPressed: () => downloadAndShare(context,
                Uri.parse('$kReportsApi/overtime/?year=$_year&month=$_month&export=xlsx'),
                'overtime_${_year}_$_month.xlsx'),
          ),
        ],
      ),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(children: [
            ActionChip(
              avatar: const Icon(Icons.calendar_month, size: 18),
              label: Text('$_month / $_year'),
              onPressed: _pickMonth,
            ),
            const SizedBox(width: 8),
            for (final f in const ['all', 'eligible', 'not'])
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: ChoiceChip(
                  label: Text(f == 'all'
                      ? (isAr ? 'الكل' : 'All')
                      : f == 'eligible'
                          ? (isAr ? 'ليهم أوفر تايم' : 'Eligible')
                          : (isAr ? 'مالهمش' : 'Not eligible'),
                      style: const TextStyle(fontSize: 12)),
                  selected: _filter == f,
                  onSelected: (_) => setState(() => _filter = f),
                ),
              ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(padding: const EdgeInsets.all(12), children: [
                        Row(children: [
                          statTile(isAr ? 'موظفين عندهم أوفر تايم' : 'Employees with OT', '$eligibleCount', kReportColor),
                          statTile(isAr ? 'الفعلية' : 'Actual', _h(totals['overtime_hours']), Colors.blue.shade700),
                        ]),
                        Row(children: [
                          statTile(isAr ? 'المحسوبة' : 'Counted', _h(totals['counted_hours']), Colors.teal),
                          statTile(isAr ? 'المدفوعة' : 'Paid', _h(totals['paid_hours']), Colors.orange.shade800),
                          statTile(isAr ? 'إجمالي المبلغ' : 'Total amount',
                              '${fmtNum(totals['amount'])} ${isAr ? 'ج' : 'EGP'}', Colors.green.shade700),
                        ]),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: isAr ? 'بحث بالاسم أو الكود' : 'Search',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _search = v),
                          ),
                        ),
                        if (shown.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Center(child: Text(isAr ? 'مفيش أوفر تايم في الشهر ده' : 'No overtime this month')),
                          ),
                        for (final e in shown) _employeeCard(e),
                      ]),
                    ),
        ),
      ]),
    );
  }

  Widget _employeeCard(Map<String, dynamic> e) {
    final eligible = e['eligible'] == true;
    final details = mapList(e['details']);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text('${e['employee_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          eligible
              ? '${isAr ? 'الأيام' : 'Days'}: ${fmtNum(e['overtime_days'])} • ${isAr ? 'الفعلية' : 'Actual'} ${_h(e['overtime_hours'])}'
                  ' • ${isAr ? 'المدفوعة' : 'Paid'} ${_h(e['paid_hours'])}'
                  '${e['multiplier'] != null ? ' (× ${fmtNum(e['multiplier'])})' : ''}'
              : (isAr ? 'مالوش أوفر تايم' : 'Not eligible for overtime'),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text('${fmtNum(e['amount'])} ${isAr ? 'ج' : 'EGP'}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
        children: [
          for (final d in details)
            ListTile(
              dense: true,
              title: Text('${d['date'] ?? ''}  ${d['shift'] ?? ''}'),
              subtitle: Text('${isAr ? 'الحضور' : 'In'} ${d['check_in'] ?? '—'} • ${isAr ? 'الانصراف' : 'Out'} ${d['check_out'] ?? '—'}'),
              trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_h(d['overtime_hours']), style: const TextStyle(fontSize: 12)),
                Text(
                  asNum(d['counted_hours']) > 0
                      ? '${isAr ? 'المحسوبة' : 'Counted'} ${_h(d['counted_hours'])}'
                      : (isAr ? 'مايتحسبش' : 'Not counted'),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ]),
            ),
        ],
      ),
    );
  }
}
