import 'package:flutter/material.dart';
import '../../../services/insurance_policy_service.dart';
import '../../../services/lookups_service.dart';

const Color kInsCreateColor = Color(0xFF00C688);

class CreateEditInsurancePolicyScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateEditInsurancePolicyScreen({super.key, this.existing});

  @override
  State<CreateEditInsurancePolicyScreen> createState() => _CreateEditInsurancePolicyScreenState();
}

class _CreateEditInsurancePolicyScreenState extends State<CreateEditInsurancePolicyScreen> {
  // Controllers
  final _nameArCtrl     = TextEditingController();
  final _nameEnCtrl     = TextEditingController();
  final _companyValCtrl = TextEditingController(text: '0');
  final _employeeValCtrl= TextEditingController(text: '0');
  final _minSalaryCtrl  = TextEditingController();
  final _maxSalaryCtrl  = TextEditingController();
  final _startDateCtrl  = TextEditingController();
  final _endDateCtrl    = TextEditingController();
  final _changeReasonCtrl = TextEditingController();
  final _empSearchCtrl  = TextEditingController();

  // State
  String _insuranceType    = 'social';
  String _companyShareType = 'percent';
  String _employeeShareType= 'percent';
  String _calculationBase  = 'basic';
  String _scope            = 'company';
  bool   _isActive         = true;
  bool   _saving           = false;
  bool   _loading          = false;

  // Lookups
  List<dynamic> _branches    = [];
  List<dynamic> _departments = [];
  List<dynamic> _employees   = [];
  int?   _selectedBranch;
  int?   _selectedDepartment;
  List<int> _selectedEmployees = [];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _startDateCtrl.text = DateTime.now().toIso8601String().split('T').first;
    _loadLookups();
    if (_isEdit) {
      final p = widget.existing!;
      _nameArCtrl.text      = p['name_ar'] ?? p['name'] ?? '';
      _nameEnCtrl.text      = p['name_en'] ?? '';
      _insuranceType        = p['insurance_type'] ?? 'social';
      _companyShareType     = p['company_share_type'] ?? 'percent';
      _employeeShareType    = p['employee_share_type'] ?? 'percent';
      _companyValCtrl.text  = (p['company_share_value'] ?? 0).toString();
      _employeeValCtrl.text = (p['employee_share_value'] ?? 0).toString();
      _calculationBase      = p['calculation_base'] ?? 'basic';
      _minSalaryCtrl.text   = p['min_insured_salary']?.toString() ?? '';
      _maxSalaryCtrl.text   = p['max_insured_salary']?.toString() ?? '';
      _scope                = p['scope'] ?? 'company';
      _isActive             = p['is_active'] ?? true;
      _startDateCtrl.text   = p['start_date'] ?? '';
      _endDateCtrl.text     = p['end_date'] ?? '';
      _selectedBranch       = p['branch_id'];
      _selectedDepartment   = p['department_id'];
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
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _companyValCtrl.dispose();
    _employeeValCtrl.dispose();
    _minSalaryCtrl.dispose();
    _maxSalaryCtrl.dispose();
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
    if (picked != null) {
      setState(() => ctrl.text = picked.toIso8601String().split('T').first);
    }
  }

