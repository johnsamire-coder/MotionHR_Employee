import 'package:flutter/material.dart';
import '../../../widgets/report_month_picker.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import '../../../services/report_excel_service.dart';
import '../../../services/api_client.dart';
import 'dart:convert';

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
  bool _exporting = false;
  String _search = '';

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  static const _color = Color(0xFF008A60);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _service.getLeavesReport(
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

  Future<void> _cancelLeave(int leaveId) async {
    final ar = _isAr;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(ar ? 'إلغاء الإجازة' : 'Cancel Leave'),
          content: TextField(
            controller: reasonCtrl,
            decoration: InputDecoration(
              hintText: ar ? 'سبب الإلغاء...' : 'Reason for cancellation...',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(ar ? 'تراجع' : 'Back'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                ar ? 'إلغاء الإجازة' : 'Cancel Leave',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      // Endpoint to cancel leave
      final res = await ApiClient.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/my-leaves/$leaveId/cancel/'),
        body: jsonEncode({'reason': reasonCtrl.text.trim()}),
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? (ar ? 'تم الإلغاء' : 'Cancelled successfully')),
        backgroundColor: data['success'] == true ? Colors.green : Colors.red,
      ));
      if (data['success'] == true) _load();
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
      final employees = (_data!['employees'] as List?) ?? [];
      final rows = <List<String>>[];
      for (var e in employees) {
        final item = Map<String, dynamic>.from(e as Map);
        rows.add([
          item['name']?.toString() ?? '-',
          '${item['total_days'] ?? 0}',
          '${item['approved_days'] ?? 0}',
          '${(item['leaves'] as List?)?.length ?? 0}',
        ]);
      }
      await ReportPdfService.printReport(
        title: _isAr ? 'تقرير الإجازات' : 'Leaves Report',
        subtitle: '${_monthName(_selectedMonth)} $_selectedYear',
        headers: _isAr
            ? ['اسم الموظف', 'إجمالي الأيام', 'موافق', 'عدد الطلبات']
            : ['Employee', 'Total Days', 'Approved', 'Requests'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${_isAr ? 'خطأ في الطباعة' : 'Print error'}: $e')),
        );
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  Future<void> _exportExcel() async {
    if (_data == null) return;
    setState(() => _exporting = true);
    try {
      final leaves = List<Map<String, dynamic>>.from(
        (_data!['employees'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      await ReportExcelService.exportLeavesReport(
        leaves: leaves,
        year: _selectedYear,
        month: _selectedMonth,
        isAr: _isAr,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${_isAr ? 'خطأ في التصدير' : 'Export error'}: $e')),
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
    final all = (_data?['employees'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    if (_search.trim().isEmpty) return all;
    final s = _search.toLowerCase().trim();
    return all.where((row) {
      final name = (row['name'] ?? '').toString().toLowerCase();
      return name.contains(s);
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
          title: Text(
            _isAr ? 'تقرير الإجازات' : 'Leaves Report',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                      hintText: _isAr ? 'بحث بالاسم...' : 'Search...',
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

  Widget _buildCard(Map<String, dynamic> emp) {
    final name = (emp['name'] ?? '').toString();
    final totalDays = emp['total_days'] ?? 0;
    final approvedDays = emp['approved_days'] ?? 0;
    final leaves = (emp['leaves'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.1),
          child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: _color)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_isAr ? 'إجمالي: $totalDays يوم | موافق: $approvedDays' : 'Total: $totalDays d | Approved: $approvedDays'),
        children: [
          const Divider(height: 1),
          if (leaves.isNotEmpty)
            ...leaves.map<Widget>((l) {
              final lv = Map<String, dynamic>.from(l as Map);
              final status = lv['status']?.toString() ?? '-';
              final sColor = _statusColor(status);
              final leaveId = lv['id'];
              final canCancel = status == 'approved' || status == 'pending';

              return ListTile(
                dense: true,
                leading: Icon(Icons.circle, color: sColor, size: 8),
                title: Text('${lv['type'] ?? '-'} — ${lv['days'] ?? 0} ${_isAr ? 'يوم' : 'days'}'),
                subtitle: Text('${lv['from'] ?? '-'} → ${lv['to'] ?? '-'}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_translateStatus(status), style: TextStyle(color: sColor, fontWeight: FontWeight.bold)),
                    if (canCancel && leaveId != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                        onPressed: () => _cancelLeave(leaveId as int),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}