import 'package:flutter/material.dart';
import '../../../services/bonus_rule_service.dart';
import '../../../services/lookups_service.dart';

const Color kBonusColor = Color(0xFF2E7D32);

class CreateEditBonusRuleScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateEditBonusRuleScreen({super.key, this.existing});

  @override
  State<CreateEditBonusRuleScreen> createState() => _CreateEditBonusRuleScreenState();
}

class _CreateEditBonusRuleScreenState extends State<CreateEditBonusRuleScreen> {
  final _nameCtrl         = TextEditingController();
  final _maxPerDayCtrl    = TextEditingController(text: '4');
  final _maxPerMonthCtrl  = TextEditingController(text: '60');
  final _startDateCtrl    = TextEditingController();
  final _endDateCtrl      = TextEditingController();
  final _changeReasonCtrl = TextEditingController();
  final _empSearchCtrl    = TextEditingController();

  String _bonusType        = 'overtime';
  String _scope            = 'company';
  bool   _requiresApproval = false;
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

  static const _bonusTypes = [
    {'value': 'overtime',     'label': 'الأوفرتايم',        'unit': 'ساعة'},
    {'value': 'night_shift',  'label': 'الشيفت الليلي',    'unit': 'ساعة'},
    {'value': 'weekend_work', 'label': 'العمل في الويكند', 'unit': 'يوم'},
    {'value': 'holiday_work', 'label': 'العمل في الأعياد', 'unit': 'يوم'},
  ];

  static const _valueTypes = [
    {'value': 'multiplier',     'label': 'معامل من الأجر (×)', 'suffix': '×'},
    {'value': 'fixed_per_unit', 'label': 'مبلغ ثابت لكل وحدة', 'suffix': 'EGP'},
    {'value': 'fixed_total',    'label': 'مبلغ ثابت إجمالي',   'suffix': 'EGP'},
    {'value': 'percent_basic',  'label': '% من الراتب الأساسي','suffix': '%'},
  ];

  String get _currentUnit => _bonusTypes.firstWhere(
    (t) => t['value'] == _bonusType,
    orElse: () => _bonusTypes[0],
  )['unit']!;

