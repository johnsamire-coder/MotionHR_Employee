import 'package:flutter/material.dart';

import '../../../services/payroll_service.dart';
import '../../../services/report_pdf_service.dart';
import 'payroll_employee_detail_screen.dart';

class PayrollSummaryScreen extends StatefulWidget {
  const PayrollSummaryScreen({super.key});

  @override
  State<PayrollSummaryScreen> createState() => _PayrollSummaryScreenState();
}

class _PayrollSummaryScreenState extends State<PayrollSummaryScreen> {
  final _service = PayrollService();

  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _service.getSummary(
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'خطأ: $e' : 'Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isAr ? 'اختر الشهر' : 'Select Month'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setS(() => tempYear--),
                  ),
                  Text(
                    '$tempYear',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: tempYear < now.year
                        ? () => setS(() => tempYear++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.4,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final m = i + 1;
                  final selected = m == tempMonth;
                  return GestureDetector(
                    onTap: () => setS(() => tempMonth = m),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF6A1B9A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _monthName(m, isAr),
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black87,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedYear = tempYear;
                  _selectedMonth = tempMonth;
                });
                Navigator.pop(ctx);
                _load();
              },
              child: Text(isAr ? 'تأكيد' : 'Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPrintDialog() async {
    final lang = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'اختر لغة الطباعة' : 'Print Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language, color: Colors.green),
              title: const Text('طباعة بالعربية'),
              onTap: () => Navigator.pop(ctx, 'ar'),
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blue),
              title: const Text('Print in English'),
              onTap: () => Navigator.pop(ctx, 'en'),
            ),
          ],
        ),
      ),
    );

    if (lang != null) {
      await _printPayroll(lang: lang);
    }
  }

  Future<void> _printPayroll({String lang = 'ar'}) async {
    if (_data == null) return;
    setState(() => _printing = true);
    try {
      final employees = (_data!['employees'] as List?) ?? [];
      final rows = employees.map<List<String>>((e) {
        final item = Map<String, dynamic>.from(e as Map);
        return [
          item['employee_name']?.toString() ?? '-',
          '${item['basic_salary'] ?? 0}',
          '${item['allowances_total'] ?? 0}',
          '${item['total_deductions'] ?? 0}',
          '${item['net_salary'] ?? 0}',
        ];
      }).toList();

      await ReportPdfService.printReport(
        title: lang == 'ar'
            ? 'ملخص الرواتب الشهري'
            : 'Monthly Payroll Summary',
        subtitle: '${_monthName(_selectedMonth, lang == 'ar')} $_selectedYear',
        headers: lang == 'ar'
            ? ['اسم الموظف', 'الراتب الأساسي', 'البدلات', 'الخصومات', 'صافي الراتب']
            : ['Employee', 'Basic Salary', 'Allowances', 'Deductions', 'Net Salary'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'خطأ في الطباعة: $e' : 'Print error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  String _money(dynamic value) {
    final n = (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0.0;
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    final currency = _data?['employees'] != null &&
            employees.isNotEmpty
        ? (employees.first as Map)['currency'] ?? 'EGP'
        : 'EGP';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'ملخص الرواتب' : 'Payroll Summary'),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
              onPressed: _pickMonth,
              icon: const Icon(Icons.calendar_month, color: Colors.white),
              label: Text(
                '${_monthName(_selectedMonth, isAr)} $_selectedYear',
                style:
                    const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            if (!_loading && _data != null)
              _printing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _showPrintDialog,
                      icon: const Icon(Icons.print),
                      tooltip: isAr ? 'طباعة الرواتب' : 'Print Payroll',
                    ),
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // ── Grand Summary Card ──────────────────────
                    Card(
                      elevation: 3,
                      color: Colors.purple.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_monthName(_selectedMonth, isAr)} $_selectedYear',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _statCol(
                                  isAr ? 'موظفين' : 'Employees',
                                  '${_data?['total_employees'] ?? 0}',
                                  Colors.blue,
                                ),
                                _statCol(
                                  isAr ? 'إجمالي الرواتب' : 'Total Salary',
                                  _money(_data?['grand_total_salary']),
                                  Colors.purple,
                                  sub: currency,
                                ),
                                _statCol(
                                  isAr ? 'البدلات' : 'Allowances',
                                  _money(_data?['grand_total_allowances']),
                                  Colors.teal,
                                  sub: currency,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              children: [
                                _statCol(
                                  isAr ? 'الأوفرتايم' : 'Overtime',
                                  _money(_data?['grand_total_overtime']),
                                  Colors.indigo,
                                  sub: currency,
                                ),
                                _statCol(
                                  isAr ? 'الخصومات' : 'Deductions',
                                  _money(_data?['grand_total_deductions']),
                                  Colors.red,
                                  sub: currency,
                                ),
                                _statCol(
                                  isAr ? 'صافي' : 'Net',
                                  _money(_data?['grand_total_net']),
                                  Colors.green,
                                  sub: currency,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Employees List ──────────────────────────
                    if (employees.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                isAr
                                    ? 'لا يوجد موظفون'
                                    : 'No employees found',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...employees.map<Widget>((e) {
                        final item =
                            Map<String, dynamic>.from(e as Map);
                        final net =
                            double.tryParse('${item['net_salary'] ?? 0}') ??
                                0.0;
                        final netColor = net >= 0
                            ? Colors.green.shade700
                            : Colors.red;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF6A1B9A),
                              child: Icon(Icons.person,
                                  color: Colors.white, size: 20),
                            ),
                            title: Text(
                              item['employee_name']?.toString() ?? '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if ((item['department_name'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    item['department_name'].toString(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  isAr
                                      ? 'حضور: ${item['attended_days'] ?? 0} | غياب: ${item['absent_days'] ?? 0} | تأخير: ${item['late_days'] ?? 0}'
                                      : 'Present: ${item['attended_days'] ?? 0} | Absent: ${item['absent_days'] ?? 0} | Late: ${item['late_days'] ?? 0}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      isAr
                                          ? 'أساسي: ${_money(item['basic_salary'])} | بدلات: ${_money(item['allowances_total'])}'
                                          : 'Basic: ${_money(item['basic_salary'])} | Allow: ${_money(item['allowances_total'])}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueGrey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isAr ? 'صافي' : 'Net',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey),
                                ),
                                Text(
                                  '${_money(item['net_salary'])} $currency',
                                  style: TextStyle(
                                    color: netColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PayrollEmployeeDetailScreen(
                                  employeeId:
                                      item['employee_id'] as int,
                                  employeeName:
                                      item['employee_name']
                                              ?.toString() ??
                                          '-',
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statCol(String label, String value, Color color,
      {String? sub}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color),
        ),
        if (sub != null)
          Text(sub,
              style:
                  const TextStyle(fontSize: 9, color: Colors.grey)),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

String _monthName(int month, bool isAr) {
  const ar = [
    '',
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];
  const en = [
    '',
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return isAr ? ar[month] : en[month];
}