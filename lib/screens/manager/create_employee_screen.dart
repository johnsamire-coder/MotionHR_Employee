import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/employee_management_service.dart';
import '../../services/employee_pdf_service.dart';
import 'package:open_file/open_file.dart';

const Color kManagerColor = Color(0xFF6A1B9A);
const Color kPrimaryColor = Color(0xFF1976D2);

// ── Country data ──
class _Country {
  final String code;
  final String nameAr;
  final String nameEn;
  final String dial;
  const _Country(this.code, this.nameAr, this.nameEn, this.dial);
}

const List<_Country> kCountries = [
  _Country('EG', 'مصر', 'Egypt', '+20'),
  _Country('SA', 'السعودية', 'Saudi Arabia', '+966'),
  _Country('AE', 'الإمارات', 'UAE', '+971'),
  _Country('KW', 'الكويت', 'Kuwait', '+965'),
  _Country('QA', 'قطر', 'Qatar', '+974'),
  _Country('BH', 'البحرين', 'Bahrain', '+973'),
  _Country('OM', 'عُمان', 'Oman', '+968'),
  _Country('JO', 'الأردن', 'Jordan', '+962'),
  _Country('LB', 'لبنان', 'Lebanon', '+961'),
  _Country('SD', 'السودان', 'Sudan', '+249'),
  _Country('LY', 'ليبيا', 'Libya', '+218'),
  _Country('TN', 'تونس', 'Tunisia', '+216'),
  _Country('DZ', 'الجزائر', 'Algeria', '+213'),
  _Country('MA', 'المغرب', 'Morocco', '+212'),
  _Country('GB', 'بريطانيا', 'UK', '+44'),
  _Country('US', 'أمريكا', 'USA', '+1'),
  _Country('DE', 'ألمانيا', 'Germany', '+49'),
  _Country('FR', 'فرنسا', 'France', '+33'),
  _Country('TR', 'تركيا', 'Turkey', '+90'),
  _Country('IN', 'الهند', 'India', '+91'),
  _Country('PK', 'باكستان', 'Pakistan', '+92'),
  _Country('PH', 'الفلبين', 'Philippines', '+63'),
  _Country('NG', 'نيجيريا', 'Nigeria', '+234'),
  _Country('ET', 'إثيوبيا', 'Ethiopia', '+251'),
];

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});
  @override
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Form keys
  final _fk1 = GlobalKey<FormState>();
  final _fk2 = GlobalKey<FormState>();
  final _fk3 = GlobalKey<FormState>();
  final _fk4 = GlobalKey<FormState>();

  // ── Step 1: Personal ──
  final _firstNameArCtrl = TextEditingController();
  final _middleNameArCtrl = TextEditingController();
  final _lastNameArCtrl = TextEditingController();
  final _firstNameEnCtrl = TextEditingController();
  final _lastNameEnCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'male';
  String _nationality = 'مصري';
  String _maritalStatus = 'single';
  String _religion = 'muslim';

  // ── Step 2: Contact ──
  _Country _selectedCountry = kCountries[0];
  final _phoneCtrl = TextEditingController();
  final _phone2Ctrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _emergencyRelationCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  // ── Step 3: Job ──
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _jobTitles = [];
  List<Map<String, dynamic>> _employeesSimple = [];
  int? _selectedBranchId;
  int? _selectedDepartmentId;
  int? _selectedJobTitleId;
  int? _selectedManagerId;
  DateTime? _hireDate = DateTime.now();
  String _contractType = 'permanent';
  DateTime? _contractEndDate;
  bool _hasInsurance = false;
  final _insuranceNumberCtrl = TextEditingController();
  bool _loadingLookups = true;
  String? _lookupError;

  // ── Step 4: Financial + Account ──
  final _salaryCtrl = TextEditingController();
  String _currency = 'EGP';
  String _paymentMethod = 'none';
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _instapayPhoneCtrl = TextEditingController();
  final _walletPhoneCtrl = TextEditingController();
  final _walletProviderCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _employeeCodeCtrl = TextEditingController();
  bool _obscurePassword = true;

  // ── Result ──
  bool _creating = false;
  Map<String, dynamic>? _createdEmployee;
  Map<String, dynamic>? _createdCredentials;
  Map<String, dynamic>? _createdWhatsapp;
  String? _pdfPath;
  bool _generatingPdf = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      _firstNameArCtrl, _middleNameArCtrl, _lastNameArCtrl,
      _firstNameEnCtrl, _lastNameEnCtrl, _nationalIdCtrl,
      _phoneCtrl, _phone2Ctrl, _emailCtrl, _addressCtrl, _cityCtrl,
      _emergencyNameCtrl, _emergencyRelationCtrl, _emergencyPhoneCtrl,
      _insuranceNumberCtrl, _salaryCtrl, _bankNameCtrl, _bankAccountCtrl,
      _ibanCtrl, _instapayPhoneCtrl, _walletPhoneCtrl, _walletProviderCtrl,
      _usernameCtrl, _passwordCtrl, _employeeCodeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() { _loadingLookups = true; _lookupError = null; });
    try {
      final results = await Future.wait([
        EmployeeManagementService.getBranches(),
        EmployeeManagementService.getDepartments(),
        EmployeeManagementService.getJobTitles(),
        EmployeeManagementService.getEmployeesSimple(),
      ]);
      setState(() {
        _branches = results[0];
        _departments = results[1];
        _jobTitles = results[2];
        _employeesSimple = results[3];
        _loadingLookups = false;
        if (_branches.length == 1) _selectedBranchId = _branches[0]['id'];
        if (_departments.length == 1) _selectedDepartmentId = _departments[0]['id'];
        if (_jobTitles.length == 1) _selectedJobTitleId = _jobTitles[0]['id'];
      });
    } catch (e) {
      setState(() { _lookupError = e.toString(); _loadingLookups = false; });
    }
  }

  void _goTo(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2 && !_validateStep3()) return;
    if (_currentStep == 3) { _createEmployee(); return; }
    if (_currentStep < _totalSteps - 1) _goTo(_currentStep + 1);
  }

  void _prevStep() {
    if (_currentStep > 0) _goTo(_currentStep - 1);
  }

  bool _validateStep1() {
    if (!(_fk1.currentState?.validate() ?? false)) return false;
    if (_birthDate == null) {
      _snack(isAr ? 'يرجى اختيار تاريخ الميلاد' : 'Please select birth date', Colors.orange);
      return false;
    }
    return true;
  }

  bool _validateStep2() => _fk2.currentState?.validate() ?? false;

  bool _validateStep3() {
    if (_selectedBranchId == null || _selectedDepartmentId == null || _selectedJobTitleId == null) {
      _snack(isAr ? 'يرجى اختيار الفرع والقسم والمسمى' : 'Please select branch, department and job title', Colors.orange);
      return false;
    }
    if (_hireDate == null) {
      _snack(isAr ? 'يرجى اختيار تاريخ التعيين' : 'Please select hire date', Colors.orange);
      return false;
    }
    return true;
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color));
  }

  void _autoSuggestUsername() {
    final first = _firstNameEnCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final last = _lastNameEnCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (first.isNotEmpty && last.isNotEmpty && _usernameCtrl.text.isEmpty) {
      _usernameCtrl.text = '$first$last';
    }
  }

  void _generatePassword() {
    final phone = _phoneCtrl.text.trim();
    final suffix = phone.length >= 4 ? phone.substring(phone.length - 4) : '1234';
    final rand = (100 + DateTime.now().millisecond % 900).toString();
    setState(() { _passwordCtrl.text = 'Emp@$suffix$rand'; });
  }

  Future<void> _pickDate({required bool isBirth, bool isContract = false}) async {
    DateTime initial, first, last;
    if (isBirth) {
      initial = _birthDate ?? DateTime(1995);
      first = DateTime(1950);
      last = DateTime.now().subtract(const Duration(days: 365 * 16));
    } else if (isContract) {
      initial = _contractEndDate ?? DateTime.now().add(const Duration(days: 365));
      first = DateTime.now();
      last = DateTime.now().add(const Duration(days: 365 * 10));
    } else {
      initial = _hireDate ?? DateTime.now();
      first = DateTime(2000);
      last = DateTime.now().add(const Duration(days: 365));
    }
    final picked = await showDatePicker(
      context: context, initialDate: initial, firstDate: first, lastDate: last);
    if (picked != null) {
      setState(() {
        if (isBirth) _birthDate = picked;
        else if (isContract) _contractEndDate = picked;
        else _hireDate = picked;
      });
    }
  }

  String _fmt(DateTime? d) => d == null ? '' :
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _createEmployee() async {
    if (!(_fk4.currentState?.validate() ?? false)) return;
    setState(() { _creating = true; _errorMessage = null; });
    try {
      final lang = isAr ? 'ar' : 'en';
      final result = await EmployeeManagementService.createEmployee(
        firstNameAr: _firstNameArCtrl.text.trim(),
        middleNameAr: _middleNameArCtrl.text.trim(),
        lastNameAr: _lastNameArCtrl.text.trim(),
        firstNameEn: _firstNameEnCtrl.text.trim(),
        lastNameEn: _lastNameEnCtrl.text.trim(),
        nationalId: _nationalIdCtrl.text.trim(),
        birthDate: _fmt(_birthDate),
        gender: _gender,
        nationality: _nationality,
        maritalStatus: _maritalStatus,
        religion: _religion,
        phone: _phoneCtrl.text.trim(),
        dialCode: _selectedCountry.dial,
        phone2: _phone2Ctrl.text.trim(),
        email: _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        country: _selectedCountry.code,
        emergencyContactName: _emergencyNameCtrl.text.trim(),
        emergencyContactRelation: _emergencyRelationCtrl.text.trim(),
        emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
        hireDate: _fmt(_hireDate),
        branchId: _selectedBranchId!,
        departmentId: _selectedDepartmentId!,
        jobTitleId: _selectedJobTitleId!,
        directManagerId: _selectedManagerId,
        contractType: _contractType,
        contractEndDate: _contractEndDate != null ? _fmt(_contractEndDate) : null,
        hasInsurance: _hasInsurance,
        insuranceNumber: _insuranceNumberCtrl.text.trim(),
        basicSalary: double.tryParse(_salaryCtrl.text.trim()),
        currency: _currency,
        salaryPaymentMethod: _paymentMethod,
        bankName: _bankNameCtrl.text.trim(),
        bankAccount: _bankAccountCtrl.text.trim(),
        iban: _ibanCtrl.text.trim(),
        instapayPhone: _instapayPhoneCtrl.text.trim(),
        walletPhone: _walletPhoneCtrl.text.trim(),
        walletProvider: _walletProviderCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        employeeCode: _employeeCodeCtrl.text.trim(),
        language: lang,
      );
      setState(() {
        _createdEmployee = result['employee'];
        _createdCredentials = result['credentials'];
        _createdWhatsapp = result['whatsapp'];
        _creating = false;
      });
      _goTo(4);
      await _generatePdf();
      _snack(isAr ? 'تم إنشاء الموظف بنجاح ✅' : 'Employee created successfully ✅', Colors.green);
    } catch (e) {
      setState(() { _creating = false; _errorMessage = e.toString(); });
      _snack('${isAr ? 'خطأ' : 'Error'}: $e', Colors.red);
    }
  }

  Future<void> _generatePdf() async {
    if (_createdEmployee == null || _createdCredentials == null) return;
    setState(() => _generatingPdf = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name') ?? '';
      String? logoUrl, phone, address;
      try {
        final info = await EmployeeManagementService.getCompanyInfo();
        logoUrl = info['logo_url']?.toString();
        phone = info['phone']?.toString();
        address = info['address']?.toString();
      } catch (_) {}
      final path = await EmployeePdfService.generateEmployeePdf(
        employee: _createdEmployee!,
        credentials: _createdCredentials!,
        whatsapp: _createdWhatsapp ?? {},
        companyName: companyName,
        companyLogoUrl: logoUrl,
        companyPhone: phone,
        companyAddress: address,
      );
      setState(() { _pdfPath = path; _generatingPdf = false; });
    } catch (e) {
      setState(() => _generatingPdf = false);
      _snack('${isAr ? 'خطأ في PDF' : 'PDF error'}: $e', Colors.orange);
    }
  }

  // ══════════════════════════════════════
  // UI HELPERS
  // ══════════════════════════════════════

  InputDecoration _dec(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon, color: kManagerColor),
      );

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: _dec(label, Icons.calendar_today),
          child: Text(
            date == null ? (isAr ? 'اختر التاريخ' : 'Select date') : _fmt(date),
            style: TextStyle(color: date == null ? Colors.grey[600] : Colors.black),
          ),
        ),
      );

  Widget _sectionTitle(String ar, String en) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(
          isAr ? ar : en,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kManagerColor),
        ),
      );

  Widget _infoBox(String ar, String en) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(isAr ? ar : en,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
        ]),
      );

  // ══════════════════════════════════════
  // STEP INDICATOR
  // ══════════════════════════════════════

  Widget _buildStepIndicator() {
    final labels = isAr
        ? ['الشخصية', 'التواصل', 'الوظيفة', 'المالية', 'المشاركة']
        : ['Personal', 'Contact', 'Job', 'Financial', 'Share'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: List.generate(_totalSteps, (i) {
          final active = i == _currentStep;
          final done = i < _currentStep;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isAr ? 0 : (i < _totalSteps - 1 ? 4 : 0),
                  left: isAr ? (i < _totalSteps - 1 ? 4 : 0) : 0),
              child: Column(children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: done || active ? kManagerColor : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      color: active ? kManagerColor : done ? Colors.green : Colors.grey,
                    ),
                    textAlign: TextAlign.center),
              ]),
            ),
          );
        }),
      ),
    );
  }

  // ══════════════════════════════════════
  // STEP 1 — PERSONAL
  // ══════════════════════════════════════

  Widget _buildStep1() => Form(
        key: _fk1,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _sectionTitle('البيانات الشخصية', 'Personal Information'),
          // Arabic name
          TextFormField(
            controller: _firstNameArCtrl,
            decoration: _dec(isAr ? 'الاسم الأول بالعربي *' : 'First Name (Arabic) *', Icons.person),
            validator: (v) => (v == null || v.trim().length < 2)
                ? (isAr ? 'مطلوب (حرفين على الأقل)' : 'Required (min 2 chars)') : null,
            onChanged: (_) => _autoSuggestUsername(),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _middleNameArCtrl,
            decoration: _dec(isAr ? 'الاسم الأوسط (اختياري)' : 'Middle Name (optional)', Icons.person_outline),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _lastNameArCtrl,
            decoration: _dec(isAr ? 'الاسم الأخير بالعربي *' : 'Last Name (Arabic) *', Icons.person),
            validator: (v) => (v == null || v.trim().length < 2)
                ? (isAr ? 'مطلوب' : 'Required') : null,
          ),
          const SizedBox(height: 14),
          _infoBox('الاسم بالإنجليزي مطلوب لتوليد اسم المستخدم',
              'English name required for auto username'),
          TextFormField(
            controller: _firstNameEnCtrl,
            decoration: _dec(isAr ? 'الاسم الأول بالإنجليزي *' : 'First Name (English) *', Icons.person),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
            validator: (v) => (v == null || v.trim().length < 2)
                ? (isAr ? 'مطلوب بالإنجليزي' : 'Required in English') : null,
            onChanged: (_) => _autoSuggestUsername(),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _lastNameEnCtrl,
            decoration: _dec(isAr ? 'الاسم الأخير بالإنجليزي *' : 'Last Name (English) *', Icons.person),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
            validator: (v) => (v == null || v.trim().length < 2)
                ? (isAr ? 'مطلوب بالإنجليزي' : 'Required in English') : null,
            onChanged: (_) => _autoSuggestUsername(),
          ),
          const SizedBox(height: 14),
          // Gender
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: _dec(isAr ? 'النوع *' : 'Gender *', Icons.wc),
            items: [
              DropdownMenuItem(value: 'male', child: Text(isAr ? 'ذكر' : 'Male')),
              DropdownMenuItem(value: 'female', child: Text(isAr ? 'أنثى' : 'Female')),
            ],
            onChanged: (v) => setState(() => _gender = v ?? 'male'),
          ),
          const SizedBox(height: 10),
          // National ID
          TextFormField(
            controller: _nationalIdCtrl,
            keyboardType: TextInputType.number,
            maxLength: 14,
            decoration: _dec(isAr ? 'الرقم القومي * (14 رقم)' : 'National ID * (14 digits)', Icons.badge),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return isAr ? 'مطلوب' : 'Required';
              if (!RegExp(r'^\d{14}$').hasMatch(v.trim()))
                return isAr ? 'يجب أن يكون 14 رقم' : 'Must be 14 digits';
              return null;
            },
          ),
          const SizedBox(height: 10),
          _dateTile(isAr ? 'تاريخ الميلاد *' : 'Birth Date *', _birthDate,
              () => _pickDate(isBirth: true)),
          const SizedBox(height: 14),
          // Nationality
          TextFormField(
            initialValue: _nationality,
            decoration: _dec(isAr ? 'الجنسية' : 'Nationality', Icons.flag),
            onChanged: (v) => _nationality = v,
          ),
          const SizedBox(height: 10),
          // Marital status
          DropdownButtonFormField<String>(
            value: _maritalStatus,
            decoration: _dec(isAr ? 'الحالة الاجتماعية' : 'Marital Status', Icons.favorite),
            items: [
              DropdownMenuItem(value: 'single', child: Text(isAr ? 'أعزب' : 'Single')),
              DropdownMenuItem(value: 'married', child: Text(isAr ? 'متزوج' : 'Married')),
              DropdownMenuItem(value: 'divorced', child: Text(isAr ? 'مطلق' : 'Divorced')),
              DropdownMenuItem(value: 'widowed', child: Text(isAr ? 'أرمل' : 'Widowed')),
            ],
            onChanged: (v) => setState(() => _maritalStatus = v ?? 'single'),
          ),
          const SizedBox(height: 10),
          // Religion
          DropdownButtonFormField<String>(
            value: _religion,
            decoration: _dec(isAr ? 'الديانة' : 'Religion', Icons.mosque),
            items: [
              DropdownMenuItem(value: 'muslim', child: Text(isAr ? 'مسلم' : 'Muslim')),
              DropdownMenuItem(value: 'christian', child: Text(isAr ? 'مسيحي' : 'Christian')),
              DropdownMenuItem(value: 'other', child: Text(isAr ? 'أخرى' : 'Other')),
            ],
            onChanged: (v) => setState(() => _religion = v ?? 'muslim'),
          ),
          const SizedBox(height: 20),
        ]),
      );

  // ══════════════════════════════════════
  // STEP 2 — CONTACT
  // ══════════════════════════════════════

  Widget _buildStep2() => Form(
        key: _fk2,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _sectionTitle('بيانات التواصل', 'Contact Information'),
          // Country selector
          DropdownButtonFormField<_Country>(
            value: _selectedCountry,
            decoration: _dec(isAr ? 'الدولة' : 'Country', Icons.public),
            isExpanded: true,
            items: kCountries.map((c) => DropdownMenuItem(
              value: c,
              child: Text('${c.dial}  ${isAr ? c.nameAr : c.nameEn}'),
            )).toList(),
            onChanged: (v) => setState(() { if (v != null) _selectedCountry = v; }),
          ),
          const SizedBox(height: 12),
          // Phone with dial code
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[400]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[100],
              ),
              child: Text(_selectedCountry.dial,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dec(isAr ? 'رقم الموبايل * (واتساب)' : 'Mobile * (WhatsApp)', Icons.phone_android),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return isAr ? 'مطلوب' : 'Required';
                  if (v.trim().replaceAll(RegExp(r'\D'), '').length < 7)
                    return isAr ? 'رقم غير صحيح' : 'Invalid number';
                  return null;
                },
              ),
            ),
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: _phone2Ctrl,
            keyboardType: TextInputType.phone,
            decoration: _dec(isAr ? 'رقم موبايل آخر (اختياري)' : 'Other Mobile (optional)', Icons.phone),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _dec(isAr ? 'البريد الإلكتروني (اختياري)' : 'Email (optional)', Icons.email),
            validator: (v) {
              if (v != null && v.isNotEmpty && !v.contains('@'))
                return isAr ? 'بريد غير صحيح' : 'Invalid email';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _sectionTitle('العنوان', 'Address'),
          TextFormField(
            controller: _addressCtrl,
            decoration: _dec(isAr ? 'العنوان (اختياري)' : 'Address (optional)', Icons.home),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cityCtrl,
            decoration: _dec(isAr ? 'المدينة (اختياري)' : 'City (optional)', Icons.location_city),
          ),
          const SizedBox(height: 14),
          _sectionTitle('جهة الاتصال في الطوارئ', 'Emergency Contact'),
          TextFormField(
            controller: _emergencyNameCtrl,
            decoration: _dec(isAr ? 'اسم جهة الاتصال' : 'Contact Name', Icons.person_pin),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emergencyRelationCtrl,
            decoration: _dec(isAr ? 'صلة القرابة' : 'Relation', Icons.family_restroom),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _emergencyPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _dec(isAr ? 'رقم الطوارئ' : 'Emergency Phone', Icons.emergency),
          ),
          const SizedBox(height: 20),
        ]),
      );

  // ══════════════════════════════════════
  // STEP 3 — JOB
  // ══════════════════════════════════════

  Widget _buildStep3() {
    if (_loadingLookups) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        Text(isAr ? 'جاري تحميل البيانات...' : 'Loading data...'),
      ],
    ));
    if (_lookupError != null) return Center(child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 50),
        const SizedBox(height: 12),
        Text('${isAr ? 'خطأ' : 'Error'}: $_lookupError', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _loadLookups,
          icon: const Icon(Icons.refresh),
          label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
        ),
      ]),
    ));

    return ListView(padding: const EdgeInsets.all(16), children: [
      _sectionTitle('بيانات الوظيفة', 'Job Details'),
      DropdownButtonFormField<int>(
        value: _selectedBranchId,
        decoration: _dec(isAr ? 'الفرع *' : 'Branch *', Icons.business),
        items: _branches.map((b) => DropdownMenuItem<int>(
          value: b['id'] as int,
          child: Text(isAr ? (b['name_ar'] ?? '') : (b['name_en'] ?? b['name_ar'] ?? '')),
        )).toList(),
        onChanged: (v) => setState(() => _selectedBranchId = v),
        validator: (v) => v == null ? (isAr ? 'مطلوب' : 'Required') : null,
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<int>(
        value: _selectedDepartmentId,
        decoration: _dec(isAr ? 'القسم *' : 'Department *', Icons.apartment),
        items: _departments.map((d) => DropdownMenuItem<int>(
          value: d['id'] as int,
          child: Text(isAr ? (d['name_ar'] ?? '') : (d['name_en'] ?? d['name_ar'] ?? '')),
        )).toList(),
        onChanged: (v) => setState(() => _selectedDepartmentId = v),
        validator: (v) => v == null ? (isAr ? 'مطلوب' : 'Required') : null,
      ),
      const SizedBox(height: 10),
      DropdownButtonFormField<int>(
        value: _selectedJobTitleId,
        decoration: _dec(isAr ? 'المسمى الوظيفي *' : 'Job Title *', Icons.work),
        items: _jobTitles.map((j) => DropdownMenuItem<int>(
          value: j['id'] as int,
          child: Text(isAr ? (j['name_ar'] ?? '') : (j['name_en'] ?? j['name_ar'] ?? '')),
        )).toList(),
        onChanged: (v) => setState(() => _selectedJobTitleId = v),
        validator: (v) => v == null ? (isAr ? 'مطلوب' : 'Required') : null,
      ),
      const SizedBox(height: 10),
      if (_employeesSimple.isNotEmpty)
        DropdownButtonFormField<int>(
          value: _selectedManagerId,
          decoration: _dec(isAr ? 'المدير المباشر (اختياري)' : 'Direct Manager (optional)', Icons.supervisor_account),
          isExpanded: true,
          items: [
            DropdownMenuItem<int>(value: null, child: Text(isAr ? 'بدون مدير مباشر' : 'No direct manager')),
            ..._employeesSimple
                .where((e) => e['is_manager'] == true)
                .map((e) => DropdownMenuItem<int>(
                  value: e['id'] as int,
                  child: Text('${e['full_name']} - ${e['job_title'] ?? ''}'),
                )),
          ],
          onChanged: (v) => setState(() => _selectedManagerId = v),
        ),
      const SizedBox(height: 12),
      _dateTile(isAr ? 'تاريخ التعيين *' : 'Hire Date *', _hireDate,
          () => _pickDate(isBirth: false)),
      const SizedBox(height: 14),
      _sectionTitle('العقد والتأمين', 'Contract & Insurance'),
      DropdownButtonFormField<String>(
        value: _contractType,
        decoration: _dec(isAr ? 'نوع العقد' : 'Contract Type', Icons.description),
        items: [
          DropdownMenuItem(value: 'permanent', child: Text(isAr ? 'دائم' : 'Permanent')),
          DropdownMenuItem(value: 'temporary', child: Text(isAr ? 'مؤقت' : 'Temporary')),
          DropdownMenuItem(value: 'training', child: Text(isAr ? 'تدريب' : 'Training')),
          DropdownMenuItem(value: 'freelance', child: Text(isAr ? 'حر' : 'Freelance')),
          DropdownMenuItem(value: 'part_time', child: Text(isAr ? 'جزء وقت' : 'Part Time')),
        ],
        onChanged: (v) => setState(() => _contractType = v ?? 'permanent'),
      ),
      const SizedBox(height: 10),
      if (_contractType == 'temporary' || _contractType == 'training')
        Column(children: [
          _dateTile(isAr ? 'تاريخ نهاية العقد' : 'Contract End Date',
              _contractEndDate, () => _pickDate(isBirth: false, isContract: true)),
          const SizedBox(height: 10),
        ]),
      SwitchListTile(
        value: _hasInsurance,
        onChanged: (v) => setState(() => _hasInsurance = v),
        title: Text(isAr ? 'مشمول بالتأمينات الاجتماعية' : 'Has Social Insurance'),
        activeColor: kManagerColor,
      ),
      if (_hasInsurance) ...[
        const SizedBox(height: 8),
        TextFormField(
          controller: _insuranceNumberCtrl,
          decoration: _dec(isAr ? 'رقم التأمين' : 'Insurance Number', Icons.shield),
        ),
      ],
      const SizedBox(height: 20),
    ]);
  }

  // ══════════════════════════════════════
  // STEP 4 — FINANCIAL + ACCOUNT
  // ══════════════════════════════════════

  Widget _buildStep4() => Form(
        key: _fk4,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _sectionTitle('البيانات المالية', 'Financial Details'),
          Row(children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _salaryCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec(isAr ? 'الراتب الأساسي' : 'Basic Salary', Icons.attach_money),
                validator: (v) {
                  if (v != null && v.isNotEmpty && double.tryParse(v) == null)
                    return isAr ? 'رقم غير صحيح' : 'Invalid';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _currency,
                decoration: _dec(isAr ? 'العملة' : 'Currency', Icons.currency_exchange),
                items: const [
                  DropdownMenuItem(value: 'EGP', child: Text('EGP')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                  DropdownMenuItem(value: 'SAR', child: Text('SAR')),
                  DropdownMenuItem(value: 'AED', child: Text('AED')),
                  DropdownMenuItem(value: 'KWD', child: Text('KWD')),
                  DropdownMenuItem(value: 'QAR', child: Text('QAR')),
                ],
                onChanged: (v) => setState(() => _currency = v ?? 'EGP'),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          // Payment method
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: _dec(isAr ? 'طريقة استلام الراتب' : 'Salary Payment Method', Icons.payment),
            items: [
              DropdownMenuItem(value: 'none', child: Text(isAr ? 'بدون وسيلة حالياً' : 'None for now')),
              DropdownMenuItem(value: 'bank', child: Text(isAr ? 'حساب بنكي' : 'Bank Account')),
              DropdownMenuItem(value: 'instapay', child: Text(isAr ? 'InstaPay' : 'InstaPay')),
              DropdownMenuItem(value: 'wallet', child: Text(isAr ? 'محفظة إلكترونية' : 'E-Wallet')),
            ],
            onChanged: (v) => setState(() => _paymentMethod = v ?? 'none'),
          ),
          const SizedBox(height: 12),

          // ── Bank fields ──
          if (_paymentMethod == 'bank') ...[
            _infoBox('أدخل بيانات الحساب البنكي للموظف', 'Enter employee bank account details'),
            TextFormField(
              controller: _bankNameCtrl,
              decoration: _dec(isAr ? 'اسم البنك' : 'Bank Name', Icons.account_balance),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _bankAccountCtrl,
              keyboardType: TextInputType.number,
              decoration: _dec(isAr ? 'رقم الحساب' : 'Account Number', Icons.credit_card),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _ibanCtrl,
              decoration: _dec('IBAN', Icons.numbers),
            ),
            const SizedBox(height: 12),
          ],

          // ── InstaPay fields ──
          if (_paymentMethod == 'instapay') ...[
            _infoBox('أدخل رقم الهاتف المربوط بـ InstaPay', 'Enter phone number linked to InstaPay'),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: Text(_selectedCountry.dial,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _instapayPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec(isAr ? 'رقم InstaPay' : 'InstaPay Phone', Icons.phone_android),
                ),
              ),
            ]),
            const SizedBox(height: 12),
          ],

          // ── Wallet fields ──
          if (_paymentMethod == 'wallet') ...[
            _infoBox('أدخل رقم المحفظة الإلكترونية', 'Enter e-wallet phone number'),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: Text(_selectedCountry.dial,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _walletPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _dec(isAr ? 'رقم المحفظة' : 'Wallet Phone', Icons.account_balance_wallet),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _walletProviderCtrl.text.isEmpty ? null : _walletProviderCtrl.text,
              decoration: _dec(isAr ? 'مقدم الخدمة (اختياري)' : 'Provider (optional)', Icons.corporate_fare),
              items: [
                DropdownMenuItem(value: null, child: Text(isAr ? 'اختر المقدم' : 'Select provider')),
                DropdownMenuItem(value: 'vodafone_cash', child: Text('Vodafone Cash')),
                DropdownMenuItem(value: 'orange_money', child: Text('Orange Money')),
                DropdownMenuItem(value: 'etisalat_cash', child: Text('Etisalat Cash')),
                DropdownMenuItem(value: 'we_pay', child: Text('WE Pay')),
                DropdownMenuItem(value: 'fawry', child: Text('Fawry')),
                DropdownMenuItem(value: 'other', child: Text(isAr ? 'أخرى' : 'Other')),
              ],
              onChanged: (v) => setState(() => _walletProviderCtrl.text = v ?? ''),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 28),
          _sectionTitle('بيانات الحساب', 'Account Details'),
          _infoBox(
            'اتركها فارغة للتوليد التلقائي من رقم الموبايل',
            'Leave empty for auto-generation from phone number',
          ),
          TextFormField(
            controller: _usernameCtrl,
            decoration: _dec(
              isAr ? 'اسم المستخدم (اختياري - تلقائي)' : 'Username (optional - auto)',
              Icons.alternate_email,
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 3)
                return isAr ? 'قصير جداً' : 'Too short';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: isAr ? 'كلمة المرور (اختياري - تلقائي)' : 'Password (optional - auto)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.lock, color: kManagerColor),
              suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_fix_high, color: kManagerColor),
                  tooltip: isAr ? 'توليد كلمة مرور' : 'Generate password',
                  onPressed: _generatePassword,
                ),
              ]),
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 6)
                return isAr ? 'يجب أن تكون 6 أحرف على الأقل' : 'Min 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _employeeCodeCtrl,
            decoration: _dec(
              isAr ? 'الرقم الوظيفي (اختياري - تلقائي EMP00001)' : 'Employee Code (optional - auto)',
              Icons.numbers,
            ),
          ),
          const SizedBox(height: 20),
          // Security note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.security, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Text(isAr ? 'ملاحظة أمنية' : 'Security Note',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ]),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? '• سيُجبر الموظف على تغيير كلمة المرور عند أول دخول\n• احتفظ بملف PDF في مكان آمن'
                    : '• Employee will be forced to change password on first login\n• Keep PDF file safe',
                style: TextStyle(fontSize: 12, color: Colors.orange[900], height: 1.5),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      );

  // ══════════════════════════════════════
  // STEP 5 — SHARE
  // ══════════════════════════════════════

  Widget _buildStep5() {
    if (_createdEmployee == null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_errorMessage != null) ...[
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text('${isAr ? 'خطأ' : 'Error'}: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _goTo(0),
              icon: const Icon(Icons.refresh),
              label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(isAr ? 'جاري إنشاء حساب الموظف...' : 'Creating employee account...'),
          ],
        ]),
      ));
    }

    final emp = _createdEmployee!;
    final cred = _createdCredentials!;
    final phone = emp['phone'] ?? _phoneCtrl.text.trim();

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Success header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 60),
          const SizedBox(height: 12),
          Text(
            isAr ? 'تم إنشاء الموظف بنجاح! 🎉' : 'Employee Created Successfully! 🎉',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(emp['full_name_ar'] ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Text(
            '${isAr ? 'الرقم الوظيفي' : 'Code'}: ${emp['employee_code'] ?? ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      // Credentials
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kManagerColor.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.vpn_key, color: kManagerColor),
            const SizedBox(width: 8),
            Text(isAr ? 'بيانات الدخول' : 'Login Credentials',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kManagerColor)),
          ]),
          const SizedBox(height: 12),
          _credTile(isAr ? 'اسم المستخدم' : 'Username',
              cred['username'] ?? '', Icons.alternate_email, Colors.blue),
          const SizedBox(height: 8),
          _credTile(isAr ? 'كلمة المرور' : 'Password',
              cred['password'] ?? '', Icons.lock, Colors.red, sensitive: true),
        ]),
      ),
      const SizedBox(height: 16),

      // PDF status
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _pdfPath != null ? Colors.green[50] : Colors.orange[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _pdfPath != null ? Colors.green[200]! : Colors.orange[200]!),
        ),
        child: Row(children: [
          Icon(_pdfPath != null ? Icons.picture_as_pdf : Icons.hourglass_top,
              color: _pdfPath != null ? Colors.green : Colors.orange),
          const SizedBox(width: 12),
          Expanded(child: Text(
            _pdfPath != null
                ? (isAr ? 'تم إنشاء ملف PDF ✅' : 'PDF file created ✅')
                : (isAr ? 'جاري إنشاء PDF...' : 'Generating PDF...'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _pdfPath != null ? Colors.green[800] : Colors.orange[800],
            ),
          )),
          if (_generatingPdf) const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          if (_pdfPath != null) IconButton(
            icon: const Icon(Icons.open_in_new, color: kPrimaryColor),
            onPressed: () => OpenFile.open(_pdfPath!),
          ),
        ]),
      ),
      const SizedBox(height: 20),

      // Share buttons
      Text(isAr ? 'مشاركة البيانات' : 'Share Data',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton.icon(
          onPressed: (_pdfPath == null || _generatingPdf) ? null : () async {
            try {
              await EmployeePdfService.sharePdf(_pdfPath!,
                  phone: emp['phone'], employeeName: emp['full_name_ar']);
            } catch (e) { _snack('Error: $e', Colors.red); }
          },
          icon: const Icon(Icons.share),
          label: Text(isAr ? 'مشاركة ملف PDF' : 'Share PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor, foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton.icon(
          onPressed: () async {
            final name = emp['full_name_ar'] ?? '';
            final username = cred['username'] ?? '';
            final password = cred['password'] ?? '';
            final msg = isAr
                ? 'مرحباً $name 👋\n\nتم إنشاء حسابك في تطبيق MotionHR\n\n👤 اسم المستخدم: $username\n🔑 كلمة المرور: $password\n\n📎 الملف المرفق يحتوي على بيانات الدخول الكاملة\n\nيرجى تحميل تطبيق MotionHR وتسجيل الدخول\nستحتاج لتغيير كلمة المرور عند أول دخول.\n\nشكراً!'
                : 'Hello $name 👋\n\nYour MotionHR account has been created\n\n👤 Username: $username\n🔑 Password: $password\n\n📎 The attached file contains your full login details\n\nPlease download the MotionHR app and login.\nYou will be asked to change your password on first login.\n\nThank you!';
            try {
              await EmployeePdfService.openWhatsApp(phone, message: msg);
            } catch (e) { _snack('Error: $e', Colors.red); }
          },
          icon: const Icon(Icons.chat),
          label: Text(isAr ? 'إرسال واتساب إلى $phone' : 'Send WhatsApp to $phone'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => Navigator.pop(context, true),
        icon: const Icon(Icons.check),
        label: Text(isAr ? 'تم - العودة للوحة التحكم' : 'Done - Back to Dashboard'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          foregroundColor: kManagerColor,
          side: const BorderSide(color: kManagerColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 10),
      ElevatedButton.icon(
        onPressed: _resetForm,
        icon: const Icon(Icons.person_add),
        label: Text(isAr ? 'إنشاء موظف آخر' : 'Create Another Employee'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: Colors.white,
          foregroundColor: kManagerColor,
          side: const BorderSide(color: kManagerColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 30),
    ]);
  }

  void _resetForm() {
    setState(() {
      _createdEmployee = null; _createdCredentials = null;
      _createdWhatsapp = null; _pdfPath = null; _errorMessage = null;
      _firstNameArCtrl.clear(); _middleNameArCtrl.clear(); _lastNameArCtrl.clear();
      _firstNameEnCtrl.clear(); _lastNameEnCtrl.clear(); _nationalIdCtrl.clear();
      _birthDate = null; _gender = 'male'; _nationality = 'مصري';
      _maritalStatus = 'single'; _religion = 'muslim';
      _phoneCtrl.clear(); _phone2Ctrl.clear(); _emailCtrl.clear();
      _addressCtrl.clear(); _cityCtrl.clear();
      _emergencyNameCtrl.clear(); _emergencyRelationCtrl.clear(); _emergencyPhoneCtrl.clear();
      _selectedBranchId = _branches.length == 1 ? _branches[0]['id'] : null;
      _selectedDepartmentId = _departments.length == 1 ? _departments[0]['id'] : null;
      _selectedJobTitleId = _jobTitles.length == 1 ? _jobTitles[0]['id'] : null;
      _selectedManagerId = null; _hireDate = DateTime.now();
      _contractType = 'permanent'; _contractEndDate = null;
      _hasInsurance = false; _insuranceNumberCtrl.clear();
      _salaryCtrl.clear(); _currency = 'EGP'; _paymentMethod = 'none';
      _bankNameCtrl.clear(); _bankAccountCtrl.clear(); _ibanCtrl.clear();
      _instapayPhoneCtrl.clear(); _walletPhoneCtrl.clear(); _walletProviderCtrl.clear();
      _usernameCtrl.clear(); _passwordCtrl.clear(); _employeeCodeCtrl.clear();
    });
    _goTo(0);
  }

  Widget _credTile(String label, String value, IconData icon, Color color, {bool sensitive = false}) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: sensitive ? Colors.red[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sensitive ? Colors.red[200]! : Colors.grey[300]!),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 2),
            SelectableText(value,
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: sensitive ? Colors.red[800] : Colors.black87,
                )),
          ])),
        ]),
      );

  // ══════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final steps = [_buildStep1, _buildStep2, _buildStep3, _buildStep4, _buildStep5];

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'إضافة موظف جديد' : 'Add New Employee'),
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_currentStep < 4)
              Center(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  isAr ? 'خطوة ${_currentStep + 1}/$_totalSteps' : 'Step ${_currentStep + 1}/$_totalSteps',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              )),
          ],
        ),
        body: Column(children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: steps.map((s) => s()).toList(),
            ),
          ),
          if (_currentStep < 4)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))],
              ),
              child: Row(children: [
                if (_currentStep > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 52),
                        side: const BorderSide(color: kManagerColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(isAr ? 'السابق' : 'Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _creating ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kManagerColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _creating
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            _currentStep == 3
                                ? (isAr ? 'إنشاء الموظف ✓' : 'Create Employee ✓')
                                : (isAr ? 'التالي ←' : 'Next →'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}
