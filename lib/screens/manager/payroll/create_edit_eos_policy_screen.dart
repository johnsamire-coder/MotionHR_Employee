import 'package:flutter/material.dart';
import '../../../services/eos_policy_service.dart';

const Color kEosCreateColor = Color(0xFFF57C00);

class CreateEditEosPolicyScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateEditEosPolicyScreen({super.key, this.existing});

  @override
  State<CreateEditEosPolicyScreen> createState() => _CreateEditEosPolicyScreenState();
}

class _CreateEditEosPolicyScreenState extends State<CreateEditEosPolicyScreen> {
  final _nameCtrl = TextEditingController();
  final _minMonthsCtrl = TextEditingController(text: '12');
  final _changeReasonCtrl = TextEditingController();

  String _salaryBaseType = 'last_basic';
  bool _includeAllowances = false;
  List<Map<String, dynamic>> _tiers = [];
  Map<String, double> _reasons = {};
  bool _saving = false;

  // Calculator
  final _calcYearsCtrl = TextEditingController(text: '7');
  final _calcSalaryCtrl = TextEditingController(text: '10000');
  String _calcReason = 'termination';
  Map<String, dynamic>? _calcResult;
  bool _calculating = false;
  bool _showCalc = false;

  bool get _isEdit => widget.existing != null;

