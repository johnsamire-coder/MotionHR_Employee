import 'package:flutter/material.dart';
import '../../services/attendance_policy_service.dart';
import '../../services/disciplinary_service.dart';
import '../../services/employee_management_service.dart';

const Color kPayrollPolicyColor = Color(0xFF2E7D32);

class PayrollPolicyScreen extends StatefulWidget {
  const PayrollPolicyScreen({super.key});
  @override
  State<PayrollPolicyScreen> createState() => _PayrollPolicyScreenState();
}

class _PayrollPolicyScreenState extends State<PayrollPolicyScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  List<Map<String, dynamic>> _policies = [];
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
      final policies = await AttendancePolicyService.getPolicies();
      setState(() { _policies = policies; _loading = false; });
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
          title: Text(
            isAr ? 'سياسة المرتبات' : 'Payroll Policy',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPayrollPolicyColor,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kPayrollPolicyColor))
            : _error != null
                ? _buildError()
                : _policies.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _policies.length,
                          itemBuilder: (_, i) => _buildCard(_policies[i]),
                        ),
                      ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> policy) {
    final status = policy['status'] ?? 'draft';
    final overtimeRules = policy['overtime_rules'] as List? ?? [];
    final nightRules = policy['night_shift_rules'] as List? ?? [];
    final weekendRules = policy['weekend_work_rules'] as List? ?? [];

    final statusColor = status == 'active'
        ? Colors.green
        : status == 'archived'
            ? Colors.grey
            : Colors.orange;

    final statusLabel = status == 'active'
        ? (isAr ? 'نشط' : 'Active')
        : status == 'archived'
            ? (isAr ? 'مؤرشف' : 'Archived')
            : (isAr ? 'مسودة' : 'Draft');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(policy['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withAlpha(100)),
              ),
              child: Text(statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Wrap(spacing: 6, runSpacing: 4, children: [
            if (overtimeRules.isNotEmpty)
              _chip(isAr ? '💪 أوفر تايم' : '💪 Overtime', Colors.blue),
            if (nightRules.isNotEmpty)
              _chip(isAr ? '🌙 بدل ليلي' : '🌙 Night', Colors.indigo),
            if (weekendRules.isNotEmpty)
              _chip(isAr ? '📅 يوم راحة' : '📅 Weekend', Colors.purple),
          ]),
          const Divider(height: 16),
          Row(children: [
            TextButton.icon(
              onPressed: () async {
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPayrollPolicyScreen(policy: policy),
                  ),
                );
                if (r == true) _load();
              },
              icon: const Icon(Icons.edit, size: 16),
              label: Text(isAr ? 'تعديل' : 'Edit'),
              style: TextButton.styleFrom(foregroundColor: kPayrollPolicyColor),
            ),
            TextButton.icon(
              onPressed: () async {
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DisciplinaryRulesScreen(policy: policy),
                  ),
                );
                if (r == true) _load();
              },
              icon: const Icon(Icons.rule, size: 16),
              label: Text(isAr ? 'قواعد' : 'Rules'),
              style: TextButton.styleFrom(foregroundColor: Colors.deepOrange),
            ),
            TextButton.icon(
              onPressed: () async {
                final r = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DisciplinaryActionsScreen(policy: policy),
                  ),
                );
                if (r == true) _load();
              },
              icon: const Icon(Icons.gavel, size: 16),
              label: Text(isAr ? 'تطبيق جزاء' : 'Actions'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
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

  Widget _buildError() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? ''),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
                backgroundColor: kPayrollPolicyColor, foregroundColor: Colors.white),
            child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
          ),
        ]),
      );

  Widget _buildEmpty() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.monetization_on_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(isAr ? 'لا توجد سياسات' : 'No policies',
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(isAr ? 'اعمل سياسة حضور أولاً' : 'Create an attendance policy first',
              style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ]),
      );
}

// ═══════════════════════════════════════
// شاشة تعديل سياسة المرتبات
// ═══════════════════════════════════════
class EditPayrollPolicyScreen extends StatefulWidget {
  final Map<String, dynamic> policy;
  const EditPayrollPolicyScreen({super.key, required this.policy});
  @override
  State<EditPayrollPolicyScreen> createState() => _EditPayrollPolicyScreenState();
}

