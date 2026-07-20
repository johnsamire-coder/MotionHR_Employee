import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/employee_management_service.dart';
import '../../services/employee_pdf_service.dart';
import 'package:open_file/open_file.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

const Color kPrimaryColor = Color(0xFF1976D2);
const Color kManagerColor = Color(0xFF6A1B9A);

class CreateEmployeeScreen extends StatefulWidget {
  const CreateEmployeeScreen({super.key});
  @override
  State<CreateEmployeeScreen> createState() =>
      _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState
    extends State<CreateEmployeeScreen> {
  bool get isAr =>
      Localizations.localeOf(context).languageCode == 'ar';

  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  final _firstNameArCtrl = TextEditingController();
  final _middleNameArCtrl = TextEditingController();
  final _lastNameArCtrl = TextEditingController();
  final _firstNameEnCtrl = TextEditingController();
  final _lastNameEnCtrl = TextEditingController();
  final _nationalIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _phone2Ctrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _gender = 'male';
  DateTime? _birthDate;

  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _jobTitles = [];
  List<Map<String, dynamic>> _employeesSimple = [];

  int? _selectedBranchId;
  int? _selectedDepartmentId;
  int? _selectedJobTitleId;
  int? _selectedManagerId;
  DateTime? _hireDate = DateTime.now();
  final _salaryCtrl = TextEditingController();
  String _selectedCurrency = 'EGP';

  List<Map<String, String>> get _currencies => [
        {'code': 'EGP', 'name': isAr ? 'جنيه مصري' : 'Egyptian Pound'},
        {'code': 'USD', 'name': isAr ? 'دولار أمريكي' : 'US Dollar'},
        {'code': 'SAR', 'name': isAr ? 'ريال سعودي' : 'Saudi Riyal'},
        {'code': 'AED', 'name': isAr ? 'درهم إماراتي' : 'UAE Dirham'},
      ];

  bool _loadingLookups = true;
  String? _lookupError;

  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _employeeCodeCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _autoGeneratePassword = true;

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
    _hireDate = DateTime.now();
    _passwordCtrl.text = '';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameArCtrl.dispose();
    _middleNameArCtrl.dispose();
    _lastNameArCtrl.dispose();
    _nationalIdCtrl.dispose();
    _phoneCtrl.dispose();
    _phone2Ctrl.dispose();
    _emailCtrl.dispose();
    _firstNameEnCtrl.dispose();
    _lastNameEnCtrl.dispose();
    _salaryCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _employeeCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() {
      _loadingLookups = true;
      _lookupError = null;
    });
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
        if (_branches.length == 1)
          _selectedBranchId = _branches[0]['id'];
        if (_departments.length == 1)
          _selectedDepartmentId = _departments[0]['id'];
        if (_jobTitles.length == 1)
          _selectedJobTitleId = _jobTitles[0]['id'];
      });
    } catch (e) {
      setState(() {
        _lookupError = e.toString();
        _loadingLookups = false;
      });
    }
  }

  bool _validateStep1() {
    if (!(_formKeyStep1.currentState?.validate() ?? false))
      return false;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr
            ? 'يرجى اختيار تاريخ الميلاد'
            : 'Please select birth date'),
        backgroundColor: Colors.orange,
      ));
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_selectedBranchId == null ||
        _selectedDepartmentId == null ||
        _selectedJobTitleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr
            ? 'يرجى اختيار الفرع والقسم والمسمى الوظيفي'
            : 'Please select branch, department and job title'),
        backgroundColor: Colors.orange,
      ));
      return false;
    }
    if (_hireDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr
            ? 'يرجى اختيار تاريخ التعيين'
            : 'Please select hire date'),
        backgroundColor: Colors.orange,
      ));
      return false;
    }
    return _formKeyStep2.currentState?.validate() ?? false;
  }

  bool _validateStep3() =>
      _formKeyStep3.currentState?.validate() ?? false;

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2 && !_validateStep3()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  void _generateRandomPassword() {
    final phone = _phoneCtrl.text.trim();
    String suffix =
        phone.length >= 4 ? phone.substring(phone.length - 4) : '1234';
    final random =
        (100 + (DateTime.now().millisecond % 900)).toString();
    _passwordCtrl.text = 'Emp@$suffix$random';
    setState(() => _autoGeneratePassword = false);
  }

  void _autoSuggestUsername() {
    final first = _firstNameEnCtrl.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '');
    final last = _lastNameEnCtrl.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z]'), '');
    if (first.isNotEmpty && last.isNotEmpty) {
      _usernameCtrl.text = '$first$last';
    } else if (first.isNotEmpty) {
      final phone =
          _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
      _usernameCtrl.text = phone.length >= 4
          ? '$first${phone.substring(phone.length - 4)}'
          : first;
    }
  }

  Future<void> _pickDate({required bool isBirth}) async {
    final initial =
        isBirth ? DateTime(1995, 1, 1) : DateTime.now();
    final first = isBirth ? DateTime(1960) : DateTime(2020);
    final last = isBirth
        ? DateTime.now().subtract(const Duration(days: 365 * 16))
        : DateTime.now().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isBirth ? (_birthDate ?? initial) : (_hireDate ?? initial),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        if (isBirth) {
          _birthDate = picked;
        } else {
          _hireDate = picked;
        }
      });
    }
  }

  Future<void> _createEmployee() async {
    setState(() {
      _creating = true;
      _errorMessage = null;
    });
    try {
      final result =
          await EmployeeManagementService.createEmployee(
        firstNameAr: _firstNameArCtrl.text.trim(),
        middleNameAr: _middleNameArCtrl.text.trim(),
        lastNameAr: _lastNameArCtrl.text.trim(),
        firstNameEn: _firstNameEnCtrl.text.trim(),
        lastNameEn: _lastNameEnCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        phone2: _phone2Ctrl.text.trim().isEmpty
            ? null
            : _phone2Ctrl.text.trim(),
        nationalId: _nationalIdCtrl.text.trim(),
        birthDate:
            _birthDate!.toIso8601String().split('T')[0],
        gender: _gender,
        hireDate: _hireDate!.toIso8601String().split('T')[0],
        branchId: _selectedBranchId!,
        departmentId: _selectedDepartmentId!,
        jobTitleId: _selectedJobTitleId!,
        directManagerId: _selectedManagerId,
        basicSalary: double.tryParse(_salaryCtrl.text.trim()),
        currency: _selectedCurrency,
        email: _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim().isEmpty
            ? null
            : _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim().isEmpty
            ? null
            : _passwordCtrl.text.trim(),
        employeeCode: _employeeCodeCtrl.text.trim().isEmpty
            ? null
            : _employeeCodeCtrl.text.trim(),
      );
      setState(() {
        _createdEmployee = result['employee'];
        _createdCredentials = result['credentials'];
        _createdWhatsapp = result['whatsapp'];
        _creating = false;
        _currentStep = 3;
      });
      _pageController.animateToPage(3,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
      await _generatePdf();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ??
              (isAr
                  ? 'تم إنشاء الموظف بنجاح'
                  : 'Employee created successfully')),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      setState(() {
        _creating = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${isAr ? 'خطأ' : 'Error'}: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_createdEmployee == null ||
        _createdCredentials == null) return;
    setState(() => _generatingPdf = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName =
          prefs.getString('company_name') ??
              _createdEmployee!['company'] ??
              '';
      String? logoUrl, phone, address;
      try {
        final companyInfo =
            await EmployeeManagementService.getCompanyInfo();
        logoUrl = companyInfo['logo_url']?.toString();
        phone = companyInfo['phone']?.toString();
        address = companyInfo['address']?.toString();
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
      setState(() {
        _pdfPath = path;
        _generatingPdf = false;
      });
    } catch (e) {
      setState(() => _generatingPdf = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${isAr ? 'خطأ في توليد PDF' : 'PDF generation error'}: $e'),
          backgroundColor: Colors.orange,
        ));
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfPath == null) await _generatePdf();
    if (_pdfPath == null) return;
    try {
      await EmployeePdfService.sharePdf(_pdfPath!,
          phone: _createdEmployee?['phone'],
          employeeName: _createdEmployee?['full_name_ar']);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '${isAr ? 'خطأ في المشاركة' : 'Share error'}: $e'),
        ));
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final phone =
        _createdEmployee?['phone'] ?? _phoneCtrl.text.trim();
    if (phone == null || phone.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr
            ? 'رقم الموبايل غير متوفر'
            : 'Phone number not available'),
      ));
      return;
    }
    final name = _createdEmployee?['full_name_ar'] ?? '';
    final username = _createdCredentials?['username'] ?? '';
    final password = _createdCredentials?['password'] ?? '';
    final message = isAr
        ? 'مرحبا $name 👋\n\nتم إنشاء حسابك في نظام MotionHR\n\n🔹 اسم المستخدم: $username\n🔹 كلمة المرور: $password\n\n📎 الملف المرفق يحتوي على بيانات الدخول الكاملة\n\nيرجى تحميل تطبيق MotionHR وتسجيل الدخول، وستحتاج لتغيير كلمة المرور عند أول دخول.\n\nشكرا لك!'
        : 'Hello $name 👋\n\nYour MotionHR account has been created\n\n🔹 Username: $username\n🔹 Password: $password\n\n📎 The attached file contains your login details\n\nPlease download the MotionHR app and login. You will be asked to change your password on first login.\n\nThank you!';
    try {
      await EmployeePdfService.openWhatsApp(phone,
          message: message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Widget _buildStepIndicator() {
    final steps = isAr
        ? ['البيانات الشخصية', 'الوظيفة', 'الحساب', 'المشاركة']
        : ['Personal Info', 'Job', 'Account', 'Share'];
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                  right: index < _totalSteps - 1 ? 6 : 0),
              child: Column(children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? kManagerColor
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isActive
                        ? kManagerColor
                        : isCompleted
                            ? Colors.green
                            : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isAr ? 'البيانات الشخصية' : 'Personal Info',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kManagerColor),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'أدخل بيانات الموظف الأساسية'
                : 'Enter employee basic info',
            style:
                TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _firstNameArCtrl,
            decoration: _inputDec(
                isAr
                    ? 'الاسم الأول بالعربي *'
                    : 'First Name (Arabic) *',
                Icons.person),
            validator: (v) =>
                (v == null || v.trim().length < 2)
                    ? (isAr
                        ? 'مطلوب (حرفين على الأقل)'
                        : 'Required (min 2 chars)')
                    : null,
            onChanged: (_) => _autoSuggestUsername(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _middleNameArCtrl,
            decoration: _inputDec(
                isAr
                    ? 'الاسم الأوسط (اختياري)'
                    : 'Middle Name (optional)',
                Icons.person_outline),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameArCtrl,
            decoration: _inputDec(
                isAr
                    ? 'الاسم الأخير بالعربي *'
                    : 'Last Name (Arabic) *',
                Icons.person),
            validator: (v) =>
                (v == null || v.trim().length < 2)
                    ? context.l10n.required
                    : null,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAr
                      ? 'الاسم بالإنجليزي مطلوب لتوليد اسم المستخدم تلقائياً'
                      : 'English name is required to auto-generate username',
                  style: TextStyle(
                      fontSize: 12, color: Colors.blueGrey),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _firstNameEnCtrl,
            decoration: _inputDec(
                isAr
                    ? 'الاسم الأول بالإنجليزي *'
                    : 'First Name (English) *',
                Icons.person),
            keyboardType: TextInputType.name,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z\s]')),
            ],
            validator: (v) =>
                (v == null || v.trim().length < 2)
                    ? (isAr
                        ? 'مطلوب بالإنجليزي'
                        : 'Required in English')
                    : null,
            onChanged: (_) => _autoSuggestUsername(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameEnCtrl,
            decoration: _inputDec(
                isAr
                    ? 'الاسم الأخير بالإنجليزي *'
                    : 'Last Name (English) *',
                Icons.person),
            keyboardType: TextInputType.name,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z\s]')),
            ],
            validator: (v) =>
                (v == null || v.trim().length < 2)
                    ? (isAr
                        ? 'مطلوب بالإنجليزي'
                        : 'Required in English')
                    : null,
            onChanged: (_) => _autoSuggestUsername(),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: _inputDec(
                isAr ? 'النوع *' : 'Gender *', Icons.wc),
            items: [
              DropdownMenuItem(
                  value: 'male',
                  child: Text(context.l10n.male)),
              DropdownMenuItem(
                  value: 'female',
                  child: Text(context.l10n.female)),
            ],
            onChanged: (v) =>
                setState(() => _gender = v ?? 'male'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nationalIdCtrl,
            keyboardType: TextInputType.number,
            maxLength: 14,
            decoration: _inputDec(
                isAr
                    ? 'الرقم القومي * (14 رقم)'
                    : 'National ID * (14 digits)',
                Icons.badge),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return context.l10n.required;
              if (!RegExp(r'^\d{14}$').hasMatch(v.trim()))
                return isAr
                    ? 'يجب أن يكون 14 رقم'
                    : 'Must be 14 digits';
              return null;
            },
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _pickDate(isBirth: true),
            child: InputDecorator(
              decoration: _inputDec(
                  isAr
                      ? 'تاريخ الميلاد *'
                      : 'Birth Date *',
                  Icons.calendar_today),
              child: Text(
                _birthDate == null
                    ? (isAr ? 'اختر التاريخ' : 'Select date')
                    : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: _birthDate == null
                        ? Colors.grey[600]
                        : Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _inputDec(
              isAr
                  ? 'رقم الموبايل * (للواتساب)'
                  : 'Mobile * (WhatsApp)',
              Icons.phone_android,
              suffix: Icons.chat,
              suffixColor: Colors.green,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty)
                return isAr
                    ? 'مطلوب - سيتم استخدامه للواتساب'
                    : 'Required - will be used for WhatsApp';
              final clean =
                  v.replaceAll(RegExp(r'\D'), '');
              if (clean.length < 10)
                return isAr ? 'رقم غير صحيح' : 'Invalid number';
              return null;
            },
            onChanged: (_) => _autoSuggestUsername(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone2Ctrl,
            keyboardType: TextInputType.phone,
            decoration: _inputDec(
                isAr
                    ? 'رقم موبايل آخر (اختياري)'
                    : 'Other Mobile (optional)',
                Icons.phone),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDec(
                isAr
                    ? 'البريد الإلكتروني (اختياري)'
                    : 'Email (optional)',
                Icons.email),
            validator: (v) {
              if (v != null &&
                  v.isNotEmpty &&
                  !v.contains('@'))
                return isAr
                    ? 'بريد غير صحيح'
                    : 'Invalid email';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    if (_loadingLookups) {
      return Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(isAr
                ? 'جاري تحميل البيانات...'
                : 'Loading data...'),
          ]));
    }
    if (_lookupError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 50),
                const SizedBox(height: 12),
                Text(
                    '${isAr ? 'خطأ' : 'Error'}: $_lookupError',
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                    onPressed: _loadLookups,
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.retry)),
              ]),
        ),
      );
    }
    return Form(
      key: _formKeyStep2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isAr ? 'بيانات الوظيفة' : 'Job Details',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kManagerColor),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'حدد الفرع والقسم والمسمى الوظيفي'
                : 'Select branch, department and job title',
            style:
                TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: _selectedBranchId,
            decoration: _inputDec(
                isAr ? 'الفرع *' : 'Branch *',
                Icons.business),
            items: _branches
                .map((b) => DropdownMenuItem<int>(
                    value: b['id'] as int,
                    child: Text(b['name_ar'] ?? '')))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedBranchId = v),
            validator: (v) =>
                v == null ? context.l10n.required : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedDepartmentId,
            decoration: _inputDec(
                isAr
                    ? 'القسم / الإدارة *'
                    : 'Department *',
                Icons.apartment),
            items: _departments
                .map((d) => DropdownMenuItem<int>(
                    value: d['id'] as int,
                    child: Text(d['name_ar'] ?? '')))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedDepartmentId = v),
            validator: (v) =>
                v == null ? context.l10n.required : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedJobTitleId,
            decoration: _inputDec(
                isAr ? 'المسمى الوظيفي *' : 'Job Title *',
                Icons.work),
            items: _jobTitles
                .map((j) => DropdownMenuItem<int>(
                    value: j['id'] as int,
                    child: Text(j['name_ar'] ?? '')))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedJobTitleId = v),
            validator: (v) =>
                v == null ? context.l10n.required : null,
          ),
          const SizedBox(height: 12),
          if (_employeesSimple.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _selectedManagerId,
              decoration: _inputDec(
                  isAr
                      ? 'المدير المباشر (اختياري)'
                      : 'Direct Manager (optional)',
                  Icons.supervisor_account),
              items: [
                DropdownMenuItem<int>(
                    value: null,
                    child: Text(isAr
                        ? 'بدون مدير مباشر'
                        : 'No direct manager')),
                ..._employeesSimple
                    .where((e) => e['is_manager'] == true)
                    .map((e) => DropdownMenuItem<int>(
                        value: e['id'] as int,
                        child: Text(
                            '${e['full_name']} - ${e['job_title'] ?? ''}'))),
              ],
              onChanged: (v) =>
                  setState(() => _selectedManagerId = v),
              isExpanded: true,
            ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _pickDate(isBirth: false),
            child: InputDecorator(
              decoration: _inputDec(
                  isAr ? 'تاريخ التعيين *' : 'Hire Date *',
                  Icons.date_range),
              child: Text(
                _hireDate == null
                    ? (isAr ? 'اختر التاريخ' : 'Select date')
                    : '${_hireDate!.year}-${_hireDate!.month.toString().padLeft(2, '0')}-${_hireDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: _hireDate == null
                        ? Colors.grey[600]
                        : Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _salaryCtrl,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true),
            decoration: _inputDec(
                isAr
                    ? 'الراتب الأساسي (اختياري)'
                    : 'Basic Salary (optional)',
                Icons.attach_money),
            validator: (v) {
              if (v != null &&
                  v.isNotEmpty &&
                  double.tryParse(v) == null)
                return isAr ? 'رقم غير صحيح' : 'Invalid number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: _inputDec(
                isAr ? 'العملة' : 'Currency',
                Icons.currency_exchange),
            items: _currencies
                .map((c) => DropdownMenuItem<String>(
                    value: c['code'],
                    child:
                        Text('${c['name']} (${c['code']})')))
                .toList(),
            onChanged: (v) {
              if (v != null)
                setState(() => _selectedCurrency = v);
            },
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: Colors.blue[200]!)),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                isAr
                    ? 'تأكد من البيانات قبل المتابعة\nعدد الفروع: ${_branches.length} | الأقسام: ${_departments.length} | المسميات: ${_jobTitles.length}'
                    : 'Verify data before continuing\nBranches: ${_branches.length} | Departments: ${_departments.length} | Titles: ${_jobTitles.length}',
                style: const TextStyle(
                    fontSize: 12, color: Colors.blueGrey),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Form(
      key: _formKeyStep3,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isAr ? 'بيانات حساب الدخول' : 'Login Credentials',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kManagerColor),
          ),
          const SizedBox(height: 4),
          Text(
            isAr
                ? 'سيتم استخدام هذه البيانات لتسجيل دخول الموظف'
                : 'These credentials will be used for employee login',
            style:
                TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _usernameCtrl,
            decoration: _inputDec(
              isAr
                  ? 'اسم المستخدم (اختياري - سيتم توليده تلقائيا)'
                  : 'Username (optional - auto-generated)',
              Icons.alternate_email,
              suffixText: 'auto',
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 3)
                return isAr ? 'قصير جداً' : 'Too short';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? '💡 إذا تركته فارغاً سيتم إنشاؤه تلقائيا من رقم الموبايل'
                : '💡 If left empty, it will be auto-generated from phone number',
            style: TextStyle(
                fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: isAr
                  ? 'كلمة المرور (اختياري - سيتم توليدها)'
                  : 'Password (optional - auto-generated)',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              prefixIcon:
                  Icon(Icons.lock, color: kManagerColor),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey),
                    onPressed: () => setState(() =>
                        _obscurePassword = !_obscurePassword),
                  ),
                  IconButton(
                    icon: Icon(Icons.auto_fix_high,
                        color: kManagerColor),
                    tooltip: isAr
                        ? 'توليد كلمة مرور'
                        : 'Generate password',
                    onPressed: _generateRandomPassword,
                  ),
                ],
              ),
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 6)
                return isAr
                    ? 'يجب أن تكون 6 أحرف على الأقل'
                    : 'Must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? '💡 كلمة المرور المؤقتة: Emp@ + آخر 4 أرقام الموبايل + رقم عشوائي'
                : '💡 Temp password: Emp@ + last 4 phone digits + random number',
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.4),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _employeeCodeCtrl,
            decoration: _inputDec(
                isAr
                    ? 'الرقم الوظيفي (اختياري - تلقائي)'
                    : 'Employee Code (optional - auto)',
                Icons.numbers),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? '💡 إذا تركته فارغاً سيتم توليده تلقائيا مثل EMP00001'
                : '💡 If empty, will be auto-generated like EMP00001',
            style: TextStyle(
                fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.security,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                        isAr
                            ? 'ملاحظة أمنية'
                            : 'Security Note',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? '• سيتم إجبار الموظف على تغيير كلمة المرور عند أول دخول\n• كلمة المرور ستظهر مرة واحدة فقط\n• احتفظ بملف PDF في مكان آمن'
                        : '• Employee will be forced to change password on first login\n• Password will appear only once\n• Keep PDF file in a safe place',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[900],
                        height: 1.5),
                  ),
                ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                      isAr
                          ? 'ملخص المراجعة'
                          : 'Review Summary',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  _reviewRow(
                      isAr ? 'الاسم:' : 'Name:',
                      '${_firstNameArCtrl.text} ${_middleNameArCtrl.text} ${_lastNameArCtrl.text}'
                          .trim()),
                  _reviewRow(
                      isAr
                          ? 'الموبايل:'
                          : 'Mobile:',
                      _phoneCtrl.text,
                      icon: Icons.chat,
                      iconColor: Colors.green),
                  _reviewRow(
                      isAr
                          ? 'الرقم القومي:'
                          : 'National ID:',
                      _nationalIdCtrl.text),
                  _reviewRow(
                      isAr ? 'الفرع:' : 'Branch:',
                      _branches
                          .firstWhere(
                              (b) =>
                                  b['id'] ==
                                  _selectedBranchId,
                              orElse: () =>
                                  {'name_ar': '-'})['name_ar']),
                  _reviewRow(
                      isAr ? 'القسم:' : 'Department:',
                      _departments
                          .firstWhere(
                              (d) =>
                                  d['id'] ==
                                  _selectedDepartmentId,
                              orElse: () =>
                                  {'name_ar': '-'})['name_ar']),
                  _reviewRow(
                      isAr ? 'المسمى:' : 'Job Title:',
                      _jobTitles
                          .firstWhere(
                              (j) =>
                                  j['id'] ==
                                  _selectedJobTitleId,
                              orElse: () =>
                                  {'name_ar': '-'})['name_ar']),
                  _reviewRow(
                      isAr
                          ? 'تاريخ التعيين:'
                          : 'Hire Date:',
                      _hireDate != null
                          ? '${_hireDate!.year}-${_hireDate!.month}-${_hireDate!.day}'
                          : '-'),
                ]),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    if (_createdEmployee == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_errorMessage != null) ...[
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text(
                      '${isAr ? 'خطأ' : 'Error'}: $_errorMessage',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.red)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                        _errorMessage = null;
                      });
                      _pageController.animateToPage(0,
                          duration:
                              const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.retry),
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(isAr
                      ? 'جاري إنشاء حساب الموظف...'
                      : 'Creating employee account...'),
                ],
              ]),
        ),
      );
    }

    final emp = _createdEmployee!;
    final cred = _createdCredentials!;
    final phone = emp['phone'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Colors.green, Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            const Icon(Icons.check_circle,
                color: Colors.white, size: 60),
            const SizedBox(height: 12),
            Text(
              isAr
                  ? 'تم إنشاء الموظف بنجاح! 🎉'
                  : 'Employee Created Successfully! 🎉',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text('${emp['full_name_ar']}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(
              '${isAr ? 'الرقم الوظيفي' : 'Employee Code'}: ${emp['employee_code']}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: kManagerColor.withOpacity(0.3),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8)
            ],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.vpn_key,
                      color: kManagerColor),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'بيانات الدخول' : 'Login Credentials',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kManagerColor),
                  ),
                ]),
                const SizedBox(height: 12),
                _credentialTile(context.l10n.username,
                    cred['username'] ?? '',
                    Icons.alternate_email, Colors.blue),
                const SizedBox(height: 8),
                _credentialTile(context.l10n.password,
                    cred['password'] ?? '', Icons.lock,
                    Colors.red, isSensitive: true),
                const SizedBox(height: 8),
                _credentialTile(
                    isAr ? 'رابط الدخول' : 'Login URL',
                    cred['login_url'] ??
                        'https://jssolutions-eg.com',
                    Icons.link,
                    Colors.green),
              ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _pdfPath != null
                ? Colors.green[50]
                : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _pdfPath != null
                    ? Colors.green[200]!
                    : Colors.orange[200]!),
          ),
          child: Row(children: [
            Icon(
                _pdfPath != null
                    ? Icons.picture_as_pdf
                    : Icons.hourglass_top,
                color: _pdfPath != null
                    ? Colors.green
                    : Colors.orange),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pdfPath != null
                          ? (isAr
                              ? 'تم إنشاء ملف PDF'
                              : 'PDF file created')
                          : (isAr
                              ? 'جاري إنشاء PDF...'
                              : 'Generating PDF...'),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _pdfPath != null
                              ? Colors.green[800]
                              : Colors.orange[800]),
                    ),
                    if (_pdfPath != null)
                      Text(_pdfPath!.split('/').last,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey)),
                  ]),
            ),
            if (_generatingPdf)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2)),
            if (_pdfPath != null)
              IconButton(
                icon: const Icon(Icons.open_in_new,
                    color: kPrimaryColor),
                tooltip:
                    isAr ? 'فتح PDF' : 'Open PDF',
                onPressed: () => OpenFile.open(_pdfPath!),
              ),
          ]),
        ),
        const SizedBox(height: 20),
        Text(
          isAr ? 'مشاركة بيانات الموظف' : 'Share Employee Data',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: (_pdfPath == null || _generatingPdf)
                ? null
                : _sharePdf,
            icon: const Icon(Icons.share, size: 24),
            label: Text(
              isAr ? 'مشاركة ملف PDF' : 'Share PDF File',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _openWhatsApp,
            icon: const Icon(Icons.chat, size: 28),
            label: Text(
              isAr
                  ? 'إرسال واتساب إلى $phone'
                  : 'Send WhatsApp to $phone',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check),
            label: Text(
              isAr
                  ? 'تم - العودة للوحة التحكم'
                  : 'Done - Back to Dashboard',
              style: const TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: kManagerColor,
              side: const BorderSide(color: kManagerColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _createdEmployee = null;
                _createdCredentials = null;
                _createdWhatsapp = null;
                _pdfPath = null;
                _currentStep = 0;
                _firstNameArCtrl.clear();
                _middleNameArCtrl.clear();
                _lastNameArCtrl.clear();
                _firstNameEnCtrl.clear();
                _lastNameEnCtrl.clear();
                _nationalIdCtrl.clear();
                _phoneCtrl.clear();
                _phone2Ctrl.clear();
                _emailCtrl.clear();
                _birthDate = null;
                _selectedBranchId = _branches.length == 1
                    ? _branches[0]['id']
                    : null;
                _selectedDepartmentId =
                    _departments.length == 1
                        ? _departments[0]['id']
                        : null;
                _selectedJobTitleId =
                    _jobTitles.length == 1
                        ? _jobTitles[0]['id']
                        : null;
                _selectedManagerId = null;
                _salaryCtrl.clear();
                _usernameCtrl.clear();
                _passwordCtrl.clear();
                _employeeCodeCtrl.clear();
                _hireDate = DateTime.now();
              });
              _pageController.animateToPage(0,
                  duration:
                      const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
            icon: const Icon(Icons.person_add),
            label: Text(
              isAr ? 'إنشاء موظف آخر' : 'Create Another Employee',
              style: const TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kManagerColor,
              side: const BorderSide(color: kManagerColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _credentialTile(String label, String value,
      IconData icon, Color color,
      {bool isSensitive = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSensitive ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isSensitive
                ? Colors.red[200]!
                : Colors.grey[300]!),
      ),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600])),
                const SizedBox(height: 2),
                SelectableText(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSensitive
                            ? Colors.red[800]
                            : Colors.black87)),
              ]),
        ),
      ]),
    );
  }

  Widget _reviewRow(String label, String value,
      {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: iconColor ?? Colors.grey),
          const SizedBox(width: 6)
        ],
        SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey))),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold))),
      ]),
    );
  }

  InputDecoration _inputDec(String label, IconData icon,
      {IconData? suffix,
      Color? suffixColor,
      String? suffixText}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, color: kManagerColor),
      suffixIcon: suffix != null
          ? Icon(suffix, color: suffixColor)
          : null,
      suffixText: suffixText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr =
        Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection:
          isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr
              ? 'إضافة موظف جديد'
              : 'Add New Employee'),
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_currentStep < 3)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  child: Text(
                    isAr
                        ? 'خطوة ${_currentStep + 1}/$_totalSteps'
                        : 'Step ${_currentStep + 1}/$_totalSteps',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70),
                  ),
                ),
              ),
          ],
        ),
        body: Column(children: [
          _buildStepIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(),
              onPageChanged: (i) =>
                  setState(() => _currentStep = i),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
          if (_currentStep < 3)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color:
                          Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -3))
                ],
              ),
              child: Row(children: [
                if (_currentStep > 0)
                  Expanded(
                      child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                              minimumSize:
                                  const Size(0, 52),
                              side: const BorderSide(
                                  color: kManagerColor),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          12))),
                          child:
                              Text(context.l10n.back))),
                if (_currentStep > 0)
                  const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _creating
                        ? null
                        : (_currentStep == 2
                            ? _createEmployee
                            : _nextStep),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kManagerColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12)),
                    ),
                    child: _creating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2))
                        : Text(
                            _currentStep == 2
                                ? (isAr
                                    ? 'إنشاء الموظف ✓'
                                    : 'Create Employee ✓')
                                : (isAr
                                    ? 'التالي →'
                                    : 'Next →'),
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold),
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