  final List<Map<String, String>> _reasonsList = [
    {'code': 'resignation',      'ar': 'استقالة',            'en': 'Resignation'},
    {'code': 'termination',      'ar': 'إنهاء من الشركة',    'en': 'Termination'},
    {'code': 'death',            'ar': 'وفاة',               'en': 'Death'},
    {'code': 'disability',       'ar': 'عجز',                'en': 'Disability'},
    {'code': 'retirement',       'ar': 'تقاعد',              'en': 'Retirement'},
    {'code': 'mutual_agreement', 'ar': 'اتفاق مشترك',        'en': 'Mutual'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text = p['name'] ?? '';
      _salaryBaseType = p['salary_base_type'] ?? 'last_basic';
      _includeAllowances = p['include_allowances'] ?? false;
      _minMonthsCtrl.text = (p['min_service_months'] ?? 12).toString();
      final t = p['service_tiers'] as List?;
      if (t != null) {
        _tiers = t.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      final r = p['termination_adjustments'] as Map?;
      if (r != null) {
        r.forEach((k, v) => _reasons[k.toString()] = (v as num).toDouble());
      } else {
        _initDefaultReasons();
      }
    } else {
      _nameCtrl.text = 'سياسة مكافأة نهاية الخدمة';
      _tiers = [
        {'from_year': 1, 'to_year': 5,  'months_per_year': 1.0},
        {'from_year': 5, 'to_year': 10, 'months_per_year': 1.5},
        {'from_year': 10, 'to_year': null, 'months_per_year': 2.0},
      ];
      _initDefaultReasons();
    }
  }

  void _initDefaultReasons() {
    _reasons = {
      'resignation':      50,
      'termination':      100,
      'death':            100,
      'disability':       100,
      'retirement':       100,
      'mutual_agreement': 75,
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minMonthsCtrl.dispose();
    _changeReasonCtrl.dispose();
    _calcYearsCtrl.dispose();
    _calcSalaryCtrl.dispose();
    super.dispose();
  }

  void _addTier() {
    final last = _tiers.isNotEmpty ? _tiers.last : null;
    final newFrom = last != null ? ((last['to_year'] ?? last['from_year'] ?? 0) as num).toInt() : 1;
    setState(() {
      _tiers.add({'from_year': newFrom, 'to_year': null, 'months_per_year': 1.0});
    });
  }

  void _removeTier(int i) {
    if (_tiers.length <= 1) return;
    setState(() => _tiers.removeAt(i));
  }

  void _updateTier(int i, String field, dynamic value) {
    setState(() {
      _tiers[i][field] = value;
    });
  }

  Future<void> _runCalculation() async {
    setState(() {
      _calculating = true;
      _calcResult = null;
    });
    try {
      final years = double.tryParse(_calcYearsCtrl.text) ?? 0;
      final salary = double.tryParse(_calcSalaryCtrl.text) ?? 0;
      final result = await EosPolicyService.calculate(
        yearsOfService: years,
        monthlySalary: salary,
        terminationReason: _calcReason,
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

    setState(() => _saving = true);

    final data = {
      'name':                    _nameCtrl.text.trim(),
      'salary_base_type':        _salaryBaseType,
      'include_allowances':      _includeAllowances,
      'min_service_months':      int.tryParse(_minMonthsCtrl.text) ?? 12,
      'service_tiers':           _tiers,
      'termination_adjustments': _reasons,
      'change_reason':           _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await EosPolicyService.updatePolicy(widget.existing!['id'], data);
      } else {
        await EosPolicyService.createPolicy(data);
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
          title: Text(_isEdit ? 'تعديل سياسة نهاية الخدمة' : 'إنشاء سياسة نهاية الخدمة'),
          backgroundColor: kEosCreateColor,
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
              _sectionCard('المعلومات الأساسية', [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'اسم السياسة *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _salaryBaseType,
                  decoration: const InputDecoration(
                    labelText: 'أساس حساب المرتب',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'last_basic',    child: Text('آخر راتب أساسي')),
                    DropdownMenuItem(value: 'last_gross',    child: Text('آخر راتب إجمالي')),
                    DropdownMenuItem(value: 'avg_3_months',  child: Text('متوسط آخر 3 شهور')),
                    DropdownMenuItem(value: 'avg_12_months', child: Text('متوسط آخر 12 شهر')),
                  ],
                  onChanged: (v) => setState(() => _salaryBaseType = v ?? 'last_basic'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _minMonthsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'الحد الأدنى لسنوات الخدمة (شهور)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('تشمل البدلات في أساس الحساب'),
                  value: _includeAllowances,
                  activeThumbColor: kEosCreateColor,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _includeAllowances = v),
                ),
              ]),
              const SizedBox(height: 14),
              _tiersCard(isAr),
              const SizedBox(height: 14),
              _reasonsCard(isAr),
              const SizedBox(height: 14),
              _calculatorCard(isAr),
              const SizedBox(height: 14),
              _sectionCard('سبب التغيير', [
                TextField(
                  controller: _changeReasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'مثال: تحديث 2025',
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
                    _saving ? 'جاري الحفظ...' : (_isEdit ? 'حفظ التعديلات' : 'إنشاء'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kEosCreateColor,
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
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kEosCreateColor)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _tiersCard(bool isAr) {
    return _sectionCard('شرائح المكافأة (بالسنوات)', [
      ..._tiers.asMap().entries.map((entry) {
        final i = entry.key;
        final t = entry.value;
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
                initialValue: (t['from_year'] ?? 0).toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'من (سنة)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _updateTier(i, 'from_year', int.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextFormField(
                initialValue: t['to_year']?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'لحد (فارغ=لا نهاية)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _updateTier(i, 'to_year', v.isEmpty ? null : int.tryParse(v)),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 75,
              child: TextFormField(
                initialValue: (t['months_per_year'] ?? 0).toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'شهر/سنة',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _updateTier(i, 'months_per_year', double.tryParse(v) ?? 0),
              ),
            ),
            IconButton(
              onPressed: () => _removeTier(i),
              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
              padding: EdgeInsets.zero,
            ),
          ]),
        );
      }),
      const SizedBox(height: 4),
      OutlinedButton.icon(
        onPressed: _addTier,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('إضافة شريحة'),
        style: OutlinedButton.styleFrom(foregroundColor: kEosCreateColor),
      ),
    ]);
  }

  Widget _reasonsCard(bool isAr) {
    return _sectionCard('نسبة الاستحقاق حسب سبب الإنهاء', [
      ..._reasonsList.map((r) {
        final code = r['code']!;
        final label = isAr ? r['ar']! : r['en']!;
        final val = _reasons[code] ?? 100;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: val.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  suffixText: '%',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() {
                  _reasons[code] = double.tryParse(v) ?? 100;
                }),
              ),
            ),
          ]),
        );
      }),
    ]);
  }

  Widget _calculatorCard(bool isAr) {
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
                const Icon(Icons.calculate, color: kEosCreateColor, size: 20),
                const SizedBox(width: 8),
                const Text('حاسبة نهاية الخدمة',
                    style: TextStyle(fontWeight: FontWeight.bold, color: kEosCreateColor)),
                const Spacer(),
                Icon(_showCalc ? Icons.expand_less : Icons.expand_more, color: kEosCreateColor),
              ]),
            ),
          ),
          if (_showCalc)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _calcYearsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'سنوات الخدمة',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _calcSalaryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'المرتب',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _calcReason,
                  decoration: const InputDecoration(
                    labelText: 'سبب الإنهاء',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: _reasonsList.map((r) => DropdownMenuItem(
                    value: r['code'],
                    child: Text(isAr ? r['ar']! : r['en']!),
                  )).toList(),
                  onChanged: (v) => setState(() => _calcReason = v ?? 'termination'),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _calculating ? null : _runCalculation,
                    icon: _calculating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.calculate, size: 18),
                    label: const Text('احسب'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kEosCreateColor, foregroundColor: Colors.white),
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
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _calcRow('الشهور المستحقة', _calcResult!['total_months_earned']),
                      _calcRow('المكافأة الإجمالية', _calcResult!['gross_benefit']),
                      _calcRow('المكافأة النهائية', _calcResult!['final_benefit'], bold: true),
                    ]),
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
          Text(label,
              style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text('$value EGP',
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: bold ? kEosCreateColor : Colors.black87,
              )),
        ],
      ),
    );
  }
}
