import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';
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
        title: Text('تقرير الغياب'),
        actions: [IconButton(onPressed: _load, icon: Icon(Icons.refresh))],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? Center(child: Text('لا توجد حالات غياب'))
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
