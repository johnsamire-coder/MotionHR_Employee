import 'package:flutter/material.dart';
import '../../../widgets/report_month_picker.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import '../../../services/report_excel_service.dart';
import '../../../services/api_client.dart';
import 'dart:convert';

class RequestsReportScreen extends StatefulWidget {
  const RequestsReportScreen({super.key});
  @override
  State<RequestsReportScreen> createState() =>
      _RequestsReportScreenState();
}

class _RequestsReportScreenState extends State<RequestsReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;
  bool _exporting = false;
  String _search = '';

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  static const _color = Color(0xFF6A1B9A);

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
          SnackBar(content: Text('${_isAr ? 'خطأ' : 'Error'}: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _actionRequest(int id, String action) async {
    final ar = _isAr;
    try {
      final res = await ApiClient.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/action/'),
        body: jsonEncode({
          'type': 'request',
          'id': id,
          'action': action,
        }),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? (action == 'approve' ? (ar ? 'تمت الموافقة' : 'Approved') : (ar ? 'تم الرفض' : 'Rejected'))),
        backgroundColor: action == 'approve' ? Colors.green : Colors.red,
      ));
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ar ? 'خطأ في الاتصال' : 'Connection error'),
          backgroundColor: Colors.red,
        ));
      }
    }
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
          _translateStatus(item['status']?.toString() ?? '-'),
        ];
      }).toList();
      await ReportPdfService.printReport(
        title: _isAr ? 'تقرير الطلبات' : 'Requests Report',
        subtitle: '${_monthName(_selectedMonth)} $_selectedYear',
        headers: _isAr
            ? ['اسم الموظف', 'نوع الطلب', 'الموضوع', 'الحالة']
            : ['Employee', 'Type', 'Subject', 'Status'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_isAr ? 'خطأ في الطباعة' : 'Print error'}: $e')),
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
        isAr: _isAr,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_isAr ? 'خطأ في التصدير' : 'Export error'}: $e')),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  String _translateStatus(String status) {
    if (!_isAr) return status;
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

  List<Map<String, dynamic>> get _filtered {
    final all = (_data?['details'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    if (_search.trim().isEmpty) return all;
    final s = _search.toLowerCase().trim();
    return all.where((row) {
      final name = (row['employee_name'] ?? '').toString().toLowerCase();
      final type = (row['request_type'] ?? '').toString().toLowerCase();
      return name.contains(s) || type.contains(s);
    }).toList();
  }

  String _monthName(int m) {
    const ar = ['', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    const en = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return _isAr ? ar[m] : en[m];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(_isAr ? 'تقرير الطلبات' : 'Requests Report',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: _color,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (!_loading && _data != null) ...[
              _exporting
                  ? const Padding(padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                  : IconButton(onPressed: _exportExcel, icon: const Icon(Icons.table_chart_outlined)),
              _printing
                  ? const Padding(padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
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
              ),
              child: Column(
                children: [
                  InkWell(
                    onTap: _pickMonth,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.white),
                          const SizedBox(width: 10),
                          Text('${_monthName(_selectedMonth)} $_selectedYear',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isAr ? 'بحث بالاسم أو نوع الطلب...' : 'Search...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _color))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _buildCard(filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> req) {
    final name = (req['employee_name'] ?? '').toString();
    final type = (req['request_type'] ?? '').toString();
    final subject = (req['subject'] ?? '').toString();
    final status = (req['status'] ?? '').toString();
    final requestId = req['id'];
    final color = _statusColor(status);
    final isPending = status.toLowerCase() == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: _color.withValues(alpha: 0.1),
                child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: _color)),
              ),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$type - $subject'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(_translateStatus(status), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            if (isPending && requestId != null) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _actionRequest(requestId as int, 'approve'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: Text(_isAr ? 'قبول' : 'Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _actionRequest(requestId as int, 'reject'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: Text(_isAr ? 'رفض' : 'Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
} 