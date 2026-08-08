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
  final _cutoffDayCtrl    = TextEditingController(text: '25');
  final _payDayCtrl       = TextEditingController(text: '5');
  final _workingDaysCtrl  = TextEditingController(text: '22');
  final _notifyDaysCtrl   = TextEditingController(text: '2');
  final _refPrefixCtrl    = TextEditingController(text: 'PR');
  final _startDateCtrl    = TextEditingController();
  final _endDateCtrl      = TextEditingController();
  final _changeReasonCtrl = TextEditingController();

  String _cycleType              = 'calendar_month';
  String _weeklyPayDay           = 'sunday';
  String _holidayHandling        = 'before';
  String _defaultCurrency        = 'EGP';
  String _prorationMethod        = '30_days';
  String _newEmployeeHandling    = 'prorated';
  String _approvalLevel          = 'hr_only';
  String _firstApproverRole      = 'hr_manager';
  String _secondApproverRole     = '';
  String _thirdApproverRole      = '';
  bool   _autoGeneratePayroll    = true;
  bool   _requireApprovalBeforePay = true;
  bool   _isActive               = true;
  bool   _saving                 = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _startDateCtrl.text = DateTime.now().toIso8601String().split('T').first;
    if (_isEdit) {
      final p = widget.existing!;
      _cycleType               = p['cycle_type']               ?? 'calendar_month';
      _cutoffDayCtrl.text      = (p['cutoff_day']              ?? 25).toString();
      _payDayCtrl.text         = (p['pay_day']                 ?? 5).toString();
      _weeklyPayDay            = p['weekly_pay_day']            ?? 'sunday';
      _holidayHandling         = p['holiday_handling']          ?? 'before';
      _defaultCurrency         = p['default_currency']          ?? 'EGP';
      _prorationMethod         = p['proration_method']          ?? '30_days';
      _workingDaysCtrl.text    = (p['working_days_per_month']   ?? 22).toString();
      _newEmployeeHandling     = p['new_employee_handling']     ?? 'prorated';
      _notifyDaysCtrl.text     = (p['payslip_notify_days_before'] ?? 2).toString();
      _autoGeneratePayroll     = p['auto_generate_payroll']     ?? true;
      _refPrefixCtrl.text      = p['payroll_ref_prefix']        ?? 'PR';
      _approvalLevel           = p['approval_level']            ?? 'hr_only';
      _requireApprovalBeforePay= p['require_approval_before_pay'] ?? true;
      _firstApproverRole       = p['first_approver_role']       ?? 'hr_manager';
      _secondApproverRole      = p['second_approver_role']      ?? '';
      _thirdApproverRole       = p['third_approver_role']       ?? '';
      _isActive                = p['is_active']                 ?? true;
      _startDateCtrl.text      = p['start_date']                ?? '';
      _endDateCtrl.text        = p['end_date']                  ?? '';
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
    try { initial = DateTime.parse(ctrl.text); } catch (_) { initial = now; }
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
    if (_startDateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاريخ البدء مطلوب')),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'cycle_type'                : _cycleType,
      'cutoff_day'                : int.tryParse(_cutoffDayCtrl.text) ?? 25,
      'pay_day'                   : int.tryParse(_payDayCtrl.text) ?? 5,
      'weekly_pay_day'            : _weeklyPayDay,
      'holiday_handling'          : _holidayHandling,
      'default_currency'          : _defaultCurrency,
      'proration_method'          : _prorationMethod,
      'working_days_per_month'    : int.tryParse(_workingDaysCtrl.text) ?? 22,
      'new_employee_handling'     : _newEmployeeHandling,
      'payslip_notify_days_before': int.tryParse(_notifyDaysCtrl.text) ?? 2,
      'auto_generate_payroll'     : _autoGeneratePayroll,
      'payroll_ref_prefix'        : _refPrefixCtrl.text.trim(),
      'approval_level'            : _approvalLevel,
      'require_approval_before_pay': _requireApprovalBeforePay,
      'first_approver_role'       : _firstApproverRole,
      'second_approver_role'      : _secondApproverRole,
      'third_approver_role'       : _thirdApproverRole,
      'is_active'                 : _isActive,
      'start_date'                : _startDateCtrl.text.trim(),
      'end_date'                  : _endDateCtrl.text.trim().isEmpty ? null : _endDateCtrl.text.trim(),
      'change_reason'             : _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await PayrollCycleService.updatePolicy(widget.existing!['id'], data);
      } else {
        await PayrollCycleService.createPolicy(data);
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

  @override
  Widget build(BuildContext context) {
    final isAr         = Localizations.localeOf(context).languageCode == 'ar';
    final isMonthly    = _cycleType == 'calendar_month' || _cycleType == 'custom_month';
    final showApprover2 = _approvalLevel == 'hr_plus_manager' || _approvalLevel == 'hr_plus_finance_plus_ceo';
    final showApprover3 = _approvalLevel == 'hr_plus_finance_plus_ceo';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(_isEdit ? 'تعديل سياسة دورة الرواتب' : 'إنشاء سياسة دورة الرواتب'),
          backgroundColor: kCycleCreateColor,
          foregroundColor: Colors.white,
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('حفظ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ═══ نوع الدورة ═══
              _card('نوع الدورة', Icons.calendar_month, [
                _dropdown(_cycleType, 'النوع', [
                  {'value': 'calendar_month', 'label': 'شهر ميلادي (1 → آخر يوم)'},
                  {'value': 'custom_month',   'label': 'شهر مخصص'},
                  {'value': 'weekly',         'label': 'أسبوعي'},
                  {'value': 'bi_weekly',      'label': 'كل أسبوعين'},
                ], (v) => setState(() => _cycleType = v)),
                if (_cycleType == 'custom_month') ...[
                  const SizedBox(height: 10),
                  _numberField(_cutoffDayCtrl, 'يوم قفل الشهر (1-31)'),
                ],
              ]),
              const SizedBox(height: 14),

              // ═══ يوم الصرف ═══
              _card('يوم صرف المرتبات', Icons.attach_money, [
                if (isMonthly)
                  _numberField(_payDayCtrl, 'يوم الصرف في الشهر (1-31)')
                else
                  _dropdown(_weeklyPayDay, 'يوم الصرف الأسبوعي', [
                    {'value': 'sunday',    'label': 'الأحد'},
                    {'value': 'monday',    'label': 'الاثنين'},
                    {'value': 'tuesday',   'label': 'الثلاثاء'},
                    {'value': 'wednesday', 'label': 'الأربعاء'},
                    {'value': 'thursday',  'label': 'الخميس'},
                    {'value': 'friday',    'label': 'الجمعة'},
                    {'value': 'saturday',  'label': 'السبت'},
                  ], (v) => setState(() => _weeklyPayDay = v)),
                const SizedBox(height: 10),
                _dropdown(_holidayHandling, 'لو الصرف يوم عطلة', [
                  {'value': 'before', 'label': 'الصرف اليوم اللي قبله'},
                  {'value': 'after',  'label': 'الصرف اليوم اللي بعده'},
                  {'value': 'same',   'label': 'نفس اليوم'},
                ], (v) => setState(() => _holidayHandling = v)),
              ]),
              const SizedBox(height: 14),

              // ═══ العملة ═══
              _card('العملة', Icons.currency_exchange, [
                _dropdown(_defaultCurrency, 'العملة الافتراضية', [
                  {'value': 'EGP', 'label': 'جنيه مصري (EGP)'},
                  {'value': 'USD', 'label': 'دولار أمريكي (USD)'},
                  {'value': 'EUR', 'label': 'يورو (EUR)'},
                  {'value': 'SAR', 'label': 'ريال سعودي (SAR)'},
                  {'value': 'AED', 'label': 'درهم إماراتي (AED)'},
                ], (v) => setState(() => _defaultCurrency = v)),
              ]),
              const SizedBox(height: 14),

              // ═══ طريقة الحساب ═══
              _card('طريقة النسبة والتناسب', Icons.calculate, [
                _dropdown(_prorationMethod, 'الطريقة', [
                  {'value': '30_days',      'label': '30 يوم دائماً'},
                  {'value': 'actual_days',  'label': 'أيام الشهر الفعلية'},
                  {'value': 'working_days', 'label': 'أيام العمل فقط'},
                ], (v) => setState(() => _prorationMethod = v)),
                if (_prorationMethod == 'working_days') ...[
                  const SizedBox(height: 10),
                  _numberField(_workingDaysCtrl, 'أيام العمل الشهرية (1-31)'),
                ],
              ]),
              const SizedBox(height: 14),

              // ═══ الموظف الجديد ═══
              _card('معالجة الموظف الجديد', Icons.person_add, [
                _dropdown(_newEmployeeHandling, 'المعالجة', [
                  {'value': 'full',       'label': 'مرتب كامل من أول يوم'},
                  {'value': 'prorated',   'label': 'بالنسبة والتناسب'},
                  {'value': 'next_cycle', 'label': 'يبدأ من الدورة الجاية'},
                ], (v) => setState(() => _newEmployeeHandling = v)),
              ]),
              const SizedBox(height: 14),

              // ═══ الإشعارات ═══
              _card('الإشعارات', Icons.notifications, [
                Row(children: [
                  Expanded(child: _numberField(_notifyDaysCtrl, 'إشعار قبل الصرف بكام يوم')),
                  const SizedBox(width: 10),
                  Expanded(child: _textField(_refPrefixCtrl, 'بادئة الرقم المسلسل')),
                ]),
                SwitchListTile(
                  title: const Text('توليد Payroll تلقائي يوم القفل'),
                  value: _autoGeneratePayroll,
                  activeThumbColor: kCycleCreateColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _autoGeneratePayroll = v),
                ),
              ]),
              const SizedBox(height: 14),

              // ═══ الموافقات ═══
              _card('الموافقات', Icons.check_circle, [
                _dropdown(_approvalLevel, 'مستوى الموافقة', [
                  {'value': 'hr_only',                  'label': 'HR فقط'},
                  {'value': 'hr_plus_manager',          'label': 'HR + المدير العام'},
                  {'value': 'hr_plus_finance_plus_ceo', 'label': 'HR + مالي + مدير عام'},
                ], (v) => setState(() => _approvalLevel = v)),
                SwitchListTile(
                  title: const Text('الموافقة مطلوبة قبل الصرف'),
                  value: _requireApprovalBeforePay,
                  activeThumbColor: kCycleCreateColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _requireApprovalBeforePay = v),
                ),
                const SizedBox(height: 10),
                Text(
                  'الأدوار المسؤولة عن اعتماد الرواتب:',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
                _dropdown(_firstApproverRole, 'الموافق الأول (HR)', [
                  {'value': 'hr_manager',    'label': 'مدير الموارد البشرية'},
                  {'value': 'company_admin', 'label': 'مدير الشركة'},
                  {'value': 'manager',       'label': 'مدير'},
                ], (v) => setState(() => _firstApproverRole = v)),
                if (showApprover2) ...[
                  const SizedBox(height: 10),
                  _dropdown(
                    _secondApproverRole.isEmpty ? 'manager' : _secondApproverRole,
                    'الموافق الثاني (المدير)',
                    [
                      {'value': 'manager',       'label': 'مدير عام'},
                      {'value': 'company_admin', 'label': 'مدير الشركة'},
                    ],
                    (v) => setState(() => _secondApproverRole = v),
                  ),
                ],
                if (showApprover3) ...[
                  const SizedBox(height: 10),
                  _dropdown(
                    _thirdApproverRole.isEmpty ? 'company_admin' : _thirdApproverRole,
                    'الموافق الثالث (مالي/CEO)',
                    [
                      {'value': 'company_admin',    'label': 'مدير الشركة (CEO)'},
                      {'value': 'finance_manager',  'label': 'مدير مالي'},
                    ],
                    (v) => setState(() => _thirdApproverRole = v),
                  ),
                ],
              ]),
              const SizedBox(height: 14),

              // ═══ التواريخ ═══
              _card('فترة السريان', Icons.date_range, [
                Row(children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _pickDate(_startDateCtrl),
                      child: IgnorePointer(
                        child: TextField(
                          controller: _startDateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'من تاريخ *',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
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
                          decoration: const InputDecoration(
                            labelText: 'لحد تاريخ (اختياري)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            suffixIcon: Icon(Icons.calendar_today, size: 18),
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('السياسة نشطة'),
                  value: _isActive,
                  activeThumbColor: kCycleCreateColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ]),

              // ═══ سبب التغيير ═══
              const SizedBox(height: 14),
              _card('سبب التغيير', Icons.edit_note, [
                TextField(
                  controller: _changeReasonCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'مثال: تغيير يوم الصرف من 5 لـ 1',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ]),

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
                    _saving ? 'جاري الحفظ...' : (_isEdit ? 'حفظ التعديلات' : 'إنشاء السياسة'),
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
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: kCycleCreateColor),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kCycleCreateColor)),
          ]),
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
