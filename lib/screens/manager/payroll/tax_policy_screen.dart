import 'package:flutter/material.dart';
import '../../../services/tax_policy_service.dart';
import 'create_edit_tax_policy_screen.dart';

const Color kTaxPolicyColor = Color(0xFFE65100);

class TaxPolicyScreen extends StatefulWidget {
  const TaxPolicyScreen({super.key});

  @override
  State<TaxPolicyScreen> createState() => _TaxPolicyScreenState();
}

class _TaxPolicyScreenState extends State<TaxPolicyScreen> {
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
      final data = await TaxPolicyService.listPolicies();
      setState(() { _policies = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEditTaxPolicyScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> policy) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEditTaxPolicyScreen(existing: policy)),
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
          title: const Text('سياسة الضرائب'),
          backgroundColor: kTaxPolicyColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: kTaxPolicyColor,
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
                          const Icon(Icons.percent, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('لا توجد سياسة ضرائب',
                              style: TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _openCreate,
                            icon: const Icon(Icons.add),
                            label: const Text('إنشاء سياسة ضرائب'),
                            style: ElevatedButton.styleFrom(backgroundColor: kTaxPolicyColor, foregroundColor: Colors.white),
                          ),
                        ]),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _policies.length,
                        itemBuilder: (_, i) {
                          final p = _policies[i];
                          final brackets = (p['tax_brackets'] as List?) ?? [];
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
                                    if (isSuperseded)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('مقفلة', style: TextStyle(fontSize: 11, color: Colors.orange)),
                                      ),
                                    if (!(p['is_active'] ?? true) && !isSuperseded)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text('معطلة', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                      ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    'إعفاء شخصي: ${p['personal_exemption_single'] ?? 0} EGP  |  نسخة ${p['version_number'] ?? 1}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  ...brackets.take(3).map((b) => Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(children: [
                                      Expanded(
                                        child: Text(
                                          '${b['from']?.toString() ?? '0'} — ${b['to']?.toString() ?? '∞'} EGP',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Text('${b['rate']}%',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTaxPolicyColor)),
                                    ]),
                                  )),
                                  if (brackets.length > 3)
                                    Text('+ ${brackets.length - 3} شرائح أخرى',
                                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  const SizedBox(height: 10),
                                  Row(children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openEdit(Map<String, dynamic>.from(p)),
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('تعديل'),
                                        style: OutlinedButton.styleFrom(foregroundColor: kTaxPolicyColor),
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
