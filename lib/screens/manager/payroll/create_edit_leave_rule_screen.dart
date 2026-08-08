import 'package:flutter/material.dart';
import '../../../services/leave_rule_service.dart';
import '../../../services/lookups_service.dart';

const Color kLeaveColor = Color(0xFF6A1B9A);

class CreateEditLeaveRuleScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateEditLeaveRuleScreen({super.key, this.existing});

  @override
  State<CreateEditLeaveRuleScreen> createState() => _CreateEditLeaveRuleScreenState();
}

class _CreateEditLeaveRuleScreenState extends State<CreateEditLeaveRuleScreen> {
  final _nameCtrl           = TextEditingController();
  final _startDateCtrl      = TextEditingController();
  final _endDateCtrl        = TextEditingController();
  final _changeReasonCtrl   = TextEditingController();
  final _empSearchCtrl      = TextEditingController();

  // Annual
  bool _annualEnabled = true;
  int  _annualDays = 21;
  String _annualEarnStart = 'after_probation';
  bool _annualCarryOver = true;
  int  _annualMaxCarryOver = 7;
  bool _annualCashOut = false;
  int  _annualMinNotice = 7;
  int  _annualMaxConsecutive = 30;

  // Sick
  bool   _sickEnabled = true;
  int    _sickMaxDays = 14;
  int    _sickCertAfter = 3;
  double _sickPaidPct = 75;

  // Emergency
  bool _emergencyEnabled = true;
  int  _emergencyMaxDays = 3;
  int  _emergencyMaxPerMonth = 1;
  int  _emergencyMinNoticeHours = 2;
  bool _emergencyRequiresReason = true;
  bool _emergencyDeductFromAnnual = false;

  // Maternity
  bool   _maternityEnabled = true;
  int    _maternityDays = 90;
  bool   _maternityPaid = true;
  double _maternityPaidPct = 100;
  int    _maternityExtensionDays = 0;
  int    _maternityMaxTimes = 3;

  // Paternity
  bool _paternityEnabled = true;
  int  _paternityDays = 3;
  bool _paternityPaid = true;

  // Unpaid
  bool   _unpaidEnabled = true;
  String _unpaidDeductionType = 'full_day';
  double _unpaidCustomAmount = 0;
  int    _unpaidMaxDays = 30;
  bool   _unpaidRequiresApproval = true;

  // Hajj
  bool _hajjEnabled = true;
  int  _hajjDays = 21;
  bool _hajjPaid = true;
  bool _hajjOnceInLifetime = true;
  int  _hajjMinServiceYears = 5;

  // Bereavement
  bool _bereavementEnabled = true;
  int  _bereavementFirst = 3;
  int  _bereavementSecond = 1;

  // Marriage
  bool _marriageEnabled = true;
  int  _marriageDays = 3;
  bool _marriageOnceInLifetime = true;

  // Scope
  String _scope = 'company';
  bool   _isActive = true;
  bool   _saving = false;
  bool   _loading = false;

  List<dynamic> _branches    = [];
  List<dynamic> _departments = [];
  List<dynamic> _employees   = [];
  int?   _selectedBranch;
  int?   _selectedDepartment;
  List<int> _selectedEmployees = [];

