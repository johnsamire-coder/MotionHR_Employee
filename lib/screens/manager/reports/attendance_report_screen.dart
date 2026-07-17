import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});
  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _service.getAttendanceReport();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الحضور'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: employees.isEmpty
                  ? ListView(children: const [SizedBox(height: 120), Center(child: Text('لا توجد بيانات'))])
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_month),
                            title: Text('الشهر: ${_data?['month'] ?? '-'} / ${_data?['year'] ?? '-'}'),
                            subtitle: Text('عدد الموظفين: ${_data?['total_employees'] ?? 0}'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...employees.map<Widget>((e) {
                          final item = Map<String, dynamic>.from(e as Map);
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(item['employee_name']?.toString() ?? '-'),
                              subtitle: Text('أيام الحضور: ${item['working_days'] ?? 0}'),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
