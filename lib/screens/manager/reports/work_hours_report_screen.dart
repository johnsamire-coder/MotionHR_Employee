import 'package:flutter/material.dart';
import '../../../widgets/report_month_picker.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';
import '../../../services/report_excel_service.dart';

class WorkHoursReportScreen extends StatefulWidget {
  const WorkHoursReportScreen({super.key});
  @override
  State<WorkHoursReportScreen> createState() =>
      _WorkHoursReportScreenState();
}

class _WorkHoursReportScreenState extends State<WorkHoursReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;
  bool _exporting = false;
  String _search = '';

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  static const _color = Color(0xFF1A0A3E);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _service.getWorkHoursReport(
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
      final rows = employees.map<List<String>>((e) {
        final item = Map<String, dynamic>.from(e as Map);
        return [
          item['employee_name']?.toString() ?? '-',
          '${item['total_hours'] ?? 0}',
          '${item['total_days_worked'] ?? 0}',
          '${item['average_hours_per_day'] ?? 0}',
        ];
      }).toList();
      await ReportPdfService.printReport(
        title: _isAr ? 'تقرير ساعات العمل' : 'Work Hours Report',
        subtitle: '${_monthName(_selectedMonth)} $_selectedYear',
        headers: _isAr
            ? ['اسم الموظف', 'إجمالي الساعات', 'أيام العمل', 'متوسط/يوم']
            : ['Employee', 'Total Hours', 'Days Worked', 'Avg/Day'],
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
      final employees = List<Map<String, dynamic>>.from(
        (_data!['employees'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      await ReportExcelService.exportWorkHoursReport(
        employees: employees,
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

  List<Map<String, dynamic>> get _filtered {
    final all = (_data?['employees'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    if (_search.trim().isEmpty) return all;
    final s = _search.toLowerCase().trim();
    return all.where((row) {
      final name =
          (row['employee_name'] ?? '').toString().toLowerCase();
      final dept = (row['department'] ?? '').toString().toLowerCase();
      return name.contains(s) || dept.contains(s);
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
    final title = _isAr ? 'تقرير ساعات العمل' : 'Work Hours Report';

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
                          ? 'بحث بالاسم أو القسم...'
                          : 'Search by name or dept...',
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
                          _isAr ? 'النتائج' : 'Results',
                          '${filtered.length}',
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
                              Icon(Icons.access_time_outlined,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                _isAr
                                    ? 'لا توجد بيانات'
                                    : 'No data found',
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

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> emp) {
    final name = (emp['employee_name'] ?? '').toString();
    final totalHours = emp['total_hours'] ?? 0;
    final daysWorked = emp['total_days_worked'] ?? 0;
    final avgPerDay = emp['average_hours_per_day'] ?? 0;
    final breakdown = (emp['daily_breakdown'] as List?) ?? [];

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
              ? 'إجمالي: $totalHours س | $daysWorked يوم'
              : 'Total: ${totalHours}h | $daysWorked days',
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
            '$totalHours${_isAr ? 'س' : 'h'}',
            style: const TextStyle(
              color: _color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                _detailRow(
                  _isAr ? 'إجمالي الساعات' : 'Total Hours',
                  '$totalHours',
                ),
                _detailRow(
                  _isAr ? 'أيام العمل' : 'Days Worked',
                  '$daysWorked',
                ),
                _detailRow(
                  _isAr ? 'متوسط/يوم' : 'Avg/Day',
                  '$avgPerDay',
                ),
              ],
            ),
          ),
          if (breakdown.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: _isAr
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  _isAr ? 'التفاصيل اليومية:' : 'Daily Breakdown:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            ...breakdown.map<Widget>((d) {
              final day = Map<String, dynamic>.from(d as Map);
              return ListTile(
                dense: true,
                leading: const Icon(Icons.circle, color: _color, size: 8),
                title: Text(
                  day['date']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '${day['check_in'] ?? '-'} ? ${day['check_out'] ?? '-'}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[600]),
                ),
                trailing: Text(
                  '${day['hours'] ?? 0}${_isAr ? 'س' : 'h'}',
                  style: const TextStyle(
                    color: _color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
