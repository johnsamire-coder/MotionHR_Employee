import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class WorkHoursReportScreen extends StatefulWidget {
  const WorkHoursReportScreen({super.key});
  @override
  State<WorkHoursReportScreen> createState() => _WorkHoursReportScreenState();
}

class _WorkHoursReportScreenState extends State<WorkHoursReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getWorkHoursReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير ساعات العمل'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? const Center(child: Text('لا توجد بيانات'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.access_time)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text('إجمالي: ${item['total_hours'] ?? 0} س - أيام: ${item['total_days_worked'] ?? 0}'),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
