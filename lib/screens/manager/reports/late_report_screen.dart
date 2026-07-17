import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class LateReportScreen extends StatefulWidget {
  const LateReportScreen({super.key});
  @override
  State<LateReportScreen> createState() => _LateReportScreenState();
}

class _LateReportScreenState extends State<LateReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getLateReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير التأخير'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? const Center(child: Text('لا توجد حالات تأخير'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    final details = (item['details'] as List?) ?? const [];
                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text('أيام التأخير: ${item['total_late_days'] ?? 0} - ${item['total_late_hours'] ?? 0} س'),
                        children: details.map<Widget>((d) {
                          final detail = Map<String, dynamic>.from(d as Map);
                          return ListTile(
                            dense: true,
                            title: Text('${detail['date']} - ${detail['time']}'),
                            trailing: Text('${detail['minutes_late']} دقيقة'),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
