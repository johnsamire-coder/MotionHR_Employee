import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class LeavesReportScreen extends StatefulWidget {
  const LeavesReportScreen({super.key});
  @override
  State<LeavesReportScreen> createState() => _LeavesReportScreenState();
}

class _LeavesReportScreenState extends State<LeavesReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await _service.getLeavesReport(); } catch (e) {}
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
        final leaves = (item['leaves'] as List?) ?? [];
        
        rows.add([
          item['name']?.toString() ?? '-',
          '${item['total_days'] ?? 0}',
          '${item['approved_days'] ?? 0}',
          'إجمالي'
        ]);

        for (var l in leaves) {
          final lv = Map<String, dynamic>.from(l as Map);
          rows.add([
            '',
            lv['type']?.toString() ?? '-',
            '${lv['days']} يوم',
            lv['status']?.toString() ?? '-'
          ]);
        }
      }

      await ReportPdfService.printReport(
        title: 'تقرير الإجازات',
        subtitle: 'الشهر: ${_data!['month'] ?? '-'} / ${_data!['year'] ?? '-'}',
        headers: ['الموظف / نوع الإجازة', 'إجمالي الأيام', 'الموافق', 'الحالة'],
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
        title: const Text('تقرير الإجازات'),
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
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('إجمالي الإجازات: ${_data?['total_leaves'] ?? 0}'),
                        const SizedBox(height: 4),
                        Text('موافق: ${_data?['approved'] ?? 0} | مرفوض: ${_data?['rejected'] ?? 0} | معلق: ${_data?['pending'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...employees.map<Widget>((e) {
                  final item = Map<String, dynamic>.from(e as Map);
                  final lvs = (item['leaves'] as List?) ?? const [];
                  return Card(
                    child: ExpansionTile(
                      title: Text(item['name']?.toString() ?? '-'),
                      subtitle: Text('إجمالي: ${item['total_days'] ?? 0} - موافق: ${item['approved_days'] ?? 0}'),
                      children: lvs.map<Widget>((l) {
                        final lv = Map<String, dynamic>.from(l as Map);
                        return ListTile(
                          dense: true,
                          title: Text('${lv['type']} - ${lv['days']} يوم'),
                          subtitle: Text('من ${lv['from']} إلى ${lv['to']}'),
                          trailing: Chip(label: Text(lv['status']?.toString() ?? '-')),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}