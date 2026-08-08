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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await PayrollCycleService.listPolicies();
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

  Future<void> _confirmDelete(Map<String, dynamic> policy) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? '????? ?????' : 'Confirm Delete'),
        content: Text(isAr
            ? '?? ???? ??? "${policy['name']}"?'
            : 'Delete "${policy['name']}"?'),
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
        await PayrollCycleService.deletePolicy(policy['id']);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? '?? ?????' : 'Deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      } catch (_) {
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

  String _cycleTypeLabel(String? c, bool isAr) {
    switch (c) {
      case 'calendar_month': return isAr ? '??? ??????' : 'Calendar Month';
      case 'custom_month': return isAr ? '???? ?????' : 'Custom Cycle';
      case 'weekly': return isAr ? '??????' : 'Weekly';
      case 'bi_weekly': return isAr ? '??? ????' : 'Bi-Weekly';
      default: return c ?? '';
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
          title: Text(isAr ? '???? ???????' : 'Payroll Cycle'),
          backgroundColor: kCycleColor,
          foregroundColor: Colors.white,
        ),
        body: _buildBody(isAr),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openCreate,
          backgroundColor: kCycleColor,
          icon: const Icon(Icons.add),
          label: Text(isAr ? '????? ????' : 'New Cycle'),
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
            Icon(Icons.calendar_month, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(isAr ? '?? ???? ???? ?????' : 'No payroll cycle',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(isAr ? '???? + ?????? ????' : 'Tap + to create',
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
    final currency = policy['default_currency'] ?? 'EGP';
    final cutoffDay = policy['cutoff_day'];
    final payDay = policy['pay_day'];

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
                  color: kCycleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_month, color: kCycleColor),
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
                      _cycleTypeLabel(policy['cycle_type'], isAr),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kCycleColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  currency,
                  style: const TextStyle(fontSize: 11, color: kCycleColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _row(isAr ? '??? ?????' : 'Cutoff Day', cutoffDay?.toString() ?? '-', isAr),
                const Divider(height: 12),
                _row(isAr ? '??? ?????' : 'Pay Day', payDay?.toString() ?? '-', isAr),
                const Divider(height: 12),
                _row(
                  isAr ? '?????? ???????' : 'Holiday Handling',
                  _holidayLabel(policy['holiday_handling'], isAr),
                  isAr,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openEdit(policy),
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(isAr ? '?????' : 'Edit'),
                  style: OutlinedButton.styleFrom(foregroundColor: kCycleColor),
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

  String _holidayLabel(String? h, bool isAr) {
    switch (h) {
      case 'before': return isAr ? '????? ??? ??????' : 'Pay Before';
      case 'after': return isAr ? '????? ??? ??????' : 'Pay After';
      case 'same': return isAr ? '??? ?????' : 'Same Day';
      default: return '-';
    }
  }

  Widget _row(String label, String value, bool isAr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kCycleColor)),
      ],
    );
  }
}
