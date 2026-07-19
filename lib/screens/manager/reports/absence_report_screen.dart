import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class AbsenceReportScreen extends StatefulWidget {
  const AbsenceReportScreen({super.key});
  @override
  State<AbsenceReportScreen> createState() => _AbsenceReportScreenState();
}

class _AbsenceReportScreenState extends State<AbsenceReportScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await _service.getAbsenceReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _print() async {
    if (_data == null) return;
    setState(() => _printing = true);
    try {
      final employees = (_data!['employees'] as List?) ?? [];
      final rows = <List<String>>[];
      
      for (var e in employees) {
        final item = Map<String, dynamic>.from(e as Map);
        final absentDates = (item['absent_dates'] as List?) ?? [];
        
        rows.add([
          item['employee_name']?.toString() ?? '-',
          '${item['absent_days'] ?? 0} / ${item['total_working_days'] ?? 0}',
          absentDates.join(', ')
        ]);
      }

      await ReportPdfService.printReport(
        title: isAr ? 'تقرير الغياب' : 'Absence Report',
        subtitle: 'الشهر: ${_data!['month'] ?? '-'} / ${_data!['year'] ?? '-'}',
        headers: ['اسم الموظف', 'أيام الغياب', 'تواريخ الغياب'],
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
        title: Text(isAr ? 'تقرير الغياب' : 'Absence Report'),
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
              ? Center(child: Text('لا توجد حالات غياب'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    final absentDates = (item['absent_dates'] as List?) ?? const [];
                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.event_busy, color: Colors.white)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text('غياب: ${item['absent_days'] ?? 0} / ${item['total_working_days'] ?? 0}'),
                        children: absentDates.map<Widget>((d) => ListTile(dense: true, title: Text(d.toString()))).toList(),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}