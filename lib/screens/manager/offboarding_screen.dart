import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

class OffboardingScreen extends StatefulWidget {
  const OffboardingScreen({super.key});

  @override
  State<OffboardingScreen> createState() => _OffboardingScreenState();
}

class _OffboardingScreenState extends State<OffboardingScreen> {
  List<dynamic> _offboarded = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final r = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/offboarding/list/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final d = json.decode(utf8.decode(r.bodyBytes));
        setState(() { _offboarded = d['employees'] ?? []; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _showOffboardSheet() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final empIdCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String selectedStatus = 'resigned';

    final statusOptions = [
      {'code': 'resigned',   'ar': 'مستقيل',   'en': 'Resigned'},
      {'code': 'terminated', 'ar': 'مفصول',    'en': 'Terminated'},
      {'code': 'suspended',  'ar': 'موقوف',    'en': 'Suspended'},
      {'code': 'retired',    'ar': 'متقاعد',   'en': 'Retired'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'إنهاء خدمة موظف' : 'Offboard Employee',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: empIdCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'ID الموظف' : 'Employee ID',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: InputDecoration(
                  labelText: isAr ? 'سبب الإنهاء' : 'Reason',
                  border: const OutlineInputBorder(),
                ),
                items: statusOptions.map((s) => DropdownMenuItem(
                  value: s['code'],
                  child: Text(isAr ? s['ar']! : s['en']!),
                )).toList(),
                onChanged: (v) => setModalState(() => selectedStatus = v ?? 'resigned'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final id = int.tryParse(empIdCtrl.text.trim());
                    if (id == null) return;
                    Navigator.pop(ctx);
                    await _offboard(id, selectedStatus, reasonCtrl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isAr ? 'إنهاء الخدمة' : 'Offboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _offboard(int empId, String status, String reason) async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final r = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/offboarding/$empId/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: json.encode({'status': status, 'reason': reason}),
      );
      final d = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(d['message'] ?? d['error'] ?? ''),
          backgroundColor: d['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (d['success'] == true) _load();
    } catch (_) {}
  }

  Future<void> _reactivate(int empId) async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final r = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/offboarding/$empId/reactivate/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: json.encode({}),
      );
      final d = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(d['message'] ?? ''), backgroundColor: Colors.green),
      );
      _load();
    } catch (_) {}
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resigned':   return Colors.orange;
      case 'terminated': return Colors.red;
      case 'suspended':  return Colors.purple;
      case 'retired':    return Colors.blue;
      default:           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إنهاء الخدمة' : 'Offboarding'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showOffboardSheet,
        backgroundColor: Colors.red,
        child: const Icon(Icons.person_remove, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _offboarded.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Text(
                        isAr ? 'مفيش موظفين منتهية خدمتهم' : 'No offboarded employees',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offboarded.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final emp = _offboarded[index] as Map<String, dynamic>;
                      final statusColor = _statusColor(emp['status'] ?? '');
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: statusColor.withValues(alpha: 0.12),
                              child: Icon(Icons.person_off, color: statusColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${emp['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${emp['department']} — ${emp['job_title']}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${emp['status_label']}',
                                      style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.restart_alt, color: Colors.green),
                              tooltip: isAr ? 'إعادة تفعيل' : 'Reactivate',
                              onPressed: () => _reactivate(emp['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
