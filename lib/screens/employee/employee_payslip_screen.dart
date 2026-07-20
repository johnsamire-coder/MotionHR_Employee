// lib/screens/employee/employee_payslip_screen.dart
import 'package:flutter/material.dart';
import '../../services/payroll_service.dart';
import '../../services/report_pdf_service.dart';

class EmployeePayslipScreen extends StatefulWidget {
  const EmployeePayslipScreen({super.key});
  @override
  State<EmployeePayslipScreen> createState() =>
      _EmployeePayslipScreenState();
}

class _EmployeePayslipScreenState extends State<EmployeePayslipScreen> {
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
      _data = await _service.getMyPayslip(
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

  Future<void> _print() async {
    if (_data == null) return;
    setState(() => _printing = true);
    try {
      await ReportPdfService.printReport(
        title: isAr ? 'كشف راتب' : 'Payslip',
        subtitle: '${_monthName(_selectedMonth, isAr)} $_selectedYear',
        headers: isAr
            ? ['البند', 'القيمة']
            : ['Item', 'Value'],
        rows: [
          [isAr ? 'الراتب الأساسي' : 'Basic Salary',
            '${_data!['basic_salary'] ?? 0} ج'],
          [isAr ? 'خصم التأخير' : 'Late Deduction',
            '${_data!['late_deduction'] ?? 0} ج'],
          [isAr ? 'خصم الغياب' : 'Absence Deduction',
            '${_data!['absence_deduction'] ?? 0} ج'],
          [isAr ? 'إجمالي الخصومات' : 'Total Deductions',
            '${_data!['total_deductions'] ?? 0} ج'],
          [isAr ? 'بونص Overtime' : 'Overtime Bonus',
            '${_data!['overtime_bonus'] ?? 0} ج'],
          [isAr ? 'صافي الراتب' : 'Net Salary',
            '${_data!['net_salary'] ?? 0} ج'],
        ],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'كشف راتبي' : 'My Payslip'),
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
                    onPressed: _print,
                    icon: const Icon(Icons.print),
                  ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(
                  child: Text(
                    isAr ? 'لا توجد بيانات' : 'No data',
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ─── Header ───────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            isAr ? 'كشف راتب' : 'Payslip',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_monthName(_selectedMonth, isAr)} $_selectedYear',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ─── Salary Card ──────────────────
                    _card(
                      isAr ? 'تفاصيل الراتب' : 'Salary Details',
                      Icons.attach_money,
                      Colors.green,
                      [
                        _row(isAr ? 'الراتب الأساسي' : 'Basic Salary',
                            '${_data!['basic_salary'] ?? 0} ج',
                            Colors.black87),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ─── Deductions ───────────────────
                    _card(
                      isAr ? 'الخصومات' : 'Deductions',
                      Icons.remove_circle_outline,
                      Colors.red,
                      [
                        _row(isAr ? 'خصم التأخير' : 'Late Deduction',
                            '- ${_data!['late_deduction'] ?? 0} ج',
                            Colors.red),
                        _row(isAr ? 'خصم الغياب' : 'Absence Deduction',
                            '- ${_data!['absence_deduction'] ?? 0} ج',
                            Colors.red),
                        const Divider(),
                        _row(isAr ? 'إجمالي الخصومات' : 'Total Deductions',
                            '- ${_data!['total_deductions'] ?? 0} ج',
                            Colors.red,
                            bold: true),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ─── Overtime ─────────────────────
                    _card(
                      isAr ? 'الإضافات' : 'Additions',
                      Icons.add_circle_outline,
                      Colors.blue,
                      [
                        _row(isAr ? 'بونص Overtime' : 'Overtime Bonus',
                            '+ ${_data!['overtime_bonus'] ?? 0} ج',
                            Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ─── Net Salary ───────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.green.shade300, width: 2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isAr ? 'صافي الراتب' : 'Net Salary',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${_data!['net_salary'] ?? 0} ج',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ─── Attendance Summary ───────────
                    _card(
                      isAr ? 'ملخص الحضور' : 'Attendance Summary',
                      Icons.calendar_today,
                      Colors.purple,
                      [
                        _row(isAr ? 'أيام الحضور' : 'Attended Days',
                            '${_data!['attended_days'] ?? 0}', Colors.black87),
                        _row(isAr ? 'أيام الغياب' : 'Absent Days',
                            '${_data!['absent_days'] ?? 0}', Colors.red),
                        _row(isAr ? 'أيام التأخير' : 'Late Days',
                            '${_data!['late_days'] ?? 0}', Colors.orange),
                        _row(isAr ? 'دقائق التأخير' : 'Late Minutes',
                            '${_data!['total_late_minutes'] ?? 0} د',
                            Colors.orange),
                        _row(isAr ? 'ساعات العمل' : 'Work Hours',
                            '${_data!['total_work_hours'] ?? 0} س',
                            Colors.black87),
                        _row(isAr ? 'ساعات Overtime' : 'Overtime Hours',
                            '${_data!['overtime_hours'] ?? 0} س',
                            Colors.blue),
                      ],
                    ),
                  ],
                ),
    );
  }

  Widget _card(String title, IconData icon, Color color,
      List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 16 : 14)),
        ],
      ),
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