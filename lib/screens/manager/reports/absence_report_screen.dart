import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class AbsenceReportScreen extends StatefulWidget {
  const AbsenceReportScreen({super.key});
  @override
  State<AbsenceReportScreen> createState() => _AbsenceReportScreenState();
}

class _AbsenceReportScreenState extends State<AbsenceReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getAbsenceReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الغياب'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? const Center(child: Text('لا توجد حالات غياب'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    final absentDates = (item['absent_dates'] as List?) ?? const [];
                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.event_busy, color: Colors.white)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text('غياب: ${item['absent_days'] ?? 0} / ${item['total_working_days'] ?? 0}'),
                        children: absentDates.map<Widget>((d) => ListTile(dense: true, title: Text(d.toString()))).toList(),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
