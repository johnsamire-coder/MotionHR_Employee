// lib/screens/manager/payroll/payroll_summary_screen.dart
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
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
                      onPressed: () => setS(() => tempYear--)),
                  Text('$tempYear',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: tempYear < now.year
                          ? () => setS(() => tempYear++)
                          : null),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, childAspectRatio: 1.4),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final m = i + 1;
                  return GestureDetector(
                    onTap: () => setS(() => tempMonth = m),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: tempMonth == m
                            ? const Color(0xFF6A1B9A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(_monthName(m, isAr),
                          style: TextStyle(
                              color: tempMonth == m
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 11)),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'إلغاء' : 'Cancel')),
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

  Future<void> _printPayroll() async {
    if (_data == null) return;
    setState(() => _printing = true);
    try {
      final employees = (_data!['employees'] as List?) ?? [];
      final rows = employees.map<List<String>>((e) {
        final item = Map<String, dynamic>.from(e as Map);
        return [
          item['employee_name']?.toString() ?? '-',
          '${item['basic_salary'] ?? 0}',
          '${item['total_deductions'] ?? 0}',
          '${item['overtime_bonus'] ?? 0}',
          '${item['net_salary'] ?? 0}',
        ];
      }).toList();

      await ReportPdfService.printReport(
        title: isAr ? 'ملخص الرواتب الشهري' : 'Monthly Payroll Summary',
        subtitle:
            '${_monthName(_selectedMonth, isAr)} $_selectedYear',
        headers: isAr
            ? ['اسم الموظف', 'الراتب الأساسي', 'الخصومات', 'Overtime', 'صافي الراتب']
            : ['Employee', 'Basic', 'Deductions', 'Overtime', 'Net'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في الطباعة: $e')));
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];

    return Scaffold(
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
              style: const TextStyle(color: Colors.white, fontSize: 12),
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
                            strokeWidth: 2, color: Colors.white)),
                  )
                : IconButton(
                    onPressed: _printPayroll,
                    icon: const Icon(Icons.print),
                    tooltip: isAr ? 'طباعة الرواتب' : 'Print Payroll',
                  ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  // ─── Grand Summary ────────────────
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_monthName(_selectedMonth, isAr)} $_selectedYear',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                          const Divider(),
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
                                '${_data?['grand_total_salary'] ?? 0}',
                                Colors.purple,
                              ),
                              _statCol(
                                isAr ? 'خصومات' : 'Deductions',
                                '${_data?['grand_total_deductions'] ?? 0}',
                                Colors.red,
                              ),
                              _statCol(
                                isAr ? 'صافي' : 'Net',
                                '${_data?['grand_total_net'] ?? 0}',
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── Employees List ───────────────
                  if (employees.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text(
                          isAr
                              ? 'لا يوجد موظفين'
                              : 'No employees found',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ...employees.map<Widget>((e) {
                      final item =
                          Map<String, dynamic>.from(e as Map);
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF6A1B9A),
                            child: Icon(Icons.person,
                                color: Colors.white),
                          ),
                          title: Text(
                              item['employee_name']?.toString() ?? '-'),
                          subtitle: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAr
                                    ? 'حضور: ${item['attended_days'] ?? 0} | غياب: ${item['absent_days'] ?? 0} | تأخير: ${item['late_days'] ?? 0}'
                                    : 'Present: ${item['attended_days'] ?? 0} | Absent: ${item['absent_days'] ?? 0} | Late: ${item['late_days'] ?? 0}',
                              ),
                              Text(
                                isAr
                                    ? 'صافي الراتب: ${item['net_salary'] ?? 0} ج'
                                    : 'Net: ${item['net_salary'] ?? 0} EGP',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14),
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
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}

String _monthName(int month, bool isAr) {
  const ar = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];
  const en = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return isAr ? ar[month] : en[month];
}