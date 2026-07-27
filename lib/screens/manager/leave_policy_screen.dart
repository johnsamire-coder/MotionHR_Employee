import 'package:flutter/material.dart';
import '../../services/leave_policy_service.dart';

const Color kLeavePolicyColor = Color(0xFF1B5E20);

class LeavePolicyScreen extends StatefulWidget {
  const LeavePolicyScreen({super.key});
  @override
  State<LeavePolicyScreen> createState() => _LeavePolicyScreenState();
}

class _LeavePolicyScreenState extends State<LeavePolicyScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  List<Map<String, dynamic>> _policies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final policies = await LeavePolicyService.getPolicies();
      setState(() { _policies = policies; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _showApplyPolicyDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'تطبيق السياسة على الموظفين الحاليين' : 'Apply Policy to Existing Employees'),
          content: Text(isAr
              ? 'هذا سيحسب ويحدث أرصدة الإجازات لكل الموظفين الحاليين حسب السياسة النشطة. هل أنت متأكد؟'
              : 'This will calculate and update leave balances for all existing employees based on the active policy. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'تراجع' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: Text(isAr ? 'تطبيق الآن' : 'Apply Now'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _loading = true);
      final result = await LeavePolicyService.applyPolicyToExistingEmployees();
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'تم التطبيق: ${result['created_balances']} رصيد جديد، ${result['updated_balances']} تحديث'
              : 'Applied: ${result['created_balances']} new, ${result['updated_balances']} updated'),
          backgroundColor: Colors.teal,
          duration: const Duration(seconds: 5),
        ));
        _load();
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }
  

  Future<void> _approve(Map<String, dynamic> policy) async {
    try {
      await LeavePolicyService.approvePolicy(policy['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم اعتماد السياسة' : 'Policy approved'),
          backgroundColor: Colors.green,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _delete(Map<String, dynamic> policy) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAr ? 'حذف السياسة' : 'Delete Policy'),
        content: Text('${isAr ? 'هل تريد حذف' : 'Delete'} "${policy['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'تراجع' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(isAr ? 'حذف' : 'Delete',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await LeavePolicyService.deletePolicy(policy['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم حذف السياسة' : 'Policy deleted'),
          backgroundColor: Colors.green,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'active': return Colors.green;
      case 'archived': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'draft': return isAr ? 'مسودة' : 'Draft';
      case 'active': return isAr ? 'نشط' : 'Active';
      case 'archived': return isAr ? 'مؤرشف' : 'Archived';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(isAr ? 'سياسات الإجازات' : 'Leave Policies',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: kLeavePolicyColor,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kLeavePolicyColor))
            : _error != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 12),
                    Text(_error ?? ''),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _load,
                        style: ElevatedButton.styleFrom(backgroundColor: kLeavePolicyColor,
                            foregroundColor: Colors.white),
                        child: Text(isAr ? 'إعادة المحاولة' : 'Retry')),
                  ]))
                : _policies.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.beach_access_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(isAr ? 'لا توجد سياسات إجازات' : 'No leave policies',
                            style: const TextStyle(fontSize: 18, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(isAr ? 'اضغط + لإنشاء سياسة جديدة' : 'Press + to create',
                            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _policies.length,
                          itemBuilder: (_, i) => _buildCard(_policies[i]),
                        ),
                      ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              heroTag: 'apply_policy',
              onPressed: _showApplyPolicyDialog,
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.people, color: Colors.white),
              label: Text(isAr ? 'تطبيق على الحاليين' : 'Apply to Existing',
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'new_policy',
              onPressed: () async {
                final r = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CreateEditLeavePolicyScreen()));
                if (r == true) _load();
              },
              backgroundColor: kLeavePolicyColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(isAr ? 'سياسة جديدة' : 'New Policy',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> policy) {
    final status = policy['status'] ?? 'draft';
    final sc = _statusColor(status);
    final tiers = policy['tiers'] as List? ?? [];
    final typeRules = policy['type_rules'] as List? ?? [];
    final enabledRules = typeRules.where((r) => r['enabled'] == true).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(policy['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: sc.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sc.withAlpha(100)),
              ),
              child: Text(_statusLabel(status),
                  style: TextStyle(color: sc, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('${isAr ? 'من' : 'From'}: ${policy['effective_from'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            if (tiers.isNotEmpty)
              _chip('${tiers.length} ${isAr ? 'شريحة خدمة' : 'tiers'}', Colors.blue),
            if (enabledRules > 0)
              _chip('$enabledRules ${isAr ? 'نوع إجازة' : 'leave types'}', Colors.teal),
            _chip(
              '${isAr ? 'تجربة' : 'Probation'}: ${policy['probation_months']} ${isAr ? 'شهر' : 'mo'}',
              Colors.purple,
            ),
          ]),
          const Divider(height: 16),
          Row(children: [
            TextButton.icon(
              onPressed: () async {
                final r = await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CreateEditLeavePolicyScreen(policy: policy)));
                if (r == true) _load();
              },
              icon: const Icon(Icons.edit, size: 16),
              label: Text(isAr ? 'تعديل' : 'Edit'),
              style: TextButton.styleFrom(foregroundColor: kLeavePolicyColor),
            ),
            TextButton.icon(
              onPressed: () async {
                final r = await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LeaveBalanceAdjustmentScreen()));
                if (r == true) _load();
              },
              icon: const Icon(Icons.account_balance_wallet, size: 16),
              label: Text(isAr ? 'الأرصدة' : 'Balances'),
              style: TextButton.styleFrom(foregroundColor: Colors.teal),
            ),
            TextButton.icon(
              onPressed: () async {
                final r = await Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LeaveTypeRulesScreen(policy: policy)));
                if (r == true) _load();
              },
              icon: const Icon(Icons.rule, size: 16),
              label: Text(isAr ? 'القواعد' : 'Rules'),
              style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
            ),
            const Spacer(),
            if (status == 'draft')
              ElevatedButton(
                onPressed: () => _approve(policy),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                child: Text(isAr ? 'اعتماد' : 'Approve',
                    style: const TextStyle(fontSize: 12)),
              ),
            if (status != 'active')
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _delete(policy),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

