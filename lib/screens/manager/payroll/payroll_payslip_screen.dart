import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../../services/payroll_run_service.dart';
import '../../../services/language_service.dart';

class PayrollPayslipScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  final int year;
  final int month;

  const PayrollPayslipScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.year,
    required this.month,
  });

  @override
  State<PayrollPayslipScreen> createState() => _PayrollPayslipScreenState();
}

class _PayrollPayslipScreenState extends State<PayrollPayslipScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isAr => LanguageService.currentLanguage == 'ar';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await PayrollRunService.getPayslipData(
      employeeId: widget.employeeId,
      year: widget.year,
      month: widget.month,
    );
    if (!mounted) return;
    if (result.containsKey('error')) {
      setState(() { _error = result['error'] as String; _loading = false; });
    } else {
      setState(() { _data = result; _loading = false; });
    }
  }

  String _monthName(int m, bool ar) {
    const arN = ['','يناير','فبراير','مارس','ابريل','مايو','يونيو',
                  'يوليو','اغسطس','سبتمبر','اكتوبر','نوفمبر','ديسمبر'];
    const enN = ['','January','February','March','April','May','June',
                  'July','August','September','October','November','December'];
    return ar ? arN[m] : enN[m];
  }

  Future<Uint8List> _generatePdf(bool ar) async {
    final pdf = pw.Document();
    final d = _data!;
    final font = await PdfGoogleFonts.cairoRegular();
    final bold = await PdfGoogleFonts.cairoBold();
    final cur = ar ? 'ج.م' : 'EGP';

    final basicSalary       = (d['basic_salary'] as num?)?.toDouble() ?? 0.0;
    final totalAllowances   = (d['allowances_total'] as num?)?.toDouble() ?? 0.0;
    final totalBonuses      = (d['bonuses_total'] as num?)?.toDouble() ?? 0.0;
    final grossSalary       = (d['gross_salary'] as num?)?.toDouble() ?? 0.0;
    final lateDeduction     = (d['late_deduction'] as num?)?.toDouble() ?? 0.0;
    final absenceDeduction  = (d['absence_deduction'] as num?)?.toDouble() ?? 0.0;
    final insuranceDeduction= (d['insurance_deduction'] as num?)?.toDouble() ?? 0.0;
    final socialInsEmp      = (d['social_insurance_employee'] as num?)?.toDouble() ?? 0.0;
    final medicalInsEmp     = (d['medical_insurance_employee'] as num?)?.toDouble() ?? 0.0;
    final taxDeduction      = (d['tax_deduction'] as num?)?.toDouble() ?? 0.0;
    final penaltyDeduction  = (d['penalties_total'] as num?)?.toDouble() ?? 0.0;
    final installmentDeduction = (d['installments_total'] as num?)?.toDouble() ?? 0.0;
    final totalDeductions   = (d['total_deductions'] as num?)?.toDouble() ?? 0.0;
    final netSalary         = (d['net_salary'] as num?)?.toDouble() ?? 0.0;
    final workDays    = d['total_working_days'] as int? ?? 0;
    final presentDays = d['present_days'] as int? ?? 0;
    final absentDays  = d['absent_days'] as int? ?? 0;
    final lateDays    = d['late_days'] as int? ?? 0;
    final companyName = d['company_name'] as String? ?? 'MotionHR';
    final position    = d['job_title_name'] as String? ?? '';
    final department  = d['department_name'] as String? ?? '';

    pw.Widget pdfRow(String label, double value, {bool isBold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 3),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(font: isBold ? bold : font, fontSize: isBold ? 13 : 11)),
            pw.Text('${value.toStringAsFixed(2)} $cur',
                style: pw.TextStyle(font: isBold ? bold : font, fontSize: isBold ? 13 : 11)),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1565C0),
              ),
              child: pw.Column(children: [
                pw.Text(companyName,
                    style: pw.TextStyle(font: bold, fontSize: 22, color: PdfColors.white)),
                pw.SizedBox(height: 6),
                pw.Text(
                  ar ? 'قسيمة الراتب - ${_monthName(widget.month, ar)} ${widget.year}'
                     : 'Payslip - ${_monthName(widget.month, ar)} ${widget.year}',
                  style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.grey300),
                ),
              ]),
            ),
            pw.SizedBox(height: 12),
            // Employee Info
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(children: [
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(ar ? 'الاسم' : 'Name',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                    pw.Text(widget.employeeName,
                        style: pw.TextStyle(font: bold, fontSize: 12)),
                  ],
                )),
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(ar ? 'المسمى' : 'Position',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                    pw.Text(position,
                        style: pw.TextStyle(font: bold, fontSize: 12)),
                  ],
                )),
                pw.Expanded(child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(ar ? 'القسم' : 'Department',
                        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                    pw.Text(department,
                        style: pw.TextStyle(font: bold, fontSize: 12)),
                  ],
                )),
              ]),
            ),
            pw.SizedBox(height: 10),
            // Attendance
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: const PdfColor.fromInt(0xFFE0E0E0)),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(ar ? 'ملخص الحضور' : 'Attendance',
                      style: pw.TextStyle(font: bold, fontSize: 13,
                          color: const PdfColor.fromInt(0xFF1565C0))),
                  pw.SizedBox(height: 8),
                  pw.Row(children: [
                    pw.Expanded(child: pw.Column(children: [
                      pw.Text('$workDays',
                          style: pw.TextStyle(font: bold, fontSize: 16)),
                      pw.Text(ar ? 'ايام العمل' : 'Work Days',
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                    ])),
                    pw.Expanded(child: pw.Column(children: [
                      pw.Text('$presentDays',
                          style: pw.TextStyle(font: bold, fontSize: 16,
                              color: const PdfColor.fromInt(0xFF2E7D32))),
                      pw.Text(ar ? 'الحضور' : 'Present',
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                    ])),
                    pw.Expanded(child: pw.Column(children: [
                      pw.Text('$absentDays',
                          style: pw.TextStyle(font: bold, fontSize: 16,
                              color: const PdfColor.fromInt(0xFFC62828))),
                      pw.Text(ar ? 'الغياب' : 'Absent',
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                    ])),
                    pw.Expanded(child: pw.Column(children: [
                      pw.Text('$lateDays',
                          style: pw.TextStyle(font: bold, fontSize: 16,
                              color: const PdfColor.fromInt(0xFFE65100))),
                      pw.Text(ar ? 'التاخير' : 'Late',
                          style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey)),
                    ])),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            // Earnings & Deductions
            pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFE8F5E9),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(ar ? 'المستحقات' : 'Earnings',
                          style: pw.TextStyle(font: bold, fontSize: 13,
                              color: const PdfColor.fromInt(0xFF1B5E20))),
                      pw.SizedBox(height: 8),
                      pdfRow(ar ? 'الراتب الاساسي' : 'Basic', basicSalary),
                      pdfRow(ar ? 'البدلات' : 'Allowances', totalAllowances),
                      pdfRow(ar ? 'المكافات' : 'Bonuses', totalBonuses),
                      pw.Divider(color: const PdfColor.fromInt(0xFF4CAF50)),
                      pdfRow(ar ? 'الاجمالي' : 'Gross', grossSalary, isBold: true),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFFFEBEE),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(ar ? 'الخصومات' : 'Deductions',
                          style: pw.TextStyle(font: bold, fontSize: 13,
                              color: const PdfColor.fromInt(0xFFB71C1C))),
                      pw.SizedBox(height: 8),
                      pdfRow(ar ? 'تاخير' : 'Late', lateDeduction),
                      pdfRow(ar ? 'غياب' : 'Absence', absenceDeduction),
                      pdfRow(ar ? 'ضريبة' : 'Tax', taxDeduction),
                      if (socialInsEmp > 0) pdfRow(ar ? '\u062a\u0623\u0645\u064a\u0646 \u0627\u062c\u062a\u0645\u0627\u0639\u064a' : 'Social Insurance', socialInsEmp),
                      if (medicalInsEmp > 0) pdfRow(ar ? '\u062a\u0623\u0645\u064a\u0646 \u0637\u0628\u064a' : 'Medical Insurance', medicalInsEmp),
                      if (insuranceDeduction > 0 && socialInsEmp == 0 && medicalInsEmp == 0) pdfRow(ar ? '\u062a\u0627\u0645\u064a\u0646' : 'Insurance', insuranceDeduction),
                      pdfRow(ar ? 'تامين' : 'Insurance', insuranceDeduction),
                      pdfRow(ar ? 'جزاءات' : 'Penalties', penaltyDeduction),
                      pdfRow(ar ? 'اقساط' : 'Installments', installmentDeduction),
                      pw.Divider(color: const PdfColor.fromInt(0xFFF44336)),
                      pdfRow(ar ? 'اجمالي الخصومات' : 'Total', totalDeductions, isBold: true),
                    ],
                  ),
                ),
              ),
            ]),
            pw.SizedBox(height: 12),
            // Net Salary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF1B5E20),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(ar ? 'صافي الراتب' : 'Net Salary',
                      style: pw.TextStyle(font: bold, fontSize: 18, color: PdfColors.white)),
                  pw.Text('${netSalary.toStringAsFixed(2)} $cur',
                      style: pw.TextStyle(font: bold, fontSize: 20, color: PdfColors.yellow)),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Text(
              ar ? 'تم انشاء هذه القسيمة بواسطة نظام MotionHR'
                 : 'Generated by MotionHR System',
              style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey),
              textAlign: pw.TextAlign.center,
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  Future<void> _printPdf() async {
    final ar = _isAr;
    setState(() => _exporting = true);
    try {
      final bytes = await _generatePdf(ar);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'Payslip_${widget.employeeName}_${widget.year}_${widget.month}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ar ? 'فشل التصدير' : 'Export failed'),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _sharePdf() async {
    final ar = _isAr;
    setState(() => _exporting = true);
    try {
      final bytes = await _generatePdf(ar);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/payslip_${widget.employeeId}_${widget.year}_${widget.month}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: ar
            ? 'قسيمة راتب - ${widget.employeeName}'
            : 'Payslip - ${widget.employeeName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ar ? 'فشل المشاركة' : 'Share failed'),
          backgroundColor: Colors.red,
        ));
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Widget _buildRow(String label, double value, bool ar,
      {bool bold = false, Color? color}) {
    final cur = ar ? 'ج.م' : 'EGP';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: bold ? 14 : 13)),
          Text('${value.toStringAsFixed(2)} $cur',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: color,
                  fontSize: bold ? 14 : 13)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows, Color headerColor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                    fontSize: 14)),
          ),
          Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: rows)),
        ],
      ),
    );
  }

  Widget _attendStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = _isAr;
    final d = _data ?? {};
    final basicSalary        = (d['basic_salary'] as num?)?.toDouble() ?? 0.0;
    final totalAllowances    = (d['allowances_total'] as num?)?.toDouble() ?? 0.0;
    final totalBonuses       = (d['bonuses_total'] as num?)?.toDouble() ?? 0.0;
    final grossSalary        = (d['gross_salary'] as num?)?.toDouble() ?? 0.0;
    final lateDeduction      = (d['late_deduction'] as num?)?.toDouble() ?? 0.0;
    final absenceDeduction   = (d['absence_deduction'] as num?)?.toDouble() ?? 0.0;
    final insuranceDeduction = (d['insurance_deduction'] as num?)?.toDouble() ?? 0.0;
    final socialInsEmp       = (d['social_insurance_employee'] as num?)?.toDouble() ?? 0.0;
    final medicalInsEmp      = (d['medical_insurance_employee'] as num?)?.toDouble() ?? 0.0;
    final taxDeduction       = (d['tax_deduction'] as num?)?.toDouble() ?? 0.0;
    final penaltyDeduction   = (d['penalties_total'] as num?)?.toDouble() ?? 0.0;
    final installmentDeduction = (d['installments_total'] as num?)?.toDouble() ?? 0.0;
    final totalDeductions    = (d['total_deductions'] as num?)?.toDouble() ?? 0.0;
    final netSalary          = (d['net_salary'] as num?)?.toDouble() ?? 0.0;
    final nightAllowance     = (d['night_allowance'] as num?)?.toDouble() ?? 0.0;
    final weekendAllowance   = (d['weekend_allowance'] as num?)?.toDouble() ?? 0.0;
    final policyName         = d['policy_name']?.toString();
    final nightShiftDays     = d['night_shift_days'] as int? ?? 0;
    final weekendWorkDays    = d['weekend_work_days'] as int? ?? 0;
    final workDays    = d['total_working_days'] as int? ?? 0;
    final presentDays = d['present_days'] as int? ?? 0;
    final absentDays  = d['absent_days'] as int? ?? 0;
    final lateDays    = d['late_days'] as int? ?? 0;
    final earlyLeaveDeduction  = (d['early_leave_deduction'] as num?)?.toDouble() ?? 0.0;
    final flexShortageDeduction = (d['flex_shortage_deduction'] as num?)?.toDouble() ?? 0.0;

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ar ? 'قسيمة الراتب' : 'Payslip'),
          centerTitle: true,
          actions: [
            if (_exporting)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              )
            else ...[
              IconButton(
                  onPressed: _sharePdf,
                  icon: const Icon(Icons.share),
                  tooltip: ar ? 'مشاركة' : 'Share'),
              IconButton(
                  onPressed: _printPdf,
                  icon: const Icon(Icons.print),
                  tooltip: ar ? 'طباعة' : 'Print'),
            ],
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(ar ? 'فشل التحميل' : 'Load failed'),
                        ElevatedButton(
                          onPressed: _load,
                          child: Text(ar ? 'اعادة المحاولة' : 'Retry'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: [
                      // Header Card
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[800]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                widget.employeeName.isNotEmpty
                                    ? widget.employeeName[0]
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(widget.employeeName,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '${_monthName(widget.month, ar)} ${widget.year}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                      // Attendance Card
                      Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  ar
                                      ? 'ملخص الحضور'
                                      : 'Attendance Summary',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _attendStat(
                                      ar ? 'ايام العمل' : 'Work Days',
                                      '$workDays',
                                      Colors.blue),
                                  _attendStat(ar ? 'الحضور' : 'Present',
                                      '$presentDays', Colors.green),
                                  _attendStat(ar ? 'الغياب' : 'Absent',
                                      '$absentDays', Colors.red),
                                  _attendStat(ar ? 'التاخير' : 'Late',
                                      '$lateDays', Colors.orange),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Earnings
                      _buildSection(
                        ar ? 'المستحقات' : 'Earnings',
                        [
                          _buildRow(ar ? 'الراتب الاساسي' : 'Basic Salary',
                              basicSalary, ar),
                          _buildRow(ar ? 'البدلات' : 'Allowances',
                              totalAllowances, ar),
                          _buildRow(ar ? 'المكافات' : 'Bonuses',
                              totalBonuses, ar,
                              color: Colors.green),
                          if (nightAllowance > 0)
                            _buildRow(ar ? 'بدل ليلي' : 'Night Allowance',
                                nightAllowance, ar,
                                color: Colors.indigo),
                          if (weekendAllowance > 0)
                            _buildRow(ar ? 'بدل يوم الراحة' : 'Weekend Allowance',
                                weekendAllowance, ar,
                                color: Colors.deepPurple),
                          const Divider(),
                          _buildRow(ar ? 'الاجمالي' : 'Gross Salary',
                              grossSalary, ar,
                              bold: true, color: Colors.blue[700]),
                        ],
                        Colors.green,
                      ),
                      // Policy Info Card
                      if (policyName != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.policy, color: Colors.teal, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ar ? 'السياسة المطبقة' : 'Applied Policy',
                                      style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      policyName,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              if (nightShiftDays > 0 || weekendWorkDays > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (nightShiftDays > 0)
                                      Text(
                                        '${ar ? "ليلي" : "Night"}: $nightShiftDays',
                                        style: const TextStyle(fontSize: 11, color: Colors.indigo),
                                      ),
                                    if (weekendWorkDays > 0)
                                      Text(
                                        '${ar ? "راحة" : "Weekend"}: $weekendWorkDays',
                                        style: const TextStyle(fontSize: 11, color: Colors.deepPurple),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      // Deductions
                      _buildSection(
                        ar ? 'الخصومات' : 'Deductions',
                        [
                          _buildRow(ar ? 'تاخير' : 'Late Deduction',
                              lateDeduction, ar,
                              color: Colors.orange),
                          if (earlyLeaveDeduction > 0)
                            _buildRow(ar ? 'انصراف مبكر' : 'Early Leave',
                                earlyLeaveDeduction, ar,
                                color: Colors.deepOrange),
                          if (flexShortageDeduction > 0)
                            _buildRow(ar ? 'نقص ساعات مرنة' : 'Flex Shortage',
                                flexShortageDeduction, ar,
                                color: Colors.brown),
                          _buildRow(ar ? 'غياب' : 'Absence Deduction',
                              absenceDeduction, ar,
                              color: Colors.red),
                          _buildRow(ar ? 'ضريبة' : 'Tax',
                              taxDeduction, ar,
                              color: Colors.indigo),
                          if (socialInsEmp > 0)
                            _buildRow(ar ? '\u062a\u0623\u0645\u064a\u0646 \u0627\u062c\u062a\u0645\u0627\u0639\u064a' : 'Social Insurance',
                                socialInsEmp, ar,
                                color: Colors.purple),
                          if (medicalInsEmp > 0)
                            _buildRow(ar ? '\u062a\u0623\u0645\u064a\u0646 \u0637\u0628\u064a' : 'Medical Insurance',
                                medicalInsEmp, ar,
                                color: Colors.purple),
                          if (insuranceDeduction > 0 && socialInsEmp == 0 && medicalInsEmp == 0)
                            _buildRow(ar ? '\u062a\u0627\u0645\u064a\u0646' : 'Insurance',
                                insuranceDeduction, ar,
                                color: Colors.purple),
                          _buildRow(ar ? 'تامين' : 'Insurance',
                              insuranceDeduction, ar,
                              color: Colors.purple),
                          _buildRow(ar ? 'جزاءات' : 'Penalties',
                              penaltyDeduction, ar,
                              color: Colors.red),
                          _buildRow(ar ? 'اقساط' : 'Installments',
                              installmentDeduction, ar,
                              color: Colors.orange),
                          const Divider(),
                          _buildRow(
                              ar ? 'اجمالي الخصومات' : 'Total Deductions',
                              totalDeductions, ar,
                              bold: true, color: Colors.red[700]),
                        ],
                        Colors.red,
                      ),
                      // Net Salary
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: Colors.green[700],
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ar ? 'صافي الراتب' : 'Net Salary',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              '${netSalary.toStringAsFixed(2)} ${ar ? 'ج.م' : 'EGP'}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
      ),
    );
  }
}
