import 'package:flutter/material.dart';
import '../../../services/penalty_rule_service.dart';
import '../../../services/lookups_service.dart';

const Color kPenaltyColor = Color(0xFFD32F2F);

class CreateEditPenaltyRuleScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateEditPenaltyRuleScreen({super.key, this.existing});

  @override
  State<CreateEditPenaltyRuleScreen> createState() => _CreateEditPenaltyRuleScreenState();
}

class _CreateEditPenaltyRuleScreenState extends State<CreateEditPenaltyRuleScreen> {
  final _nameCtrl         = TextEditingController();
  final _graceCtrl        = TextEditingController(text: '0');
  final _startDateCtrl    = TextEditingController();
  final _endDateCtrl      = TextEditingController();
  final _changeReasonCtrl = TextEditingController();
  final _empSearchCtrl    = TextEditingController();
  final _warn1Ctrl        = TextEditingController(text: '3');
  final _warn2Ctrl        = TextEditingController(text: '5');
  final _terminateCtrl    = TextEditingController(text: '10');

  String _penaltyType      = 'late_arrival';
  String _scope            = 'company';
  bool   _isActive         = true;
  bool   _warningsEnabled  = false;
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

  static const _penaltyTypes = [
    {'value': 'late_arrival',     'label': 'تأخير الحضور',        'unit': 'دقيقة'},
    {'value': 'absence',          'label': 'الغياب',               'unit': 'يوم'},
    {'value': 'early_leave',      'label': 'الخروج المبكر',        'unit': 'دقيقة'},
    {'value': 'missing_checkout', 'label': 'عدم تسجيل الخروج',    'unit': 'مرة'},
  ];

  static const _deductionTypes = [
    {'value': 'fixed_per_unit',   'label': 'مبلغ ثابت لكل وحدة',  'needs_value': true,  'suffix': 'EGP'},
    {'value': 'fixed_total',      'label': 'مبلغ ثابت إجمالي',    'needs_value': true,  'suffix': 'EGP'},
    {'value': 'percent_basic',    'label': '% من الراتب الأساسي', 'needs_value': true,  'suffix': '%'},
    {'value': 'quarter_day',      'label': 'ربع يوم',              'needs_value': false, 'suffix': ''},
    {'value': 'half_day',         'label': 'نصف يوم',              'needs_value': false, 'suffix': ''},
    {'value': 'full_day',         'label': 'يوم كامل',             'needs_value': false, 'suffix': ''},
    {'value': 'two_days',         'label': 'يومين',                'needs_value': false, 'suffix': ''},
    {'value': 'three_days',       'label': '3 أيام',               'needs_value': false, 'suffix': ''},
    {'value': 'day_plus_warning', 'label': 'يوم + إنذار كتابي',   'needs_value': false, 'suffix': ''},
  ];

  String get _currentUnit {
    return _penaltyTypes.firstWhere(
      (t) => t['value'] == _penaltyType,
      orElse: () => _penaltyTypes[0],
    )['unit']!;
  }

