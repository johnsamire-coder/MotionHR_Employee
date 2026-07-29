import 'package:flutter/material.dart';
import '../../../widgets/report_month_picker.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import '../../../services/report_excel_service.dart';

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

  static const _color = Color(0xFF00695C);

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
              content: Text(
                  '${_isAr ? 'خطأ في الطباعة' : 'Print error'}: $e')),
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
              content: Text(
                  '${_isAr ? 'خطأ في التصدير' : 'Export error'}: $e')),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  String _translateStatus(String status) {
    if (!_isAr) return status;
    switch (status.toLowerCase()) {
      case 'approved':
        return 'موافق';
      case 'pending':
        return 'معلق';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
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
    const ar = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const en = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return _isAr ? ar[m] : en[m];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final title = _isAr ? 'تقرير الإجازات' : 'Leaves Report';

    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _color,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (!_loading && _data != null) ...[
              _exporting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _exportExcel,
                      icon: const Icon(Icons.table_chart_outlined),
                      tooltip: _isAr ? 'تصدير Excel' : 'Export Excel',
                    ),
              _printing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _print,
                      icon: const Icon(Icons.print),
                    ),
            ],
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickMonth,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_monthName(_selectedMonth)} $_selectedYear',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            _isAr
                                ? Icons.arrow_back_ios_new
                                : Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isAr
                          ? 'بحث بالاسم...'
                          : 'Search by name...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(
                          _isAr ? 'إجمالي' : 'Total',
                          '${_data?['total_leaves'] ?? 0}',
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          _isAr ? 'موافق' : 'Approved',
                          '${_data?['approved'] ?? 0}',
                          chipColor: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          _isAr ? 'معلق' : 'Pending',
                          '${_data?['pending'] ?? 0}',
                          chipColor: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          _isAr ? 'مرفوض' : 'Rejected',
                          '${_data?['rejected'] ?? 0}',
                          chipColor: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _color),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.beach_access_outlined,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                _isAr
                                    ? 'لا توجد إجازات في هذا الشهر'
                                    : 'No leaves this month',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(12),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _buildCard(filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, {Color? chipColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: (chipColor ?? Colors.white).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: chipColor ?? Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: (chipColor ?? Colors.white).withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
        ],
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
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: const TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name.isNotEmpty ? name : (_isAr ? 'بدون اسم' : 'No name'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          _isAr
              ? 'إجمالي: $totalDays يوم | موافق: $approvedDays'
              : 'Total: ${totalDays}d | Approved: $approvedDays',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$totalDays',
            style: const TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        children: [
          const Divider(height: 1),
          if (leaves.isNotEmpty)
            ...leaves.map<Widget>((l) {
              final lv = Map<String, dynamic>.from(l as Map);
              final status = lv['status']?.toString() ?? '-';
              final sColor = _statusColor(status);
              return ListTile(
                dense: true,
                leading: Icon(Icons.circle, color: sColor, size: 8),
                title: Text(
                  '${lv['type'] ?? '-'} — ${lv['days'] ?? 0} ${_isAr ? 'يوم' : 'days'}',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '${lv['from'] ?? '-'} → ${lv['to'] ?? '-'}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[600]),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _translateStatus(status),
                    style: TextStyle(
                      color: sColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }),
          if (leaves.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _isAr ? 'لا توجد تفاصيل' : 'No details',
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}