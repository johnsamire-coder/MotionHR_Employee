import 'package:flutter/material.dart';
import '../../../services/tax_policy_service.dart';

const Color kTaxColor = Color(0xFFE65100);

class CreateEditTaxPolicyScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateEditTaxPolicyScreen({super.key, this.existing});

  @override
  State<CreateEditTaxPolicyScreen> createState() => _CreateEditTaxPolicyScreenState();
}

class _CreateEditTaxPolicyScreenState extends State<CreateEditTaxPolicyScreen> {
  final _nameCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: '');
  final _singleExemptionCtrl = TextEditingController(text: '9000');
  final _marriedExemptionCtrl = TextEditingController(text: '9000');
  final _childExemptionCtrl = TextEditingController(text: '0');
  final _maxChildrenCtrl = TextEditingController(text: '3');
  final _additionalExemptionCtrl = TextEditingController(text: '0');
  final _changeReasonCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  String _country = 'EG';
  String _calculationMethod = 'monthly_progressive';
  String _scope = 'company';
  bool _isActive = true;
  bool _exemptSocial = true;
  bool _exemptMedical = true;
  List<Map<String, dynamic>> _brackets = [];
  bool _saving = false;

  // Calculator
  final _calcIncomeCtrl = TextEditingController(text: '100000');
  String _calcMarital = 'single';
  Map<String, dynamic>? _calcResult;
  bool _calculating = false;
  bool _showCalc = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _yearCtrl.text = DateTime.now().year.toString();
    _startDateCtrl.text = DateTime.now().toIso8601String().split('T').first;
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text = p['name'] ?? '';
      _yearCtrl.text = (p['tax_year'] ?? DateTime.now().year).toString();
      _country = p['country'] ?? 'EG';
      _singleExemptionCtrl.text = (p['personal_exemption_single'] ?? 9000).toString();
      _marriedExemptionCtrl.text = (p['personal_exemption_married'] ?? 9000).toString();
      _childExemptionCtrl.text = (p['child_exemption'] ?? 0).toString();
      _maxChildrenCtrl.text = (p['max_children_exempted'] ?? 3).toString();
      _additionalExemptionCtrl.text = (p['additional_exemption'] ?? 0).toString();
      _exemptSocial = p['exempt_social_insurance'] ?? true;
      _exemptMedical = p['exempt_medical_insurance'] ?? true;
      _calculationMethod = p['calculation_method'] ?? 'monthly_progressive';
      _scope = p['scope'] ?? 'company';
      _isActive = p['is_active'] ?? true;
      _startDateCtrl.text = p['start_date'] ?? '';
      _endDateCtrl.text = p['end_date'] ?? '';
      final b = p['tax_brackets'] as List?;
      if (b != null) {
        _brackets = b.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } else {
      _nameCtrl.text = 'ضريبة الدخل';
      _brackets = [
        {'from': 0, 'to': 40000, 'rate': 0.0},
        {'from': 40001, 'to': 55000, 'rate': 10.0},
        {'from': 55001, 'to': 70000, 'rate': 15.0},
        {'from': 70001, 'to': 200000, 'rate': 20.0},
        {'from': 200001, 'to': 400000, 'rate': 22.5},
        {'from': 400001, 'to': 1200000, 'rate': 25.0},
        {'from': 1200001, 'to': null, 'rate': 27.5},
      ];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yearCtrl.dispose();
    _singleExemptionCtrl.dispose();
    _marriedExemptionCtrl.dispose();
    _childExemptionCtrl.dispose();
    _maxChildrenCtrl.dispose();
    _additionalExemptionCtrl.dispose();
    _changeReasonCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _calcIncomeCtrl.dispose();
    super.dispose();
  }

  void _addBracket() {
    final last = _brackets.isNotEmpty ? _brackets.last : null;
    final newFrom = last != null ? ((last['to'] ?? last['from'] ?? 0) as num).toInt() + 1 : 0;
    setState(() {
      _brackets.add({'from': newFrom, 'to': null, 'rate': 0.0});
    });
  }

  void _removeBracket(int i) {
    if (_brackets.length <= 1) return;
    setState(() => _brackets.removeAt(i));
  }

  void _updateBracket(int i, String field, dynamic value) {
    setState(() {
      _brackets[i][field] = value;
    });
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: ctrl.text.isNotEmpty
          ? DateTime.tryParse(ctrl.text) ?? now
          : now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        ctrl.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  Future<void> _runCalculation() async {
    setState(() {
      _calculating = true;
      _calcResult = null;
    });
    try {
      final income = double.tryParse(_calcIncomeCtrl.text) ?? 0;
      final result = await TaxPolicyService.calculate(
        annualIncome: income,
        maritalStatus: _calcMarital,
        policyId: _isEdit ? widget.existing!['id'] : null,
      );
      setState(() {
        _calcResult = result;
        _calculating = false;
      });
    } catch (e) {
      setState(() => _calculating = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل الحساب')),
      );
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم السياسة مطلوب')),
      );
      return;
    }
    if (_startDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاريخ البدء مطلوب')),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'name': _nameCtrl.text.trim(),
      'country': _country,
      'tax_year': int.tryParse(_yearCtrl.text) ?? DateTime.now().year,
      'tax_brackets': _brackets,
      'personal_exemption_single': double.tryParse(_singleExemptionCtrl.text) ?? 0,
      'personal_exemption_married': double.tryParse(_marriedExemptionCtrl.text) ?? 0,
      'child_exemption': double.tryParse(_childExemptionCtrl.text) ?? 0,
      'max_children_exempted': int.tryParse(_maxChildrenCtrl.text) ?? 3,
      'additional_exemption': double.tryParse(_additionalExemptionCtrl.text) ?? 0,
      'exempt_social_insurance': _exemptSocial,
      'exempt_medical_insurance': _exemptMedical,
      'calculation_method': _calculationMethod,
      'scope': _scope,
      'is_active': _isActive,
      'start_date': _startDateCtrl.text,
      'end_date': _endDateCtrl.text.isEmpty ? null : _endDateCtrl.text,
      'change_reason': _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await TaxPolicyService.updatePolicy(widget.existing!['id'], data);
      } else {
        await TaxPolicyService.createPolicy(data);
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(_isEdit ? 'تعديل سياسة الضرائب' : 'إنشاء سياسة ضرائب'),
          backgroundColor: kTaxColor,
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
              // ═══ المعلومات الأساسية ═══
              _sectionCard('المعلومات الأساسية', [
                _textField(_nameCtrl, 'اسم السياسة *'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _countryDropdown()),
                  const SizedBox(width: 10),
                  Expanded(child: _textField(_yearCtrl, 'السنة الضريبية', isNumber: true)),
                ]),
                const SizedBox(height: 10),
                // is_active switch
                Row(children: [
                  const Expanded(child: Text('نشط', style: TextStyle(fontSize: 14))),
                  Switch(
                    value: _isActive,
                    activeThumbColor: kTaxColor,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ]),
              ]),
              const SizedBox(height: 14),

              // ═══ النطاق وطريقة الحساب ═══
              _sectionCard('إعدادات الحساب', [
                _dropdownField(
                  label: 'طريقة الحساب',
                  value: _calculationMethod,
                  items: const [
                    DropdownMenuItem(value: 'monthly_progressive', child: Text('تقدمي شهري')),
                    DropdownMenuItem(value: 'cumulative', child: Text('تراكمي')),
                  ],
                  onChanged: (v) => setState(() => _calculationMethod = v ?? _calculationMethod),
                ),
                const SizedBox(height: 10),
                _dropdownField(
                  label: 'نطاق التطبيق',
                  value: _scope,
                  items: const [
                    DropdownMenuItem(value: 'company', child: Text('الشركة كلها')),
                    DropdownMenuItem(value: 'branch', child: Text('فرع محدد')),
                    DropdownMenuItem(value: 'department', child: Text('إدارة محددة')),
                  ],
                  onChanged: (v) => setState(() => _scope = v ?? _scope),
                ),
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

              // ═══ الشرائح الضريبية ═══
              _bracketsCard(),
              const SizedBox(height: 14),

              // ═══ الإعفاءات الشخصية ═══
              _sectionCard('الإعفاءات الشخصية (سنوي)', [
                Row(children: [
                  Expanded(child: _textField(_singleExemptionCtrl, 'إعفاء أعزب', isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _textField(_marriedExemptionCtrl, 'إعفاء متزوج', isNumber: true)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _textField(_childExemptionCtrl, 'إعفاء لكل ابن', isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _textField(_maxChildrenCtrl, 'أقصى عدد أبناء', isNumber: true)),
                ]),
                const SizedBox(height: 10),
                _textField(_additionalExemptionCtrl, 'إعفاءات إضافية سنوية', isNumber: true),
              ]),
              const SizedBox(height: 14),

              // ═══ إعفاءات التأمين ═══
              _sectionCard('إعفاءات التأمين', [
                SwitchListTile(
                  title: const Text('إعفاء حصة الموظف من التأمين الاجتماعي'),
                  value: _exemptSocial,
                  activeThumbColor: kTaxColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _exemptSocial = v),
                ),
                SwitchListTile(
                  title: const Text('إعفاء حصة الموظف من التأمين الطبي'),
                  value: _exemptMedical,
                  activeThumbColor: kTaxColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _exemptMedical = v),
                ),
              ]),
              const SizedBox(height: 14),

              // ═══ الحاسبة ═══
              _calculatorCard(),
              const SizedBox(height: 14),

              // ═══ سبب التغيير ═══
              _sectionCard('سبب التغيير', [
                _textField(_changeReasonCtrl, 'مثال: تحديث شرائح 2025'),
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
                    backgroundColor: kTaxColor,
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

  // ════════════════════════════════════════════
  // Widgets مساعدة
  // ════════════════════════════════════════════

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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTaxColor)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  Widget _countryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _country,
      decoration: const InputDecoration(
        labelText: 'الدولة',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: const [
        DropdownMenuItem(value: 'EG', child: Text('مصر')),
        DropdownMenuItem(value: 'SA', child: Text('السعودية')),
        DropdownMenuItem(value: 'AE', child: Text('الإمارات')),
        DropdownMenuItem(value: 'KW', child: Text('الكويت')),
        DropdownMenuItem(value: 'OTHER', child: Text('أخرى')),
      ],
      onChanged: (v) => setState(() => _country = v ?? 'EG'),
    );
  }

  Widget _dropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _bracketsCard() {
    return _sectionCard('الشرائح الضريبية (سنوي)', [
      ..._brackets.asMap().entries.map((entry) {
        final i = entry.key;
        final b = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFE0B2)),
          ),
          child: Row(children: [
            Expanded(
              child: TextFormField(
                initialValue: (b['from'] ?? 0).toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'من', isDense: true, border: OutlineInputBorder()),
                onChanged: (v) => _updateBracket(i, 'from', int.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                initialValue: b['to']?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'لحد (فارغ=لا نهاية)', isDense: true, border: OutlineInputBorder()),
                onChanged: (v) => _updateBracket(i, 'to', v.isEmpty ? null : int.tryParse(v)),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 70,
              child: TextFormField(
                initialValue: (b['rate'] ?? 0).toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '%', isDense: true, border: OutlineInputBorder()),
                onChanged: (v) => _updateBracket(i, 'rate', double.tryParse(v) ?? 0),
              ),
            ),
            IconButton(
              onPressed: () => _removeBracket(i),
              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
            ),
          ]),
        );
      }),
      const SizedBox(height: 4),
      OutlinedButton.icon(
        onPressed: _addBracket,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('إضافة شريحة'),
        style: OutlinedButton.styleFrom(foregroundColor: kTaxColor),
      ),
    ]);
  }

  Widget _calculatorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _showCalc = !_showCalc),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: _showCalc ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(children: [
                const Icon(Icons.calculate, color: kTaxColor, size: 20),
                const SizedBox(width: 8),
                const Text('حاسبة الضريبة', style: TextStyle(fontWeight: FontWeight.bold, color: kTaxColor)),
                const Spacer(),
                Icon(_showCalc ? Icons.expand_less : Icons.expand_more, color: kTaxColor),
              ]),
            ),
          ),
          if (_showCalc)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Expanded(child: _textField(_calcIncomeCtrl, 'الدخل السنوي', isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _calcMarital,
                      decoration: const InputDecoration(
                        labelText: 'الحالة',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'single', child: Text('أعزب')),
                        DropdownMenuItem(value: 'married', child: Text('متزوج')),
                      ],
                      onChanged: (v) => setState(() => _calcMarital = v ?? 'single'),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _calculating ? null : _runCalculation,
                    icon: _calculating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.calculate, size: 18),
                    label: const Text('احسب'),
                    style: ElevatedButton.styleFrom(backgroundColor: kTaxColor, foregroundColor: Colors.white),
                  ),
                ),
                if (_calcResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _calcRow('الدخل الخاضع', _calcResult!['taxable_income']),
                        _calcRow('الضريبة السنوية', _calcResult!['annual_tax']),
                        _calcRow('الضريبة الشهرية', _calcResult!['monthly_tax'], bold: true),
                      ],
                    ),
                  ),
                ],
              ]),
            ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('$value EGP',
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: bold ? kTaxColor : Colors.black87,
              )),
        ],
      ),
    );
  }
}
