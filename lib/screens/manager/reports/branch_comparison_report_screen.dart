import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import '../../../services/report_excel_service.dart';

class BranchComparisonReportScreen extends StatefulWidget {
  const BranchComparisonReportScreen({super.key});
  @override
  State<BranchComparisonReportScreen> createState() => _BranchComparisonReportScreenState();
}

class _BranchComparisonReportScreenState extends State<BranchComparisonReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;
  bool _exporting = false;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';
  static const _color = Color(0xFF00838F);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _service.getBranchComparisonReport();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_isAr ? 'خطأ' : 'Error'}: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _print() async {
    if (_data == null) return;
    setState(() => _printing = true);
    try {
      final rows = List<Map<String, dynamic>>.from(_data!['results'] ?? []);
      final pdfRows = rows.map((r) => [
        r['branch_name']?.toString() ?? '-',
        '${r['employees_count'] ?? 0}',
        '${r['total_salary'] ?? 0}',
        '${r['avg_salary'] ?? 0}',
        '${r['present_days'] ?? 0}',
        '${r['absent_days'] ?? 0}',
        '${r['total_late_minutes'] ?? 0}',
        '${r['total_overtime_hours'] ?? 0}',
      ]).toList();
      await ReportPdfService.printReport(
        title: _isAr ? 'مقارنة الفروع' : 'Branch Comparison',
        subtitle: _isAr ? 'آخر 30 يوم' : 'Last 30 days',
        headers: _isAr
            ? ['الفرع', 'الموظفين', 'إجمالي الرواتب', 'متوسط الراتب', 'أيام الحضور', 'أيام الغياب', 'دقائق التأخير', 'أوفر تايم']
            : ['Branch', 'Employees', 'Total Salary', 'Avg Salary', 'Present Days', 'Absent Days', 'Late Mins', 'Overtime Hrs'],
        rows: pdfRows,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _printing = false);
  }

  Future<void> _exportExcel() async {
    if (_data == null) return;
    setState(() => _exporting = true);
    try {
      final rows = List<Map<String, dynamic>>.from(_data!['results'] ?? []);
      await ReportExcelService.exportBranchComparisonReport(
        rows: rows,
        isAr: _isAr,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _exporting = false);
  }

  List<Map<String, dynamic>> get _rows =>
      List<Map<String, dynamic>>.from(_data?['results'] ?? []);

  @override
  Widget build(BuildContext context) {
    final title = _isAr ? 'مقارنة الفروع' : 'Branch Comparison';
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: _color,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (!_loading && _data != null) ...[
              _exporting
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : IconButton(onPressed: _exportExcel, icon: const Icon(Icons.table_chart_outlined), tooltip: _isAr ? 'تصدير Excel' : 'Export Excel'),
              _printing
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : IconButton(onPressed: _print, icon: const Icon(Icons.print)),
            ],
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [BoxShadow(color: _color.withValues(alpha: 0.18), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Row(
                children: [
                  _chip(_isAr ? 'الفروع' : 'Branches', '${_rows.length}'),
                  const SizedBox(width: 8),
                  _chip(
                    _isAr ? 'إجمالي الموظفين' : 'Total Employees',
                    '${_rows.fold<int>(0, (s, r) => s + (r['employees_count'] as int? ?? 0))}',
                  ),
                  const SizedBox(width: 8),
                  _chip(_isAr ? 'آخر 30 يوم' : 'Last 30 days', '📅'),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _color))
                  : _rows.isEmpty
                      ? Center(child: Text(_isAr ? 'لا توجد بيانات' : 'No data', style: TextStyle(color: Colors.grey[600])))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _rows.length,
                            itemBuilder: (_, i) => _buildCard(_rows[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(30)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> branch) {
    final name = branch['branch_name']?.toString() ?? '-';
    final empCount = branch['employees_count'] ?? 0;
    final totalSalary = branch['total_salary'] ?? 0;
    final avgSalary = branch['avg_salary'] ?? 0;
    final maxSalary = branch['max_salary'] ?? 0;
    final minSalary = branch['min_salary'] ?? 0;
    final presentDays = branch['present_days'] ?? 0;
    final absentDays = branch['absent_days'] ?? 0;
    final lateMinutes = branch['total_late_minutes'] ?? 0;
    final overtimeHours = branch['total_overtime_hours'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.1),
          child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: _color, fontWeight: FontWeight.bold)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(
          _isAr ? '$empCount موظف' : '$empCount employees',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Text('$empCount', style: const TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(children: [
              _row(Icons.attach_money, _isAr ? 'إجمالي الرواتب' : 'Total Salary', '$totalSalary'),
              _row(Icons.trending_up, _isAr ? 'متوسط الراتب' : 'Avg Salary', '$avgSalary'),
              _row(Icons.arrow_upward, _isAr ? 'أعلى راتب' : 'Max Salary', '$maxSalary'),
              _row(Icons.arrow_downward, _isAr ? 'أقل راتب' : 'Min Salary', '$minSalary'),
              const Divider(height: 20),
              _row(Icons.check_circle_outline, _isAr ? 'أيام الحضور (30 يوم)' : 'Present Days (30d)', '$presentDays', color: Colors.green),
              _row(Icons.cancel_outlined, _isAr ? 'أيام الغياب (30 يوم)' : 'Absent Days (30d)', '$absentDays', color: Colors.red),
              _row(Icons.alarm, _isAr ? 'دقائق التأخير' : 'Late Minutes', '$lateMinutes', color: Colors.orange),
              _row(Icons.more_time, _isAr ? 'ساعات الأوفر تايم' : 'Overtime Hours', '$overtimeHours', color: Colors.blue),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 16, color: color ?? _color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? _color)),
      ]),
    );
  }
}
