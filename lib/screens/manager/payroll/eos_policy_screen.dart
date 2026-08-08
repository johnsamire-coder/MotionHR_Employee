import 'package:flutter/material.dart';
import '../../../services/eos_policy_service.dart';
import 'create_edit_eos_policy_screen.dart';

const Color kEosColor = Color(0xFFF57C00);

class EosPolicyScreen extends StatefulWidget {
  const EosPolicyScreen({super.key});

  @override
  State<EosPolicyScreen> createState() => _EosPolicyScreenState();
}

class _EosPolicyScreenState extends State<EosPolicyScreen> {
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
      final data = await EosPolicyService.listPolicies();
      setState(() { _policies = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEditEosPolicyScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> policy) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEditEosPolicyScreen(existing: policy)),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('مكافأة نهاية الخدمة'),
          backgroundColor: kEosColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: kEosColor,
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
                          const Icon(Icons.workspace_premium, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('لا توجد سياسة مكافأة نهاية الخدمة',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openCreate,
                            icon: const Icon(Icons.add),
                            label: const Text('إنشاء سياسة مكافأة'),
                            style: ElevatedButton.styleFrom(backgroundColor: kEosColor, foregroundColor: Colors.white),
                          ),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _policies.length,
                        itemBuilder: (_, i) {
                          final p = _policies[i];
                          final tiers = (p['service_tiers'] as List?) ?? [];
                          final isSuperseded = p['is_superseded'] ?? false;
                          return Opacity(
                            opacity: isSuperseded ? 0.6 : 1.0,
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFFFCC80)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(p['name'] ?? '',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF3E0),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text('${tiers.length} شرائح',
                                          style: const TextStyle(fontSize: 11, color: kEosColor, fontWeight: FontWeight.bold)),
                                    ),
                                    if (isSuperseded) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('مقفلة', style: TextStyle(fontSize: 11, color: Colors.orange)),
                                      ),
                                    ],
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    'أساس الحساب: ${p['salary_base_type'] ?? ''}  |  نسخة ${p['version_number'] ?? 1}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  ...tiers.take(3).map((t) => Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(children: [
                                      Expanded(
                                        child: Text(
                                          '${t['from_year'] ?? 0} — ${t['to_year']?.toString() ?? '∞'} سنة',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Text('${t['months_per_year']} شهر/سنة',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEosColor)),
                                    ]),
                                  )),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openEdit(Map<String, dynamic>.from(p)),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('تعديل'),
                                        style: OutlinedButton.styleFrom(foregroundColor: kEosColor),
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
}
