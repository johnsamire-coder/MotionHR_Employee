// lib/screens/employee/employee_payslip_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/payroll_service.dart';
import '../../services/report_pdf_service.dart';
import '../../services/payslip_breakdown.dart';

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
  bool _sharing = false;

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
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
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
                SizedBox(
                  height: 220,
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
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
                                ? const Color(0xFF382483)
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
                ),
              ],
            ),
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
        rows: _printRows(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  Future<void> _sharePayslipPdf() async {
    if (_data == null) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _service.getMyPayslipPdf(
        year: _selectedYear,
        month: _selectedMonth,
      );
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/payslip_${_selectedYear}_${_selectedMonth}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: isAr
            ? 'كشف راتب'
            : 'Payslip',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'فشل تحميل PDF' : 'PDF download failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _sharing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'كشف راتبي' : 'My Payslip'),
        backgroundColor: const Color(0xFF382483),
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
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _print,
                        icon: const Icon(Icons.print),
                        tooltip: isAr ? 'طباعة' : 'Print',
                      ),
                      _sharing
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                            )
                          : IconButton(
                              onPressed: _sharePayslipPdf,
                              icon: const Icon(Icons.download),
                              tooltip: isAr ? 'تحميل ومشاركة' : 'Download',
                            ),
                    ],
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
                          colors: [Color(0xFF382483), Color(0xFF1A0A3E)],
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

                    ..._buildMoneySections(),
                    const SizedBox(height: 12),

                    // ─── Policy Info ───────────────────
                    if (_data!['policy_name'] != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFE0FAF2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF7DEAC8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.policy, color: Color(0xFF00C688), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isAr ? 'السياسة المطبقة' : 'Applied Policy',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF00C688), fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${_data!['policy_name']}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ─── Attendance Summary ───────────
                    _card(
                      isAr ? 'ملخص الحضور' : 'Attendance Summary',
                      Icons.calendar_today,
                      Color(0xFF382483),
                      [
                        _row(isAr ? 'أيام العمل' : 'Working Days',
                            '${_data!['total_working_days'] ?? 0}', Colors.black87),
                        _row(isAr ? 'أيام الحضور' : 'Present Days',
                            '${_data!['present_days'] ?? 0}', Colors.green),
                        _row(isAr ? 'الأيام المحسوبة' : 'Paid Days',
                            '${_data!['attended_days'] ?? 0}', Colors.black87),
                        if (payslipNum(_data!['mission_days']) > 0)
                          _row(isAr ? 'أيام المأموريات' : 'Mission Days',
                              '${_data!['mission_days']}', Colors.black87),
                        if (payslipNum(_data!['on_leave_days']) > 0)
                          _row(isAr ? 'أيام الإجازات' : 'Leave Days',
                              '${_data!['on_leave_days']}', Colors.black87),
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
                        // الأوفر تايم: الفعلية، واللي بتتحسب (بعد أقل مدة في اليوم)، والمدفوعة (× المضاعف)
                        _row(isAr ? 'ساعات Overtime الفعلية' : 'Overtime Hours (actual)',
                            _hoursText(_data!['overtime_hours'], isAr),
                            Color(0xFF382483)),
                        if (_data!['overtime_counted_hours'] != null) ...[
                          _row(isAr ? 'ساعات Overtime المحسوبة' : 'Overtime Hours (counted)',
                              _hoursText(_data!['overtime_counted_hours'], isAr),
                              Color(0xFF382483)),
                          _row(
                              _data!['overtime_multiplier'] != null
                                  ? (isAr
                                      ? 'ساعات Overtime المدفوعة (× ${_data!['overtime_multiplier']})'
                                      : 'Overtime Hours paid (× ${_data!['overtime_multiplier']})')
                                  : (isAr ? 'ساعات Overtime المدفوعة' : 'Overtime Hours paid'),
                              _hoursText(_data!['overtime_paid_hours'], isAr),
                              Color(0xFF382483),
                              bold: true),
                          if ((_data!['overtime_hours'] ?? 0) > 0 &&
                              (_data!['overtime_counted_hours'] ?? 0) == 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                isAr
                                    ? 'الأوفر تايم مش بيتصرف ليك حسب سياسة الشركة'
                                    : 'Overtime is not paid for you under the company policy',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            )
                          else if ((_data!['overtime_hours'] ?? 0) >
                              (_data!['overtime_counted_hours'] ?? 0))
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                isAr
                                    ? 'الأيام اللي فيها أوفر تايم أقل من الحد الأدنى مابتتحسبش'
                                    : 'Days below the daily minimum are not counted',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
    );
  }

  String _currency() {
    final c = '${_data?['currency'] ?? ''}'.trim();
    if (c.isEmpty || c.toUpperCase() == 'EGP') return isAr ? 'ج' : 'EGP';
    return c;
  }

  String _money(double v) => '${formatPayslipMoney(v)} ${_currency()}';

  // نفس بنود الشاشة في ملف الطباعة
  List<List<String>> _printRows() {
    final b = buildPayslipBreakdown(_data!, isAr);
    final rows = <List<String>>[];
    for (final l in b.earnings) {
      rows.add([l.label, _money(l.amount)]);
    }
    rows.add([isAr ? 'إجمالي المستحق' : 'Gross Salary', _money(b.gross)]);
    for (final l in b.deductions) {
      rows.add([l.label, '- ${_money(l.amount)}']);
    }
    rows.add([isAr ? 'إجمالي الخصومات' : 'Total Deductions', '- ${_money(b.totalDeductions)}']);
    rows.add([isAr ? 'صافي الراتب' : 'Net Salary', _money(b.net)]);
    return rows;
  }

  List<Widget> _lineWidgets(PayslipLine l, String sign, Color color) {
    return [
      _row(l.label, '$sign${_money(l.amount)}', color),
      for (final it in l.items)
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16, top: 2, bottom: 2),
          child: Row(
            children: [
              Expanded(
                child: Text('• ${it.name}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ),
              Text(_money(it.amount),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildMoneySections() {
    final b = buildPayslipBreakdown(_data!, isAr);
    return [
      // ─── صافي الراتب ───
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade300, width: 2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isAr ? 'صافي الراتب' : 'Net Salary',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  _money(b.net),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            if (b.isFinal)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  isAr ? 'نهائي: من مسير الرواتب المعتمد' : 'Final: from the approved payroll run',
                  style: TextStyle(fontSize: 12, color: Colors.green.shade800),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // ─── الإيرادات ───
      _card(
        isAr ? 'الإيرادات' : 'Earnings',
        Icons.add_circle_outline,
        Colors.green,
        [
          for (final l in b.earnings)
            ..._lineWidgets(l, l.key == 'basic_salary' ? '' : '+ ', Colors.green.shade700),
          const Divider(),
          _row(isAr ? 'إجمالي المستحق' : 'Gross Salary', _money(b.gross),
              Colors.green.shade800,
              bold: true),
        ],
      ),
      const SizedBox(height: 12),

      // ─── الخصومات ───
      _card(
        isAr ? 'الخصومات' : 'Deductions',
        Icons.remove_circle_outline,
        Colors.red,
        [
          if (b.deductions.isEmpty)
            _row(isAr ? 'لا توجد خصومات' : 'No deductions', '0', Colors.grey),
          for (final l in b.deductions) ..._lineWidgets(l, '- ', Colors.red),
          const Divider(),
          _row(isAr ? 'إجمالي الخصومات' : 'Total Deductions',
              '- ${_money(b.totalDeductions)}', Colors.red,
              bold: true),
        ],
      ),

      // ─── مساهمة الشركة في التأمينات (للعلم بس) ───
      if (b.companyInsurance.isNotEmpty) ...[
        const SizedBox(height: 12),
        _card(
          isAr ? 'مساهمة الشركة في التأمينات (للعلم فقط)' : 'Company Insurance Contribution (Info Only)',
          Icons.business,
          const Color(0xFF1565C0),
          [
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                isAr
                    ? 'المبالغ دي مش بتتخصم من مرتبك، الشركة بتدفعها عنك'
                    : 'These amounts are NOT deducted from your salary - paid by the company',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
            for (final l in b.companyInsurance)
              _row(l.label, _money(l.amount), const Color(0xFF1565C0),
                  bold: l.key == 'total_company_insurance_contribution'),
          ],
        ),
      ],
    ];
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
              Flexible(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ),
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
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
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

/// 2.5 -> "2 س 30 د"
String _hoursText(dynamic value, bool isAr) {
  final v = (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0.0;
  final h = v.floor();
  final m = ((v - h) * 60).round();
  if (m == 0) return isAr ? '$h س' : '${h}h';
  return isAr ? '$h س $m د' : '${h}h ${m}m';
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