  // Open section
  String? _openSection = 'annual';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _startDateCtrl.text = DateTime.now().toIso8601String().split('T').first;
    _loadLookups();
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text = p['name'] ?? '';
      _annualEnabled          = p['annual_leave_enabled']           ?? true;
      _annualDays             = p['annual_leave_days']              ?? 21;
      _annualEarnStart        = p['annual_earn_start']              ?? 'after_probation';
      _annualCarryOver        = p['annual_carry_over']              ?? true;
      _annualMaxCarryOver     = p['annual_max_carry_over']          ?? 7;
      _annualCashOut          = p['annual_cash_out_allowed']        ?? false;
      _annualMinNotice        = p['annual_min_notice_days']         ?? 7;
      _annualMaxConsecutive   = p['annual_max_consecutive_days']    ?? 30;
      _sickEnabled            = p['sick_leave_enabled']             ?? true;
      _sickMaxDays            = p['sick_leave_max_days']            ?? 14;
      _sickCertAfter          = p['sick_requires_certificate_after']?? 3;
      _sickPaidPct            = (p['sick_paid_percentage']          ?? 75).toDouble();
      _emergencyEnabled       = p['emergency_leave_enabled']        ?? true;
      _emergencyMaxDays       = p['emergency_max_days']             ?? 3;
      _emergencyMaxPerMonth   = p['emergency_max_per_month']        ?? 1;
      _emergencyMinNoticeHours= p['emergency_min_notice_hours']     ?? 2;
      _emergencyRequiresReason= p['emergency_requires_reason']      ?? true;
      _emergencyDeductFromAnnual = p['emergency_deducted_from_annual'] ?? false;
      _maternityEnabled       = p['maternity_enabled']              ?? true;
      _maternityDays          = p['maternity_days']                 ?? 90;
      _maternityPaid          = p['maternity_paid']                 ?? true;
      _maternityPaidPct       = (p['maternity_paid_percentage']     ?? 100).toDouble();
      _maternityExtensionDays = p['maternity_extension_days']       ?? 0;
      _maternityMaxTimes      = p['maternity_max_times']            ?? 3;
      _paternityEnabled       = p['paternity_enabled']              ?? true;
      _paternityDays          = p['paternity_days']                 ?? 3;
      _paternityPaid          = p['paternity_paid']                 ?? true;
      _unpaidEnabled          = p['unpaid_leave_enabled']           ?? true;
      _unpaidDeductionType    = p['unpaid_deduction_type']          ?? 'full_day';
      _unpaidCustomAmount     = (p['unpaid_custom_amount']          ?? 0).toDouble();
      _unpaidMaxDays          = p['max_unpaid_days_per_year']       ?? 30;
      _unpaidRequiresApproval = p['unpaid_requires_approval']       ?? true;
      _hajjEnabled            = p['hajj_enabled']                   ?? true;
      _hajjDays               = p['hajj_days']                      ?? 21;
      _hajjPaid               = p['hajj_paid']                      ?? true;
      _hajjOnceInLifetime     = p['hajj_once_in_lifetime']          ?? true;
      _hajjMinServiceYears    = p['hajj_min_service_years']         ?? 5;
      _bereavementEnabled     = p['bereavement_enabled']            ?? true;
      _bereavementFirst       = p['bereavement_days_first_degree']  ?? 3;
      _bereavementSecond      = p['bereavement_days_second_degree'] ?? 1;
      _marriageEnabled        = p['marriage_enabled']               ?? true;
      _marriageDays           = p['marriage_days']                  ?? 3;
      _marriageOnceInLifetime = p['marriage_once_in_lifetime']      ?? true;
      _scope                  = p['scope']                          ?? 'company';
      _isActive               = p['is_active']                      ?? true;
      _startDateCtrl.text     = p['start_date']                     ?? '';
      _endDateCtrl.text       = p['end_date']                       ?? '';
      _selectedBranch         = p['branch_id'];
      _selectedDepartment     = p['department_id'];
      final emps = p['specific_employees'];
      if (emps is List) {
        _selectedEmployees = emps.map<int>((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
      }
    }
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        LookupsService.listBranches(),
        LookupsService.listDepartments(),
        LookupsService.listEmployeesSimple(),
      ]);
      if (!mounted) return;
      setState(() {
        _branches    = results[0];
        _departments = results[1];
        _employees   = results[2];
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _changeReasonCtrl.dispose();
    _empSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.text.isNotEmpty ? DateTime.tryParse(ctrl.text) ?? now : now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => ctrl.text = picked.toIso8601String().split('T').first);
  }

  List<dynamic> get _filteredEmployees {
    final q = _empSearchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _employees;
    return _employees.where((e) {
      final name = (e['full_name'] ?? '${e['first_name_ar'] ?? ''} ${e['last_name_ar'] ?? ''}').toLowerCase();
      final code = (e['employee_code'] ?? '').toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اسم القاعدة مطلوب')));
      return;
    }
    if (_scope == 'branch' && _selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر الفرع')));
      return;
    }
    if (_scope == 'department' && _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر الإدارة')));
      return;
    }
    if (_scope == 'employees' && _selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر موظف واحد على الأقل')));
      return;
    }

    setState(() => _saving = true);

    final data = {
      'name'                            : _nameCtrl.text.trim(),
      'annual_leave_enabled'            : _annualEnabled,
      'annual_leave_days'               : _annualDays,
      'annual_earn_start'               : _annualEarnStart,
      'annual_carry_over'               : _annualCarryOver,
      'annual_max_carry_over'           : _annualMaxCarryOver,
      'annual_cash_out_allowed'         : _annualCashOut,
      'annual_min_notice_days'          : _annualMinNotice,
      'annual_max_consecutive_days'     : _annualMaxConsecutive,
      'sick_leave_enabled'              : _sickEnabled,
      'sick_leave_max_days'             : _sickMaxDays,
      'sick_requires_certificate_after' : _sickCertAfter,
      'sick_paid_percentage'            : _sickPaidPct,
      'emergency_leave_enabled'         : _emergencyEnabled,
      'emergency_max_days'              : _emergencyMaxDays,
      'emergency_max_per_month'         : _emergencyMaxPerMonth,
      'emergency_min_notice_hours'      : _emergencyMinNoticeHours,
      'emergency_requires_reason'       : _emergencyRequiresReason,
      'emergency_deducted_from_annual'  : _emergencyDeductFromAnnual,
      'maternity_enabled'               : _maternityEnabled,
      'maternity_days'                  : _maternityDays,
      'maternity_paid'                  : _maternityPaid,
      'maternity_paid_percentage'       : _maternityPaidPct,
      'maternity_extension_days'        : _maternityExtensionDays,
      'maternity_max_times'             : _maternityMaxTimes,
      'paternity_enabled'               : _paternityEnabled,
      'paternity_days'                  : _paternityDays,
      'paternity_paid'                  : _paternityPaid,
      'unpaid_leave_enabled'            : _unpaidEnabled,
      'unpaid_deduction_type'           : _unpaidDeductionType,
      'unpaid_custom_amount'            : _unpaidCustomAmount,
      'max_unpaid_days_per_year'        : _unpaidMaxDays,
      'unpaid_requires_approval'        : _unpaidRequiresApproval,
      'hajj_enabled'                    : _hajjEnabled,
      'hajj_days'                       : _hajjDays,
      'hajj_paid'                       : _hajjPaid,
      'hajj_once_in_lifetime'           : _hajjOnceInLifetime,
      'hajj_min_service_years'          : _hajjMinServiceYears,
      'bereavement_enabled'             : _bereavementEnabled,
      'bereavement_days_first_degree'   : _bereavementFirst,
      'bereavement_days_second_degree'  : _bereavementSecond,
      'marriage_enabled'                : _marriageEnabled,
      'marriage_days'                   : _marriageDays,
      'marriage_once_in_lifetime'       : _marriageOnceInLifetime,
      'scope'                           : _scope,
      'branch_id'                       : _scope == 'branch'     ? _selectedBranch     : null,
      'department_id'                   : _scope == 'department' ? _selectedDepartment : null,
      'specific_employees'              : _scope == 'employees'  ? _selectedEmployees  : [],
      'is_active'                       : _isActive,
      'start_date'                      : _startDateCtrl.text,
      'end_date'                        : _endDateCtrl.text.isEmpty ? null : _endDateCtrl.text,
      'change_reason'                   : _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await LeaveRuleService.updateRule(widget.existing!['id'], data);
      } else {
        await LeaveRuleService.createRule(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل الحفظ: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _leaveSection({
    required String id,
    required String title,
    required IconData icon,
    required Color color,
    required bool enabled,
    required void Function(bool) onToggle,
    required List<Widget> children,
  }) {
    final isOpen = _openSection == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled ? color : Colors.grey.shade300,
          width: enabled ? 2 : 1,
        ),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _openSection = isOpen ? null : id),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: enabled ? color.withValues(alpha: 0.08) : Colors.grey.shade50,
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(10),
                bottom: isOpen ? Radius.zero : const Radius.circular(10),
              ),
            ),
            child: Row(children: [
              Checkbox(
                value: enabled,
                activeColor: color,
                onChanged: (v) => setState(() => onToggle(v ?? enabled)),
              ),
              Icon(icon, color: enabled ? color : Colors.grey, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: enabled ? color : Colors.grey,
                    )),
              ),
              Icon(isOpen ? Icons.expand_less : Icons.expand_more,
                  color: enabled ? color : Colors.grey),
            ]),
          ),
        ),
        if (isOpen && enabled)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
      ]),
    );
  }

  Widget _numRow(String label, int value, void Function(int) onChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      SizedBox(
        width: 80,
        child: TextFormField(
          initialValue: value.toString(),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
          onChanged: (v) => onChanged(int.tryParse(v) ?? value),
        ),
      ),
    ]);
  }

  Widget _checkRow(String label, bool value, void Function(bool) onChanged) {
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
      Checkbox(
        value: value,
        activeColor: kLeaveColor,
        onChanged: (v) => onChanged(v ?? value),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(_isEdit ? 'تعديل قواعد الإجازات' : 'إنشاء قواعد إجازات'),
          backgroundColor: kLeaveColor,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // اسم القاعدة
                    _sectionCard('اسم القاعدة *', [
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'مثال: قواعد الإجازات الافتراضية',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '💡 اضغط على كل قسم لفتحه، وشيل الشيك لتعطيل نوع الإجازة',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ═══ 1. السنوية ═══
                    _leaveSection(
                      id: 'annual', title: 'الإجازة السنوية',
                      icon: Icons.wb_sunny, color: Colors.blue,
                      enabled: _annualEnabled, onToggle: (v) => _annualEnabled = v,
                      children: [
                        _numRow('عدد الأيام السنوية', _annualDays, (v) => setState(() => _annualDays = v)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _annualEarnStart,
                          decoration: const InputDecoration(labelText: 'بدء الاستحقاق', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'immediate',       child: Text('من أول يوم')),
                            DropdownMenuItem(value: 'after_probation', child: Text('بعد فترة الاختبار')),
                            DropdownMenuItem(value: 'after_year',      child: Text('بعد سنة كاملة')),
                          ],
                          onChanged: (v) => setState(() => _annualEarnStart = v ?? _annualEarnStart),
                        ),
                        const SizedBox(height: 8),
                        _numRow('أقل مدة إخطار (أيام)', _annualMinNotice, (v) => setState(() => _annualMinNotice = v)),
                        _numRow('أقصى إجازة متتالية', _annualMaxConsecutive, (v) => setState(() => _annualMaxConsecutive = v)),
                        _checkRow('ترحيل الرصيد للسنة التالية', _annualCarryOver, (v) => _annualCarryOver = v),
                        if (_annualCarryOver)
                          _numRow('أقصى أيام للترحيل', _annualMaxCarryOver, (v) => setState(() => _annualMaxCarryOver = v)),
                        _checkRow('السماح بصرف نقدي للرصيد المتبقي', _annualCashOut, (v) => _annualCashOut = v),
                      ],
                    ),

                    // ═══ 2. المرضية ═══
                    _leaveSection(
                      id: 'sick', title: 'الإجازة المرضية',
                      icon: Icons.favorite, color: Colors.red,
                      enabled: _sickEnabled, onToggle: (v) => _sickEnabled = v,
                      children: [
                        _numRow('أقصى أيام في السنة', _sickMaxDays, (v) => setState(() => _sickMaxDays = v)),
                        _numRow('شهادة طبية بعد كام يوم', _sickCertAfter, (v) => setState(() => _sickCertAfter = v)),
                        Row(children: [
                          const Expanded(child: Text('نسبة الأجر %', style: TextStyle(fontSize: 13))),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: _sickPaidPct.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), suffixText: '%'),
                              onChanged: (v) => setState(() => _sickPaidPct = double.tryParse(v) ?? _sickPaidPct),
                            ),
                          ),
                        ]),
                      ],
                    ),

                    // ═══ 3. الطارئة ═══
                    _leaveSection(
                      id: 'emergency', title: 'الإجازة الطارئة',
                      icon: Icons.bolt, color: Colors.amber,
                      enabled: _emergencyEnabled, onToggle: (v) => _emergencyEnabled = v,
                      children: [
                        _numRow('أقصى أيام/سنة', _emergencyMaxDays, (v) => setState(() => _emergencyMaxDays = v)),
                        _numRow('أقصى مرات/شهر', _emergencyMaxPerMonth, (v) => setState(() => _emergencyMaxPerMonth = v)),
                        _numRow('إخطار مسبق (ساعات)', _emergencyMinNoticeHours, (v) => setState(() => _emergencyMinNoticeHours = v)),
                        _checkRow('السبب مطلوب', _emergencyRequiresReason, (v) => _emergencyRequiresReason = v),
                        _checkRow('تُخصم من رصيد السنوية', _emergencyDeductFromAnnual, (v) => _emergencyDeductFromAnnual = v),
                      ],
                    ),

                    // ═══ 4. الأمومة ═══
                    _leaveSection(
                      id: 'maternity', title: 'إجازة الأمومة',
                      icon: Icons.child_care, color: Colors.pink,
                      enabled: _maternityEnabled, onToggle: (v) => _maternityEnabled = v,
                      children: [
                        _numRow('عدد الأيام', _maternityDays, (v) => setState(() => _maternityDays = v)),
                        Row(children: [
                          const Expanded(child: Text('نسبة الأجر %', style: TextStyle(fontSize: 13))),
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              initialValue: _maternityPaidPct.toStringAsFixed(0),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), suffixText: '%'),
                              onChanged: (v) => setState(() => _maternityPaidPct = double.tryParse(v) ?? _maternityPaidPct),
                            ),
                          ),
                        ]),
                        _numRow('أيام تمديد', _maternityExtensionDays, (v) => setState(() => _maternityExtensionDays = v)),
                        _numRow('الحد الأقصى (مرات)', _maternityMaxTimes, (v) => setState(() => _maternityMaxTimes = v)),
                        _checkRow('مدفوعة', _maternityPaid, (v) => _maternityPaid = v),
                      ],
                    ),

                    // ═══ 5. الأبوة ═══
                    _leaveSection(
                      id: 'paternity', title: 'إجازة الأبوة',
                      icon: Icons.person, color: Colors.cyan,
                      enabled: _paternityEnabled, onToggle: (v) => _paternityEnabled = v,
                      children: [
                        _numRow('عدد الأيام', _paternityDays, (v) => setState(() => _paternityDays = v)),
                        _checkRow('مدفوعة', _paternityPaid, (v) => _paternityPaid = v),
                      ],
                    ),

                    // ═══ 6. بدون رصيد ═══
                    _leaveSection(
                      id: 'unpaid', title: 'الإجازة بدون رصيد',
                      icon: Icons.block, color: Colors.orange,
                      enabled: _unpaidEnabled, onToggle: (v) => _unpaidEnabled = v,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _unpaidDeductionType,
                          decoration: const InputDecoration(labelText: 'طريقة الحسم', border: OutlineInputBorder(), isDense: true),
                          items: const [
                            DropdownMenuItem(value: 'full_day',   child: Text('يوم كامل من المرتب')),
                            DropdownMenuItem(value: 'basic_only', child: Text('من الأساسي فقط')),
                            DropdownMenuItem(value: 'custom',     child: Text('مبلغ مخصص لكل يوم')),
                          ],
                          onChanged: (v) => setState(() => _unpaidDeductionType = v ?? _unpaidDeductionType),
                        ),
                        if (_unpaidDeductionType == 'custom') ...[
                          const SizedBox(height: 8),
                          Row(children: [
                            const Expanded(child: Text('المبلغ لكل يوم (EGP)', style: TextStyle(fontSize: 13))),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                initialValue: _unpaidCustomAmount.toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                                onChanged: (v) => setState(() => _unpaidCustomAmount = double.tryParse(v) ?? _unpaidCustomAmount),
                              ),
                            ),
                          ]),
                        ],
                        _numRow('أقصى أيام/سنة', _unpaidMaxDays, (v) => setState(() => _unpaidMaxDays = v)),
                        _checkRow('يحتاج موافقة', _unpaidRequiresApproval, (v) => _unpaidRequiresApproval = v),
                      ],
                    ),

                    // ═══ 7. الحج ═══
                    _leaveSection(
                      id: 'hajj', title: 'إجازة الحج',
                      icon: Icons.nights_stay, color: Colors.green,
                      enabled: _hajjEnabled, onToggle: (v) => _hajjEnabled = v,
                      children: [
                        _numRow('عدد الأيام', _hajjDays, (v) => setState(() => _hajjDays = v)),
                        _numRow('أقل سنوات خدمة', _hajjMinServiceYears, (v) => setState(() => _hajjMinServiceYears = v)),
                        _checkRow('مدفوعة', _hajjPaid, (v) => _hajjPaid = v),
                        _checkRow('مرة واحدة طوال الخدمة', _hajjOnceInLifetime, (v) => _hajjOnceInLifetime = v),
                      ],
                    ),

                    // ═══ 8. الوفاة ═══
                    _leaveSection(
                      id: 'bereavement', title: 'إجازة الوفاة',
                      icon: Icons.sentiment_very_dissatisfied, color: Colors.blueGrey,
                      enabled: _bereavementEnabled, onToggle: (v) => _bereavementEnabled = v,
                      children: [
                        _numRow('أيام (درجة أولى: أب/أم/زوج/زوجة/ابن)', _bereavementFirst, (v) => setState(() => _bereavementFirst = v)),
                        _numRow('أيام (درجة ثانية: أخ/جد)', _bereavementSecond, (v) => setState(() => _bereavementSecond = v)),
                      ],
                    ),

                    // ═══ 9. الزواج ═══
                    _leaveSection(
                      id: 'marriage', title: 'إجازة الزواج',
                      icon: Icons.favorite_border, color: Colors.pink,
                      enabled: _marriageEnabled, onToggle: (v) => _marriageEnabled = v,
                      children: [
                        _numRow('عدد الأيام', _marriageDays, (v) => setState(() => _marriageDays = v)),
                        _checkRow('مرة واحدة طوال الخدمة', _marriageOnceInLifetime, (v) => _marriageOnceInLifetime = v),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // ═══ نطاق التطبيق ═══
                    _sectionCard('نطاق التطبيق *', [
                      DropdownButtonFormField<String>(
                        initialValue: _scope,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'company',    child: Text('الشركة كلها')),
                          DropdownMenuItem(value: 'branch',     child: Text('فرع محدد')),
                          DropdownMenuItem(value: 'department', child: Text('إدارة محددة')),
                          DropdownMenuItem(value: 'employees',  child: Text('موظفين محددين')),
                        ],
                        onChanged: (v) => setState(() => _scope = v ?? _scope),
                      ),
                      if (_scope == 'branch') ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedBranch,
                          decoration: const InputDecoration(labelText: 'الفرع', border: OutlineInputBorder(), isDense: true),
                          hint: const Text('-- اختر --'),
                          items: _branches.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(
                            value: b['id'] as int,
                            child: Text(b['name_ar'] ?? b['name_en'] ?? ''),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedBranch = v),
                        ),
                      ],
                      if (_scope == 'department') ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedDepartment,
                          decoration: const InputDecoration(labelText: 'الإدارة', border: OutlineInputBorder(), isDense: true),
                          hint: const Text('-- اختر --'),
                          items: _departments.map<DropdownMenuItem<int>>((d) => DropdownMenuItem(
                            value: d['id'] as int,
                            child: Text(d['name_ar'] ?? d['name_en'] ?? ''),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedDepartment = v),
                        ),
                      ],
                      if (_scope == 'employees') ...[
                        const SizedBox(height: 10),
                        Text('الموظفين المحددين (${_selectedEmployees.length})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _empSearchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'بحث...',
                            prefixIcon: Icon(Icons.search, size: 18),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView(
                            children: _filteredEmployees.map((e) {
                              final id   = e['id'] as int;
                              final name = e['full_name'] ?? '${e['first_name_ar'] ?? ''} ${e['last_name_ar'] ?? ''}'.trim();
                              final code = e['employee_code'] ?? '';
                              return CheckboxListTile(
                                value: _selectedEmployees.contains(id),
                                dense: true,
                                title: Text(name, style: const TextStyle(fontSize: 13)),
                                subtitle: code.isNotEmpty ? Text(code, style: const TextStyle(fontSize: 11)) : null,
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    _selectedEmployees.add(id);
                                  } else {
                                    _selectedEmployees.remove(id);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 14),

                    // ═══ التواريخ ═══
                    _sectionCard('التواريخ', [
                      Row(children: [
                        Expanded(child: _datePicker(_startDateCtrl, 'من تاريخ *')),
                        const SizedBox(width: 10),
                        Expanded(child: _datePicker(_endDateCtrl, 'لحد تاريخ (اختياري)')),
                      ]),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ الحالة ═══
                    _sectionCard('الحالة', [
                      Row(children: [
                        const Expanded(child: Text('القاعدة نشطة', style: TextStyle(fontSize: 14))),
                        Switch(
                          value: _isActive,
                          activeThumbColor: kLeaveColor,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ]),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ سبب التغيير ═══
                    _sectionCard('سبب التغيير', [
                      TextField(
                        controller: _changeReasonCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'مثال: تحديث أيام الإجازة السنوية 2025',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // ═══ زر الحفظ ═══
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check),
                        label: Text(
                          _saving ? 'جاري الحفظ...' : (_isEdit ? 'حفظ التعديلات' : 'إنشاء'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kLeaveColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kLeaveColor)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _datePicker(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
      onTap: () => _pickDate(ctrl),
    );
  }
}
