// lib/screens/manager/reports/requests_report_screen.dart
// Phase 17 — Excel Export + encoding fix + AR/EN + Container bug fix

import 'package:flutter/material.dart';
import '../../../widgets/report_month_picker.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import '../../../services/report_excel_service.dart';

class RequestsReportScreen extends StatefulWidget {
  const RequestsReportScreen({super.key});
  @override
  State<RequestsReportScreen> createState() => _RequestsReportScreenState();
}

class _RequestsReportScreenState extends State<RequestsReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;
  bool _exporting = false;

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
      _data = await _service.getRequestsReport(
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isAr ? 'خطأ' : 'Error'}: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickMonth() async {
    final result = await showReportMonthPicker(
      context,
      initialYear: _selectedYear,
      initialMonth: _selectedMonth,
    );
    if (result != null && mounted) {
      setState(() {
        _selectedYear = result.year;
        _selectedMonth = result.month;
      });
      _load();
    }
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
          item['request_type']?.toString() ?? '-',
          item['subject']?.toString() ?? '-',
          _translateStatus(item['status']?.toString() ?? '-', isAr),
        ];
      }).toList();
      await ReportPdfService.printReport(
        title: isAr ? 'تقرير الطلبات' : 'Requests Report',
        subtitle: '${_monthName(_selectedMonth, isAr)} $_selectedYear',
        headers: isAr
            ? ['اسم الموظف', 'نوع الطلب', 'الموضوع', 'الحالة']
            : ['Employee', 'Type', 'Subject', 'Status'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isAr ? 'خطأ في الطباعة' : 'Print error'}: $e')),
        );
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  Future<void> _exportExcel() async {
    if (_data == null) return;
    setState(() => _exporting = true);
    try {
      final requests = List<Map<String, dynamic>>.from(
        (_data!['details'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      await ReportExcelService.exportRequestsReport(
        requests: requests,
        year: _selectedYear,
        month: _selectedMonth,
        isAr: isAr,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isAr ? 'خطأ في التصدير' : 'Export error'}: $e')),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  String _translateStatus(String status, bool ar) {
    if (!ar) return status;
    switch (status.toLowerCase()) {
      case 'approved': return 'موافق';
      case 'pending': return 'معلق';
      case 'rejected': return 'مرفوض';
      default: return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = (_data?['details'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تقرير الطلبات' : 'Requests Report'),
        backgroundColor: const Color(0xFF6A1B9A),
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
          if (!_loading && _data != null) ...[
            _exporting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  )
                : IconButton(
                    onPressed: _exportExcel,
                    icon: const Icon(Icons.table_chart_outlined),
                    tooltip: isAr ? 'تصدير Excel' : 'Export Excel',
                  ),
            _printing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  )
                : IconButton(
                    onPressed: _print,
                    icon: const Icon(Icons.print),
                  ),
          ],
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat(isAr ? 'إجمالي' : 'Total',
                          '${_data?['total_requests'] ?? 0}', Colors.purple),
                      _stat(isAr ? 'موافق' : 'Approved',
                          '${_data?['approved'] ?? 0}', Colors.green),
                      _stat(isAr ? 'معلق' : 'Pending',
                          '${_data?['pending'] ?? 0}', Colors.orange),
                      _stat(isAr ? 'مرفوض' : 'Rejected',
                          '${_data?['rejected'] ?? 0}', Colors.red),
                    ],
                  ),
                ),
                Expanded(
                  child: details.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined,
                                  size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                isAr
                                    ? 'لا توجد طلبات في هذا الشهر'
                                    : 'No requests this month',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: details.length,
                          itemBuilder: (_, idx) {
                            final item = Map<String, dynamic>.from(
                                details[idx] as Map);
                            final status =
                                item['status']?.toString() ?? '-';
                            final color = _statusColor(status);
                            return Card(
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.purple,
                                  child: Icon(Icons.request_page,
                                      color: Colors.white, size: 18),
                                ),
                                title: Text(
                                    item['employee_name']?.toString() ?? '-'),
                                subtitle: Text(
                                  '${item['request_type'] ?? '-'} — ${item['subject'] ?? '-'}',
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color),
                                  ),
                                  child: Text(
                                    _translateStatus(status, isAr),
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

String _monthName(int month, bool isAr) {
  const ar = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
  const en = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return isAr ? ar[month] : en[month];
}
