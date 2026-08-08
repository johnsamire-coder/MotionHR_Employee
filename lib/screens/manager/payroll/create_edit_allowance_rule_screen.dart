import 'package:flutter/material.dart';
import '../../../services/allowance_rule_service.dart';
import '../../../services/lookups_service.dart';

const Color kAllowanceColor = Color(0xFFE65100);

class CreateEditAllowanceRuleScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateEditAllowanceRuleScreen({super.key, this.existing});

  @override
  State<CreateEditAllowanceRuleScreen> createState() => _CreateEditAllowanceRuleScreenState();
}

class _CreateEditAllowanceRuleScreenState extends State<CreateEditAllowanceRuleScreen> {
  final _nameCtrl           = TextEditingController();
  final _fixedAmountCtrl    = TextEditingController(text: '0');
  final _minWorkHoursCtrl   = TextEditingController(text: '0');
  final _startDateCtrl      = TextEditingController();
  final _endDateCtrl        = TextEditingController();
  final _changeReasonCtrl   = TextEditingController();
  final _empSearchCtrl      = TextEditingController();

  String _allowanceType    = 'field_work';
  String _calculationType  = 'fixed_monthly';
  String _scope            = 'company';
  bool   _isActive         = true;
  bool   _saving           = false;
  bool   _loading          = false;

  List<Map<String, dynamic>> _tiers = [];
  List<dynamic> _branches    = [];
  List<dynamic> _departments = [];
  List<dynamic> _employees   = [];
  int?   _selectedBranch;
  int?   _selectedDepartment;
  List<int> _selectedEmployees = [];

  bool get _isEdit => widget.existing != null;

  static const _allowanceTypes = [
    {'value': 'field_work',     'label': 'بدل الميدان'},
    {'value': 'meals',          'label': 'بدل الوجبات'},
    {'value': 'transport',      'label': 'بدل المواصلات'},
    {'value': 'housing',        'label': 'بدل السكن'},
    {'value': 'phone',          'label': 'بدل التليفون'},
    {'value': 'clothing',       'label': 'بدل الملابس'},
    {'value': 'representation', 'label': 'بدل تمثيل'},
    {'value': 'education',      'label': 'بدل تعليم'},
    {'value': 'other',          'label': 'بدل آخر'},
  ];

  static const _calculationTypes = [
    {'value': 'fixed_monthly', 'label': 'مبلغ شهري ثابت',      'hint': 'يُصرف كامل كل شهر'},
    {'value': 'per_day',       'label': 'لكل يوم عمل',          'hint': 'يُضرب في عدد أيام العمل'},
    {'value': 'per_visit',     'label': 'لكل زيارة/عملية',      'hint': 'يُضرب في عدد الزيارات'},
    {'value': 'per_km',        'label': 'لكل كيلومتر',          'hint': 'يُضرب في عدد الكيلومترات'},
    {'value': 'tiered',        'label': 'شرائح تصاعدية',        'hint': 'حسب عدد الوحدات'},
  ];

  String get _currentCalcHint => _calculationTypes.firstWhere(
    (t) => t['value'] == _calculationType,
    orElse: () => _calculationTypes[0],
  )['hint']!;

  String get _fixedAmountLabel {
    switch (_calculationType) {
      case 'fixed_monthly': return 'المبلغ الشهري (EGP)';
      case 'per_day':       return 'المبلغ لكل يوم (EGP)';
      case 'per_visit':     return 'المبلغ لكل زيارة (EGP)';
      case 'per_km':        return 'المبلغ لكل كيلومتر (EGP)';
      default:              return 'المبلغ (EGP)';
    }
  }