// ════════════════════════════════════
// شاشة إنشاء / تعديل سياسة الإجازات
// ════════════════════════════════════
class CreateEditLeavePolicyScreen extends StatefulWidget {
  final Map<String, dynamic>? policy;
  const CreateEditLeavePolicyScreen({super.key, this.policy});
  @override
  State<CreateEditLeavePolicyScreen> createState() =>
      _CreateEditLeavePolicyScreenState();
}

class _CreateEditLeavePolicyScreenState
    extends State<CreateEditLeavePolicyScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  bool get isEdit => widget.policy != null;

  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _effectiveFrom = DateTime.now();
  DateTime? _effectiveTo;
  int _probationMonths = 3;
  String _probationLeaveMode = 'blocked';
  String _accrualMode = 'annual_lump';
  bool _saving = false;

  List<Map<String, dynamic>> _tiers = [
    {'from_months': 0, 'to_months': 24, 'annual_entitlement_days': 21.0, 'description': ''},
    {'from_months': 25, 'to_months': null, 'annual_entitlement_days': 30.0, 'description': ''},
  ];

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final p = widget.policy!;
      _nameCtrl.text = p['name'] ?? '';
      _notesCtrl.text = p['notes'] ?? '';
      if (p['effective_from'] != null) {
        _effectiveFrom = DateTime.tryParse(p['effective_from']) ?? DateTime.now();
      }
      if (p['effective_to'] != null) {
        _effectiveTo = DateTime.tryParse(p['effective_to']);
      }
      _probationMonths = p['probation_months'] ?? 3;
      _probationLeaveMode = p['probation_leave_mode'] ?? 'blocked';
      _accrualMode = p['accrual_mode'] ?? 'annual_lump';
      if ((p['tiers'] as List? ?? []).isNotEmpty) {
        _tiers = List<Map<String, dynamic>>.from(p['tiers']);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _effectiveFrom : (_effectiveTo ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => isStart ? _effectiveFrom = picked : _effectiveTo = picked);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'اسم السياسة مطلوب' : 'Policy name required'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _saving = true);
    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'effective_from': _fmt(_effectiveFrom),
        'effective_to': _effectiveTo != null ? _fmt(_effectiveTo!) : null,
        'probation_months': _probationMonths,
        'probation_leave_mode': _probationLeaveMode,
        'accrual_mode': _accrualMode,
        'notes': _notesCtrl.text.trim(),
        'tiers': _tiers,
      };
      if (isEdit) {
        await LeavePolicyService.updatePolicy(widget.policy!['id'], body);
      } else {
        await LeavePolicyService.createPolicy(body);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم الحفظ بنجاح' : 'Saved successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isEdit
                ? (isAr ? 'تعديل السياسة' : 'Edit Policy')
                : (isAr ? 'سياسة إجازات جديدة' : 'New Leave Policy'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kLeavePolicyColor,
          foregroundColor: Colors.white,
        ),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          // البيانات الأساسية
          _sectionTitle(isAr ? 'البيانات الأساسية' : 'Basic Info'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: isAr ? 'اسم السياسة *' : 'Policy Name *',
              prefixIcon: const Icon(Icons.beach_access, color: kLeavePolicyColor),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _pickDate(isStart: true),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: isAr ? 'سارية من *' : 'Effective From *',
                prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                border: const OutlineInputBorder(),
              ),
              child: Text(_fmt(_effectiveFrom),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
              prefixIcon: const Icon(Icons.notes, color: kLeavePolicyColor),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // إعدادات فترة التجربة
          _sectionTitle(isAr ? 'فترة التجربة' : 'Probation Period'),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _probationMonths.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isAr ? 'مدة التجربة (بالشهور)' : 'Probation (months)',
              helperText: isAr ? '0 = لا توجد فترة تجربة' : '0 = no probation',
              prefixIcon: const Icon(Icons.timer, color: Colors.orange),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => _probationMonths = int.tryParse(v) ?? 3,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _probationLeaveMode,
            decoration: InputDecoration(
              labelText: isAr ? 'الإجازات في فترة التجربة' : 'Leaves during probation',
              prefixIcon: const Icon(Icons.block, color: Colors.red),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'blocked',
                  child: Text(isAr ? 'ممنوع الإجازات' : 'No leaves allowed')),
              DropdownMenuItem(value: 'limited_types',
                  child: Text(isAr ? 'أنواع محددة فقط' : 'Limited types only')),
              DropdownMenuItem(value: 'accrue_no_use',
                  child: Text(isAr ? 'يتحسب بس مايتستخدمش' : 'Accrue but no use')),
              DropdownMenuItem(value: 'normal',
                  child: Text(isAr ? 'عادي' : 'Normal')),
            ],
            onChanged: (v) => setState(() => _probationLeaveMode = v ?? 'blocked'),
          ),
          const SizedBox(height: 20),

          // طريقة منح الرصيد
          _sectionTitle(isAr ? 'طريقة منح الرصيد' : 'Accrual Mode'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _accrualMode,
            decoration: InputDecoration(
              labelText: isAr ? 'الرصيد بينزل إزاي؟' : 'How is balance granted?',
              prefixIcon: const Icon(Icons.calendar_month, color: kLeavePolicyColor),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(value: 'annual_lump',
                  child: Text(isAr ? 'دفعة واحدة أول السنة' : 'Annual lump sum')),
              DropdownMenuItem(value: 'monthly',
                  child: Text(isAr ? 'شهري' : 'Monthly')),
            ],
            onChanged: (v) => setState(() => _accrualMode = v ?? 'annual_lump'),
          ),
          const SizedBox(height: 20),

          // شرائح مدة الخدمة
          _sectionTitle(isAr ? 'شرائح مدة الخدمة' : 'Service Tiers'),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'حدد كام يوم إجازة يستحق الموظف حسب مدة خدمته'
                : 'Define entitlement days based on years of service',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          ..._tiers.asMap().entries.map((e) {
            final i = e.key;
            final tier = e.value;
            return Card(
              color: Colors.grey[50],
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Row(children: [
                    Text('${isAr ? 'شريحة' : 'Tier'} ${i + 1}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: kLeavePolicyColor)),
                    const Spacer(),
                    if (_tiers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        onPressed: () => setState(() => _tiers.removeAt(i)),
                      ),
                  ]),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: tier['from_months'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? 'من الشهر' : 'From month',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _tiers[i]['from_months'] = int.tryParse(v) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: tier['to_months']?.toString() ?? '',
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? 'لحد الشهر' : 'To month',
                          hintText: isAr ? 'فاضي = بلا حد' : 'empty = no limit',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _tiers[i]['to_months'] = int.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: tier['annual_entitlement_days'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? 'أيام سنوي' : 'Days/year',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) => _tiers[i]['annual_entitlement_days'] =
                            double.tryParse(v) ?? 21.0,
                      ),
                    ),
                  ]),
                ]),
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _tiers.add({
                  'from_months': 0,
                  'to_months': null,
                  'annual_entitlement_days': 21.0,
                  'description': '',
                })),
            icon: const Icon(Icons.add),
            label: Text(isAr ? 'إضافة شريحة' : 'Add Tier'),
            style: TextButton.styleFrom(foregroundColor: kLeavePolicyColor),
          ),
          const SizedBox(height: 80),
        ]),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kLeavePolicyColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      isEdit
                          ? (isAr ? 'تعديل وحفظ' : 'Update & Save')
                          : (isAr ? 'حفظ السياسة' : 'Save Policy'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: kLeavePolicyColor));
  }
}

