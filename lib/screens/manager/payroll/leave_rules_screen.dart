import 'package:flutter/material.dart';
import '../../../services/leave_rule_service.dart';
import 'create_edit_leave_rule_screen.dart';

const Color kLeaveRulesColor = Color(0xFF382483);

class LeaveRulesScreen extends StatefulWidget {
  const LeaveRulesScreen({super.key});

  @override
  State<LeaveRulesScreen> createState() => _LeaveRulesScreenState();
}

class _LeaveRulesScreenState extends State<LeaveRulesScreen> {
  List<dynamic> _rules = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await LeaveRuleService.listRules();
      if (!mounted) return;
      setState(() {
        _rules = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final r = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEditLeaveRuleScreen()),
    );
    if (r == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> rule) async {
    final r = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEditLeaveRuleScreen(existing: rule)),
    );
    if (r == true) _load();
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف قواعد الإجازات؟'),
          content: const Text('سيتم حذف القاعدة نهائياً إذا كانت قابلة للحذف.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    try {
      final ok = await LeaveRuleService.deleteRule(id);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف القاعدة'), backgroundColor: Colors.green),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل حذف القاعدة'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل حذف القاعدة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.calendar_month, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('لا توجد قواعد إجازات', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _openCreate,
          icon: const Icon(Icons.add),
          label: const Text('إنشاء قواعد إجازات'),
          style: ElevatedButton.styleFrom(backgroundColor: kLeaveRulesColor, foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Widget _ruleCard(dynamic rule) {
    final isSuperseded = rule['is_superseded'] ?? false;
    final branchName = rule['branch_name'] ?? '';
    final departmentName = rule['department_name'] ?? '';
    final employeesCount = ((rule['specific_employees'] as List?)?.length ?? 0);

    return Opacity(
      opacity: isSuperseded ? 0.6 : 1,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF9B8BD9), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kLeaveRulesColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_month, color: kLeaveRulesColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(rule['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    'نسخة ${rule['version_number'] ?? 1} · ${rule['scope_display'] ?? ''}',
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
              Expanded(child: _miniBox('سنوية', '${rule['annual_leave_days'] ?? 0} يوم', Color(0xFF382483))),
              const SizedBox(width: 8),
              Expanded(child: _miniBox('مرضية', '${rule['sick_leave_max_days'] ?? 0} يوم', Colors.red)),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _miniBox('طارئة', '${rule['emergency_max_days'] ?? 0} يوم', Colors.amber.shade700)),
              const SizedBox(width: 8),
              Expanded(child: _miniBox('أمومة', '${rule['maternity_days'] ?? 0} يوم', Colors.pink)),
            ]),
            const SizedBox(height: 8),
            Text(
              '${branchName.toString().isNotEmpty ? 'الفرع: $branchName' : ''}'
              '${departmentName.toString().isNotEmpty ? ' · الإدارة: $departmentName' : ''}'
              '${employeesCount > 0 ? ' · $employeesCount موظف' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 3),
            Text(
              'من ${rule['start_date'] ?? ''}${rule['end_date'] != null ? ' · ${rule['end_date']}' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEdit(Map<String, dynamic>.from(rule)),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('تعديل'),
                  style: OutlinedButton.styleFrom(foregroundColor: kLeaveRulesColor),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _delete(rule['id'] as int),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Icon(Icons.delete_outline),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _miniBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 10, color: color)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('قواعد الإجازات'),
          backgroundColor: kLeaveRulesColor,
          foregroundColor: Colors.white,
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: kLeaveRulesColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إنشاء قاعدة'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, textAlign: TextAlign.center))
                : _rules.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rules.length,
                        itemBuilder: (_, i) => _ruleCard(_rules[i]),
                      ),
      ),
    );
  }
}
