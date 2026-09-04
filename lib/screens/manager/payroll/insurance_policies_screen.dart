import 'package:flutter/material.dart';
import '../../../services/insurance_policy_service.dart';
import 'create_edit_insurance_policy_screen.dart';

const Color kInsuranceColor = Color(0xFF00C688);
const Color kSocialColor    = Color(0xFF1A0A3E);
const Color kMedicalColor   = Color(0xFF388E3C);

class InsurancePoliciesScreen extends StatefulWidget {
  const InsurancePoliciesScreen({super.key});

  @override
  State<InsurancePoliciesScreen> createState() => _InsurancePoliciesScreenState();
}

class _InsurancePoliciesScreenState extends State<InsurancePoliciesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _policies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await InsurancePolicyService.listPolicies();
      setState(() { _policies = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateEditInsurancePolicyScreen()),
    );
    if (result == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> policy) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEditInsurancePolicyScreen(existing: policy)),
    );
    if (result == true) _load();
  }

  List<dynamic> get _socialPolicies => _policies.where((p) => p['insurance_type'] == 'social').toList();
  List<dynamic> get _medicalPolicies => _policies.where((p) => p['insurance_type'] == 'medical').toList();

  @override
  Widget build(BuildContext context) {
    final socialCount  = _policies.where((p) => p['insurance_type'] == 'social'  && !(p['is_superseded'] ?? false)).length;
    final medicalCount = _policies.where((p) => p['insurance_type'] == 'medical' && !(p['is_superseded'] ?? false)).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('سياسات التأمين'),
          backgroundColor: kInsuranceColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
          bottom: TabBar(
            controller: _tab,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'الكل (${_policies.length})'),
              Tab(text: 'اجتماعي ($socialCount)'),
              Tab(text: 'طبي ($medicalCount)'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: kInsuranceColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('إضافة سياسة'),
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
                : TabBarView(
                    controller: _tab,
                    children: [
                      _buildList(_policies),
                      _buildList(_socialPolicies),
                      _buildList(_medicalPolicies),
                    ],
                  ),
      ),
    );
  }

  Widget _buildList(List<dynamic> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shield_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('لا توجد سياسات تأمين',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: const Text('إضافة سياسة تأمين'),
            style: ElevatedButton.styleFrom(backgroundColor: kInsuranceColor, foregroundColor: Colors.white),
          ),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        final isSocial     = p['insurance_type'] == 'social';
        final typeColor    = isSocial ? kSocialColor : kMedicalColor;
        final typeBg       = isSocial ? const Color(0xFFEDEAF7) : const Color(0xFFE8F5E9);
        final isSuperseded = p['is_superseded'] ?? false;

        return Opacity(
          opacity: isSuperseded ? 0.6 : 1.0,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: typeColor.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(8)),
                    child: Icon(isSocial ? Icons.shield : Icons.medical_services, color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['name_ar'] ?? '',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(
                        '${isSocial ? "تأمين اجتماعي" : "تأمين طبي"}  ·  نسخة ${p['version_number'] ?? 1}',
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
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('حصة الشركة', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text(
                          '${p['company_share_value']}${p['company_share_type'] == 'percent' ? '%' : ' EGP'}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('حصة الموظف', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                        Text(
                          '${p['employee_share_value']}${p['employee_share_type'] == 'percent' ? '%' : ' EGP'}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ]),
                    ),
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
                      style: OutlinedButton.styleFrom(foregroundColor: typeColor),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        );
      },
    );
  }
}