  @override
  void initState() {
    super.initState();
    _startDateCtrl.text = DateTime.now().toIso8601String().split('T').first;
    _tiers = [{'from': 1, 'to': 2, 'value_type': 'multiplier', 'value': 1.5}];
    _loadLookups();
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text       = p['name'] ?? '';
      _bonusType           = p['bonus_type'] ?? 'overtime';
      _maxPerDayCtrl.text  = (p['max_per_day'] ?? 4).toString();
      _maxPerMonthCtrl.text= (p['max_per_month'] ?? 60).toString();
      _requiresApproval    = p['requires_approval'] ?? false;
      _scope               = p['scope'] ?? 'company';
      _isActive            = p['is_active'] ?? true;
      _startDateCtrl.text  = p['start_date'] ?? '';
      _endDateCtrl.text    = p['end_date'] ?? '';
      _selectedBranch      = p['branch_id'];
      _selectedDepartment  = p['department_id'];
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
    _maxPerDayCtrl.dispose();
    _maxPerMonthCtrl.dispose();
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
    final newFrom = last != null ? ((last['to'] ?? last['from'] ?? 0) as num).toDouble() + 0.5 : 1.0;
    setState(() {
      _tiers.add({'from': newFrom, 'to': newFrom + 1, 'value_type': 'multiplier', 'value': 2.0});
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
    if (_tiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لازم شريحة واحدة على الأقل')));
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
      'name'              : _nameCtrl.text.trim(),
      'bonus_type'        : _bonusType,
      'tiers'             : _tiers,
      'max_per_day'       : double.tryParse(_maxPerDayCtrl.text) ?? 0,
      'max_per_month'     : double.tryParse(_maxPerMonthCtrl.text) ?? 0,
      'requires_approval' : _requiresApproval,
      'scope'             : _scope,
      'branch_id'         : _scope == 'branch'     ? _selectedBranch     : null,
      'department_id'     : _scope == 'department' ? _selectedDepartment : null,
      'specific_employees': _scope == 'employees'  ? _selectedEmployees  : [],
      'is_active'         : _isActive,
      'start_date'        : _startDateCtrl.text,
      'end_date'          : _endDateCtrl.text.isEmpty ? null : _endDateCtrl.text,
      'change_reason'     : _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await BonusRuleService.updateRule(widget.existing!['id'], data);
      } else {
        await BonusRuleService.createRule(data);
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
          title: Text(_isEdit ? 'تعديل قاعدة مكافأة' : 'إنشاء قاعدة مكافأة'),
          backgroundColor: kBonusColor,
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
                          labelText: 'مثال: أوفرتايم عادي',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ نوع المكافأة ═══
                    _sectionCard('نوع المكافأة *', [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3,
                        children: _bonusTypes.map((t) {
                          final selected = _bonusType == t['value'];
                          return GestureDetector(
                            onTap: _isEdit ? null : () => setState(() => _bonusType = t['value']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? kBonusColor.withValues(alpha: 0.08) : Colors.white,
                                border: Border.all(
                                  color: selected ? kBonusColor : Colors.grey.shade300,
                                  width: selected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? kBonusColor : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_isEdit)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('لا يمكن تغيير نوع المكافأة بعد الإنشاء',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ الشرائح ═══
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kBonusColor.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.trending_up, color: kBonusColor, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('الشرائح التصاعدية',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kBonusColor)),
                          ),
                          OutlinedButton.icon(
                            onPressed: _addTier,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('إضافة شريحة', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kBonusColor,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        ..._tiers.asMap().entries.map((entry) {
                          final i      = entry.key;
                          final t      = entry.value;
                          final vtVal  = t['value_type'] ?? 'multiplier';
                          final vtDef  = _valueTypes.firstWhere(
                            (v) => v['value'] == vtVal,
                            orElse: () => _valueTypes[0],
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text('الشريحة ${i + 1}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kBonusColor)),
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
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'من ($_currentUnit)',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => _updateTier(i, 'from', double.tryParse(v) ?? 0),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: t['to']?.toString() ?? '',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'إلى (فارغ=بلا حد)',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (v) => _updateTier(i, 'to', v.isEmpty ? null : double.tryParse(v)),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: vtVal,
                                    decoration: const InputDecoration(
                                      labelText: 'نوع القيمة',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _valueTypes.map((v) => DropdownMenuItem(
                                      value: v['value'] as String,
                                      child: Text(v['label'] as String, style: const TextStyle(fontSize: 12)),
                                    )).toList(),
                                    onChanged: (v) => _updateTier(i, 'value_type', v),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 100,
                                  child: TextFormField(
                                    initialValue: (t['value'] ?? 0).toString(),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'القيمة',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      suffixText: vtDef['suffix'] as String,
                                    ),
                                    onChanged: (v) => _updateTier(i, 'value', double.tryParse(v) ?? 0),
                                  ),
                                ),
                              ]),
                            ]),
                          );
                        }),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ═══ الحدود القصوى ═══
                    _sectionCard('الحدود القصوى', [
                      Row(children: [
                        Expanded(child: _numField(_maxPerDayCtrl, 'أقصى ساعات/يوم (0=بدون حد)')),
                        const SizedBox(width: 10),
                        Expanded(child: _numField(_maxPerMonthCtrl, 'أقصى ساعات/شهر (0=بدون حد)')),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Expanded(child: Text('يحتاج موافقة مسبقة', style: TextStyle(fontSize: 14))),
                        Switch(
                          value: _requiresApproval,
                          activeThumbColor: kBonusColor,
                          onChanged: (v) => setState(() => _requiresApproval = v),
                        ),
                      ]),
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
                          activeThumbColor: kBonusColor,
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
                          labelText: 'مثال: تحديث معامل الأوفرتايم 2025',
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
                          backgroundColor: kBonusColor,
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kBonusColor)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
}