class _EditPayrollPolicyScreenState extends State<EditPayrollPolicyScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  bool _saving = false;

  List<Map<String, dynamic>> _overtimeRules = [];
  List<Map<String, dynamic>> _nightRules = [];
  List<Map<String, dynamic>> _weekendRules = [];

  bool _overtimeEnabled = false;
  bool _nightEnabled = false;
  bool _weekendEnabled = false;

  bool _overtimeConfirmed = false;
  bool _nightConfirmed = false;
  bool _weekendConfirmed = false;

  @override
  void initState() {
    super.initState();
    final p = widget.policy;
    if ((p['overtime_rules'] as List? ?? []).isNotEmpty) {
      _overtimeRules = List<Map<String, dynamic>>.from(p['overtime_rules']);
    } else {
      _overtimeRules = [
        {'overtime_type': 'after_shift', 'multiplier': 1.5, 'min_minutes': 30},
        {'overtime_type': 'weekend', 'multiplier': 2.0, 'min_minutes': 60},
        {'overtime_type': 'holiday', 'multiplier': 2.5, 'min_minutes': 60},
      ];
    }
    if ((p['night_shift_rules'] as List? ?? []).isNotEmpty) {
      _nightRules = List<Map<String, dynamic>>.from(p['night_shift_rules']);
    } else {
      _nightRules = [
        {'allowance_type': 'fixed_amount', 'amount': 50.0, 'percentage': 10.0,
         'night_start_hour': 20, 'min_night_hours': 4},
      ];
    }
    if ((p['weekend_work_rules'] as List? ?? []).isNotEmpty) {
      _weekendRules = List<Map<String, dynamic>>.from(p['weekend_work_rules']);
    } else {
      _weekendRules = [
        {'compensation_type': 'overtime_multiplier', 'multiplier': 2.0, 'amount': 0.0},
      ];
    }

    _overtimeEnabled = _overtimeRules.isNotEmpty &&
        (widget.policy['overtime_rules'] as List? ?? []).isNotEmpty;
    _nightEnabled = _nightRules.isNotEmpty &&
        (widget.policy['night_shift_rules'] as List? ?? []).isNotEmpty;
    _weekendEnabled = _weekendRules.isNotEmpty &&
        (widget.policy['weekend_work_rules'] as List? ?? []).isNotEmpty;

    _overtimeConfirmed = _overtimeEnabled;
    _nightConfirmed = _nightEnabled;
    _weekendConfirmed = _weekendEnabled;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'name': widget.policy['name'],
        'effective_from': widget.policy['effective_from'],
        'overtime_rules': _overtimeEnabled ? _overtimeRules : [],
        'night_shift_rules': _nightEnabled ? _nightRules : [],
        'weekend_work_rules': _weekendEnabled ? _weekendRules : [],
        'permission_enabled': widget.policy['permission_enabled'] ?? false,
        'permission_monthly_hours': widget.policy['permission_monthly_hours'] ?? 0,
        'permission_monthly_count': widget.policy['permission_monthly_count'] ?? 0,
        'permission_max_hours_per_request': widget.policy['permission_max_hours_per_request'] ?? 0,
        'permission_fraction_as_full': widget.policy['permission_fraction_as_full'] ?? false,
        'permission_reset_cycle': widget.policy['permission_reset_cycle'] ?? 'calendar',
        'late_rules': widget.policy['late_rules'] ?? [],
        'absence_rules': widget.policy['absence_rules'] ?? [],
      };
      await AttendancePolicyService.updatePolicy(widget.policy['id'], body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr ? 'تم الحفظ بنجاح ✅' : 'Saved ✅'),
            backgroundColor: Colors.green));
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
            isAr ? 'تعديل سياسة المرتبات' : 'Edit Payroll Policy',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPayrollPolicyColor,
          foregroundColor: Colors.white,
        ),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          Card(
            color: kPayrollPolicyColor.withAlpha(15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.info_outline, color: kPayrollPolicyColor, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  isAr
                      ? 'إعدادات الأوفر تايم والبدلات الليلية والراحة الأسبوعية'
                      : 'Overtime, night allowance and weekend work settings',
                  style: const TextStyle(fontSize: 13, color: kPayrollPolicyColor),
                )),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          _section(
            isAr ? '💪 الأوفر تايم' : '💪 Overtime',
            _buildOvertimeContent(),
            enabled: _overtimeEnabled,
            confirmed: _overtimeConfirmed,
            onToggle: (v) => setState(() {
              _overtimeEnabled = v;
              _overtimeConfirmed = false;
            }),
            onConfirm: () => setState(() => _overtimeConfirmed = true),
            confirmLabel: isAr ? 'تأكيد إعدادات الأوفر تايم' : 'Confirm Overtime',
          ),
          _section(
            isAr ? '🌙 البدل الليلي' : '🌙 Night Allowance',
            _buildNightContent(),
            enabled: _nightEnabled,
            confirmed: _nightConfirmed,
            onToggle: (v) => setState(() {
              _nightEnabled = v;
              _nightConfirmed = false;
            }),
            onConfirm: () => setState(() => _nightConfirmed = true),
            confirmLabel: isAr ? 'تأكيد البدل الليلي' : 'Confirm Night Allowance',
          ),
          _section(
            isAr ? '📅 شغل يوم الراحة' : '📅 Weekend Work',
            _buildWeekendContent(),
            enabled: _weekendEnabled,
            confirmed: _weekendConfirmed,
            onToggle: (v) => setState(() {
              _weekendEnabled = v;
              _weekendConfirmed = false;
            }),
            onConfirm: () => setState(() => _weekendConfirmed = true),
            confirmLabel: isAr ? 'تأكيد يوم الراحة' : 'Confirm Weekend',
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
                backgroundColor: kPayrollPolicyColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      isAr ? 'تعديل وحفظ ✓' : 'Update & Save ✓',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(
    String title,
    Widget content, {
    bool enabled = true,
    ValueChanged<bool>? onToggle,
    bool confirmed = false,
    VoidCallback? onConfirm,
    String? confirmLabel,
  }) {
    final statusText = !enabled
        ? (isAr ? 'غير مفعّل' : 'Disabled')
        : (confirmed
            ? (isAr ? 'تم التأكيد ✅' : 'Confirmed ✅')
            : (isAr ? 'غير مؤكد بعد' : 'Not confirmed'));
    final statusColor =
        !enabled ? Colors.grey : (confirmed ? Colors.green : Colors.orange);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Row(children: [
          Expanded(child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withAlpha(60)),
            ),
            child: Text(statusText,
                style: TextStyle(
                    color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ]),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(isAr ? 'تطبيق الجزء ده' : 'Enable this section'),
            subtitle: Text(enabled
                ? (isAr ? 'داخل في الحفظ' : 'Will be saved')
                : (isAr ? 'خارج الحفظ' : 'Will be skipped')),
            value: enabled,
            activeThumbColor: kPayrollPolicyColor,
            onChanged: onToggle,
          ),
          const SizedBox(height: 8),
          if (enabled) content,
          if (!enabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                isAr ? 'الجزء ده مقفول ومش هيتحفظ' : 'Disabled - will not be saved',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ElevatedButton.icon(
              onPressed: enabled ? onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: enabled ? kPayrollPolicyColor : Colors.grey[400],
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(confirmLabel ?? (isAr ? 'تأكيد' : 'Confirm')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOvertimeContent() {
    final types = [
      {'value': 'after_shift', 'label': isAr ? 'بعد الشيفت' : 'After shift'},
      {'value': 'weekend', 'label': isAr ? 'يوم الراحة' : 'Weekend'},
      {'value': 'holiday', 'label': isAr ? 'إجازة رسمية' : 'Holiday'},
    ];
    return Column(children: _overtimeRules.asMap().entries.map((e) {
      final i = e.key;
      final r = e.value;
      final label = types.firstWhere(
          (t) => t['value'] == r['overtime_type'],
          orElse: () => {'label': r['overtime_type'].toString()})['label']!;
      return Card(
        color: Colors.grey[50],
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: kPayrollPolicyColor)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextFormField(
                  initialValue: r['multiplier'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'المضاعف' : 'Multiplier',
                    helperText: '1.5x / 2x',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      _overtimeRules[i]['multiplier'] = double.tryParse(v) ?? 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: r['min_minutes'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'أقل دقائق' : 'Min min',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      _overtimeRules[i]['min_minutes'] = int.tryParse(v) ?? 30,
                ),
              ),
            ]),
          ]),
        ),
      );
    }).toList());
  }

  Widget _buildNightContent() {
    if (_nightRules.isEmpty) return const SizedBox.shrink();
    final r = _nightRules[0];
    return Column(children: [
      Row(children: [
        Expanded(
          child: TextFormField(
            initialValue: r['amount'].toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isAr ? 'المبلغ الثابت' : 'Fixed Amount',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => _nightRules[0]['amount'] = double.tryParse(v) ?? 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: r['percentage'].toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isAr ? 'النسبة %' : 'Percentage %',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => _nightRules[0]['percentage'] = double.tryParse(v) ?? 0,
          ),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(
          child: TextFormField(
            initialValue: r['night_start_hour'].toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isAr ? 'بداية الليل (ساعة)' : 'Night Start Hour',
              helperText: isAr ? '20 = 8 مساءً' : '20 = 8 PM',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) =>
                _nightRules[0]['night_start_hour'] = int.tryParse(v) ?? 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: r['min_night_hours'].toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: isAr ? 'أقل ساعات ليلية' : 'Min Night Hours',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) =>
                _nightRules[0]['min_night_hours'] = int.tryParse(v) ?? 4,
          ),
        ),
      ]),
    ]);
  }

  Widget _buildWeekendContent() {
    if (_weekendRules.isEmpty) return const SizedBox.shrink();
    final r = _weekendRules[0];
    return Row(children: [
      Expanded(
        child: TextFormField(
          initialValue: r['multiplier'].toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isAr ? 'المضاعف' : 'Multiplier',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) =>
              _weekendRules[0]['multiplier'] = double.tryParse(v) ?? 2.0,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: TextFormField(
          initialValue: r['amount'].toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: isAr ? 'المبلغ الثابت' : 'Fixed Amount',
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) =>
              _weekendRules[0]['amount'] = double.tryParse(v) ?? 0,
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════
// شاشة الجزاءات التأديبية
// ═══════════════════════════════════════
class DisciplinaryActionsScreen extends StatefulWidget {
  final Map<String, dynamic> policy;
  const DisciplinaryActionsScreen({super.key, required this.policy});
  @override
  State<DisciplinaryActionsScreen> createState() =>
      _DisciplinaryActionsScreenState();
}

class _DisciplinaryActionsScreenState
    extends State<DisciplinaryActionsScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  List<Map<String, dynamic>> _actions = [];
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
      final actions = await DisciplinaryService.getActions();
      setState(() { _actions = actions; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _review(Map<String, dynamic> action, String decision) async {
    try {
      await DisciplinaryService.reviewAction(action['id'], decision);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(decision == 'approve'
              ? (isAr ? 'تم اعتماد الجزاء ✅' : 'Action approved ✅')
              : (isAr ? 'تم رفض الجزاء' : 'Action rejected')),
          backgroundColor:
              decision == 'approve' ? Colors.green : Colors.orange,
        ));
        _load();
      }
    } catch (e) {
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
          title: Text(isAr ? 'الجزاءات التأديبية' : 'Disciplinary Actions',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : _error != null
                ? Center(child: Text(_error!))
                : _actions.isEmpty
                    ? Center(
                        child: Text(
                          isAr ? 'لا توجد جزاءات' : 'No disciplinary actions',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _actions.length,
                        itemBuilder: (_, i) => _buildActionCard(_actions[i]),
                      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: Colors.red[700],
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(isAr ? 'جزاء جديد' : 'New Action',
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final status = action['status'] ?? 'pending';
    final statusColor = status == 'approved'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;
    final statusLabel = status == 'approved'
        ? (isAr ? 'معتمد' : 'Approved')
        : status == 'rejected'
            ? (isAr ? 'مرفوض' : 'Rejected')
            : (isAr ? 'معلق' : 'Pending');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(action['employee_name'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withAlpha(100)),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(action['action_type_display'] ?? '',
              style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          if ((action['reason'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(action['reason'],
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
          if ((action['deduction_amount'] ?? 0) > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${isAr ? 'خصم' : 'Deduction'}: ${action['deduction_amount']} ${isAr ? 'جنيه' : 'EGP'}',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
          if ((action['payroll_month'] ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${isAr ? 'شهر المرتب' : 'Payroll Month'}: ${action['payroll_month']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
          if (status == 'pending') ...[
            const Divider(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _review(action, 'reject'),
                  icon: const Icon(Icons.close, size: 16, color: Colors.red),
                  label: Text(isAr ? 'رفض' : 'Reject',
                      style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _review(action, 'approve'),
                  icon: const Icon(Icons.check, size: 16),
                  label: Text(isAr ? 'اعتماد' : 'Approve'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Future<void> _showAddDialog() async {
    List<Map<String, dynamic>> employees = [];
    try {
      employees = await EmployeeManagementService.getEmployeesSimple();
    } catch (_) {}

    if (!mounted) return;

    String actionType = 'verbal_warning';
    String reason = '';
    String payrollMonth = '';
    double deductionAmount = 0;
    int? selectedEmployeeId;

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Text(isAr ? 'إضافة جزاء تأديبي' : 'Add Disciplinary Action'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    labelText: isAr ? 'الموظف' : 'Employee',
                    border: const OutlineInputBorder(),
                  ),
                  items: employees.map((e) => DropdownMenuItem<int>(
                    value: e['id'] as int,
                    child: Text(isAr ? (e['full_name_ar'] ?? '') : (e['full_name_en'] ?? e['full_name_ar'] ?? '')),
                  )).toList(),
                  onChanged: (v) => setS(() => selectedEmployeeId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: actionType,
                  decoration: InputDecoration(
                    labelText: isAr ? 'نوع الجزاء' : 'Action Type',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'verbal_warning',
                        child: Text(isAr ? 'إنذار شفهي' : 'Verbal Warning')),
                    DropdownMenuItem(value: 'written_warning',
                        child: Text(isAr ? 'إنذار كتابي' : 'Written Warning')),
                    DropdownMenuItem(value: 'quarter_day_deduction',
                        child: Text(isAr ? 'خصم ربع يوم' : 'Quarter Day')),
                    DropdownMenuItem(value: 'half_day_deduction',
                        child: Text(isAr ? 'خصم نص يوم' : 'Half Day')),
                    DropdownMenuItem(value: 'full_day_deduction',
                        child: Text(isAr ? 'خصم يوم كامل' : 'Full Day')),
                    DropdownMenuItem(value: 'suspension',
                        child: Text(isAr ? 'إيقاف' : 'Suspension')),
                  ],
                  onChanged: (v) => setS(() => actionType = v ?? actionType),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: isAr ? 'السبب' : 'Reason',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  onChanged: (v) => reason = v,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: isAr ? 'مبلغ الخصم (لو فيه)' : 'Deduction Amount',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => deductionAmount = double.tryParse(v) ?? 0,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: isAr ? 'شهر المرتب (YYYY-MM)' : 'Payroll Month',
                    hintText: '2026-07',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => payrollMonth = v,
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'تراجع' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedEmployeeId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isAr ? 'اختر الموظف أولاً' : 'Select employee first'),
                      backgroundColor: Colors.orange,
                    ));
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await DisciplinaryService.addAction({
                      'employee_id': selectedEmployeeId,
                      'action_type': actionType,
                      'reason': reason,
                      'deduction_amount': deductionAmount,
                      'payroll_month': payrollMonth,
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isAr ? 'تم إضافة الجزاء ✅' : 'Action added ✅'),
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
                    backgroundColor: Colors.red[700], foregroundColor: Colors.white),
                child: Text(isAr ? 'إضافة' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// شاشة قواعد الجزاءات التأديبية في السياسة
// ═══════════════════════════════════════
class DisciplinaryRulesScreen extends StatefulWidget {
  final Map<String, dynamic> policy;
  const DisciplinaryRulesScreen({super.key, required this.policy});
  @override
  State<DisciplinaryRulesScreen> createState() => _DisciplinaryRulesScreenState();
}

class _DisciplinaryRulesScreenState extends State<DisciplinaryRulesScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  List<Map<String, dynamic>> _rules = [];
  bool _loading = true;
  String? _error;

  final _violationTypes = [
    {'value': 'late_repeat', 'label_ar': 'تكرار التأخير', 'label_en': 'Late Repeat'},
    {'value': 'absence_repeat', 'label_ar': 'تكرار الغياب', 'label_en': 'Absence Repeat'},
    {'value': 'early_leave_repeat', 'label_ar': 'تكرار الانصراف المبكر', 'label_en': 'Early Leave Repeat'},
    {'value': 'policy_violation', 'label_ar': 'مخالفة لائحة', 'label_en': 'Policy Violation'},
    {'value': 'misconduct', 'label_ar': 'سوء سلوك', 'label_en': 'Misconduct'},
    {'value': 'negligence', 'label_ar': 'إهمال', 'label_en': 'Negligence'},
    {'value': 'other', 'label_ar': 'أخرى', 'label_en': 'Other'},
  ];

  final _penaltyTypes = [
    {'value': 'verbal_warning', 'label_ar': 'إنذار شفهي', 'label_en': 'Verbal Warning'},
    {'value': 'written_warning', 'label_ar': 'إنذار كتابي', 'label_en': 'Written Warning'},
    {'value': 'deduction_days', 'label_ar': 'خصم أيام', 'label_en': 'Deduction Days'},
    {'value': 'deduction_amount', 'label_ar': 'خصم مبلغ', 'label_en': 'Deduction Amount'},
    {'value': 'suspension', 'label_ar': 'إيقاف عن العمل', 'label_en': 'Suspension'},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rules = await DisciplinaryService.getRules(widget.policy['id']);
      setState(() { _rules = rules; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(int ruleId) async {
    try {
      await DisciplinaryService.deleteRule(widget.policy['id'], ruleId);
      _load();
    } catch (e) {
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
          title: Text(isAr ? 'قواعد الجزاءات' : 'Disciplinary Rules',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.deepOrange))
            : _error != null
                ? Center(child: Text(_error!))
                : _rules.isEmpty
                    ? Center(
                        child: Text(
                          isAr ? 'لا توجد قواعد' : 'No rules',
                          style: const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _rules.length,
                        itemBuilder: (_, i) => _buildRuleCard(_rules[i]),
                      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddDialog,
          backgroundColor: Colors.deepOrange,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(isAr ? 'إضافة قاعدة' : 'Add Rule',
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildRuleCard(Map<String, dynamic> rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(rule['violation_type_display'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _delete(rule['id']),
            ),
          ]),
          Text(
            isAr 
              ? 'من المرة ${rule['occurrence_from']} إلى المرة ${rule['occurrence_to']}'
              : 'From occurrence ${rule['occurrence_from']} to ${rule['occurrence_to']}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.deepOrange.withAlpha(60)),
            ),
            child: Text(rule['penalty_type_display'] ?? '',
                style: const TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          if ((rule['deduction_days'] ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(isAr ? 'خصم: ${rule['deduction_days']} أيام' : 'Deduction: ${rule['deduction_days']} days',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
          if ((rule['deduction_amount'] ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Text(isAr ? 'مبلغ الخصم: ${rule['deduction_amount']}' : 'Amount: ${rule['deduction_amount']}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ]),
      ),
    );
  }

  void _showAddDialog() {
    String vType = 'policy_violation';
    int fromOc = 1;
    int toOc = 1;
    String pType = 'verbal_warning';
    double dDays = 0;
    double dAmount = 0;

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Text(isAr ? 'قاعدة جزاء جديدة' : 'New Disciplinary Rule'),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  value: vType,
                  decoration: InputDecoration(labelText: isAr ? 'المخالفة' : 'Violation', border: const OutlineInputBorder()),
                  items: _violationTypes.map((t) => DropdownMenuItem(
                    value: t['value'], child: Text(isAr ? t['label_ar']! : t['label_en']!),
                  )).toList(),
                  onChanged: (v) => setS(() => vType = v ?? vType),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(
                    initialValue: '1', keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: isAr ? 'من المرة' : 'From', border: const OutlineInputBorder()),
                    onChanged: (v) => fromOc = int.tryParse(v) ?? 1,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(
                    initialValue: '1', keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: isAr ? 'إلى المرة' : 'To', border: const OutlineInputBorder()),
                    onChanged: (v) => toOc = int.tryParse(v) ?? 1,
                  )),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: pType,
                  decoration: InputDecoration(labelText: isAr ? 'الجزاء' : 'Penalty', border: const OutlineInputBorder()),
                  items: _penaltyTypes.map((t) => DropdownMenuItem(
                    value: t['value'], child: Text(isAr ? t['label_ar']! : t['label_en']!),
                  )).toList(),
                  onChanged: (v) => setS(() => pType = v ?? pType),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: isAr ? 'أيام خصم' : 'Days', border: const OutlineInputBorder()),
                    onChanged: (v) => dDays = double.tryParse(v) ?? 0,
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: isAr ? 'مبلغ خصم' : 'Amount', border: const OutlineInputBorder()),
                    onChanged: (v) => dAmount = double.tryParse(v) ?? 0,
                  )),
                ]),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'تراجع' : 'Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await DisciplinaryService.addRule(widget.policy['id'], {
                      'violation_type': vType,
                      'occurrence_from': fromOc,
                      'occurrence_to': toOc,
                      'penalty_type': pType,
                      'deduction_days': dDays,
                      'deduction_amount': dAmount,
                    });
                    _load();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                child: Text(isAr ? 'حفظ' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
