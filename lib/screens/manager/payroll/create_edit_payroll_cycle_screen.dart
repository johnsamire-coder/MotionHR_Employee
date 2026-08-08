import 'package:flutter/material.dart';
import '../../../services/payroll_cycle_service.dart';

const Color kCycleCreateColor = Color(0xFF5E35B1);

class CreateEditPayrollCycleScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateEditPayrollCycleScreen({super.key, this.existing});

  @override
  State<CreateEditPayrollCycleScreen> createState() => _CreateEditPayrollCycleScreenState();
}

class _CreateEditPayrollCycleScreenState extends State<CreateEditPayrollCycleScreen> {
  final _cutoffDayCtrl = TextEditingController(text: '25');
  final _payDayCtrl = TextEditingController(text: '5');
  final _workingDaysCtrl = TextEditingController(text: '22');
  final _notifyDaysCtrl = TextEditingController(text: '2');
  final _refPrefixCtrl = TextEditingController(text: 'PR');
  final _startDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T').first);
  final _endDateCtrl = TextEditingController();
  final _changeReasonCtrl = TextEditingController();

  String _cycleType = 'calendar_month';
  String _weeklyPayDay = 'sunday';
  String _holidayHandling = 'before';
  String _defaultCurrency = 'EGP';
  String _prorationMethod = '30_days';
  String _newEmployeeHandling = 'prorated';
  String _approvalLevel = 'hr_only';
  String _firstApproverRole = 'hr_manager';
  String _secondApproverRole = '';
  String _thirdApproverRole = '';
  bool _autoGeneratePayroll = true;
  bool _requireApprovalBeforePay = true;
  bool _isActive = true;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existing!;
      _cycleType = p['cycle_type'] ?? 'calendar_month';
      _cutoffDayCtrl.text = (p['cutoff_day'] ?? 25).toString();
      _payDayCtrl.text = (p['pay_day'] ?? 5).toString();
      _weeklyPayDay = p['weekly_pay_day'] ?? 'sunday';
      _holidayHandling = p['holiday_handling'] ?? 'before';
      _defaultCurrency = p['default_currency'] ?? 'EGP';
      _prorationMethod = p['proration_method'] ?? '30_days';
      _workingDaysCtrl.text = (p['working_days_per_month'] ?? 22).toString();
      _newEmployeeHandling = p['new_employee_handling'] ?? 'prorated';
      _notifyDaysCtrl.text = (p['payslip_notify_days_before'] ?? 2).toString();
      _autoGeneratePayroll = p['auto_generate_payroll'] ?? true;
      _refPrefixCtrl.text = p['payroll_ref_prefix'] ?? 'PR';
      _approvalLevel = p['approval_level'] ?? 'hr_only';
      _requireApprovalBeforePay = p['require_approval_before_pay'] ?? true;
      _firstApproverRole = p['first_approver_role'] ?? 'hr_manager';
      _secondApproverRole = p['second_approver_role'] ?? '';
      _thirdApproverRole = p['third_approver_role'] ?? '';
      _isActive = p['is_active'] ?? true;
      _startDateCtrl.text = p['start_date'] ?? '';
      _endDateCtrl.text = p['end_date'] ?? '';
    }
  }

  @override
  void dispose() {
    _cutoffDayCtrl.dispose();
    _payDayCtrl.dispose();
    _workingDaysCtrl.dispose();
    _notifyDaysCtrl.dispose();
    _refPrefixCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _changeReasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    DateTime initial;
    try {
      initial = DateTime.parse(ctrl.text);
    } catch (_) {
      initial = now;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ctrl.text = picked.toIso8601String().split('T').first;
      setState(() {});
    }
  }

  Future<void> _save() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_startDateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? '????? ????? ?????' : 'Start date required')),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'cycle_type': _cycleType,
      'cutoff_day': int.tryParse(_cutoffDayCtrl.text) ?? 25,
      'pay_day': int.tryParse(_payDayCtrl.text) ?? 5,
      'weekly_pay_day': _weeklyPayDay,
      'holiday_handling': _holidayHandling,
      'default_currency': _defaultCurrency,
      'proration_method': _prorationMethod,
      'working_days_per_month': int.tryParse(_workingDaysCtrl.text) ?? 22,
      'new_employee_handling': _newEmployeeHandling,
      'payslip_notify_days_before': int.tryParse(_notifyDaysCtrl.text) ?? 2,
      'auto_generate_payroll': _autoGeneratePayroll,
      'payroll_ref_prefix': _refPrefixCtrl.text.trim(),
      'approval_level': _approvalLevel,
      'require_approval_before_pay': _requireApprovalBeforePay,
      'first_approver_role': _firstApproverRole,
      'second_approver_role': _secondApproverRole,
      'third_approver_role': _thirdApproverRole,
      'is_active': _isActive,
      'start_date': _startDateCtrl.text.trim(),
      'end_date': _endDateCtrl.text.trim().isEmpty ? null : _endDateCtrl.text.trim(),
      'change_reason': _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await PayrollCycleService.updatePolicy(widget.existing!['id'], data);
      } else {
        await PayrollCycleService.createPolicy(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? '?? ?????' : 'Saved'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? '??? ?????: $e' : 'Save failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isMonthly = _cycleType == 'calendar_month' || _cycleType == 'custom_month';
    final showApprover2 = _approvalLevel == 'hr_plus_manager' || _approvalLevel == 'hr_plus_finance_plus_ceo';
    final showApprover3 = _approvalLevel == 'hr_plus_finance_plus_ceo';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(_isEdit
              ? (isAr ? '????? ????? ???? ???????' : 'Edit Payroll Cycle')
              : (isAr ? '????? ????? ???? ???????' : 'Create Payroll Cycle')),
          backgroundColor: kCycleCreateColor,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: Text(
                isAr ? '???' : 'Save',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ??? ??????
              _card(isAr ? '??? ??????' : 'Cycle Type', Icons.calendar_month, [
                _dropdown(_cycleType, isAr ? '?????' : 'Type', [
                  {'value': 'calendar_month', 'label': isAr ? '??? ?????? (1 ? ??? ???)' : 'Calendar Month'},
                  {'value': 'custom_month', 'label': isAr ? '??? ????' : 'Custom Month'},
                  {'value': 'weekly', 'label': isAr ? '??????' : 'Weekly'},
                  {'value': 'bi_weekly', 'label': isAr ? '?? ???????' : 'Bi-Weekly'},
                ], (v) => setState(() => _cycleType = v)),
                if (_cycleType == 'custom_month') ...[
                  const SizedBox(height: 10),
                  _numberField(_cutoffDayCtrl, isAr ? '??? ??? ????? (1-31)' : 'Cutoff Day (1-31)'),
                ],
              ]),
              const SizedBox(height: 14),

              // ??? ?????
              _card(isAr ? '??? ??? ????????' : 'Pay Day', Icons.attach_money, [
                if (isMonthly)
                  _numberField(_payDayCtrl, isAr ? '??? ????? ?? ????? (1-31)' : 'Pay Day (1-31)')
                else
                  _dropdown(_weeklyPayDay, isAr ? '??? ????? ????????' : 'Weekly Pay Day', [
                    {'value': 'sunday', 'label': isAr ? '?????' : 'Sunday'},
                    {'value': 'monday', 'label': isAr ? '???????' : 'Monday'},
                    {'value': 'tuesday', 'label': isAr ? '????????' : 'Tuesday'},
                    {'value': 'wednesday', 'label': isAr ? '????????' : 'Wednesday'},
                    {'value': 'thursday', 'label': isAr ? '??????' : 'Thursday'},
                    {'value': 'friday', 'label': isAr ? '??????' : 'Friday'},
                    {'value': 'saturday', 'label': isAr ? '?????' : 'Saturday'},
                  ], (v) => setState(() => _weeklyPayDay = v)),
                const SizedBox(height: 10),
                _dropdown(_holidayHandling, isAr ? '?? ????? ??? ????' : 'If Pay Day is Holiday', [
                  {'value': 'before', 'label': isAr ? '????? ????? ???? ????' : 'Pay Before'},
                  {'value': 'after', 'label': isAr ? '????? ????? ???? ????' : 'Pay After'},
                  {'value': 'same', 'label': isAr ? '??? ?????' : 'Same Day'},
                ], (v) => setState(() => _holidayHandling = v)),
              ]),
              const SizedBox(height: 14),

              // ??????
              _card(isAr ? '??????' : 'Currency', Icons.currency_exchange, [
                _dropdown(_defaultCurrency, isAr ? '?????? ??????????' : 'Default Currency', [
                  {'value': 'EGP', 'label': isAr ? '???? ???? (EGP)' : 'Egyptian Pound (EGP)'},
                  {'value': 'USD', 'label': isAr ? '????? ?????? (USD)' : 'US Dollar (USD)'},
                  {'value': 'EUR', 'label': isAr ? '???? (EUR)' : 'Euro (EUR)'},
                  {'value': 'SAR', 'label': isAr ? '???? ????? (SAR)' : 'Saudi Riyal (SAR)'},
                  {'value': 'AED', 'label': isAr ? '???? ??????? (AED)' : 'UAE Dirham (AED)'},
                ], (v) => setState(() => _defaultCurrency = v)),
              ]),
              const SizedBox(height: 14),

              // ????? ??????
              _card(isAr ? '????? ?????? ????????' : 'Proration Method', Icons.calculate, [
                _dropdown(_prorationMethod, isAr ? '???????' : 'Method', [
                  {'value': '30_days', 'label': isAr ? '30 ??? ??????' : '30 Days Always'},
                  {'value': 'actual_days', 'label': isAr ? '???? ????? ???????' : 'Actual Days'},
                  {'value': 'working_days', 'label': isAr ? '???? ????? ???' : 'Working Days'},
                ], (v) => setState(() => _prorationMethod = v)),
                if (_prorationMethod == 'working_days') ...[
                  const SizedBox(height: 10),
                  _numberField(_workingDaysCtrl, isAr ? '???? ????? ??????? (1-31)' : 'Working Days/Month'),
                ],
              ]),
              const SizedBox(height: 14),

              // ?????? ??????
              _card(isAr ? '?????? ?????? ??????' : 'New Employee Handling', Icons.person_add, [
                _dropdown(_newEmployeeHandling, isAr ? '??????' : 'Handling', [
                  {'value': 'full', 'label': isAr ? '???? ???? ?? ??? ???' : 'Full Salary'},
                  {'value': 'prorated', 'label': isAr ? '??????? ????????' : 'Prorated'},
                  {'value': 'next_cycle', 'label': isAr ? '???? ?? ?????? ??????' : 'Next Cycle'},
                ], (v) => setState(() => _newEmployeeHandling = v)),
              ]),
              const SizedBox(height: 14),

              // ?????????
              _card(isAr ? '?????????' : 'Notifications', Icons.notifications, [
                Row(
                  children: [
                    Expanded(child: _numberField(_notifyDaysCtrl, isAr ? '????? ??? ???? ???' : 'Notify Days Before')),
                    const SizedBox(width: 10),
                    Expanded(child: _textField(_refPrefixCtrl, isAr ? '????? ?????' : 'Ref Prefix')),
                  ],
                ),
                SwitchListTile(
                  title: Text(isAr ? '????? Payroll ?????? ??? ?????' : 'Auto-generate on cutoff'),
                  value: _autoGeneratePayroll,
                  activeThumbColor: kCycleCreateColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _autoGeneratePayroll = v),
                ),
              ]),
              const SizedBox(height: 14),

              // ?????????
              _card(isAr ? '?????????' : 'Approvals', Icons.check_circle, [
                _dropdown(_approvalLevel, isAr ? '????? ????????' : 'Approval Level', [
                  {'value': 'hr_only', 'label': isAr ? 'HR ???' : 'HR Only'},
                  {'value': 'hr_plus_manager', 'label': isAr ? 'HR + ?????? ?????' : 'HR + Manager'},
                  {'value': 'hr_plus_finance_plus_ceo', 'label': isAr ? 'HR + ???? + ???? ???' : 'HR + Finance + CEO'},
                ], (v) => setState(() => _approvalLevel = v)),
                SwitchListTile(
                  title: Text(isAr ? '???????? ?????? ??? ?????' : 'Require approval before pay'),
                  value: _requireApprovalBeforePay,
                  activeThumbColor: kCycleCreateColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _requireApprovalBeforePay = v),
                ),
                const SizedBox(height: 10),
                Text(
                  isAr
                      ? '??? ??????? ???????? ?? ?????? ????????:'
                      : 'Roles responsible for approving payroll:',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
                _dropdown(_firstApproverRole, isAr ? '??????? ????? (HR)' : 'First Approver (HR)', [
                  {'value': 'hr_manager', 'label': isAr ? '???? ??????? ???????' : 'HR Manager'},
                  {'value': 'company_admin', 'label': isAr ? '???? ??????' : 'Company Admin'},
                  {'value': 'manager', 'label': isAr ? '????' : 'Manager'},
                ], (v) => setState(() => _firstApproverRole = v)),
                if (showApprover2) ...[
                  const SizedBox(height: 10),
                  _dropdown(_secondApproverRole.isEmpty ? 'manager' : _secondApproverRole,
                      isAr ? '??????? ?????? (??????)' : 'Second Approver (Manager)', [
                    {'value': 'manager', 'label': isAr ? '???? ???' : 'General Manager'},
                    {'value': 'company_admin', 'label': isAr ? '???? ??????' : 'Company Admin'},
                  ], (v) => setState(() => _secondApproverRole = v)),
                ],
                if (showApprover3) ...[
                  const SizedBox(height: 10),
                  _dropdown(_thirdApproverRole.isEmpty ? 'company_admin' : _thirdApproverRole,
                      isAr ? '??????? ?????? (??????/CEO)' : 'Third Approver (Finance/CEO)', [
                    {'value': 'company_admin', 'label': isAr ? '???? ?????? (CEO)' : 'Company Admin (CEO)'},
                    {'value': 'finance_manager', 'label': isAr ? '???? ????' : 'Finance Manager'},
                  ], (v) => setState(() => _thirdApproverRole = v)),
                ],
              ]),
              const SizedBox(height: 14),

              // ????????
              _card(isAr ? '???? ???????' : 'Effective Period', Icons.date_range, [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(_startDateCtrl),
                        child: IgnorePointer(
                          child: TextField(
                            controller: _startDateCtrl,
                            decoration: InputDecoration(
                              labelText: isAr ? '?? ????? *' : 'Start Date *',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(_endDateCtrl),
                        child: IgnorePointer(
                          child: TextField(
                            controller: _endDateCtrl,
                            decoration: InputDecoration(
                              labelText: isAr ? '??? ????? (???????)' : 'End Date (optional)',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              suffixIcon: const Icon(Icons.calendar_today, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: Text(isAr ? '??????? ????' : 'Policy is active'),
                  value: _isActive,
                  activeThumbColor: kCycleCreateColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ]),

              if (_isEdit) ...[
                const SizedBox(height: 14),
                _card(isAr ? '??? ???????' : 'Change Reason', Icons.edit_note, [
                  TextField(
                    controller: _changeReasonCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: isAr ? '????: ????? ??? ????? ?? 5 ??? 1' : 'e.g. Change pay day from 5 to 1',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ]),
              ],

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label: Text(
                    _saving
                        ? (isAr ? '???? ?????...' : 'Saving...')
                        : (_isEdit ? (isAr ? '??? ?????????' : 'Save Changes') : (isAr ? '????? ???????' : 'Create Policy')),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCycleCreateColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: kCycleCreateColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kCycleCreateColor)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _numberField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _dropdown(String currentValue, String label, List<Map<String, String>> items, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items.map((item) => DropdownMenuItem(
        value: item['value'],
        child: Text(item['label']!, style: const TextStyle(fontSize: 13)),
      )).toList(),
      onChanged: (v) => onChanged(v ?? currentValue),
    );
  }
}
