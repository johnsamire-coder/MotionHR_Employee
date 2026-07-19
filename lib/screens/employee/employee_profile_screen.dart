import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'employee_movements_screen.dart';
import 'employee_documents_screen.dart';
import 'employee_summary_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/employee/profile/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() {
          _profile = json.decode(utf8.decode(response.bodyBytes));
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'تعذر تحميل البيانات (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
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
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 45,
          backgroundColor: Colors.white,
          backgroundImage: (photo != null && photo.toString().isNotEmpty)
              ? NetworkImage('https://jssolutions-eg.com$photo')
              : null,
          child: (photo == null || photo.toString().isEmpty)
              ? const Icon(Icons.person, size: 50, color: Color(0xFF1976D2))
              : null,
        ),
        const SizedBox(height: 12),
        Text(name,
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
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

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1976D2),
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
                        padding: const EdgeInsets.all(12),
                        child: Column(children: [
                          // ── البيانات الشخصية ──
                          _section(
                            isAr ? 'البيانات الشخصية' : 'Personal Info',
                            Icons.person,
                            const Color(0xFF1976D2),
                            [
                              _infoRow(context.l10n.nationalId, _profile!['national_id'], icon: Icons.badge),
                              _infoRow(context.l10n.birthDate, _profile!['birth_date'], icon: Icons.cake),
                              _infoRow(context.l10n.gender, _profile!['gender']),
                              _infoRow(context.l10n.status, _profile!['marital_status']),
                              _infoRow(isAr ? 'الديانة' : 'Religion', _profile!['religion']),
                              _infoRow(isAr ? 'الجنسية' : 'Nationality', _profile!['nationality']),
                            ],
                          ),
                          // ── التواصل ──
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
                          // ── البيانات الوظيفية ──
                          _section(
                            isAr ? 'البيانات الوظيفية' : 'Job Info',
                            Icons.work,
                            const Color(0xFFE65100),
                            [
                              _infoRow(context.l10n.branch, _profile!['branch'], icon: Icons.business),
                              _infoRow(context.l10n.department, _profile!['department']),
                              _infoRow(isAr ? 'المسمى الوظيفي' : 'Job Title', _profile!['job_title']),
                              _infoRow(isAr ? 'المدير المباشر' : 'Direct Manager', _profile!['direct_manager']?['name']),
                              _infoRow(context.l10n.hireDate, _profile!['hire_date'], icon: Icons.calendar_today),
                              _infoRow(isAr ? 'نوع العقد' : 'Contract Type', _profile!['contract_type']),
                              _infoRow(isAr ? 'انتهاء العقد' : 'Contract End', _profile!['contract_end_date']),
                              _infoRow(context.l10n.status, _profile!['status']),
                            ],
                          ),
                          // ── البيانات البنكية ──
                          _section(
                            isAr ? 'البيانات البنكية' : 'Bank Info',
                            Icons.account_balance,
                            const Color(0xFF6A1B9A),
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
                      // ── أزرار الشاشات الفرعية ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const EmployeeSummaryScreen())),
                              icon: const Icon(Icons.analytics, color: Colors.white),
                              label: Text(
                                isAr ? 'الملخص' : 'Summary',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A1B9A),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const EmployeeDocumentsScreen())),
                              icon: const Icon(Icons.folder_open, color: Colors.white),
                              label: Text(
                                isAr ? 'المستندات' : 'Documents',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF388E3C),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const EmployeeMovementsScreen())),
                              icon: const Icon(Icons.history, color: Colors.white),
                              label: Text(
                                isAr ? 'تاريخ الموظف' : 'Employee History',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE65100),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 20),
                    ]),
                  ),
      ),
    );
  }
}