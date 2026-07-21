// lib/services/employee_management_service.dart
// Phase 15: Create employee - Full fields

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class EmployeeManagementService {
  static const String baseUrl = 'https://jssolutions-eg.com';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('auth_token');
  }

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      };

  // ── BRANCHES ──
  static Future<List<Map<String, dynamic>>> getBranches() async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/branches/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true)
        return List<Map<String, dynamic>>.from(data['branches'] ?? []);
      throw Exception(data['error'] ?? 'خطأ في جلب الفروع');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── DEPARTMENTS ──
  static Future<List<Map<String, dynamic>>> getDepartments() async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/departments/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true)
        return List<Map<String, dynamic>>.from(data['departments'] ?? []);
      throw Exception(data['error'] ?? 'خطأ في جلب الأقسام');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── JOB TITLES ──
  static Future<List<Map<String, dynamic>>> getJobTitles() async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/job-titles/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true)
        return List<Map<String, dynamic>>.from(data['job_titles'] ?? []);
      throw Exception(data['error'] ?? 'خطأ في جلب المسميات');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── COMPANY INFO ──
  static Future<Map<String, dynamic>> getCompanyInfo() async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/company-info/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true)
        return Map<String, dynamic>.from(data['company'] ?? {});
      throw Exception(data['error'] ?? 'خطأ في جلب بيانات الشركة');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── UPDATE COMPANY INFO ──
  static Future<bool> updateCompanyInfo(Map<String, dynamic> data) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.patch(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/company-info/update/'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (res.statusCode == 200 || res.statusCode == 204) return true;
    throw Exception('Status: ${res.statusCode} | Body: ${res.body}');
  }

  // ── UPLOAD COMPANY LOGO ──
  static Future<bool> uploadCompanyLogo(String filePath) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/attendance/api/mobile/manager/company-info/upload-logo/'),
    );
    request.headers['Authorization'] = 'Token $token';
    request.headers['Accept'] = 'application/json';
    final ext = filePath.split('.').last.toLowerCase();
    final mimeType = ext == 'png'
        ? 'image/png'
        : ext == 'gif'
            ? 'image/gif'
            : ext == 'webp'
                ? 'image/webp'
                : 'image/jpeg';
    request.files.add(await http.MultipartFile.fromPath(
      'logo',
      filePath,
      contentType: MediaType('image', mimeType.split('/').last),
    ));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        response.statusCode == 204) return true;
    throw Exception('Status: ${response.statusCode} | Body: ${response.body}');
  }

  // ── EMPLOYEES SIMPLE ──
  static Future<List<Map<String, dynamic>>> getEmployeesSimple() async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/employees/simple/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true)
        return List<Map<String, dynamic>>.from(data['employees'] ?? []);
      throw Exception(data['error'] ?? 'خطأ في جلب الموظفين');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }

  // ── CREATE EMPLOYEE (Full Phase 15) ──
  static Future<Map<String, dynamic>> createEmployee({
    // Personal
    required String firstNameAr,
    String? middleNameAr,
    required String lastNameAr,
    required String firstNameEn,
    required String lastNameEn,
    required String nationalId,
    required String birthDate,
    required String gender,
    String? nationality,
    String? maritalStatus,
    String? religion,
    // Contact
    required String phone,
    String? dialCode,
    String? phone2,
    String? email,
    String? address,
    String? city,
    String? country,
    String? emergencyContactName,
    String? emergencyContactRelation,
    String? emergencyContactPhone,
    // Job
    required String hireDate,
    required int branchId,
    required int departmentId,
    required int jobTitleId,
    int? directManagerId,
    String? contractType,
    String? contractEndDate,
    bool? hasInsurance,
    String? insuranceNumber,
    // Financial
    double? basicSalary,
    String? currency,
    String? salaryPaymentMethod,
    String? bankName,
    String? bankAccount,
    String? iban,
    String? instapayPhone,
    String? walletPhone,
    String? walletProvider,
    // Account
    String? username,
    String? password,
    String? employeeCode,
    String? language,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');

    final body = <String, dynamic>{
      'first_name_ar': firstNameAr,
      'last_name_ar': lastNameAr,
      'first_name_en': firstNameEn,
      'last_name_en': lastNameEn,
      'national_id': nationalId,
      'birth_date': birthDate,
      'gender': gender,
      'hire_date': hireDate,
      'branch_id': branchId,
      'department_id': departmentId,
      'job_title_id': jobTitleId,
      'language': language ?? 'ar',
    };

    // Personal optional
    if (middleNameAr != null && middleNameAr.isNotEmpty)
      body['middle_name_ar'] = middleNameAr;
    if (nationality != null && nationality.isNotEmpty)
      body['nationality'] = nationality;
    if (maritalStatus != null && maritalStatus.isNotEmpty)
      body['marital_status'] = maritalStatus;
    if (religion != null && religion.isNotEmpty)
      body['religion'] = religion;

    // Contact
    body['phone'] = (dialCode != null && dialCode.isNotEmpty)
        ? '$dialCode${phone.replaceAll(RegExp(r'^0+'), '')}'
        : phone;
    if (phone2 != null && phone2.isNotEmpty) body['phone2'] = phone2;
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (city != null && city.isNotEmpty) body['city'] = city;
    if (country != null && country.isNotEmpty) body['country'] = country;
    if (emergencyContactName != null && emergencyContactName.isNotEmpty)
      body['emergency_contact_name'] = emergencyContactName;
    if (emergencyContactRelation != null && emergencyContactRelation.isNotEmpty)
      body['emergency_contact_relation'] = emergencyContactRelation;
    if (emergencyContactPhone != null && emergencyContactPhone.isNotEmpty)
      body['emergency_contact_phone'] = emergencyContactPhone;

    // Job
    if (directManagerId != null) body['direct_manager_id'] = directManagerId;
    if (contractType != null && contractType.isNotEmpty)
      body['contract_type'] = contractType;
    if (contractEndDate != null && contractEndDate.isNotEmpty)
      body['contract_end_date'] = contractEndDate;
    if (hasInsurance != null) body['has_insurance'] = hasInsurance;
    if (insuranceNumber != null && insuranceNumber.isNotEmpty)
      body['insurance_number'] = insuranceNumber;

    // Financial
    if (basicSalary != null) body['basic_salary'] = basicSalary;
    if (currency != null && currency.isNotEmpty) body['currency'] = currency;
    if (salaryPaymentMethod != null && salaryPaymentMethod.isNotEmpty)
      body['salary_payment_method'] = salaryPaymentMethod;
    if (bankName != null && bankName.isNotEmpty) body['bank_name'] = bankName;
    if (bankAccount != null && bankAccount.isNotEmpty)
      body['bank_account'] = bankAccount;
    if (iban != null && iban.isNotEmpty) body['iban'] = iban;
    if (instapayPhone != null && instapayPhone.isNotEmpty)
      body['instapay_phone'] = instapayPhone;
    if (walletPhone != null && walletPhone.isNotEmpty)
      body['wallet_phone'] = walletPhone;
    if (walletProvider != null && walletProvider.isNotEmpty)
      body['wallet_provider'] = walletProvider;

    // Account
    if (username != null && username.isNotEmpty) body['username'] = username;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (employeeCode != null && employeeCode.isNotEmpty)
      body['employee_code'] = employeeCode;

    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/employees/create/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );

    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 201 || res.statusCode == 200) {
      if (data['success'] == true) return data;
    }
    throw Exception(
        data['error'] ?? data['message'] ?? 'فشل إنشاء الموظف (${res.statusCode})');
  }

  // ── TRANSFER EMPLOYEE ──
  static Future<Map<String, dynamic>> transferEmployee({
    required int employeeId,
    int? newManagerId,
    int? newBranchId,
    int? newDepartmentId,
    int? newJobTitleId,
    String? reason,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final body = <String, dynamic>{};
    if (newManagerId != null) body['new_manager_id'] = newManagerId;
    if (newBranchId != null) body['new_branch_id'] = newBranchId;
    if (newDepartmentId != null) body['new_department_id'] = newDepartmentId;
    if (newJobTitleId != null) body['new_job_title_id'] = newJobTitleId;
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    final res = await http.post(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/employees/$employeeId/transfer/'),
      headers: _headers(token),
      body: jsonEncode(body),
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode == 200 && data['success'] == true)
      return Map<String, dynamic>.from(data);
    throw Exception(data['error'] ?? 'فشل نقل الموظف');
  }

  // ── ORGANIZATION TREE ──
  static Future<Map<String, dynamic>> getOrganizationTree() async {
    final token = await _getToken();
    if (token == null) throw Exception('غير مسجل الدخول');
    final res = await http.get(
      Uri.parse('$baseUrl/attendance/api/mobile/manager/organization-tree/'),
      headers: _headers(token),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data['success'] == true) return Map<String, dynamic>.from(data);
      throw Exception(data['error'] ?? 'خطأ في جلب الهيكل التنظيمي');
    }
    throw Exception('خطأ: ${res.statusCode}');
  }
}
