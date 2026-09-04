import 'package:motionhr_employee/services/api_client.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motionhr_employee/services/employee_pdf_service.dart';
import 'employee_movements_screen.dart';
import 'employee_documents_screen.dart';
import 'employee_summary_screen.dart';
import 'employee_payslip_screen.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});
  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('username') ?? '';
    try {
      final response = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/employee/profile/'),
        headers: await ApiClient.buildHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() {
          _profile = json.decode(utf8.decode(response.bodyBytes));
          _username = savedUsername;
          _loading = false;
        });
      } else {
        setState(() {
          _username = savedUsername;
          _error = 'تعذر تحميل البيانات (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _username = savedUsername;
        _error = 'خطأ في الاتصال';
        _loading = false;
      });
    }
  }

  Widget _infoRow(String label, dynamic value, {IconData? icon}) {
    final displayValue = (value == null || value.toString().isEmpty) ? '-' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 130,
            child: Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(displayValue,
              style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final photo = _profile!['photo'];
    final name = _profile!['full_name_ar'] ?? '';
    final code = _profile!['employee_code'] ?? '';
    final jobTitle = _profile!['job_title'] ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A3E), Color(0xFF1A0A3E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              backgroundImage: (photo != null && photo.toString().isNotEmpty)
                  ? NetworkImage('https://jssolutions-eg.com$photo')
                  : null,
              child: (photo == null || photo.toString().isEmpty)
                  ? const Icon(Icons.person, size: 50, color: Color(0xFF1A0A3E))
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickAndUploadPhoto,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A0A3E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(name,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _showEditNameDialog,
              child: const Icon(Icons.edit, size: 16, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(jobTitle,
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(code,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  Widget _buildActivationCard(bool isAr) {
    final employeeCode = (_profile?['employee_code'] ?? '').toString();
    final jobTitle = (_profile?['job_title'] ?? '').toString();
    final hireDate = (
      _profile?['hire_date'] ??
      _profile?['join_date'] ??
      _profile?['date_joined'] ??
      ''
    ).toString();
    final fullName = (
      _profile?['full_name_ar'] ??
      _profile?['full_name_en'] ??
      ''
    ).toString();
    const loginUrl = 'https://jssolutions-eg.com/login/';

    final loginText = '''
${isAr ? 'الاسم' : 'Name'}: $fullName
${isAr ? 'اسم المستخدم' : 'Username'}: ${_username.isNotEmpty ? _username : '-'}
${isAr ? 'الكود الوظيفي' : 'Employee Code'}: ${employeeCode.isNotEmpty ? employeeCode : '-'}
${isAr ? 'المسمى الوظيفي' : 'Job Title'}: ${jobTitle.isNotEmpty ? jobTitle : '-'}
${isAr ? 'تاريخ التعيين' : 'Hire Date'}: ${hireDate.isNotEmpty ? hireDate : '-'}
${isAr ? 'رابط الدخول' : 'Login URL'}: $loginUrl
'''.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF1A0A3E).withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user, color: Color(0xFF1A0A3E), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isAr ? 'بطاقة الدخول والتفعيل' : 'Access & Activation Card',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A0A3E)),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: loginText));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isAr ? 'تم نسخ بيانات الدخول' : 'Login details copied'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: Text(isAr ? 'نسخ' : 'Copy'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        final phone = (_profile?['phone'] ?? '').toString();
                        if (phone.isEmpty) return;
                        EmployeePdfService.openWhatsApp(phone, message: loginText);
                      },
                      icon: const Icon(Icons.chat, size: 16, color: Colors.green),
                      label: Text(
                        isAr ? 'واتساب' : 'WhatsApp',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _infoRow(isAr ? 'اسم المستخدم' : 'Username', _username, icon: Icons.person_outline),
                _infoRow(isAr ? 'الكود الوظيفي' : 'Employee Code', employeeCode, icon: Icons.badge),
                _infoRow(isAr ? 'المسمى الوظيفي' : 'Job Title', jobTitle, icon: Icons.work_outline),
                _infoRow(isAr ? 'تاريخ التعيين' : 'Hire Date', hireDate, icon: Icons.calendar_month),
                _infoRow(isAr ? 'رابط الدخول' : 'Login URL', loginUrl, icon: Icons.link),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    isAr
                        ? 'لو محتاج إعادة تفعيل أو تحديث كلمة المرور، تواصل مع الموارد البشرية.'
                        : 'If you need reactivation or password reset, contact HR.',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, color: Colors.white),
          label: Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A0A3E),
          foregroundColor: Colors.white,
          title: Text(context.l10n.profile,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: Text(context.l10n.retry),
                      ),
                    ]))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(children: [
                      _buildHeader(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: _buildActivationCard(isAr),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          _section(
                            isAr ? 'البيانات الشخصية' : 'Personal Info',
                            Icons.person,
                            const Color(0xFF1A0A3E),
                            [
                              _infoRow(context.l10n.nationalId, _profile!['national_id'], icon: Icons.badge),
                              _infoRow(context.l10n.birthDate, _profile!['birth_date'], icon: Icons.cake),
                              _infoRow(context.l10n.gender, _profile!['gender']),
                              _infoRow(context.l10n.status, _profile!['marital_status']),
                              _infoRow(isAr ? 'الديانة' : 'Religion', _profile!['religion']),
                              _infoRow(isAr ? 'الجنسية' : 'Nationality', _profile!['nationality']),
                            ],
                          ),
                          _section(
                            isAr ? 'التواصل' : 'Contact',
                            Icons.phone,
                            const Color(0xFF388E3C),
                            [
                              _infoRow(context.l10n.phone, _profile!['phone'], icon: Icons.phone_android),
                              _infoRow(isAr ? 'موبايل آخر' : 'Other Mobile', _profile!['phone2']),
                              _infoRow(isAr ? 'البريد الإلكتروني' : 'Email', _profile!['email'], icon: Icons.email),
                              _infoRow(context.l10n.address, _profile!['address'], icon: Icons.location_on),
                              _infoRow(isAr ? 'المدينة' : 'City', _profile!['city']),
                            ],
                          ),
                          _section(
                            isAr ? 'البيانات الوظيفية' : 'Job Info',
                            Icons.work,
                            const Color(0xFFE65100),
                            [
                              _infoRow(context.l10n.branch, _profile!['branch'], icon: Icons.business),
                              _infoRow(context.l10n.department, _profile!['department']),
                              _infoRow(isAr ? 'المسمى الوظيفي' : 'Job Title', _profile!['job_title']),
                              _infoRow(isAr ? '\u062A\u0635\u0646\u064A\u0641 \u0627\u0644\u0645\u0648\u0638\u0641' : 'Worker Type', _profile!['worker_type_display'] ?? _profile!['worker_type'], icon: Icons.badge_outlined),
                              _infoRow(isAr ? 'المدير المباشر' : 'Direct Manager', _profile!['direct_manager']?['name']),
                              _infoRow(context.l10n.hireDate, _profile!['hire_date'], icon: Icons.calendar_today),
                              _infoRow(isAr ? 'نوع العقد' : 'Contract Type', _profile!['contract_type']),
                              _infoRow(isAr ? 'انتهاء العقد' : 'Contract End', _profile!['contract_end_date']),
                              _infoRow(context.l10n.status, _profile!['status']),
                            ],
                          ),
                          _section(
                            isAr ? 'البيانات البنكية' : 'Bank Info',
                            Icons.account_balance,
                            const Color(0xFF382483),
                            [
                              _infoRow(isAr ? 'البنك' : 'Bank', _profile!['bank_name']),
                              _infoRow(isAr ? 'رقم الحساب' : 'Account Number', _profile!['bank_account']),
                              _infoRow('IBAN', _profile!['iban']),
                              _infoRow(
                                isAr ? 'رقم هاتف إنستاباي' : 'InstaPay Phone',
                                _profile!['instapay_phone'],
                                icon: Icons.mobile_friendly,
                              ),
                              _infoRow(
                                isAr ? 'رقم المحفظة الإلكترونية' : 'E-Wallet Phone',
                                _profile!['wallet_phone'],
                                icon: Icons.account_balance_wallet,
                              ),
                            ],
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(children: [
                          _actionButton(
                            label: isAr ? 'الملخص' : 'Summary',
                            icon: Icons.analytics,
                            color: const Color(0xFF382483),
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const EmployeeSummaryScreen())),
                          ),
                          _actionButton(
                            label: isAr ? 'كشف راتبي' : 'My Payslip',
                            icon: Icons.receipt_long,
                            color: const Color(0xFF1B5E20),
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const EmployeePayslipScreen())),
                          ),
                          _actionButton(
                            label: isAr ? 'المستندات' : 'Documents',
                            icon: Icons.folder_open,
                            color: const Color(0xFF388E3C),
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const EmployeeDocumentsScreen())),
                          ),
                          _actionButton(
                            label: isAr ? 'تاريخ الموظف' : 'Employee History',
                            icon: Icons.history,
                            color: const Color(0xFFE65100),
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const EmployeeMovementsScreen())),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),
                    ]),
                  ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final file = File(picked.path);
    final sizeMB = (await file.length()) / (1024 * 1024);
    if (sizeMB > 5) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? '\u062d\u062c\u0645 \u0627\u0644\u0635\u0648\u0631\u0629 \u0623\u0643\u0628\u0631 \u0645\u0646 5 \u0645\u064a\u062c\u0627\u0628\u0627\u064a\u062a' : 'Image too large (max 5MB)'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/employee/upload-photo/'),
      );
      request.headers.addAll(await ApiClient.buildHeaders());
      final ext = picked.path.split('.').last.toLowerCase();
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        picked.path,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? '\u062a\u0645 \u062a\u062d\u062f\u064a\u062b \u0627\u0644\u0635\u0648\u0631\u0629' : 'Photo updated'),
          backgroundColor: Colors.green,
        ));
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? '\u0641\u0634\u0644 \u0631\u0641\u0639 \u0627\u0644\u0635\u0648\u0631\u0629' : 'Photo upload failed'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? '\u062d\u062f\u062b \u062e\u0637\u0623' : 'Error occurred'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _showEditNameDialog() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final currentName = (_profile?['full_name_ar'] ?? '').toString();
    final ctrl = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? '\u0637\u0644\u0628 \u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0627\u0633\u0645' : 'Request Name Change'),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: isAr ? '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u062c\u062f\u064a\u062f' : 'New Name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? '\u0625\u0644\u063a\u0627\u0621' : 'Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: Text(isAr ? '\u0625\u0631\u0633\u0627\u0644' : 'Send'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == currentName) return;
    if (!mounted) return;
    try {
      final typesRes = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/request-types/'),
        headers: await ApiClient.buildHeaders(),
      );
      final typesData = json.decode(utf8.decode(typesRes.bodyBytes));
      int? typeId;
      if (typesData['categories'] is List) {
        for (final cat in typesData['categories'] as List) {
          if (cat['types'] is List) {
            for (final t in cat['types'] as List) {
              final tname = (t['name'] ?? '').toString();
              if (tname.contains('\u062a\u0639\u062f\u064a\u0644 \u0627\u0644\u0627\u0633\u0645')) {
                typeId = t['id'];
                break;
              }
            }
          }
          if (typeId != null) break;
        }
      }
      if (typeId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? '\u0647\u0630\u0647 \u0627\u0644\u062e\u062f\u0645\u0629 \u063a\u064a\u0631 \u0645\u062a\u0627\u062d\u0629 \u062d\u0627\u0644\u064a\u0627\u064b' : 'Feature not available'),
          backgroundColor: Colors.red,
        ));
        return;
      }
      final res = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/submit-request/'),
        headers: await ApiClient.buildHeaders(includeContentType: true),
        body: json.encode({
          'request_type_id': typeId,
          'details': newName,
          'subject': isAr ? 'طلب تعديل الاسم' : 'Name Change Request',
          'form_data': {},
        }),
      );
      final data = json.decode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? (isAr ? '\u062a\u0645 \u0625\u0631\u0633\u0627\u0644 \u0627\u0644\u0637\u0644\u0628' : 'Request sent')),
        backgroundColor: data['success'] == true ? Colors.green : Colors.red,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? '\u062d\u062f\u062b \u062e\u0637\u0623' : 'Error occurred'),
        backgroundColor: Colors.red,
      ));
    }
  }
}
