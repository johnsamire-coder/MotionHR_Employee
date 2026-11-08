// lib/screens/manager/substitution_summary_screen.dart
//
// ملخص فترة الغياب للمدير (زي صفحة "ملخص فترة الغياب" في الويب):
// اللي اتعمل في الطلبات والإجازات والمهام وهو غايب، ومين كان بديله، وزرار "تعليم كمُراجَع".
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';

const String _kUrl = 'https://jssolutions-eg.com/attendance/api/mobile/manager/substitution-summary/';
const Color _kPrimary = Color(0xFF382483);

class SubstitutionSummaryScreen extends StatefulWidget {
  const SubstitutionSummaryScreen({super.key});
  @override
  State<SubstitutionSummaryScreen> createState() => _SubstitutionSummaryScreenState();
}

class _SubstitutionSummaryScreenState extends State<SubstitutionSummaryScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get(Uri.parse(_kUrl));
      final d = jsonDecode(utf8.decode(res.bodyBytes));
      _data = d is Map<String, dynamic> ? d : null;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAr ? 'فشل التحميل' : 'Failed to load')));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markViewed() async {
    try {
      final res = await ApiClient.post(Uri.parse(_kUrl));
      if (res.statusCode >= 400) throw Exception();
      setState(() => _data?['summary_viewed'] = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr ? 'تم تعليم الملخص كمُراجَع' : 'Marked as reviewed'), backgroundColor: Colors.green));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr ? 'ماتحفظش، حاول تاني' : 'Not saved, try again'), backgroundColor: Colors.red));
      }
    }
  }

  (String, Color) _status(String s) {
    switch (s) {
      case 'approved': return (isAr ? 'موافق' : 'Approved', Colors.green.shade700);
      case 'rejected': return (isAr ? 'مرفوض' : 'Rejected', Colors.red.shade700);
      case 'manager_approved': return (isAr ? 'موافقة المدير' : 'Manager approved', Colors.blue.shade700);
      case 'hr_approved': return (isAr ? 'موافقة HR' : 'HR approved', Colors.blue.shade700);
      case 'cancelled': return (isAr ? 'ملغي' : 'Cancelled', Colors.grey.shade700);
      case 'pending': return (isAr ? 'معلق' : 'Pending', Colors.orange.shade800);
      default: return (s.isEmpty ? '—' : s, Colors.grey.shade700);
    }
  }

  Widget _badge(String s) {
    final (label, c) = _status(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 12, color: c)),
    );
  }

  Widget _section(String title, IconData icon, List items, Widget Function(Map<String, dynamic>) row) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, size: 20, color: _kPrimary), const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
          const Divider(),
          for (final it in items.whereType<Map>()) row(Map<String, dynamic>.from(it)),
        ]),
      ),
    );
  }

  Widget _line(String title, String sub, String status) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
          ),
          _badge(status),
        ]),
      );

  Widget _stat(String label, dynamic v, Color c) => Expanded(
        child: Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Column(children: [
            Text('${v ?? 0}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: c)),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'ملخص فترة الغياب' : 'Absence Period Summary'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (d == null || d['has_summary'] != true)
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                    const SizedBox(height: 10),
                    Text(isAr ? 'لا يوجد سجل غياب سابق' : 'No previous absence record'),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.all(12), children: [
                    Builder(builder: (_) {
                      final p = Map<String, dynamic>.from(d['absence_period'] as Map? ?? {});
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${p['start'] ?? ''} → ${p['end'] ?? ''}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            if ('${p['substitute_name'] ?? ''}'.isNotEmpty)
                              Text('${isAr ? 'البديل' : 'Substitute'}: ${p['substitute_name']}'),
                            const SizedBox(height: 8),
                            d['summary_viewed'] == true
                                ? Row(children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                                    const SizedBox(width: 4),
                                    Text(isAr ? 'تمت المراجعة' : 'Reviewed',
                                        style: TextStyle(color: Colors.green.shade700)),
                                  ])
                                : ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: _kPrimary, foregroundColor: Colors.white),
                                    onPressed: _markViewed,
                                    icon: const Icon(Icons.visibility),
                                    label: Text(isAr ? 'تعليم كمُراجَع' : 'Mark Reviewed'),
                                  ),
                          ]),
                        ),
                      );
                    }),
                    Builder(builder: (_) {
                      final s = Map<String, dynamic>.from(d['stats'] as Map? ?? {});
                      final approved = (num.tryParse('${s['approved_requests'] ?? 0}') ?? 0) +
                          (num.tryParse('${s['approved_leaves'] ?? 0}') ?? 0);
                      return Row(children: [
                        _stat(isAr ? 'إجمالي الطلبات' : 'Total Requests', s['total_requests'], Colors.purple),
                        _stat(isAr ? 'إجمالي الإجازات' : 'Total Leaves', s['total_leaves'], Colors.green.shade700),
                        _stat(isAr ? 'إجمالي المهام' : 'Total Missions', s['total_missions'], Colors.blue.shade700),
                        _stat(isAr ? 'موافقات' : 'Approved', approved, Colors.teal),
                      ]);
                    }),
                    _section(isAr ? 'الطلبات' : 'Requests', Icons.description, d['requests'] as List? ?? [],
                        (r) => _line('${r['employee_name'] ?? ''}',
                            [r['type'], r['subject'], r['updated_at']].where((e) => '${e ?? ''}'.isNotEmpty).join(' • '),
                            '${r['status'] ?? ''}')),
                    _section(isAr ? 'الإجازات' : 'Leaves', Icons.event, d['leaves'] as List? ?? [],
                        (l) => _line('${l['employee_name'] ?? ''}',
                            '${l['leave_type'] ?? ''} • ${l['start_date'] ?? ''} → ${l['end_date'] ?? ''}',
                            '${l['status'] ?? ''}')),
                    _section(isAr ? 'المهام' : 'Missions', Icons.work_outline, d['missions'] as List? ?? [],
                        (m) => _line('${m['title'] ?? ''}', '${m['created_at'] ?? ''}', '${m['status'] ?? ''}')),
                  ]),
                ),
    );
  }
}
