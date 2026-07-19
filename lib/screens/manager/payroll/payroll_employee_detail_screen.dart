import 'package:flutter/material.dart';
import '../../../services/payroll_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class PayrollEmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  const PayrollEmployeeDetailScreen({super.key, required this.employeeId, required this.employeeName});

  @override
  State<PayrollEmployeeDetailScreen> createState() => _PayrollEmployeeDetailScreenState();
}

class _PayrollEmployeeDetailScreenState extends State<PayrollEmployeeDetailScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _service = PayrollService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getEmployeeDetail(employeeId: widget.employeeId); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final daily = (_data?['daily_details'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(widget.employeeName)),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _data == null
              ? Center(child: Text(context.l10n.noData))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isAr ? 'الملخص المالي' : 'Financial Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Divider(),
                            _row(context.l10n.basicSalary, '${_data?['basic_salary'] ?? 0} ج'),
                            _row(isAr ? 'خصم التأخير' : 'Late Deduction', '${_data?['late_deduction'] ?? 0} ج', color: Colors.red),
                            _row(isAr ? 'خصم الغياب' : 'Absence Deduction', '${_data?['absence_deduction'] ?? 0} ج', color: Colors.red),
                            _row('إجمالي الخصومات', '${_data?['total_deductions'] ?? 0} ج', color: Colors.red),
                            _row('بونص Overtime', '${_data?['overtime_bonus'] ?? 0} ج', color: Colors.blue),
                            Divider(),
                            _row('صافي الراتب', '${_data?['net_salary'] ?? 0} ج', color: Colors.green, bold: true),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ملخص الحضور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Divider(),
                            _row('أيام الحضور', '${_data?['attended_days'] ?? 0}'),
                            _row('أيام الحاضر (present)', '${_data?['present_days'] ?? 0}'),
                            _row('أيام التأخير', '${_data?['late_days'] ?? 0}', color: Colors.orange),
                            _row('أيام الغياب', '${_data?['absent_days'] ?? 0}', color: Colors.red),
                            _row('أيام الإجازة', '${_data?['on_leave_days'] ?? 0}'),
                            _row('دقائق التأخير', '${_data?['total_late_minutes'] ?? 0} د'),
                            _row('إجمالي ساعات العمل', '${_data?['total_work_hours'] ?? 0} س'),
                            _row('ساعات Overtime', '${_data?['overtime_hours'] ?? 0} س'),
                          ],
                        ),
                      ),
                    ),
                    if (daily.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('التفاصيل اليومية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      ...daily.map<Widget>((d) {
                        final day = Map<String, dynamic>.from(d as Map);
                        final status = day['status']?.toString() ?? '-';
                        final color = status == 'present' ? Colors.green : status == 'late' ? Colors.orange : status == 'absent' ? Colors.red : Colors.grey;
                        return Card(
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.circle, color: color, size: 16),
                            title: Text(day['date']?.toString() ?? '-'),
                            subtitle: Text('دخول: ${day['check_in'] ?? '-'} | خروج: ${day['check_out'] ?? '-'} | ساعات: ${day['work_hours'] ?? 0}'),
                            trailing: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }),
                    ],
                  ],
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
