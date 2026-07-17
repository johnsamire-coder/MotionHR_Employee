import 'package:flutter/material.dart';
import '../../../services/payroll_service.dart';

class PayrollSettingsScreen extends StatefulWidget {
  const PayrollSettingsScreen({super.key});
  @override
  State<PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<PayrollSettingsScreen> {
  final _service = PayrollService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getSettings(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الرواتب')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('لا توجد بيانات'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.blue),
                        title: Text('ملاحظة'),
                        subtitle: Text('الإعدادات حالياً ثابتة وستكون قابلة للتعديل لاحقاً'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(Icons.money_off, 'خصم التأخير / دقيقة', '${_data?['late_deduction_per_minute'] ?? '-'} ج'),
                    _card(Icons.event_busy, 'خصم الغياب / يوم', '${_data?['absence_deduction_per_day'] ?? '-'} ج'),
                    _card(Icons.more_time, 'معدل Overtime / ساعة', '${_data?['overtime_rate_per_hour'] ?? '-'} ج'),
                  ],
                ),
    );
  }

  Widget _card(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon, size: 20)),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
