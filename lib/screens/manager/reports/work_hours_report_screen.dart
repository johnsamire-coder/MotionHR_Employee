import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class WorkHoursReportScreen extends StatefulWidget {
  const WorkHoursReportScreen({super.key});
  @override
  State<WorkHoursReportScreen> createState() => _WorkHoursReportScreenState();
}

class _WorkHoursReportScreenState extends State<WorkHoursReportScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await _service.getWorkHoursReport(); } catch (e) {}
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
          '${item['total_hours'] ?? 0} س',
          '${item['total_days_worked'] ?? 0}',
        ];
      }).toList();

      await ReportPdfService.printReport(
        title: isAr ? 'تقرير ساعات العمل' : 'Work Hours Report',
        subtitle: 'الشهر: ${_data!['month'] ?? '-'} / ${_data!['year'] ?? '-'}',
        headers: ['اسم الموظف', 'إجمالي الساعات', 'أيام العمل'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الطباعة: $e')));
    }
    if (mounted) setState(() => _printing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تقرير ساعات العمل' : 'Work Hours Report'),
        actions: [
          if (!_loading && _data != null)
            _printing
                ? Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : IconButton(onPressed: _print, icon: Icon(Icons.print)),
          IconButton(onPressed: _load, icon: Icon(Icons.refresh))
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? Center(child: Text(context.l10n.noData))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.access_time)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text('إجمالي: ${item['total_hours'] ?? 0} س - أيام: ${item['total_days_worked'] ?? 0}'),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}