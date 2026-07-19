import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class RequestsReportScreen extends StatefulWidget {
  const RequestsReportScreen({super.key});
  @override
  State<RequestsReportScreen> createState() => _RequestsReportScreenState();
}

class _RequestsReportScreenState extends State<RequestsReportScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await _service.getRequestsReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _print() async {
    if (_data == null) return;
    setState(() => _printing = true);
    try {
      final details = (_data!['details'] as List?) ?? [];
      final rows = details.map<List<String>>((r) {
        final item = Map<String, dynamic>.from(r as Map);
        return [
          item['employee_name']?.toString() ?? '-',
          item['category']?.toString() ?? '-',
          item['subject']?.toString() ?? '-',
          item['status']?.toString() ?? '-',
        ];
      }).toList();

      await ReportPdfService.printReport(
        title: isAr ? 'تقرير الطلبات' : 'Requests Report',
        subtitle: 'إجمالي: ${_data!['total_requests']} (موافق: ${_data!['approved']} - معلق: ${_data!['pending']})',
        headers: ['اسم الموظف', 'الفئة', 'الموضوع', 'الحالة'],
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
    final details = (_data?['details'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تقرير الطلبات' : 'Requests Report'),
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
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('إجمالي الطلبات: ${_data?['total_requests'] ?? 0}'),
                        SizedBox(height: 4),
                        Text('موافق: ${_data?['approved'] ?? 0} | مرفوض: ${_data?['rejected'] ?? 0} | معلق: ${_data?['pending'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 8),
                ...details.map<Widget>((r) {
                  final item = Map<String, dynamic>.from(r as Map);
                  return Card(
                    child: ListTile(
                      title: Text(item['employee_name']?.toString() ?? '-'),
                      subtitle: Text('${item['category']} - ${item['subject']}'),
                      trailing: Chip(label: Text(item['status']?.toString() ?? '-')),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}