import 'package:flutter/material.dart';
import '../../../services/payroll_service.dart';
import 'payroll_employee_detail_screen.dart';

class PayrollSummaryScreen extends StatefulWidget {
  const PayrollSummaryScreen({super.key});
  @override
  State<PayrollSummaryScreen> createState() => _PayrollSummaryScreenState();
}

class _PayrollSummaryScreenState extends State<PayrollSummaryScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _service = PayrollService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await _service.getSummary(); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'ملخص الرواتب' : 'Payroll Summary'),
        actions: [IconButton(onPressed: _load, icon: Icon(Icons.refresh))],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الشهر: ${_data?['month'] ?? '-'} / ${_data?['year'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Divider(),
                          _row(isAr ? 'عدد الموظفين' : 'Total Employees', '${_data?['total_employees'] ?? 0}'),
                          _row(isAr ? 'إجمالي الرواتب' : 'Total Salary', '${_data?['grand_total_salary'] ?? 0} ج'),
                          _row('إجمالي الخصومات', '${_data?['grand_total_deductions'] ?? 0} ج', color: Colors.red),
                          _row('إجمالي Overtime', '${_data?['grand_total_overtime'] ?? 0} ج', color: Colors.blue),
                          const Divider(),
                          _row(isAr ? 'صافي الرواتب' : 'Net Salary', '${_data?['grand_total_net'] ?? 0} ج', color: Colors.green, bold: true),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  if (employees.isEmpty)
                    Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text(isAr ? 'لا يوجد موظفين لعرضهم' : 'No employees found')))),
                  ...employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('حضور: ${item['attended_days'] ?? 0} | غياب: ${item['absent_days'] ?? 0} | تأخير: ${item['late_days'] ?? 0}'),
                            Text('ساعات: ${item['total_work_hours'] ?? 0} | OT: ${item['overtime_hours'] ?? 0}'),
                            Text('صافي: ${item['net_salary'] ?? 0} ج', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PayrollEmployeeDetailScreen(
                            employeeId: item['employee_id'] as int,
                            employeeName: item['employee_name']?.toString() ?? '-',
                          )));
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}
