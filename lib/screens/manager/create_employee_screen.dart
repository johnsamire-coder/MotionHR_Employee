// lib/screens/manager/create_employee_screen.dart
// Phase 8 - Manager creates employee from app + PDF + WhatsApp share

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
  State<CreateEmployeeScreen> createState() => _CreateEmployeeScreenState();
}

class _CreateEmployeeScreenState extends State<CreateEmployeeScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // ── Form Keys ──
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();
  // ── Step 1: Personal Info Controllers ──
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

  // ── Step 2: Job Info ──
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
final List<Map<String, String>> _currencies = [
  {'code': 'EGP', 'name': 'جنيه مصري'},
  {'code': 'USD', 'name': 'دولار أمريكي'},
  {'code': 'SAR', 'name': 'ريال سعودي'},
  {'code': 'AED', 'name': 'درهم إماراتي'},
];
  bool _loadingLookups = true;
  String? _lookupError;
  // ── Step 3: Account Info ──
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _employeeCodeCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _autoGeneratePassword = true;

  // ── Step 4: Result ──
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
    // Auto-generate username/password hint
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
        // Auto-select first if only one
        if (_branches.length == 1) _selectedBranchId = _branches[0]['id'];
        if (_departments.length == 1) _selectedDepartmentId = _departments[0]['id'];
        if (_jobTitles.length == 1) _selectedJobTitleId = _jobTitles[0]['id'];
      });
    } catch (e) {
      setState(() {
        _lookupError = e.toString();
        _loadingLookups = false;
      });
    }
  }

  // ── Validation Helpers ──
  bool _validateStep1() {
    if (!(_formKeyStep1.currentState?.validate() ?? false)) return false;
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار تاريخ الميلاد'), backgroundColor: Colors.orange),
      );
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_selectedBranchId == null || _selectedDepartmentId == null || _selectedJobTitleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار الفرع والقسم والمسمى الوظيفي'), backgroundColor: Colors.orange),
      );
      return false;
    }
    if (_hireDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('يرجى اختيار تاريخ التعيين'), backgroundColor: Colors.orange),
      );
      return false;
    }
    return _formKeyStep2.currentState?.validate() ?? false;
  }

  bool _validateStep3() {
    return _formKeyStep3.currentState?.validate() ?? false;
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && !_validateStep2()) return;
    if (_currentStep == 2 && !_validateStep3()) return;

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _generateRandomPassword() {
    final phone = _phoneCtrl.text.trim();
    String suffix = '';
    if (phone.length >= 4) {
      suffix = phone.substring(phone.length - 4);
    } else {
      suffix = '1234';
    }
    final random = (100 + (DateTime.now().millisecond % 900)).toString();
    _passwordCtrl.text = 'Emp@$suffix$random';
    setState(() => _autoGeneratePassword = false);
  }
  void _autoSuggestUsername() {
    final first = _firstNameEnCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    final last = _lastNameEnCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (first.isNotEmpty && last.isNotEmpty) {
      _usernameCtrl.text = '$first$last';
    } else if (first.isNotEmpty) {
      final phone = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');
      _usernameCtrl.text = phone.length >= 4 ? '$first${phone.substring(phone.length - 4)}' : first;
    }
  }
  Future<void> _pickDate({required bool isBirth}) async {
    final initial = isBirth ? DateTime(1995, 1, 1) : DateTime.now();
    final first = isBirth ? DateTime(1960) : DateTime(2020);
    final last = isBirth ? DateTime.now().subtract(const Duration(days: 365 * 16)) : DateTime.now().add(const Duration(days: 365));
    final picked = await showDatePicker(
      context: context,
      initialDate: isBirth ? (_birthDate ?? initial) : (_hireDate ?? initial),
      firstDate: first,
      lastDate: last,
      locale: const Locale('ar'),
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
    try {      final result = await EmployeeManagementService.createEmployee(
        firstNameAr: _firstNameArCtrl.text.trim(),
        middleNameAr: _middleNameArCtrl.text.trim(),
        lastNameAr: _lastNameArCtrl.text.trim(),
        firstNameEn: _firstNameEnCtrl.text.trim(),
        lastNameEn: _lastNameEnCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        phone2: _phone2Ctrl.text.trim().isEmpty ? null : _phone2Ctrl.text.trim(),
        nationalId: _nationalIdCtrl.text.trim(),
        birthDate: _birthDate!.toIso8601String().split('T')[0],
        gender: _gender,
        hireDate: _hireDate!.toIso8601String().split('T')[0],
        branchId: _selectedBranchId!,
        departmentId: _selectedDepartmentId!,
        jobTitleId: _selectedJobTitleId!,
        directManagerId: _selectedManagerId,
        basicSalary: double.tryParse(_salaryCtrl.text.trim()),
        currency: _selectedCurrency,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim().isEmpty ? null : _usernameCtrl.text.trim(),
        password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text.trim(),
        employeeCode: _employeeCodeCtrl.text.trim().isEmpty ? null : _employeeCodeCtrl.text.trim(),
      );

      setState(() {
        _createdEmployee = result['employee'];
        _createdCredentials = result['credentials'];
        _createdWhatsapp = result['whatsapp'];
        _creating = false;
        _currentStep = 3;
      });
      _pageController.animateToPage(3, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);

      // Auto-generate PDF
      await _generatePdf();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'تم إنشاء الموظف بنجاح'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() {
        _creating = false;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  Future<void> _generatePdf() async {
    if (_createdEmployee == null || _createdCredentials == null) return;
    setState(() => _generatingPdf = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final companyName = prefs.getString('company_name') ?? _createdEmployee!['company'] ?? '';

      // جلب بيانات الشركة الكاملة (لوجو + عنوان + هاتف)
      String? logoUrl;
      String? phone;
      String? address;
      try {
        final companyInfo = await EmployeeManagementService.getCompanyInfo();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في توليد PDF: $e'), backgroundColor: Colors.orange),
        );
      }
    }
  }
  Future<void> _sharePdf() async {
    if (_pdfPath == null) {
      await _generatePdf();
    }
    if (_pdfPath == null) return;
    try {
      await EmployeePdfService.sharePdf(
        _pdfPath!,
        phone: _createdEmployee?['phone'],
        employeeName: _createdEmployee?['full_name_ar'],
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في المشاركة: $e')));
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final phone = _createdEmployee?['phone'] ?? _whatsappPhone;
    if (phone == null || phone.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('رقم الموبايل غير متوفر')));
      return;
    }
    final name = _createdEmployee?['full_name_ar'] ?? '';
    final username = _createdCredentials?['username'] ?? '';
    final password = _createdCredentials?['password'] ?? '';
    final message = '''مرحبا $name 👋

تم إنشاء حسابك في نظام MotionHR

🔹 اسم المستخدم: $username
🔹 كلمة المرور: $password

📎 الملف المرفق يحتوي على بيانات الدخول الكاملة

يرجى تحميل تطبيق MotionHR وتسجيل الدخول، وستحتاج لتغيير كلمة المرور عند أول دخول.

شكرا لك!''';

    try {
      await EmployeePdfService.openWhatsApp(phone, message: message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _shareViaWhatsAppWithPdf() async {
    if (_pdfPath == null) {
      await _generatePdf();
    }
    if (_pdfPath == null) return;
    // First open share sheet for PDF
    await _sharePdf();
    // Small delay then open WhatsApp chat
    await Future.delayed(const Duration(milliseconds: 800));
    // Optionally open WhatsApp as well (user can choose)
  }

  String get _whatsappPhone => _phoneCtrl.text.trim();

  // ── UI Helpers ──
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: List.generate(_totalSteps, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 6 : 0),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive ? kManagerColor : Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    _getStepTitle(index),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? kManagerColor : isCompleted ? Colors.green : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int index) {
    switch (index) {
      case 0:
        return 'البيانات الشخصية';
      case 1:
        return 'الوظيفة';
      case 2:
        return 'الحساب';
      case 3:
        return 'المشاركة';
      default:
        return '';
    }
  }

  // ── Step Widgets ──
  Widget _buildStep1() {
    return Form(
      key: _formKeyStep1,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('البيانات الشخصية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kManagerColor)),
          SizedBox(height: 4),
          const Text('أدخل بيانات الموظف الأساسية', style: TextStyle(color: Colors.grey, fontSize: 13)),
          SizedBox(height: 20),
          TextFormField(
            controller: _firstNameArCtrl,
            decoration: _inputDec('الاسم الأول بالعربي *', Icons.person),
            validator: (v) => (v == null || v.trim().length < 2) ? 'مطلوب (حرفين على الأقل)' : null,
            onChanged: (_) => _autoSuggestUsername(),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _middleNameArCtrl,
            decoration: _inputDec('الاسم الأوسط (اختياري)', Icons.person_outline),
          ),
          SizedBox(height: 12),
                    TextFormField(
            controller: _lastNameArCtrl,
            decoration: _inputDec('الاسم الأخير بالعربي *', Icons.person),
            validator: (v) => (v == null || v.trim().length < 2) ? context.l10n.required : null,
          ),
          SizedBox(height: 16),

          // ── الاسم بالإنجليزي ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الاسم بالإنجليزي مطلوب لتوليد اسم المستخدم تلقائياً',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _firstNameEnCtrl,
            decoration: _inputDec('الاسم الأول بالإنجليزي *', Icons.person),
            keyboardType: TextInputType.name,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ],
            validator: (v) => (v == null || v.trim().length < 2) ? 'مطلوب بالإنجليزي' : null,
            onChanged: (_) => _autoSuggestUsername(),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _lastNameEnCtrl,
            decoration: _inputDec('الاسم الأخير بالإنجليزي *', Icons.person),
            keyboardType: TextInputType.name,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ],
            validator: (v) => (v == null || v.trim().length < 2) ? 'مطلوب بالإنجليزي' : null,
            onChanged: (_) => _autoSuggestUsername(),
          ),
          SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _gender,
            decoration: _inputDec('النوع *', Icons.wc),
            items: [
              DropdownMenuItem(value: 'male', child: Text(context.l10n.male)),
              DropdownMenuItem(value: 'female', child: Text(context.l10n.female)),
            ],
            onChanged: (v) => setState(() => _gender = v ?? 'male'),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _nationalIdCtrl,
            keyboardType: TextInputType.number,
            maxLength: 14,
            decoration: _inputDec('الرقم القومي * (14 رقم)', Icons.badge),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return context.l10n.required;
              if (!RegExp(r'^\d{14}$').hasMatch(v.trim())) return 'يجب أن يكون 14 رقم';
              return null;
            },
          ),
          SizedBox(height: 12),
          InkWell(
            onTap: () => _pickDate(isBirth: true),
            child: InputDecorator(
              decoration: _inputDec('تاريخ الميلاد *', Icons.calendar_today),
              child: Text(
                _birthDate == null ? 'اختر التاريخ' : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(color: _birthDate == null ? Colors.grey[600] : Colors.black),
              ),
            ),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _inputDec('رقم الموبايل * (للواتساب)', Icons.phone_android, suffix: Icons.chat, suffixColor: Colors.green),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'مطلوب - سيتم استخدامه للواتساب';
              final clean = v.replaceAll(RegExp(r'\D'), '');
              if (clean.length < 10) return 'رقم غير صحيح';
              return null;
            },
            onChanged: (_) => _autoSuggestUsername(),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _phone2Ctrl,
            keyboardType: TextInputType.phone,
            decoration: _inputDec('رقم موبايل آخر (اختياري)', Icons.phone),
          ),
          SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDec('البريد الإلكتروني (اختياري)', Icons.email),
            validator: (v) {
              if (v != null && v.isNotEmpty && !v.contains('@')) return 'بريد غير صحيح';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    if (_loadingLookups) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 12), Text('جاري تحميل البيانات...')]));
    }
    if (_lookupError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 50),
              SizedBox(height: 12),
              Text('خطأ: $_lookupError', textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _loadLookups, icon: Icon(Icons.refresh), label: Text(context.l10n.retry)),
            ],
          ),
        ),
      );
    }
    return Form(
      key: _formKeyStep2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('بيانات الوظيفة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kManagerColor)),
          SizedBox(height: 4),
          const Text('حدد الفرع والقسم والمسمى الوظيفي', style: TextStyle(color: Colors.grey, fontSize: 13)),
          SizedBox(height: 20),
          // Branch
          DropdownButtonFormField<int>(
            value: _selectedBranchId,
            decoration: _inputDec('الفرع *', Icons.business),
            items: _branches.map((b) => DropdownMenuItem<int>(value: b['id'] as int, child: Text(b['name_ar'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _selectedBranchId = v),
            validator: (v) => v == null ? context.l10n.required : null,
          ),
          SizedBox(height: 12),
          // Department
          DropdownButtonFormField<int>(
            value: _selectedDepartmentId,
            decoration: _inputDec('القسم / الإدارة *', Icons.apartment),
            items: _departments.map((d) => DropdownMenuItem<int>(value: d['id'] as int, child: Text(d['name_ar'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _selectedDepartmentId = v),
            validator: (v) => v == null ? context.l10n.required : null,
          ),
          SizedBox(height: 12),
          // Job Title
          DropdownButtonFormField<int>(
            value: _selectedJobTitleId,
            decoration: _inputDec('المسمى الوظيفي *', Icons.work),
            items: _jobTitles.map((j) => DropdownMenuItem<int>(value: j['id'] as int, child: Text(j['name_ar'] ?? ''))).toList(),
            onChanged: (v) => setState(() => _selectedJobTitleId = v),
            validator: (v) => v == null ? context.l10n.required : null,
          ),
          SizedBox(height: 12),
          // Direct Manager
          if (_employeesSimple.isNotEmpty)
            DropdownButtonFormField<int>(
              value: _selectedManagerId,
              decoration: _inputDec('المدير المباشر (اختياري)', Icons.supervisor_account),          items: [
                const DropdownMenuItem<int>(value: null, child: Text('بدون مدير مباشر')),
                ..._employeesSimple.where((e) => e['is_manager'] == true).map((e) => DropdownMenuItem<int>(value: e['id'] as int, child: Text('${e['full_name']} - ${e['job_title'] ?? ''}'))),
              ],

              onChanged: (v) => setState(() => _selectedManagerId = v),
              isExpanded: true,
            ),
          SizedBox(height: 16),
          InkWell(
            onTap: () => _pickDate(isBirth: false),
            child: InputDecorator(
              decoration: _inputDec('تاريخ التعيين *', Icons.date_range),
              child: Text(
                _hireDate == null ? 'اختر التاريخ' : '${_hireDate!.year}-${_hireDate!.month.toString().padLeft(2, '0')}-${_hireDate!.day.toString().padLeft(2, '0')}',
                style: TextStyle(color: _hireDate == null ? Colors.grey[600] : Colors.black),
              ),
            ),
          ),
          SizedBox(height: 12),          TextFormField(
            controller: _salaryCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDec('الراتب الأساسي (اختياري)', Icons.attach_money),
            validator: (v) {
              if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'رقم غير صحيح';
              return null;
            },
          ),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedCurrency,
            decoration: _inputDec('العملة', Icons.currency_exchange),
            items: _currencies.map((c) {
              return DropdownMenuItem<String>(
                value: c['code'],
                child: Text('${c['name']} (${c['code']})'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCurrency = value);
              }
            },
          ),
          SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue[200]!)),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('تأكد من البيانات قبل المتابعة\nعدد الفروع: ${_branches.length} | الأقسام: ${_departments.length} | المسميات: ${_jobTitles.length}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey))),
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
          const Text('بيانات حساب الدخول', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kManagerColor)),
          SizedBox(height: 4),
          const Text('سيتم استخدام هذه البيانات لتسجيل دخول الموظف', style: TextStyle(color: Colors.grey, fontSize: 13)),
          SizedBox(height: 20),
          TextFormField(
            controller: _usernameCtrl,
            decoration: _inputDec('اسم المستخدم (اختياري - سيتم توليده تلقائيا)', Icons.alternate_email, suffixText: 'auto'),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 3) return 'قصير جداً';
              return null;
            },
          ),
          SizedBox(height: 8),
          Text(
            '💡 إذا تركته فارغاً سيتم إنشاؤه تلقائيا من رقم الموبايل: emp + آخر 7 أرقام',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'كلمة المرور (اختياري - سيتم توليدها)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: Icon(Icons.lock, color: kManagerColor),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  IconButton(
                    icon: Icon(Icons.auto_fix_high, color: kManagerColor),
                    tooltip: 'توليد كلمة مرور',
                    onPressed: _generateRandomPassword,
                  ),
                ],
              ),
            ),
            validator: (v) {
              if (v != null && v.isNotEmpty && v.length < 6) return 'يجب أن تكون 6 أحرف على الأقل';
              return null;
            },
          ),
          SizedBox(height: 8),
          Text(
            '💡 كلمة المرور المؤقتة: Emp@ + آخر 4 أرقام الموبايل + رقم عشوائي\nمثال: Emp@5678 12 - الموظف سيغيرها عند أول دخول',
            style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _employeeCodeCtrl,
            decoration: _inputDec('الرقم الوظيفي (اختياري - تلقائي)', Icons.numbers),
          ),
          SizedBox(height: 8),
          Text(
            '💡 إذا تركته فارغاً سيتم توليده تلقائيا مثل EMP00001',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.security, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text('ملاحظة أمنية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ]),
                SizedBox(height: 8),
                Text(
                  '• سيتم إجبار الموظف على تغيير كلمة المرور عند أول دخول\n• كلمة المرور ستظهر مرة واحدة فقط في هذه الشاشة ثم في ملف PDF\n• احتفظ بملف PDF في مكان آمن وشاركه فقط مع الموظف عبر الواتساب',
                  style: TextStyle(fontSize: 12, color: Colors.orange[900], height: 1.5),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          // Review Summary
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ملخص المراجعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 12),
                _reviewRow('الاسم:', '${_firstNameArCtrl.text} ${_middleNameArCtrl.text} ${_lastNameArCtrl.text}'.trim()),
                _reviewRow('الموبايل (واتساب):', _phoneCtrl.text, icon: Icons.chat, iconColor: Colors.green),
                _reviewRow('الرقم القومي:', _nationalIdCtrl.text),
                _reviewRow('الفرع:', _branches.firstWhere((b) => b['id'] == _selectedBranchId, orElse: () => {'name_ar': '-'})['name_ar']),
                _reviewRow('القسم:', _departments.firstWhere((d) => d['id'] == _selectedDepartmentId, orElse: () => {'name_ar': '-'})['name_ar']),
                _reviewRow('المسمى:', _jobTitles.firstWhere((j) => j['id'] == _selectedJobTitleId, orElse: () => {'name_ar': '-'})['name_ar']),
                _reviewRow('تاريخ التعيين:', _hireDate != null ? '${_hireDate!.year}-${_hireDate!.month}-${_hireDate!.day}' : '-'),
              ],
            ),
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
                Icon(Icons.error_outline, color: Colors.red, size: 60),
                SizedBox(height: 16),
                Text('خطأ: $_errorMessage', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _currentStep = 0;
                      _errorMessage = null;
                    });
                    _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  icon: Icon(Icons.refresh),
                  label: Text(context.l10n.retry),
                ),
              ] else ...[
                const CircularProgressIndicator(),
                SizedBox(height: 16),
                const Text('جاري إنشاء حساب الموظف...'),
              ],
            ],
          ),
        ),
      );
    }

    final emp = _createdEmployee!;
    final cred = _createdCredentials!;
    final phone = emp['phone'] ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Success Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.green, Color(0xFF2E7D32)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 60),
              SizedBox(height: 12),
              const Text('تم إنشاء الموظف بنجاح! 🎉', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text('${emp['full_name_ar']}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('الرقم الوظيفي: ${emp['employee_code']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
        SizedBox(height: 20),
        // Credentials Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kManagerColor.withOpacity(0.3), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.vpn_key, color: kManagerColor),
                SizedBox(width: 8),
                Text('بيانات الدخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kManagerColor)),
              ]),
              SizedBox(height: 12),
              _credentialTile(context.l10n.username, cred['username'] ?? '', Icons.alternate_email, Colors.blue),
              SizedBox(height: 8),
              _credentialTile(context.l10n.password, cred['password'] ?? '', Icons.lock, Colors.red, isSensitive: true),
              SizedBox(height: 8),
              _credentialTile('رابط الدخول', cred['login_url'] ?? 'https://jssolutions-eg.com', Icons.link, Colors.green),
            ],
          ),
        ),
        SizedBox(height: 16),
        // PDF Status
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _pdfPath != null ? Colors.green[50] : Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _pdfPath != null ? Colors.green[200]! : Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(_pdfPath != null ? Icons.picture_as_pdf : Icons.hourglass_top, color: _pdfPath != null ? Colors.green : Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_pdfPath != null ? 'تم إنشاء ملف PDF' : 'جاري إنشاء PDF...', style: TextStyle(fontWeight: FontWeight.bold, color: _pdfPath != null ? Colors.green[800] : Colors.orange[800])),
                    if (_pdfPath != null) Text(_pdfPath!.split('/').last, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              if (_generatingPdf) SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              if (_pdfPath != null)
                IconButton(
                  icon: Icon(Icons.open_in_new, color: kPrimaryColor),
                  tooltip: 'فتح PDF',
                  onPressed: () => OpenFile.open(_pdfPath!),
                ),
            ],
          ),
        ),
        SizedBox(height: 20),
        // Share Buttons
        const Text('مشاركة بيانات الموظف', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 12),
        // Share PDF button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: (_pdfPath == null || _generatingPdf) ? null : _sharePdf,
            icon: Icon(Icons.share, size: 24),
            label: const Text('مشاركة ملف PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(height: 12),
        // WhatsApp button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _openWhatsApp,
            icon: Icon(Icons.chat, size: 28),
            label: Text('إرسال واتساب إلى $phone', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF25D366),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(height: 12),
        // Share PDF + WhatsApp combined
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: (_pdfPath == null || _generatingPdf) ? null : _shareViaWhatsAppWithPdf,
            icon: Icon(Icons.picture_as_pdf, size: 24),
            label: const Text('مشاركة PDF عبر واتساب (اختار واتساب من القائمة)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kManagerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue[200]!)),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text('• اضغط "مشاركة PDF" واختار واتساب من قائمة المشاركة لإرسال الملف\n• أو اضغط "إرسال واتساب" لفتح محادثة واتساب مباشرة مع الموظف\n• الملف يحتوي على بيانات الدخول كاملة', style: TextStyle(fontSize: 12, height: 1.4))),
            ],
          ),
        ),
        SizedBox(height: 24),
        // Done button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              // Go back to dashboard or create another
              Navigator.pop(context, true);
            },
            icon: Icon(Icons.check),
            label: const Text('تم - العودة للوحة التحكم', style: TextStyle(fontSize: 16)),
            style: OutlinedButton.styleFrom(
              foregroundColor: kManagerColor,
              side: const BorderSide(color: kManagerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              // Reset for new employee
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
                _selectedBranchId = _branches.length == 1 ? _branches[0]['id'] : null;
                _selectedDepartmentId = _departments.length == 1 ? _departments[0]['id'] : null;
                _selectedJobTitleId = _jobTitles.length == 1 ? _jobTitles[0]['id'] : null;
                _selectedManagerId = null;
                _salaryCtrl.clear();
                _usernameCtrl.clear();
                _passwordCtrl.clear();
                _employeeCodeCtrl.clear();
                _hireDate = DateTime.now();
              });
              _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            icon: Icon(Icons.person_add),
            label: const Text('إنشاء موظف آخر', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: kManagerColor,
              side: const BorderSide(color: kManagerColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Widget _credentialTile(String label, String value, IconData icon, Color color, {bool isSensitive = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSensitive ? Colors.red[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSensitive ? Colors.red[200]! : Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                SizedBox(height: 2),
                SelectableText(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSensitive ? Colors.red[800] : Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value, {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: iconColor ?? Colors.grey), SizedBox(width: 6)],
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon, {IconData? suffix, Color? suffixColor, String? suffixText}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, color: kManagerColor),
      suffixIcon: suffix != null ? Icon(suffix, color: suffixColor) : null,
      suffixText: suffixText,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة موظف جديد'),
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (_currentStep < 3)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('خطوة ${_currentStep + 1}/$_totalSteps', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                  _buildStep4(),
                ],
              ),
            ),
            // Bottom Navigation
            if (_currentStep < 3)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -3))]),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(child: OutlinedButton(onPressed: _prevStep, style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), side: const BorderSide(color: kManagerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(context.l10n.back))),
                    if (_currentStep > 0) SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _creating ? null : (_currentStep == 2 ? _createEmployee : _nextStep),
                        style: ElevatedButton.styleFrom(backgroundColor: kManagerColor, foregroundColor: Colors.white, minimumSize: const Size(0, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: _creating
                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(_currentStep == 2 ? 'إنشاء الموظف ✓' : 'التالي →', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
