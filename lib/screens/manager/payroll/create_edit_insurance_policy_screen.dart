import 'package:flutter/material.dart';
import '../../../services/insurance_policy_service.dart';

const Color kInsCreateColor = Color(0xFF00838F);

class CreateEditInsurancePolicyScreen extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const CreateEditInsurancePolicyScreen({super.key, this.existing});

  @override
  State<CreateEditInsurancePolicyScreen> createState() => _CreateEditInsurancePolicyScreenState();
}

class _CreateEditInsurancePolicyScreenState extends State<CreateEditInsurancePolicyScreen> {
  final _nameCtrl = TextEditingController();
  final _companyShareCtrl = TextEditingController(text: '0');
  final _employeeShareCtrl = TextEditingController(text: '0');
  final _minSalaryCtrl = TextEditingController(text: '0');
  final _maxSalaryCtrl = TextEditingController(text: '0');
  final _changeReasonCtrl = TextEditingController();

  String _insuranceType = 'social';
  String _companyShareType = 'percent';
  String _employeeShareType = 'percent';
  String _calculationBase = 'basic';
  String _scope = 'company';
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.existing!;
      _nameCtrl.text = p['name'] ?? '';
      _insuranceType = p['insurance_type'] ?? 'social';
      _companyShareType = p['company_share_type'] ?? 'percent';
      _employeeShareType = p['employee_share_type'] ?? 'percent';
      _calculationBase = p['calculation_base'] ?? 'basic';
      _scope = p['scope'] ?? 'company';
      _companyShareCtrl.text = (p['company_share'] ?? 0).toString();
      _employeeShareCtrl.text = (p['employee_share'] ?? 0).toString();
      _minSalaryCtrl.text = (p['min_salary'] ?? 0).toString();
      _maxSalaryCtrl.text = (p['max_salary'] ?? 0).toString();
    } else {
      _nameCtrl.text = '????? ???????';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyShareCtrl.dispose();
    _employeeShareCtrl.dispose();
    _minSalaryCtrl.dispose();
    _maxSalaryCtrl.dispose();
    _changeReasonCtrl.dispose();
    super.dispose();
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
      'insurance_type': _insuranceType,
      'company_share': double.tryParse(_companyShareCtrl.text) ?? 0,
      'company_share_type': _companyShareType,
      'employee_share': double.tryParse(_employeeShareCtrl.text) ?? 0,
      'employee_share_type': _employeeShareType,
      'calculation_base': _calculationBase,
      'min_salary': double.tryParse(_minSalaryCtrl.text) ?? 0,
      'max_salary': double.tryParse(_maxSalaryCtrl.text) ?? 0,
      'scope': _scope,
      'is_active': true,
      'start_date': DateTime.now().toIso8601String().split('T').first,
      'change_reason': _changeReasonCtrl.text.trim(),
    };

    try {
      if (_isEdit) {
        await InsurancePolicyService.updatePolicy(widget.existing!['id'], data);
      } else {
        await InsurancePolicyService.createPolicy(data);
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
    final typeColor = _insuranceType == 'social' ? const Color(0xFF1976D2) : const Color(0xFF388E3C);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(_isEdit
              ? (isAr ? '????? ????? ?????' : 'Edit Insurance')
              : (isAr ? '????? ????? ?????' : 'Create Insurance')),
          backgroundColor: kInsCreateColor,
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
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? '??? ??????? *' : 'Policy Name *',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _insuranceType,
                  decoration: InputDecoration(
                    labelText: isAr ? '??? ???????' : 'Insurance Type',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    DropdownMenuItem(value: 'social', child: Row(children: [
                      Icon(Icons.shield, color: const Color(0xFF1976D2), size: 18),
                      const SizedBox(width: 8),
                      Text(isAr ? '????? ???????' : 'Social Insurance'),
                    ])),
                    DropdownMenuItem(value: 'medical', child: Row(children: [
                      Icon(Icons.medical_services, color: const Color(0xFF388E3C), size: 18),
                      const SizedBox(width: 8),
                      Text(isAr ? '????? ???' : 'Medical Insurance'),
                    ])),
                  ],
                  onChanged: (v) => setState(() => _insuranceType = v ?? 'social'),
                ),
              ]),
              const SizedBox(height: 14),
              _shareCard(
                isAr ? '??? ??????' : 'Company Share',
                _companyShareCtrl,
                _companyShareType,
                (v) => setState(() => _companyShareType = v),
                isAr,
                typeColor,
              ),
              const SizedBox(height: 14),
              _shareCard(
                isAr ? '??? ??????' : 'Employee Share',
                _employeeShareCtrl,
                _employeeShareType,
                (v) => setState(() => _employeeShareType = v),
                isAr,
                typeColor,
              ),
              const SizedBox(height: 14),
              _sectionCard(isAr ? '???? ??????' : 'Calculation Base', [
                DropdownButtonFormField<String>(
                  initialValue: _calculationBase,
                  decoration: InputDecoration(
                    labelText: isAr ? '???? ??????' : 'Base',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    DropdownMenuItem(value: 'basic', child: Text(isAr ? '???????' : 'Basic Salary')),
                    DropdownMenuItem(value: 'gross', child: Text(isAr ? '????????' : 'Gross Salary')),
                    DropdownMenuItem(value: 'employee_custom', child: Text(isAr ? '???? ??? ????' : 'Employee Custom')),
                  ],
                  onChanged: (v) => setState(() => _calculationBase = v ?? 'basic'),
                ),
              ]),
              const SizedBox(height: 14),
              _sectionCard(isAr ? '??? ?????? ??????? ????' : 'Salary Cap', [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minSalaryCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? '???? ??????' : 'Min (EGP)',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _maxSalaryCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? '???? ??????' : 'Max (EGP)',
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isAr ? '0 = ???? ??' : '0 = no limit',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ]),
              const SizedBox(height: 14),
              _sectionCard(isAr ? '???? ???????' : 'Scope', [
                DropdownButtonFormField<String>(
                  initialValue: _scope,
                  decoration: InputDecoration(
                    labelText: isAr ? '??????' : 'Scope',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    DropdownMenuItem(value: 'company', child: Text(isAr ? '?????? ????' : 'Whole Company')),
                    DropdownMenuItem(value: 'branch', child: Text(isAr ? '??? ????' : 'Specific Branch')),
                    DropdownMenuItem(value: 'department', child: Text(isAr ? '??? ????' : 'Specific Department')),
                    DropdownMenuItem(value: 'specific_employees', child: Text(isAr ? '?????? ??????' : 'Specific Employees')),
                  ],
                  onChanged: (v) => setState(() => _scope = v ?? 'company'),
                ),
              ]),
              if (_isEdit) ...[
                const SizedBox(height: 14),
                _sectionCard(isAr ? '??? ???????' : 'Change Reason', [
                  TextField(
                    controller: _changeReasonCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? '????: ????? 2025' : 'e.g. Update 2025',
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
                        : (_isEdit ? (isAr ? '??? ?????????' : 'Save Changes') : (isAr ? '?????' : 'Create')),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kInsCreateColor,
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
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kInsCreateColor)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _shareCard(
    String title,
    TextEditingController ctrl,
    String currentType,
    ValueChanged<String> onTypeChanged,
    bool isAr,
    Color color,
  ) {
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
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? '??????' : 'Value',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    suffixText: currentType == 'percent' ? '%' : 'EGP',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _typeBtn(isAr ? '?' : '%', currentType == 'percent', color, () => onTypeChanged('percent')),
                    _typeBtn(isAr ? '????' : 'Fixed', currentType == 'fixed', color, () => onTypeChanged('fixed')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
}
