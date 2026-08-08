import 'package:flutter/material.dart';
import '../../../services/allowance_rule_service.dart';
import 'create_edit_allowance_rule_screen.dart';

const Color kAllowanceListColor = Color(0xFFE65100);

class AllowanceRulesScreen extends StatefulWidget {
  const AllowanceRulesScreen({super.key});

  @override
  State<AllowanceRulesScreen> createState() => _AllowanceRulesScreenState();
}

class _AllowanceRulesScreenState extends State<AllowanceRulesScreen> {
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
      final data = await AllowanceRuleService.listRules();
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
      MaterialPageRoute(builder: (_) => const CreateEditAllowanceRuleScreen()),
    );
    if (r == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> rule) async {
    final r = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEditAllowanceRuleScreen(existing: rule)),
    );
    if (r == true) _load();
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف قاعدة البدل؟'),
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
      final ok = await AllowanceRuleService.deleteRule(id);
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
        const Icon(Icons.attach_money, size: 64, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('لا توجد قواعد بدلات', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _openCreate,
          icon: const Icon(Icons.add),
          label: const Text('إنشاء قاعدة بدل'),
          style: ElevatedButton.styleFrom(backgroundColor: kAllowanceListColor, foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Widget _ruleCard(dynamic rule) {
    final tiers = (rule['tiers'] as List?) ?? [];
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
          side: const BorderSide(color: Color(0xFFFFCC80), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kAllowanceListColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.attach_money, color: kAllowanceListColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(rule['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    '${rule['allowance_type_display'] ?? rule['allowance_type'] ?? ''} · نسخة ${rule['version_number'] ?? 1}',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: rule['calculation_type'] != 'tiered'
                  ? Text(
                      'المبلغ: ${rule['fixed_amount'] ?? 0} EGP',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    )
                  : Text(
                      'الشرائح: ${tiers.length}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              '${rule['scope_display'] ?? ''}'
              '${branchName.toString().isNotEmpty ? ' · $branchName' : ''}'
              '${departmentName.toString().isNotEmpty ? ' · $departmentName' : ''}'
              '${employeesCount > 0 ? ' · $employeesCount موظف' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 3),
            Text(
              'من ${rule['start_date'] ?? ''}${rule['end_date'] != null ? ' · إلى ${rule['end_date']}' : ''}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEdit(Map<String, dynamic>.from(rule)),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('تعديل'),
                  style: OutlinedButton.styleFrom(foregroundColor: kAllowanceListColor),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('قواعد البدلات'),
          backgroundColor: kAllowanceListColor,
          foregroundColor: Colors.white,
          actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: kAllowanceListColor,
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
