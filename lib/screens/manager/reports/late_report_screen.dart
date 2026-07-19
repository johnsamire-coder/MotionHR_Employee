import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';

class LateReportScreen extends StatefulWidget {
  const LateReportScreen({super.key});
  @override
  State<LateReportScreen> createState() => _LateReportScreenState();
}

class _LateReportScreenState extends State<LateReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await _service.getLateReport(); } catch (e) {}
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
        final details = (item['details'] as List?) ?? [];
        
        // سطر الموظف الرئيسي
        rows.add([
          item['employee_name']?.toString() ?? '-',
          item['total_late_days']?.toString() ?? '0',
          '${item['total_late_hours'] ?? 0} س',
          'إجمالي'
        ]);

        // تفاصيل كل يوم تأخير
        for (var d in details) {
          final detail = Map<String, dynamic>.from(d as Map);
          rows.add([
            '',
            detail['date']?.toString() ?? '-',
            '${detail['minutes_late']} د',
            'تأخير يومي'
          ]);
        }
      }

      await ReportPdfService.printReport(
        title: 'تقرير التأخير',
        subtitle: 'الشهر: ${_data!['month'] ?? '-'} / ${_data!['year'] ?? '-'}',
        headers: ['الموظف / التاريخ', 'الأيام / الساعة', 'المدة', 'الحالة'],
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
        title: const Text('تقرير التأخير'),
        actions: [
          if (!_loading && _data != null)
            _printing
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                : IconButton(onPressed: _print, icon: const Icon(Icons.print)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh))
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? const Center(child: Text('لا توجد حالات تأخير'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    final details = (item['details'] as List?) ?? const [];
                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text('أيام التأخير: ${item['total_late_days'] ?? 0} - ${item['total_late_hours'] ?? 0} س'),
                        children: details.map<Widget>((d) {
                          final detail = Map<String, dynamic>.from(d as Map);
                          return ListTile(
                            dense: true,
                            title: Text('${detail['date']} - ${detail['time']}'),
                            trailing: Text('${detail['minutes_late']} دقيقة'),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}