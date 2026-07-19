import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});
  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _service.getAttendanceReport();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _print() async {
    if (_data == null) return;
    setState(() => _printing = true);
    try {
      final employees = (_data!['employees'] as List?) ?? [];
      final rows = employees.map<List<String>>((e) {
        final item = Map<String, dynamic>.from(e as Map);
        return [
          item['employee_name']?.toString() ?? '-',
          item['working_days']?.toString() ?? '0',
          item['absent_days']?.toString() ?? '0',
          item['late_days']?.toString() ?? '0',
        ];
      }).toList();

      await ReportPdfService.printReport(
        title: 'تقرير الحضور الشهري',
        subtitle: 'الشهر: ${_data!['month'] ?? '-'} / ${_data!['year'] ?? '-'}',
        headers: ['اسم الموظف', 'أيام الحضور', 'أيام الغياب', 'أيام التأخير'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الطباعة: $e')));
    }
    if (mounted) setState(() => _printing = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text('تقرير الحضور الشهري'),
        actions: [
          if (!_loading && _data != null)
            _printing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                  )
                : IconButton(
                    onPressed: _print,
                    icon: const Icon(Icons.print),
                    tooltip: 'طباعة التقرير',
                  ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: employees.isEmpty
                  ? ListView(children: [const SizedBox(height: 120), Center(child: Text(context.l10n.noData))])
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_month),
                            title: Text('الشهر: ${_data?['month'] ?? '-'} / ${_data?['year'] ?? '-'}'),
                            subtitle: Text('عدد الموظفين: ${_data?['total_employees'] ?? 0}'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...employees.map<Widget>((e) {
                          final item = Map<String, dynamic>.from(e as Map);
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(item['employee_name']?.toString() ?? '-'),
                              subtitle: Text('أيام الحضور: ${item['working_days'] ?? 0}'),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}