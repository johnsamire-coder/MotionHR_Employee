// lib/screens/manager/reports/work_hours_report_screen.dart
import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';
import '../../../services/report_pdf_service.dart';

class WorkHoursReportScreen extends StatefulWidget {
  const WorkHoursReportScreen({super.key});
  @override
  State<WorkHoursReportScreen> createState() => _WorkHoursReportScreenState();
}

class _WorkHoursReportScreenState extends State<WorkHoursReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;

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
      _data = await _service.getWorkHoursReport(
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(isAr ? 'اختر الشهر' : 'Select Month'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setS(() => tempYear--)),
                  Text('$tempYear',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: tempYear < now.year
                          ? () => setS(() => tempYear++)
                          : null),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, childAspectRatio: 1.4),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final m = i + 1;
                  return GestureDetector(
                    onTap: () => setS(() => tempMonth = m),
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: tempMonth == m
                            ? const Color(0xFF6A1B9A)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(_monthName(m, isAr),
                          style: TextStyle(
                              color: tempMonth == m
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 11)),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedYear = tempYear;
                  _selectedMonth = tempMonth;
                });
                Navigator.pop(ctx);
                _load();
              },
              child: Text(isAr ? 'تأكيد' : 'Confirm'),
            ),
          ],
        ),
      ),
    );
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
        title: isAr ? 'تقرير ساعات العمل' : 'Work Hours Report',
        subtitle: '${_monthName(_selectedMonth, isAr)} $_selectedYear',
        headers: isAr
            ? ['اسم الموظف', 'إجمالي الساعات', 'أيام العمل', 'متوسط/يوم']
            : ['Employee', 'Total Hours', 'Days Worked', 'Avg/Day'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في الطباعة: $e')));
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تقرير ساعات العمل' : 'Work Hours Report'),
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
          if (!_loading && _data != null)
            _printing
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)),
                  )
                : IconButton(onPressed: _print, icon: const Icon(Icons.print)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? Center(
                  child: Text(
                    isAr ? 'لا توجد بيانات' : 'No data found',
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: employees.length,
                  itemBuilder: (_, idx) {
                    final item =
                        Map<String, dynamic>.from(employees[idx] as Map);
                    final breakdown =
                        (item['daily_breakdown'] as List?) ?? const [];
                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child:
                              Icon(Icons.access_time, color: Colors.white),
                        ),
                        title:
                            Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text(
                          isAr
                              ? 'إجمالي: ${item['total_hours'] ?? 0} س | ${item['total_days_worked'] ?? 0} يوم'
                              : 'Total: ${item['total_hours'] ?? 0}h | ${item['total_days_worked'] ?? 0} days',
                        ),
                        trailing: Text(
                          '${item['total_hours'] ?? 0}س',
                          style: const TextStyle(
                            color: Colors.indigo,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        children: breakdown.map<Widget>((d) {
                          final day =
                              Map<String, dynamic>.from(d as Map);
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.circle,
                                color: Colors.indigo, size: 10),
                            title: Text(day['date']?.toString() ?? '-'),
                            subtitle: Text(
                                '${day['check_in'] ?? '-'} → ${day['check_out'] ?? '-'}'),
                            trailing: Text(
                              '${day['hours'] ?? 0}س',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}

String _monthName(int month, bool isAr) {
  const ar = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];
  const en = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return isAr ? ar[month] : en[month];
}