// ════════════════════════════════════
// شاشة تعديل أرصدة الإجازات
// ════════════════════════════════════
class LeaveBalanceAdjustmentScreen extends StatefulWidget {
  const LeaveBalanceAdjustmentScreen({super.key});
  @override
  State<LeaveBalanceAdjustmentScreen> createState() =>
      _LeaveBalanceAdjustmentScreenState();
}

class _LeaveBalanceAdjustmentScreenState
    extends State<LeaveBalanceAdjustmentScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  List<Map<String, dynamic>> _adjustments = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final adj = await LeavePolicyService.getBalanceAdjustments();
      setState(() { _adjustments = adj; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(isAr ? 'تعديل أرصدة الإجازات' : 'Leave Balance Adjustments',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : _error != null
                ? Center(child: Text(_error!))
                : _adjustments.isEmpty
                    ? Center(child: Text(
                        isAr ? 'لا توجد تعديلات' : 'No adjustments',
                        style: const TextStyle(color: Colors.grey, fontSize: 16)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _adjustments.length,
                        itemBuilder: (_, i) {
                          final adj = _adjustments[i];
                          final days = double.tryParse(adj['days'].toString()) ?? 0;
                          final isAdd = days >= 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isAdd
                                    ? Colors.green.withAlpha(30)
                                    : Colors.red.withAlpha(30),
                                child: Icon(
                                  isAdd ? Icons.add : Icons.remove,
                                  color: isAdd ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(adj['employee_name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${adj['leave_type_name']} | ${adj['year']} | ${adj['adjustment_type']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Text(
                                '${isAdd ? '+' : ''}$days ${isAr ? 'يوم' : 'days'}',
                                style: TextStyle(
                                  color: isAdd ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: Colors.teal,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(isAr ? 'تعديل جديد' : 'New Adjustment',
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  void _showAddDialog() {
    int? selectedEmpId;
    int? selectedLeaveTypeId;
    double days = 0;
    int year = DateTime.now().year;
    String adjType = 'opening_balance';
    String reason = '';

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'تعديل رصيد إجازة' : 'Adjust Leave Balance'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'رقم الموظف (ID)' : 'Employee ID',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => selectedEmpId = int.tryParse(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'رقم نوع الإجازة (ID)' : 'Leave Type ID',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => selectedLeaveTypeId = int.tryParse(v),
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'السنة' : 'Year',
                  border: const OutlineInputBorder(),
                ),
                initialValue: year.toString(),
                onChanged: (v) => year = int.tryParse(v) ?? DateTime.now().year,
              ),
              const SizedBox(height: 12),
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                decoration: InputDecoration(
                  labelText: isAr ? 'عدد الأيام (موجب = إضافة / سالب = خصم)' : 'Days',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => days = double.tryParse(v) ?? 0,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: InputDecoration(
                  labelText: isAr ? 'السبب' : 'Reason',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => reason = v,
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAr ? 'تراجع' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedEmpId == null || selectedLeaveTypeId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(isAr ? 'ادخل رقم الموظف ونوع الإجازة' : 'Enter employee and leave type IDs'),
                    backgroundColor: Colors.orange,
                  ));
                  return;
                }
                Navigator.pop(context);
                try {
                  await LeavePolicyService.addBalanceAdjustment({
                    'employee_id': selectedEmpId,
                    'leave_type_id': selectedLeaveTypeId,
                    'year': year,
                    'days': days,
                    'adjustment_type': adjType,
                    'reason': reason,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isAr ? 'تم التعديل بنجاح' : 'Adjustment saved'),
                      backgroundColor: Colors.green,
                    ));
                    _load();
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: Text(isAr ? 'حفظ' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}


// ════════════════════════════════════
// شاشة قواعد أنواع الإجازات
// ════════════════════════════════════
class LeaveTypeRulesScreen extends StatefulWidget {
  final Map<String, dynamic> policy;
  const LeaveTypeRulesScreen({super.key, required this.policy});

  @override
  State<LeaveTypeRulesScreen> createState() => _LeaveTypeRulesScreenState();
}

class _LeaveTypeRulesScreenState extends State<LeaveTypeRulesScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  List<Map<String, dynamic>> _leaveTypes = [];
  List<Map<String, dynamic>> _typeRules = [];
  bool _loading = true;
  bool _saving = false;
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
      final leaveTypes = await LeavePolicyService.getLeaveTypes();
      final existingRules = List<Map<String, dynamic>>.from(
        widget.policy['type_rules'] ?? [],
      );

      final merged = <Map<String, dynamic>>[];
      for (final lt in leaveTypes) {
        final existing = existingRules.cast<Map<String, dynamic>?>().firstWhere(
          (r) => r?['leave_type_id'] == lt['id'],
          orElse: () => null,
        );

        merged.add({
          'leave_type_id': lt['id'],
          'leave_type_name': lt['name'],
          'enabled': existing?['enabled'] ?? true,
          'entitlement_mode': existing?['entitlement_mode'] ?? 'from_service_tier',
          'fixed_days': existing?['fixed_days'] ?? 0.0,
          'parent_leave_type_id': existing?['parent_leave_type_id'],
          'subset_limit_days': existing?['subset_limit_days'] ?? 0.0,
          'requires_balance': existing?['requires_balance'] ?? true,
          'allow_negative_balance': existing?['allow_negative_balance'] ?? false,
          'negative_limit_days': existing?['negative_limit_days'] ?? 0.0,
          'allow_half_day': existing?['allow_half_day'] ?? true,
          'allow_hourly': existing?['allow_hourly'] ?? false,
          'max_days_per_request': existing?['max_days_per_request'] ?? 0,
          'max_requests_per_year': existing?['max_requests_per_year'] ?? 0,
          'can_use_during_probation': existing?['can_use_during_probation'] ?? false,
          'carry_mode': existing?['carry_mode'] ?? 'none',
          'carry_percentage': existing?['carry_percentage'] ?? 100.0,
          'carry_max_days': existing?['carry_max_days'] ?? 0.0,
          'cash_compensation_enabled': existing?['cash_compensation_enabled'] ?? false,
          'cash_compensation_basis': existing?['cash_compensation_basis'] ?? 'basic_salary',
        });
      }

      setState(() {
        _leaveTypes = leaveTypes;
        _typeRules = merged;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'name': widget.policy['name'],
        'effective_from': widget.policy['effective_from'],
        'effective_to': widget.policy['effective_to'],
        'probation_months': widget.policy['probation_months'],
        'probation_leave_mode': widget.policy['probation_leave_mode'],
        'accrual_mode': widget.policy['accrual_mode'],
        'notes': widget.policy['notes'] ?? '',
        'tiers': widget.policy['tiers'] ?? [],
        'type_rules': _typeRules,
      };

      await LeavePolicyService.updatePolicy(widget.policy['id'], body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم حفظ القواعد بنجاح' : 'Rules saved successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'قواعد أنواع الإجازات' : 'Leave Type Rules',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
            : _error != null
                ? Center(child: Text(_error!))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _typeRules.length,
                    itemBuilder: (_, i) => _buildRuleCard(i),
                  ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      isAr ? 'حفظ القواعد' : 'Save Rules',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRuleCard(int index) {
    final rule = _typeRules[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              rule['leave_type_name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isAr ? 'تفعيل النوع' : 'Enable Leave Type'),
              value: rule['enabled'] == true,
              onChanged: (v) => setState(() => rule['enabled'] = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isAr ? 'مسموح في فترة التجربة' : 'Allowed During Probation'),
              value: rule['can_use_during_probation'] == true,
              onChanged: (v) => setState(() => rule['can_use_during_probation'] = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isAr ? 'مسموح بنصف يوم' : 'Allow Half Day'),
              value: rule['allow_half_day'] == true,
              onChanged: (v) => setState(() => rule['allow_half_day'] = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isAr ? 'مسموح بالساعة' : 'Allow Hourly'),
              value: rule['allow_hourly'] == true,
              onChanged: (v) => setState(() => rule['allow_hourly'] = v),
            ),
            const SizedBox(height: 10),
            const Divider(),
            DropdownButtonFormField<String>(
              initialValue: rule['entitlement_mode'],
              decoration: InputDecoration(
                labelText: isAr ? 'مصدر الرصيد' : 'Entitlement Mode',
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'from_service_tier', child: Text(isAr ? 'من شرائح الخدمة' : 'From Service Tier')),
                DropdownMenuItem(value: 'fixed_days', child: Text(isAr ? 'عدد أيام ثابت' : 'Fixed Days')),
                DropdownMenuItem(value: 'subset_of_parent', child: Text(isAr ? 'جزء من إجازة أخرى (مثل الطارئة)' : 'Subset of Parent')),
              ],
              onChanged: (v) => setState(() => rule['entitlement_mode'] = v ?? 'from_service_tier'),
            ),
            if (rule['entitlement_mode'] == 'fixed_days') ...[
              const SizedBox(height: 10),
              TextFormField(
                initialValue: rule['fixed_days'].toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'عدد الأيام' : 'Fixed Days',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => rule['fixed_days'] = double.tryParse(v) ?? 0.0,
              ),
            ],
            if (rule['entitlement_mode'] == 'subset_of_parent') ...[
              const SizedBox(height: 10),
              TextFormField(
                initialValue: rule['subset_limit_days'].toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'الحد الأقصى كجزء من الأب (مثال: 7)' : 'Subset Limit Days',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => rule['subset_limit_days'] = double.tryParse(v) ?? 0.0,
              ),
            ],
            const Divider(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isAr ? 'مسموح برصيد سالب' : 'Allow Negative Balance'),
              value: rule['allow_negative_balance'] == true,
              onChanged: (v) => setState(() => rule['allow_negative_balance'] = v),
            ),
            if (rule['allow_negative_balance'] == true) ...[
              const SizedBox(height: 10),
              TextFormField(
                initialValue: rule['negative_limit_days'].toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'حد الرصيد السالب' : 'Negative Limit Days',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => rule['negative_limit_days'] = double.tryParse(v) ?? 0.0,
              ),
            ],
            const Divider(),
            DropdownButtonFormField<String>(
              initialValue: rule['carry_mode'],
              decoration: InputDecoration(
                labelText: isAr ? 'سياسة الترحيل' : 'Carry Forward Policy',
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(value: 'none', child: Text(isAr ? 'لا ترحيل' : 'No Carry')),
                DropdownMenuItem(value: 'all', child: Text(isAr ? 'ترحيل كامل' : 'Carry All')),
                DropdownMenuItem(value: 'percentage', child: Text(isAr ? 'ترحيل نسبة' : 'Carry Percentage')),
                DropdownMenuItem(value: 'percentage_with_cap', child: Text(isAr ? 'ترحيل بنسبة وحد أقصى' : 'Carry % with Cap')),
                DropdownMenuItem(value: 'cash_only', child: Text(isAr ? 'مقابل نقدي فقط' : 'Cash Only')),
              ],
              onChanged: (v) => setState(() => rule['carry_mode'] = v ?? 'none'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: rule['carry_percentage'].toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isAr ? 'نسبة الترحيل %' : 'Carry Percentage %',
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => rule['carry_percentage'] = double.tryParse(v) ?? 100.0,
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: rule['carry_max_days'].toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isAr ? 'أقصى عدد أيام ترحيل' : 'Max Carry Days',
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => rule['carry_max_days'] = double.tryParse(v) ?? 0.0,
            ),
          ],
        ),
      ),
    );
  }
}
