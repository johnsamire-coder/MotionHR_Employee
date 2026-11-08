// lib/screens/manager/reports/server_table_report_screen.dart
//
// شاشة واحدة لتقارير الويب اللي بتعرض جدول من السيرفر بنفس الشكل:
// كشف تحويلات البنك، العقود المنتهية، التقرير التنفيذي، التأمينات، السلف والقروض،
// أداء المهام، رد المصروفات، الضرائب، معدل دوران الموظفين.
// نفس أسماء الأعمدة اللي في الويب، ونفس ملفات التصدير (Excel و PDF) من السيرفر.
import 'package:flutter/material.dart';

import 'report_common.dart';

class ServerReportDef {
  final String slug;
  final String titleAr;
  final String titleEn;
  final IconData icon;
  final Color color;
  const ServerReportDef(this.slug, this.titleAr, this.titleEn, this.icon, this.color);
}

const kServerTableReports = <ServerReportDef>[
  ServerReportDef('bank-transfer', 'كشف تحويلات البنك', 'Bank Transfer', Icons.account_balance, Colors.indigo),
  ServerReportDef('contracts-expiry', 'العقود المنتهية', 'Contracts Expiry', Icons.event_busy, Colors.deepOrange),
  ServerReportDef('executive-dashboard', 'التقرير التنفيذي', 'Executive Dashboard', Icons.insights, Colors.blueGrey),
  ServerReportDef('insurance', 'التأمينات', 'Insurance', Icons.health_and_safety, Colors.blue),
  ServerReportDef('loans-advances', 'السلف والقروض', 'Loans & Advances', Icons.payments, Colors.brown),
  ServerReportDef('missions-performance', 'أداء المهام', 'Missions Performance', Icons.task_alt, Colors.teal),
  ServerReportDef('reimbursements', 'رد المصروفات', 'Reimbursements', Icons.receipt_long, Colors.purple),
  ServerReportDef('tax', 'الضرائب', 'Tax Report', Icons.request_quote, Colors.red),
  ServerReportDef('turnover', 'معدل دوران الموظفين', 'Turnover', Icons.sync_alt, Colors.cyan),
];

// نفس أسماء الأعمدة اللي في صفحات الويب
const _labelsAr = {
  'employee_id': 'ID', 'employee_code': 'الكود', 'employee_name': 'اسم الموظف',
  'department': 'القسم', 'branch': 'الفرع', 'bank_name': 'البنك',
  'account_number': 'رقم الحساب', 'iban': 'IBAN', 'amount': 'المبلغ',
  'insurance_number': 'رقم التأمين', 'basic_salary': 'الراتب الأساسي',
  'insurance_base': 'الأساس التأميني', 'insurance_amount': 'مبلغ التأمين',
  'tax_amount': 'الضريبة', 'metric': 'البند', 'value': 'القيمة',
  'branch_name': 'الفرع', 'employees_count': 'عدد الموظفين',
  'total_salary': 'إجمالي الرواتب', 'avg_salary': 'متوسط الراتب',
  'max_salary': 'أعلى راتب', 'min_salary': 'أقل راتب',
  'contract_end': 'تاريخ الانتهاء', 'status': 'الحالة', 'days': 'الأيام',
  'type': 'النوع', 'subject': 'الموضوع', 'created_at': 'التاريخ',
  'total_missions': 'إجمالي المهام', 'completed': 'المكتملة',
  'in_progress': 'جاري تنفيذها', 'pending': 'معلقة',
  'completion_rate': 'نسبة الإنجاز %',
};

class ServerTableReportScreen extends StatefulWidget {
  final ServerReportDef def;
  const ServerTableReportScreen({super.key, required this.def});
  @override
  State<ServerTableReportScreen> createState() => _ServerTableReportScreenState();
}

class _ServerTableReportScreenState extends State<ServerTableReportScreen> {
  Map<String, dynamic>? _data;
  String _error = '';
  bool _loading = true;
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
      _data = await getJson(Uri.parse('$kReportsApi/${widget.def.slug}/'),
          fallbackError: isAr ? 'فشل تحميل البيانات' : 'Failed');
    } catch (e) {
      _error = '$e'.replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  void _export(String kind) => downloadAndShare(
        context,
        Uri.parse(kind == 'pdf'
            ? '$kReportsApi/${widget.def.slug}/export/pdf/'
            : '$kReportsApi/${widget.def.slug}/export/'),
        '${widget.def.slug}.${kind == 'pdf' ? 'pdf' : 'xlsx'}',
      );

  String _label(String k) => isAr ? (_labelsAr[k] ?? k) : k.replaceAll('_', ' ');

  String _cell(dynamic v) {
    if (v == null) return '—';
    if (v is num) return fmtNum(v);
    if (v is Map || v is List) return v.toString();
    final s = '$v';
    return s.isEmpty ? '—' : s;
  }

  @override
  Widget build(BuildContext context) {
    final rows = mapList(_data?['results']);
    final cols = rows.isNotEmpty ? rows.first.keys.toList() : <String>[];
    // أول عمود فيه اسم بيبقى عنوان الكارت
    final titleKey = const ['employee_name', 'branch_name', 'metric', 'employee_code']
        .firstWhere((k) => cols.contains(k), orElse: () => cols.isNotEmpty ? cols.first : '');
    final q = _search.trim().toLowerCase();
    final shown = q.isEmpty
        ? rows
        : rows.where((r) => r.values.any((v) => '$v'.toLowerCase().contains(q))).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? widget.def.titleAr : widget.def.titleEn),
        backgroundColor: kReportColor,
        foregroundColor: Colors.white,
        actions: [
          if (_data != null) exportMenu(context, _export),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      Text('${_data?['count'] ?? rows.length} ${isAr ? 'سجل' : 'records'}',
                          style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      if (rows.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                      if (rows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Center(child: Text(isAr ? 'لا توجد بيانات' : 'No data')),
                        ),
                      for (final r in shown)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (titleKey.isNotEmpty)
                                  Text(_cell(r[titleKey]),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                for (final c in cols.where((c) => c != titleKey))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      SizedBox(
                                        width: 130,
                                        child: Text(_label(c),
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      ),
                                      Expanded(child: Text(_cell(r[c]), style: const TextStyle(fontSize: 13))),
                                    ]),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}