  @override
  void initState() {
    super.initState();
    _startDateCtrl.text = DateTime.now().toIso8601String().split('T').first;
    _tiers = [{'from': 1, 'to': 10, 'value': 500.0}];
    _loadLookups();
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text         = p['name'] ?? '';
      _allowanceType         = p['allowance_type'] ?? 'field_work';
      _calculationType       = p['calculation_type'] ?? 'fixed_monthly';
      _fixedAmountCtrl.text  = (p['fixed_amount'] ?? 0).toString();
      _minWorkHoursCtrl.text = (p['min_work_hours_per_day'] ?? 0).toString();
      _scope                 = p['scope'] ?? 'company';
      _isActive              = p['is_active'] ?? true;
      _startDateCtrl.text    = p['start_date'] ?? '';
      _endDateCtrl.text      = p['end_date'] ?? '';
      _selectedBranch        = p['branch_id'];
      _selectedDepartment    = p['department_id'];
      final emps = p['specific_employees'];
      if (emps is List) {
        _selectedEmployees = emps.map<int>((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
      }
      final t = p['tiers'] as List?;
      if (t != null && t.isNotEmpty) {
        _tiers = t.map((e) => Map<String, dynamic>.from(e)).toList();
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
    _fixedAmountCtrl.dispose();
    _minWorkHoursCtrl.dispose();
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

  void _addTier() {
    final last = _tiers.isNotEmpty ? _tiers.last : null;
    final newFrom = last != null ? ((last['to'] ?? last['from'] ?? 0) as num).toInt() + 1 : 1;
    setState(() {
      _tiers.add({'from': newFrom, 'to': newFrom + 9, 'value': 750.0});
    });
  }

  void _removeTier(int i) {
    if (_tiers.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لازم شريحة واحدة على الأقل')),
      );
      return;
    }
    setState(() => _tiers.removeAt(i));
  }

  void _updateTier(int i, String field, dynamic value) {
    setState(() => _tiers[i][field] = value);
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
      'name'                   : _nameCtrl.text.trim(),
      'allowance_type'         : _allowanceType,
      'calculation_type'       : _calculationType,
      'fixed_amount'           : double.tryParse(_fixedAmountCtrl.text) ?? 0,
      'tiers'                  : _calculationType == 'tiered' ? _tiers : [],
      'min_work_hours_per_day' : int.tryParse(_minWorkHoursCtrl.text) ?? 0,
      'scope'                  : _scope,
      'branch_id'              : _scope == 'branch'     ? _selectedBranch     : null,
      'department_id'          : _scope == 'department' ? _selectedDepartment : null,
      'specific_employees'     : _scope == 'employees'  ? _selectedEmployees  : [],
      'is_active'              : _isActive,
      'start_date'             : _startDateCtrl.text,
      'end_date'               : _endDateCtrl.text.isEmpty ? null : _endDateCtrl.text,
      'change_reason'          : _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await AllowanceRuleService.updateRule(widget.existing!['id'], data);
      } else {
        await AllowanceRuleService.createRule(data);
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(_isEdit ? 'تعديل قاعدة بدل' : 'إنشاء قاعدة بدل'),
          backgroundColor: kAllowanceColor,
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

                    // ═══ اسم القاعدة ═══
                    _sectionCard('اسم القاعدة *', [
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'مثال: بدل الميدان الأساسي',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ نوع البدل ═══
                    _sectionCard('نوع البدل *', [
                      DropdownButtonFormField<String>(
                        initialValue: _allowanceType,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: _allowanceTypes.map((t) => DropdownMenuItem(
                          value: t['value'],
                          child: Text(t['label']!),
                        )).toList(),
                        onChanged: _isEdit ? null : (v) => setState(() => _allowanceType = v ?? _allowanceType),
                      ),
                      if (_isEdit)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('لا يمكن تغيير نوع البدل بعد الإنشاء',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ طريقة الحساب ═══
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kAllowanceColor.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('طريقة الحساب *',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kAllowanceColor)),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _calculationType,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          items: _calculationTypes.map((t) => DropdownMenuItem(
                            value: t['value'],
                            child: Text(t['label']!),
                          )).toList(),
                          onChanged: (v) => setState(() => _calculationType = v ?? _calculationType),
                        ),
                        const SizedBox(height: 6),
                        Text('💡 $_currentCalcHint',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),

                        if (_calculationType != 'tiered') ...[
                          const SizedBox(height: 10),
                          TextField(
                            controller: _fixedAmountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: _fixedAmountLabel,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ],

                        if (_calculationType == 'tiered') ...[
                          const SizedBox(height: 12),
                          Row(children: [
                            const Expanded(
                              child: Text('الشرائح',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: kAllowanceColor)),
                            ),
                            OutlinedButton.icon(
                              onPressed: _addTier,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('إضافة شريحة', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kAllowanceColor,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          ..._tiers.asMap().entries.map((entry) {
                            final i = entry.key;
                            final t = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFFCC80)),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Text('الشريحة ${i + 1}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kAllowanceColor)),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => _removeTier(i),
                                    icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: (t['from'] ?? 0).toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'من',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) => _updateTier(i, 'from', int.tryParse(v) ?? 0),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: t['to']?.toString() ?? '',
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: 'إلى (فارغ=بلا حد)',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) => _updateTier(i, 'to', v.isEmpty ? null : int.tryParse(v)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      initialValue: (t['value'] ?? 0).toString(),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'المبلغ (EGP)',
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) => _updateTier(i, 'value', double.tryParse(v) ?? 0),
                                    ),
                                  ),
                                ]),
                              ]),
                            );
                          }),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ═══ شروط الاستحقاق ═══
                    _sectionCard('شروط الاستحقاق', [
                      TextField(
                        controller: _minWorkHoursCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'أقل ساعات عمل يومياً للاستحقاق (0 = بدون شرط)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),

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
                          activeThumbColor: kAllowanceColor,
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
                          labelText: 'مثال: تحديث قيمة البدل 2025',
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
                          _saving ? 'جاري الحفظ...' : (_isEdit ? 'حفظ التعديلات' : 'إنشاء القاعدة'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAllowanceColor,
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kAllowanceColor)),
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
