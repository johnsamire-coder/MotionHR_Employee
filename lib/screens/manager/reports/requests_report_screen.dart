import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class RequestsReportScreen extends StatefulWidget {
  const RequestsReportScreen({super.key});
  @override
  State<RequestsReportScreen> createState() => _RequestsReportScreenState();
}

class _RequestsReportScreenState extends State<RequestsReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getRequestsReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final details = (_data?['details'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الطلبات'),
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
                        Text('إجمالي الطلبات: ${_data?['total_requests'] ?? 0}'),
                        const SizedBox(height: 4),
                        Text('موافق: ${_data?['approved'] ?? 0} | مرفوض: ${_data?['rejected'] ?? 0} | معلق: ${_data?['pending'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...details.map<Widget>((r) {
                  final item = Map<String, dynamic>.from(r as Map);
                  return Card(
                    child: ListTile(
                      title: Text(item['employee_name']?.toString() ?? '-'),
                      subtitle: Text('${item['category']} - ${item['subject']}'),
                      trailing: Chip(label: Text(item['status']?.toString() ?? '-')),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
