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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await EosPolicyService.listPolicies();
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
        await EosPolicyService.deletePolicy(policy['id']);
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

  String _salaryBaseLabel(String? code, bool isAr) {
    switch (code) {
      case 'last_basic': return isAr ? '??? ???? ?????' : 'Last basic';
      case 'last_gross': return isAr ? '??? ???? ??????' : 'Last gross';
      case 'avg_3_months': return isAr ? '????? 3 ????' : 'Avg 3 months';
      case 'avg_12_months': return isAr ? '????? 12 ???' : 'Avg 12 months';
      default: return code ?? '';
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
          title: Text(isAr ? '?????? ????? ??????' : 'End of Service'),
          backgroundColor: kEosColor,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(isAr),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: kEosColor,
          icon: const Icon(Icons.add),
          label: Text(isAr ? '????? ?????' : 'New Policy'),
        ),
      ),
    );
  }

  Widget _buildBody(bool isAr) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
            Icon(Icons.card_giftcard, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(isAr ? '?? ???? ????? ??????' : 'No EOS policy',
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
    final tiers = (policy['service_tiers'] as List?) ?? [];
    final baseType = policy['salary_base_type'] as String?;

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
                  color: kEosColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.card_giftcard, color: kEosColor),
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
                      _salaryBaseLabel(baseType, isAr),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kEosColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAr ? '${tiers.length} ?????' : '${tiers.length} tiers',
                  style: const TextStyle(fontSize: 11, color: kEosColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (tiers.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAr ? '????? ??????:' : 'Service Tiers:',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEosColor),
                  ),
                  const SizedBox(height: 6),
                  ...tiers.take(3).map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${t['from_year'] ?? 0} - ${t['to_year'] ?? '?'} ' + (isAr ? '???' : 'yr'),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${t['months_per_year'] ?? 0} ' + (isAr ? '???/???' : 'mo/yr'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kEosColor),
                            ),
                          ],
                        ),
                      )),
                  if (tiers.length > 3)
                    Text(
                      isAr ? '+ ${tiers.length - 3} ????? ????' : '+ ${tiers.length - 3} more',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                ],
              ),
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
                  style: OutlinedButton.styleFrom(foregroundColor: kEosColor),
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
}
