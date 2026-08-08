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
  final _yearCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _singleExemptionCtrl = TextEditingController(text: '20000');
  final _marriedExemptionCtrl = TextEditingController(text: '20000');
  final _childExemptionCtrl = TextEditingController(text: '0');
  final _maxChildrenCtrl = TextEditingController(text: '3');
  final _changeReasonCtrl = TextEditingController();

  String _country = 'EG';
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
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text = p['name'] ?? '';
      _yearCtrl.text = (p['tax_year'] ?? DateTime.now().year).toString();
      _country = p['country'] ?? 'EG';
      _singleExemptionCtrl.text = (p['personal_exemption_single'] ?? 20000).toString();
      _marriedExemptionCtrl.text = (p['personal_exemption_married'] ?? 20000).toString();
      _childExemptionCtrl.text = (p['child_exemption'] ?? 0).toString();
      _maxChildrenCtrl.text = (p['max_children_exempted'] ?? 3).toString();
      _exemptSocial = p['exempt_social_insurance'] ?? true;
      _exemptMedical = p['exempt_medical_insurance'] ?? true;
      final b = p['tax_brackets'] as List?;
      if (b != null) {
        _brackets = b.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } else {
      _nameCtrl.text = '????? ?????';
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
    _changeReasonCtrl.dispose();
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
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? '??? ??????' : 'Calc failed')),
      );
    }
  }

  Future<void> _save() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? '????? ?????' : 'Name required')),
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
      'exempt_social_insurance': _exemptSocial,
      'exempt_medical_insurance': _exemptMedical,
      'calculation_method': 'monthly_progressive',
      'scope': 'company',
      'is_active': true,
      'start_date': DateTime.now().toIso8601String().split('T').first,
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

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(_isEdit
              ? (isAr ? '????? ????? ???????' : 'Edit Tax Policy')
              : (isAr ? '????? ????? ???????' : 'Create Tax Policy')),
          backgroundColor: kTaxColor,
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
              _sectionCard(isAr ? '???????? ????????' : 'Basic Info', [
                _textField(_nameCtrl, isAr ? '??? ??????? *' : 'Policy Name *'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _countryDropdown(isAr),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _textField(_yearCtrl, isAr ? '?????' : 'Year', isNumber: true),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 14),
              _bracketsCard(isAr),
              const SizedBox(height: 14),
              _exemptionsCard(isAr),
              const SizedBox(height: 14),
              _insuranceExemptionsCard(isAr),
              const SizedBox(height: 14),
              _calculatorCard(isAr),
              if (_isEdit) ...[
                const SizedBox(height: 14),
                _sectionCard(isAr ? '??? ???????' : 'Change Reason', [
                  _textField(_changeReasonCtrl,
                      isAr ? '????: ????? ??? 2025' : 'e.g. Update 2025 rates'),
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
                        : (_isEdit ? (isAr ? '??? ?????????' : 'Save Changes') : (isAr ? '?????' : 'Create')),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTaxColor,
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

  Widget _sectionCard(String title, List<Widget> children) {
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

  Widget _countryDropdown(bool isAr) {
    return DropdownButtonFormField<String>(
      value: _country,
      decoration: InputDecoration(
        labelText: isAr ? '??????' : 'Country',
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        DropdownMenuItem(value: 'EG', child: Text(isAr ? '???' : 'Egypt')),
        DropdownMenuItem(value: 'SA', child: Text(isAr ? '????????' : 'Saudi')),
        DropdownMenuItem(value: 'AE', child: Text(isAr ? '????????' : 'UAE')),
      ],
      onChanged: (v) => setState(() => _country = v ?? 'EG'),
    );
  }

  Widget _bracketsCard(bool isAr) {
    return _sectionCard(isAr ? '??????? ???????? (????)' : 'Tax Brackets (Annual)', [
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
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: (b['from'] ?? 0).toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? '??' : 'From',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => _updateBracket(i, 'from', int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextFormField(
                  initialValue: (b['to'] ?? '').toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? '??? (? ????)' : 'To (? blank)',
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => _updateBracket(i, 'to', v.isEmpty ? null : int.tryParse(v)),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 70,
                child: TextFormField(
                  initialValue: (b['rate'] ?? 0).toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '%',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _updateBracket(i, 'rate', double.tryParse(v) ?? 0),
                ),
              ),
              IconButton(
                onPressed: () => _removeBracket(i),
                icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 4),
      OutlinedButton.icon(
        onPressed: _addBracket,
        icon: const Icon(Icons.add, size: 18),
        label: Text(isAr ? '????? ?????' : 'Add Bracket'),
        style: OutlinedButton.styleFrom(foregroundColor: kTaxColor),
      ),
    ]);
  }

  Widget _exemptionsCard(bool isAr) {
    return _sectionCard(isAr ? '????????? ??????? (????)' : 'Personal Exemptions (Annual)', [
      Row(
        children: [
          Expanded(
            child: _textField(_singleExemptionCtrl, isAr ? '????? ????' : 'Single', isNumber: true),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _textField(_marriedExemptionCtrl, isAr ? '????? ?????' : 'Married', isNumber: true),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _textField(_childExemptionCtrl, isAr ? '????? ??? ???' : 'Per Child', isNumber: true),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _textField(_maxChildrenCtrl, isAr ? '???? ?????' : 'Max Children', isNumber: true),
          ),
        ],
      ),
    ]);
  }

  Widget _insuranceExemptionsCard(bool isAr) {
    return _sectionCard(isAr ? '??????? ?????????' : 'Insurance Exemptions', [
      SwitchListTile(
        title: Text(isAr ? '????? ??????? ????????? (??? ??????)' : 'Exempt social insurance'),
        value: _exemptSocial,
        activeColor: kTaxColor,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => setState(() => _exemptSocial = v),
      ),
      SwitchListTile(
        title: Text(isAr ? '????? ??????? ????? (??? ??????)' : 'Exempt medical insurance'),
        value: _exemptMedical,
        activeColor: kTaxColor,
        contentPadding: EdgeInsets.zero,
        onChanged: (v) => setState(() => _exemptMedical = v),
      ),
    ]);
  }

  Widget _calculatorCard(bool isAr) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
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
                borderRadius: BorderRadius.vertical(top: const Radius.circular(12), bottom: _showCalc ? Radius.zero : const Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calculate, color: kTaxColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? '????? ???????' : 'Tax Calculator',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: kTaxColor),
                  ),
                  const Spacer(),
                  Icon(_showCalc ? Icons.expand_less : Icons.expand_more, color: kTaxColor),
                ],
              ),
            ),
          ),
          if (_showCalc)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _textField(_calcIncomeCtrl, isAr ? '????? ??????' : 'Annual Income', isNumber: true),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _calcMarital,
                          decoration: InputDecoration(
                            labelText: isAr ? '??????' : 'Status',
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          items: [
                            DropdownMenuItem(value: 'single', child: Text(isAr ? '????' : 'Single')),
                            DropdownMenuItem(value: 'married', child: Text(isAr ? '?????' : 'Married')),
                          ],
                          onChanged: (v) => setState(() => _calcMarital = v ?? 'single'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _calculating ? null : _runCalculation,
                      icon: _calculating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.calculate, size: 18),
                      label: Text(isAr ? '????' : 'Calculate'),
                      style: ElevatedButton.styleFrom(backgroundColor: kTaxColor, foregroundColor: Colors.white),
                    ),
                  ),
                  if (_calcResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _calcRow(isAr ? '????? ??????' : 'Taxable', _calcResult!['taxable_income']),
                          _calcRow(isAr ? '??????? ???????' : 'Annual Tax', _calcResult!['annual_tax']),
                          _calcRow(isAr ? '??????? ???????' : 'Monthly Tax', _calcResult!['monthly_tax'], bold: true),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
          Text(
            '$value EGP',
            style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: bold ? kTaxColor : Colors.black87),
          ),
        ],
      ),
    );
  }
}