  Future<void> _save() async {
    if (_nameArCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الاسم بالعربي مطلوب')),
      );
      return;
    }
    if (_startDateCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تاريخ البدء مطلوب')),
      );
      return;
    }
    if (_scope == 'branch' && _selectedBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الفرع')),
      );
      return;
    }
    if (_scope == 'department' && _selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر الإدارة')),
      );
      return;
    }
    if (_scope == 'employees' && _selectedEmployees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر موظف واحد على الأقل')),
      );
      return;
    }

    setState(() => _saving = true);

    final data = {
      'insurance_type'      : _insuranceType,
      'name_ar'             : _nameArCtrl.text.trim(),
      'name_en'             : _nameEnCtrl.text.trim(),
      'company_share_type'  : _companyShareType,
      'company_share_value' : double.tryParse(_companyValCtrl.text) ?? 0,
      'employee_share_type' : _employeeShareType,
      'employee_share_value': double.tryParse(_employeeValCtrl.text) ?? 0,
      'calculation_base'    : _calculationBase,
      'min_insured_salary'  : _minSalaryCtrl.text.isEmpty ? null : double.tryParse(_minSalaryCtrl.text),
      'max_insured_salary'  : _maxSalaryCtrl.text.isEmpty ? null : double.tryParse(_maxSalaryCtrl.text),
      'scope'               : _scope,
      'branch_id'           : _scope == 'branch'     ? _selectedBranch     : null,
      'department_id'       : _scope == 'department' ? _selectedDepartment : null,
      'specific_employees'  : _scope == 'employees'  ? _selectedEmployees  : [],
      'is_active'           : _isActive,
      'start_date'          : _startDateCtrl.text,
      'end_date'            : _endDateCtrl.text.isEmpty ? null : _endDateCtrl.text,
      'change_reason'       : _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await InsurancePolicyService.updatePolicy(widget.existing!['id'], data);
      } else {
        await InsurancePolicyService.createPolicy(data);
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
    final isSocial   = _insuranceType == 'social';
    final typeColor  = isSocial ? const Color(0xFF1A0A3E) : const Color(0xFF388E3C);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(_isEdit ? 'تعديل سياسة تأمين' : 'إنشاء سياسة تأمين'),
          backgroundColor: kInsCreateColor,
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

                    // ═══ نوع التأمين ═══
                    _sectionCard('نوع التأمين *', [
                      Row(children: [
                        Expanded(child: _typeCard(
                          label: 'تأمين اجتماعي',
                          icon: Icons.shield,
                          color: const Color(0xFF1A0A3E),
                          selected: _insuranceType == 'social',
                          onTap: _isEdit ? null : () => setState(() => _insuranceType = 'social'),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _typeCard(
                          label: 'تأمين طبي',
                          icon: Icons.medical_services,
                          color: const Color(0xFF388E3C),
                          selected: _insuranceType == 'medical',
                          onTap: _isEdit ? null : () => setState(() => _insuranceType = 'medical'),
                        )),
                      ]),
                      if (_isEdit)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('لا يمكن تغيير نوع التأمين بعد الإنشاء',
                              style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ الأسماء ═══
                    _sectionCard('الاسم', [
                      _textField(_nameArCtrl, 'الاسم بالعربي *'),
                      const SizedBox(height: 10),
                      _textField(_nameEnCtrl, 'الاسم بالإنجليزي', hint: 'Basic Social Insurance'),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ حصة الشركة ═══
                    _shareCard(
                      title: 'حصة الشركة',
                      icon: Icons.business,
                      color: typeColor,
                      ctrl: _companyValCtrl,
                      shareType: _companyShareType,
                      onTypeChanged: (v) => setState(() => _companyShareType = v),
                    ),
                    const SizedBox(height: 14),

                    // ═══ حصة الموظف ═══
                    _shareCard(
                      title: 'حصة الموظف',
                      icon: Icons.person,
                      color: typeColor,
                      ctrl: _employeeValCtrl,
                      shareType: _employeeShareType,
                      onTypeChanged: (v) => setState(() => _employeeShareType = v),
                    ),
                    const SizedBox(height: 14),

                    // ═══ أساس الحساب ═══
                    _sectionCard('أساس حساب التأمين *', [
                      _radioOption(
                        value: 'basic',
                        group: _calculationBase,
                        label: 'الراتب الأساسي فقط',
                        desc: 'يُستخدم basic_salary الخاص بالموظف',
                        onChanged: (v) => setState(() => _calculationBase = v),
                      ),
                      _radioOption(
                        value: 'gross',
                        group: _calculationBase,
                        label: 'الراتب الإجمالي (أساسي + بدلات)',
                        desc: 'مستقبلي - حالياً يستخدم basic',
                        onChanged: (v) => setState(() => _calculationBase = v),
                      ),
                      _radioOption(
                        value: 'employee_custom',
                        group: _calculationBase,
                        label: 'المرتب التأميني الخاص بالموظف',
                        desc: 'يستخدم insurance_base_salary لكل موظف',
                        onChanged: (v) => setState(() => _calculationBase = v),
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ حدود المرتب (للاجتماعي فقط) ═══
                    if (isSocial) ...[
                      _sectionCard('حدود المرتب المؤمّن عليه (اختياري)', [
                        Row(children: [
                          Expanded(child: _textField(_minSalaryCtrl, 'الحد الأدنى (EGP)', isNumber: true, hint: 'مثلا: 1400')),
                          const SizedBox(width: 10),
                          Expanded(child: _textField(_maxSalaryCtrl, 'الحد الأقصى (EGP)', isNumber: true, hint: 'مثلا: 12600')),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          'لو راتب الموظف خارج النطاق، الحساب هيتم على الحد الأدنى/الأقصى.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ]),
                      const SizedBox(height: 14),
                    ],

                    // ═══ نطاق التطبيق ═══
                    _sectionCard('نطاق التطبيق *', [
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 3.5,
                        children: [
                          _scopeCard('company',   'الشركة كلها',    Icons.business,   typeColor),
                          _scopeCard('branch',    'فرع محدد',       Icons.layers,     typeColor),
                          _scopeCard('department','إدارة محددة',    Icons.people,     typeColor),
                          _scopeCard('employees', 'موظفين محددين',  Icons.person_pin, typeColor),
                        ],
                      ),
                      // Scope details
                      if (_scope == 'branch') ...[
                        const SizedBox(height: 10),
                        const Text('الفرع', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedBranch,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          hint: const Text('— اختر —'),
                          items: _branches.map<DropdownMenuItem<int>>((b) => DropdownMenuItem(
                            value: b['id'] as int,
                            child: Text(b['name_ar'] ?? b['name_en'] ?? ''),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedBranch = v),
                        ),
                      ],
                      if (_scope == 'department') ...[
                        const SizedBox(height: 10),
                        const Text('الإدارة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<int>(
                          initialValue: _selectedDepartment,
                          decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                          hint: const Text('— اختر —'),
                          items: _departments.map<DropdownMenuItem<int>>((d) => DropdownMenuItem(
                            value: d['id'] as int,
                            child: Text(d['name_ar'] ?? d['name_en'] ?? ''),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedDepartment = v),
                        ),
                      ],
                      if (_scope == 'employees') ...[
                        const SizedBox(height: 10),
                        Text(
                          'الموظفين المحددين (${_selectedEmployees.length})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
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

                    // ═══ نشط ═══
                    _sectionCard('الحالة', [
                      Row(children: [
                        const Expanded(child: Text('السياسة نشطة', style: TextStyle(fontSize: 14))),
                        Switch(
                          value: _isActive,
                          activeThumbColor: kInsCreateColor,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ]),
                    ]),
                    const SizedBox(height: 14),

                    // ═══ سبب التغيير ═══
                    _sectionCard('سبب التغيير', [
                      _textField(_changeReasonCtrl, 'مثال: قرار وزاري رقم 12/2026',
                          hint: 'مطلوب لو هتعدل النسب'),
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
                          _saving ? 'جاري الحفظ...' : (_isEdit ? 'حفظ التعديلات' : 'إنشاء السياسة'),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kInsCreateColor,
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
  // Helpers
  // ════════════════════════════════════════════

  List<dynamic> get _filteredEmployees {
    final q = _empSearchCtrl.text.toLowerCase().trim();
    if (q.isEmpty) return _employees;
    return _employees.where((e) {
      final name = (e['full_name'] ?? '${e['first_name_ar'] ?? ''} ${e['last_name_ar'] ?? ''}').toLowerCase();
      final code = (e['employee_code'] ?? '').toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kInsCreateColor)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String label,
      {bool isNumber = false, String? hint}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  Widget _typeCard({
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ]),
      ),
    );
  }

  Widget _shareCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController ctrl,
    required String shareType,
    required ValueChanged<String> onTypeChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: shareType == 'percent' ? 'النسبة (%)' : 'المبلغ (EGP)',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixText: shareType == 'percent' ? '%' : 'EGP',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              _typeBtn('%', shareType == 'percent', color, () => onTypeChanged('percent')),
              _typeBtn('ثابت', shareType == 'fixed', color, () => onTypeChanged('fixed')),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _typeBtn(String label, bool selected, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _radioOption({
    required String value,
    required String group,
    required String label,
    required String desc,
    required ValueChanged<String> onChanged,
  }) {
    final selected = value == group;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF8E1) : Colors.white,
          border: Border.all(color: selected ? Colors.amber.shade600 : Colors.grey.shade300, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: kInsCreateColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ])),
        ]),
      ),
    );
  }

  Widget _scopeCard(String value, String label, IconData icon, Color color) {
    final selected = _scope == value;
    return GestureDetector(
      onTap: () => setState(() => _scope = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
        ]),
      ),
    );
  }
}
