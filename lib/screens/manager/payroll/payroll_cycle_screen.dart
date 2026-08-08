import 'package:flutter/material.dart';
import '../../../services/payroll_cycle_service.dart';
import 'create_edit_payroll_cycle_screen.dart';

const Color kCycleColor = Color(0xFF5E35B1);

class PayrollCycleScreen extends StatefulWidget {
  const PayrollCycleScreen({super.key});

  @override
  State<PayrollCycleScreen> createState() => _PayrollCycleScreenState();
}

class _PayrollCycleScreenState extends State<PayrollCycleScreen> {
  List<dynamic> _policies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await PayrollCycleService.listPolicies();
      setState(() { _policies = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openCreate() async {
    final r = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEditPayrollCycleScreen()),
    );
    if (r == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> policy) async {
    final r = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEditPayrollCycleScreen(existing: policy)),
    );
    if (r == true) _load();
  }

  String _cycleLabel(String? type) {
    switch (type) {
      case 'calendar_month': return 'شهر ميلادي';
      case 'custom_month':   return 'شهر مخصص';
      case 'weekly':         return 'أسبوعي';
      case 'bi_weekly':      return 'كل أسبوعين';
      default:               return type ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('دورة الرواتب'),
          backgroundColor: kCycleColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: kCycleColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إنشاء سياسة'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('إعادة المحاولة')),
                    ]),
                  )
                : _policies.isEmpty
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.calendar_month, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('لا توجد سياسة دورة رواتب',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openCreate,
                            icon: const Icon(Icons.add),
                            label: const Text('إنشاء سياسة دورة رواتب'),
                            style: ElevatedButton.styleFrom(backgroundColor: kCycleColor, foregroundColor: Colors.white),
                          ),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _policies.length,
                        itemBuilder: (_, i) {
                          final p = _policies[i];
                          final isSuperseded = p['is_superseded'] ?? false;
                          return Opacity(
                            opacity: isSuperseded ? 0.6 : 1.0,
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFCE93D8)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Container(
                                      width: 36, height: 36,
                                      decoration: BoxDecoration(
                                        color: kCycleColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.calendar_month, color: kCycleColor, size: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(_cycleLabel(p['cycle_type']),
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        Text(
                                          'نسخة ${p['version_number'] ?? 1}  ·  ${p['default_currency'] ?? 'EGP'}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                        ),
                                      ]),
                                    ),
                                    if (isSuperseded)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('مقفلة', style: TextStyle(fontSize: 11, color: Colors.orange)),
                                      ),
                                  ]),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                      child: _infoChip(Icons.calendar_today, 'يوم الصرف', '${p['pay_day'] ?? '-'}'),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _infoChip(Icons.check_circle_outline, 'الموافقة', p['approval_level'] ?? ''),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  Text(
                                    'من ${p['start_date'] ?? ''}${p['end_date'] != null ? '  إلى  ${p['end_date']}' : ''}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openEdit(Map<String, dynamic>.from(p)),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('تعديل'),
                                        style: OutlinedButton.styleFrom(foregroundColor: kCycleColor),
                                      ),
                                    ),
                                  ]),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}
