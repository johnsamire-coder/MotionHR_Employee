// lib/screens/manager/reports/absence_report_screen.dart
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
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _printing = false;

  // â”€â”€â”€ Date Filter â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
      _data = await _service.getAbsenceReport(
        year: _selectedYear,
        month: _selectedMonth,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط®ط·ط£: $e')),
        );
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
          title: Text(isAr ? 'ط§ط®طھط± ط§ظ„ط´ظ‡ط±' : 'Select Month'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setS(() => tempYear--),
                  ),
                  Text(
                    '$tempYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: tempYear < now.year
                        ? () => setS(() => tempYear++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Month grid
              GridView.builder(
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.4,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final m = i + 1;
                  final selected =
                      m == tempMonth && tempYear == _selectedYear;
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
                      child: Text(
                        _monthName(m, isAr),
                        style: TextStyle(
                          color: tempMonth == m
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(isAr ? 'ط¥ظ„ط؛ط§ط،' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedYear = tempYear;
                  _selectedMonth = tempMonth;
                });
                Navigator.pop(ctx);
                _load();
              },
              child: Text(isAr ? 'طھط£ظƒظٹط¯' : 'Confirm'),
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
      final rows = <List<String>>[];

      for (var e in employees) {
        final item = Map<String, dynamic>.from(e as Map);
        final absentDates = (item['absent_dates'] as List?) ?? [];
        rows.add([
          item['employee_name']?.toString() ?? '-',
          '${item['absent_days'] ?? 0}',
          '${item['total_working_days'] ?? 0}',
          absentDates.take(5).join(', '),
        ]);
      }

      await ReportPdfService.printReport(
        title: isAr ? 'طھظ‚ط±ظٹط± ط§ظ„ط؛ظٹط§ط¨' : 'Absence Report',
        subtitle:
            '${_monthName(_selectedMonth, isAr)} $_selectedYear',
        headers: isAr
            ? ['ط§ط³ظ… ط§ظ„ظ…ظˆط¸ظپ', 'ط£ظٹط§ظ… ط§ظ„ط؛ظٹط§ط¨', 'ط£ظٹط§ظ… ط§ظ„ط¹ظ…ظ„', 'طھظˆط§ط±ظٹط® ط§ظ„ط؛ظٹط§ط¨']
            : ['Employee', 'Absent Days', 'Working Days', 'Dates'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ط®ط·ط£ ظپظٹ ط§ظ„ط·ط¨ط§ط¹ط©: $e')),
        );
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'طھظ‚ط±ظٹط± ط§ظ„ط؛ظٹط§ط¨' : 'Absence Report'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          // Month Picker Button
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: _print,
                    icon: const Icon(Icons.print),
                  ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // â”€â”€â”€ Summary Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                _SummaryCard(data: _data, isAr: isAr),

                // â”€â”€â”€ List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                Expanded(
                  child: employees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                isAr
                                    ? 'ظ„ط§ ظٹظˆط¬ط¯ ط؛ظٹط§ط¨ ظپظٹ ظ‡ط°ط§ ط§ظ„ط´ظ‡ط± âœ…'
                                    : 'No absences this month âœ…',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: employees.length,
                          itemBuilder: (_, idx) {
                            final item = Map<String, dynamic>.from(
                                employees[idx] as Map);
                            final absentDates =
                                (item['absent_dates'] as List?) ?? [];
                            return Card(
                              child: ExpansionTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.redAccent,
                                  child: Icon(
                                    Icons.event_busy,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  item['employee_name']?.toString() ?? '-',
                                ),
                                subtitle: Text(
                                  isAr
                                      ? 'ط؛ظٹط§ط¨: ${item['absent_days'] ?? 0} / ${item['total_working_days'] ?? 0} ظٹظˆظ…'
                                      : 'Absent: ${item['absent_days'] ?? 0} / ${item['total_working_days'] ?? 0} days',
                                ),
                                children: absentDates
                                    .map<Widget>(
                                      (d) => ListTile(
                                        dense: true,
                                        leading: const Icon(
                                          Icons.circle,
                                          color: Colors.red,
                                          size: 10,
                                        ),
                                        title: Text(d.toString()),
                                      ),
                                    )
                                    .toList(),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// â”€â”€â”€ Summary Card Widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _SummaryCard extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool isAr;
  const _SummaryCard({this.data, required this.isAr});

  @override
  Widget build(BuildContext context) {
    if (data == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
            isAr ? 'ط£ظٹط§ظ… ط§ظ„ط¹ظ…ظ„' : 'Working Days',
            '${data!['total_working_days_in_month'] ?? 0}',
            Colors.blue,
          ),
          _statItem(
            isAr ? 'ظ…ظˆط¸ظپظٹظ† ط؛ط§ط¦ط¨ظٹظ†' : 'Employees Absent',
            '${data!['total_employees_with_absence'] ?? 0}',
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// â”€â”€â”€ Month Name Helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
String _monthName(int month, bool isAr) {
  const ar = [
    '', 'ظٹظ†ط§ظٹط±', 'ظپط¨ط±ط§ظٹط±', 'ظ…ط§ط±ط³', 'ط£ط¨ط±ظٹظ„', 'ظ…ط§ظٹظˆ', 'ظٹظˆظ†ظٹظˆ',
    'ظٹظˆظ„ظٹظˆ', 'ط£ط؛ط³ط·ط³', 'ط³ط¨طھظ…ط¨ط±', 'ط£ظƒطھظˆط¨ط±', 'ظ†ظˆظپظ…ط¨ط±', 'ط¯ظٹط³ظ…ط¨ط±'
  ];
  const en = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return isAr ? ar[month] : en[month];
}
