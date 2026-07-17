import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class LeavesReportScreen extends StatefulWidget {
  const LeavesReportScreen({super.key});
  @override
  State<LeavesReportScreen> createState() => _LeavesReportScreenState();
}

class _LeavesReportScreenState extends State<LeavesReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getLeavesReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الإجازات'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('إجمالي الإجازات: ${_data?['total_leaves'] ?? 0}'),
                        const SizedBox(height: 4),
                        Text('موافق: ${_data?['approved'] ?? 0} | مرفوض: ${_data?['rejected'] ?? 0} | معلق: ${_data?['pending'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...employees.map<Widget>((e) {
                  final item = Map<String, dynamic>.from(e as Map);
                  final lvs = (item['leaves'] as List?) ?? const [];
                  return Card(
                    child: ExpansionTile(
                      title: Text(item['name']?.toString() ?? '-'),
                      subtitle: Text('إجمالي: ${item['total_days'] ?? 0} - موافق: ${item['approved_days'] ?? 0}'),
                      children: lvs.map<Widget>((l) {
                        final lv = Map<String, dynamic>.from(l as Map);
                        return ListTile(
                          dense: true,
                          title: Text('${lv['type']} - ${lv['days']} يوم'),
                          subtitle: Text('من ${lv['from']} إلى ${lv['to']}'),
                          trailing: Chip(label: Text(lv['status']?.toString() ?? '-')),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