  @override
  void initState() {
    super.initState();
    _startDateCtrl.text = DateTime.now().toIso8601String().split('T').first;
    _tiers = [{'from': 1, 'to': 15, 'deduction_type': 'fixed_per_unit', 'value': 1.0}];
    _loadLookups();
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text      = p['name'] ?? '';
      _penaltyType        = p['penalty_type'] ?? 'late_arrival';
      _graceCtrl.text     = (p['grace_amount'] ?? 0).toString();
      _warningsEnabled    = p['warnings_enabled'] ?? false;
      _warn1Ctrl.text     = (p['first_warning_after'] ?? 3).toString();
      _warn2Ctrl.text     = (p['second_warning_after'] ?? 5).toString();
      _terminateCtrl.text = (p['termination_after'] ?? 10).toString();
      _scope              = p['scope'] ?? 'company';
      _isActive           = p['is_active'] ?? true;
      _startDateCtrl.text = p['start_date'] ?? '';
      _endDateCtrl.text   = p['end_date'] ?? '';
      _selectedBranch     = p['branch_id'];
      _selectedDepartment = p['department_id'];
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
    _graceCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _changeReasonCtrl.dispose();
    _empSearchCtrl.dispose();
    _warn1Ctrl.dispose();
    _warn2Ctrl.dispose();
    _terminateCtrl.dispose();
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
      _tiers.add({'from': newFrom, 'to': newFrom + 14, 'deduction_type': 'fixed_per_unit', 'value': 1.0});
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
      'name'                  : _nameCtrl.text.trim(),
      'penalty_type'          : _penaltyType,
      'grace_amount'          : int.tryParse(_graceCtrl.text) ?? 0,
      'tiers'                 : _tiers,
      'warnings_enabled'      : _warningsEnabled,
      'first_warning_after'   : int.tryParse(_warn1Ctrl.text) ?? 3,
      'second_warning_after'  : int.tryParse(_warn2Ctrl.text) ?? 5,
      'termination_after'     : int.tryParse(_terminateCtrl.text) ?? 10,
      'scope'                 : _scope,
      'branch_id'             : _scope == 'branch'     ? _selectedBranch     : null,
      'department_id'         : _scope == 'department' ? _selectedDepartment : null,
      'specific_employees'    : _scope == 'employees'  ? _selectedEmployees  : [],
      'is_active'             : _isActive,
      'start_date'            : _startDateCtrl.text,
      'end_date'              : _endDateCtrl.text.isEmpty ? null : _endDateCtrl.text,
      'change_reason'         : _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await PenaltyRuleService.updateRule(widget.existing!['id'], data);
      } else {
        await PenaltyRuleService.createRule(data);
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
          title: Text(_isEdit ? 'تعديل قاعدة جزاء' : 'إنشاء قاعدة جزاء'),
          backgroundColor: kPenaltyColor,
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
                          labelText: 'مثال: جزاء التأخير الأساسي',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ نوع الجزاء ═══
                    _sectionCard('نوع الجزاء *', [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3,
                        children: _penaltyTypes.map((t) {
                          final selected = _penaltyType == t['value'];
                          return GestureDetector(
                            onTap: _isEdit ? null : () => setState(() => _penaltyType = t['value']!),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? kPenaltyColor.withValues(alpha: 0.08) : Colors.white,
                                border: Border.all(
                                  color: selected ? kPenaltyColor : Colors.grey.shade300,
                                  width: selected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                t['label']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: selected ? kPenaltyColor : Colors.black87,
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
                          child: Text('لا يمكن تغيير نوع الجزاء بعد الإنشاء',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ فترة السماح ═══
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFEB3B)),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('فترة السماح ($_currentUnit)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _graceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('الوحدات الأولى من الجزاء لا تُحسب',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ═══ الشرائح التصاعدية ═══
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kPenaltyColor.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.trending_up, color: kPenaltyColor, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('الشرائح التصاعدية',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPenaltyColor)),
                          ),
                          OutlinedButton.icon(
                            onPressed: _addTier,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('إضافة شريحة', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPenaltyColor,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 12),
                        ..._tiers.asMap().entries.map((entry) {
                          final i   = entry.key;
                          final t   = entry.value;
                          final dtVal  = t['deduction_type'] ?? 'fixed_per_unit';
                          final dtDef  = _deductionTypes.firstWhere(
                            (d) => d['value'] == dtVal,
                            orElse: () => _deductionTypes[0],
                          );
                          final needsVal = dtDef['needs_value'] as bool;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFFCDD2)),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text('الشريحة ${i + 1}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kPenaltyColor)),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _removeTier(i),
                                  icon: const Icon(Icons.delete, color: kPenaltyColor, size: 18),
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
                                    decoration: InputDecoration(
                                      labelText: 'من ($_currentUnit)',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
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
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: dtVal,
                                    decoration: const InputDecoration(
                                      labelText: 'نوع الخصم',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: _deductionTypes.map((d) => DropdownMenuItem(
                                      value: d['value'] as String,
                                      child: Text(d['label'] as String, style: const TextStyle(fontSize: 12)),
                                    )).toList(),
                                    onChanged: (v) => _updateTier(i, 'deduction_type', v),
                                  ),
                                ),
                                if (needsVal) ...[
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 90,
                                    child: TextFormField(
                                      initialValue: (t['value'] ?? 0).toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'القيمة',
                                        isDense: true,
                                        border: const OutlineInputBorder(),
                                        suffixText: dtDef['suffix'] as String,
                                      ),
                                      onChanged: (v) => _updateTier(i, 'value', double.tryParse(v) ?? 0),
                                    ),
                                  ),
                                ],
                              ]),
                            ]),
                          );
                        }),
                      ]),
                    ),
                    const SizedBox(height: 14),

                    // ═══ الإنذارات التصاعدية ═══
                    _sectionCard('الإنذارات التصاعدية', [
                      Row(children: [
                        const Expanded(child: Text('تفعيل الإنذارات التصاعدية', style: TextStyle(fontSize: 14))),
                        Switch(
                          value: _warningsEnabled,
                          activeThumbColor: Colors.orange,
                          onChanged: (v) => setState(() => _warningsEnabled = v),
                        ),
                      ]),
                      if (_warningsEnabled) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _numberField(_warn1Ctrl, 'الإنذار 1 بعد')),
                          const SizedBox(width: 8),
                          Expanded(child: _numberField(_warn2Ctrl, 'الإنذار 2 بعد')),
                          const SizedBox(width: 8),
                          Expanded(child: _numberField(_terminateCtrl, 'الفصل بعد')),
                        ]),
                      ],
                    ]),
                    const SizedBox(height: 14),

                    // ═══ نطاق التطبيق ═══
                    _sectionCard('نطاق التطبيق *', [
                      DropdownButtonFormField<String>(
                        initialValue: _scope,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: const [
                          DropdownMenuItem(value: 'company',   child: Text('الشركة كلها')),
                          DropdownMenuItem(value: 'branch',    child: Text('فرع محدد')),
                          DropdownMenuItem(value: 'department',child: Text('إدارة محددة')),
                          DropdownMenuItem(value: 'employees', child: Text('موظفين محددين')),
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
                          activeThumbColor: kPenaltyColor,
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
                          labelText: 'مثال: تحديث نسب الجزاءات 2025',
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
                          backgroundColor: kPenaltyColor,
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kPenaltyColor)),
          const SizedBox(height: 12),
          ...children,
        ],
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
