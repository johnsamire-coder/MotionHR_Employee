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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await TaxPolicyService.listPolicies();
      setState(() {
        _policies = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateEditTaxPolicyScreen(),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _openEdit(Map<String, dynamic> policy) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEditTaxPolicyScreen(existing: policy),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _confirmDelete(Map<String, dynamic> policy) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? '????? ?????' : 'Confirm Delete'),
        content: Text(isAr
            ? '?? ???? ??? ????? "${policy['name']}"?'
            : 'Delete policy "${policy['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? '?????' : 'Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? '???' : 'Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await TaxPolicyService.deletePolicy(policy['id']);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? '?? ?????' : 'Deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? '??? ?????' : 'Failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(isAr ? '????? ???????' : 'Tax Policy'),
          backgroundColor: kTaxPolicyColor,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(isAr),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: kTaxPolicyColor,
          icon: const Icon(Icons.add),
          label: Text(isAr ? '????? ?????' : 'New Policy'),
        ),
      ),
    );
  }

  Widget _buildBody(bool isAr) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(isAr ? '???? ?????' : 'Error',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(isAr ? '????? ????????' : 'Retry'),
            ),
          ],
        ),
      );
    }

    final active = _policies.where((p) => p['is_superseded'] != true).toList();

    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(isAr ? '?? ???? ????? ?????' : 'No tax policy',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(isAr ? '???? + ?????? ??? ?????' : 'Tap + to create',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: active.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _policyCard(active[i], isAr),
      ),
    );
  }

  Widget _policyCard(Map<String, dynamic> policy, bool isAr) {
    final brackets = (policy['tax_brackets'] as List?) ?? [];
    final singleExemption = policy['personal_exemption_single'] ?? 0;
    final marriedExemption = policy['personal_exemption_married'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kTaxPolicyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long, color: kTaxPolicyColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      policy['name'] ?? '',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${policy['country'] ?? ''} - ${policy['tax_year'] ?? ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kTaxPolicyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAr ? '${brackets.length} ?????' : '${brackets.length} brackets',
                  style: const TextStyle(fontSize: 11, color: kTaxPolicyColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? '????????? ???????:' : 'Personal Exemptions:',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _exemptionRow(isAr ? '????' : 'Single', singleExemption, isAr),
                    ),
                    Expanded(
                      child: _exemptionRow(isAr ? '?????' : 'Married', marriedExemption, isAr),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (brackets.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              isAr ? '??????? ????????:' : 'Tax Brackets:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ...brackets.take(3).map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${b['from'] ?? 0} - ${b['to'] ?? '?'} EGP',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        '${b['rate'] ?? 0}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kTaxPolicyColor),
                      ),
                    ],
                  ),
                )),
            if (brackets.length > 3)
              Text(
                isAr ? '+ ${brackets.length - 3} ????? ????' : '+ ${brackets.length - 3} more',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEdit(policy),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(isAr ? '?????' : 'Edit'),
                  style: OutlinedButton.styleFrom(foregroundColor: kTaxPolicyColor),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDelete(policy),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _exemptionRow(String label, dynamic value, bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        const SizedBox(height: 2),
        Text('$value EGP', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
