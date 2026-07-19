import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../employee/employee_summary_screen.dart';
import '../../widgets/empty_state_widget.dart';
import '../../services/employee_management_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';


class ManagerEmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  const ManagerEmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<ManagerEmployeeDetailScreen> createState() => _ManagerEmployeeDetailScreenState();
}

class _ManagerEmployeeDetailScreenState extends State<ManagerEmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  List<dynamic> _documents = [];
  List<dynamic> _movements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final headers = {'Authorization': 'Token $token'};
      final base = 'https://jssolutions-eg.com/attendance/api/mobile/manager/employees/${widget.employeeId}';

      final results = await Future.wait([
        http.get(Uri.parse('$base/profile/'), headers: headers).timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$base/documents/'), headers: headers).timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$base/movements/'), headers: headers).timeout(const Duration(seconds: 15)),
      ]);

      if (results[0].statusCode == 200) {
        _profile = json.decode(utf8.decode(results[0].bodyBytes));
      }
      if (results[1].statusCode == 200) {
        final d = json.decode(utf8.decode(results[1].bodyBytes));
        _documents = d['documents'] ?? [];
      }
      if (results[2].statusCode == 200) {
        final d = json.decode(utf8.decode(results[2].bodyBytes));
        _movements = d['movements'] ?? [];
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'خطأ في التحميل';
        _loading = false;
      });
    }
  }

  // ── Reset Password ──
  Future<void> _resetPassword() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(context.l10n.resetPassword),
          content: Text('هل تريد إعادة تعيين كلمة مرور الموظف "${widget.employeeName}"؟\nسيتم توليد كلمة مرور جديدة تلقائياً.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('إعادة تعيين', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      // توليد باسورد جديد
      final random = Random();
      final digits = List.generate(4, (_) => random.nextInt(10)).join();
      final newPassword = 'Emp@$digits${String.fromCharCode(65 + random.nextInt(26))}';

      final response = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/employees/${widget.employeeId}/reset-password/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'new_password': newPassword}),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showNewPasswordDialog(newPassword);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إعادة التعيين'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاتصال'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showNewPasswordDialog(String newPassword) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('تم إعادة التعيين'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('كلمة المرور الجديدة:'),
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      newPassword,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Colors.red,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.red),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: newPassword));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('تم النسخ'), backgroundColor: Colors.green),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '⚠️ احتفظ بكلمة المرور وأعطها للموظف. سيُطلب منه تغييرها عند أول دخول.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6A1B9A)),
              child: Text(context.l10n.ok, style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── تعديل بيانات الموظف ──
  void _editEmployee() {
    if (_profile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditEmployeeSheet(
        profile: _profile!,
        employeeId: widget.employeeId,
        onSaved: _loadAll,
      ),
    );
  }
Future<void> _transferEmployee() async {
  try {
    final data = await EmployeeManagementService.getOrganizationTree();
    if (!mounted) return;

    final branches = List<Map<String, dynamic>>.from(data['branches'] ?? []);

    int? selectedBranchId;
    int? selectedDepartmentId;
    int? selectedManagerId;

    List<Map<String, dynamic>> filteredDepartments = [];
    List<Map<String, dynamic>> filteredManagers = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.l10n.transferEmployee),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedBranchId,
                        decoration: InputDecoration(
                          labelText: 'اختر الفرع',
                          border: OutlineInputBorder(),
                        ),
                        items: branches.map((branch) {
                          return DropdownMenuItem<int>(
                            value: branch['id'],
                            child: Text(branch['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedBranchId = value;
                          selectedDepartmentId = null;
                          selectedManagerId = null;

                          final selectedBranch = branches.firstWhere(
                            (b) => b['id'] == value,
                            orElse: () => <String, dynamic>{},
                          );

                          filteredDepartments = List<Map<String, dynamic>>.from(
                            selectedBranch['departments'] ?? [],
                          );
                          filteredManagers = [];

                          setDialogState(() {});
                        },
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedDepartmentId,
                        decoration: InputDecoration(
                          labelText: 'اختر القسم',
                          border: OutlineInputBorder(),
                        ),
                        items: filteredDepartments.map((dept) {
                          return DropdownMenuItem<int>(
                            value: dept['id'],
                            child: Text(dept['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: selectedBranchId == null
                            ? null
                            : (value) {
                                selectedDepartmentId = value;
                                selectedManagerId = null;

                                final selectedDept = filteredDepartments.firstWhere(
                                  (d) => d['id'] == value,
                                  orElse: () => <String, dynamic>{},
                                );

                                filteredManagers = List<Map<String, dynamic>>.from(
                                  selectedDept['managers'] ?? [],
                                );

                                setDialogState(() {});
                              },
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedManagerId,
                        decoration: InputDecoration(
                          labelText: 'اختر المدير الجديد',
                          border: OutlineInputBorder(),
                        ),
                        items: filteredManagers.map((manager) {
                          return DropdownMenuItem<int>(
                            value: manager['id'],
                            child: Text(manager['name'] ?? ''),
                          );
                        }).toList(),
                        onChanged: selectedDepartmentId == null
                            ? null
                            : (value) {
                                selectedManagerId = value;
                                setDialogState(() {});
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.cancel),
                ),
                ElevatedButton(
onPressed: () async {
  if (selectedBranchId == null || selectedDepartmentId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('اختر الفرع والقسم أولاً')),
    );
    return;
  }

  try {
    await EmployeeManagementService.transferEmployee(
      employeeId: widget.employeeId,
      newManagerId: selectedManagerId,
      newBranchId: selectedBranchId,
      newDepartmentId: selectedDepartmentId,
    );

    if (!mounted) return;
    Navigator.pop(context);
    await _loadAll();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم نقل الموظف بنجاح ✅')),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ في النقل: $e')),
    );
  }
},                  child: Text(context.l10n.confirm),
                ),
              ],
            );
          },
        );
      },
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('خطأ: $e')),
    );
  }
}
List<DropdownMenuItem<int>> _buildManagersDropdown(dynamic data) {
  final List<DropdownMenuItem<int>> items = [];

  if (data == null || data['branches'] == null) return items;

  for (var branch in data['branches']) {
    for (var dept in branch['departments']) {
      for (var manager in dept['managers']) {
        items.add(
          DropdownMenuItem<int>(
            value: manager['id'],
            child: Text(
              '${manager['name']} - ${dept['name']}',
              style: const TextStyle(fontSize: 13),
            ),
          ),
        );
      }
    }
  }

  return items;
}
  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    final full = url.startsWith('http') ? url : 'https://jssolutions-eg.com$url';
    final uri = Uri.parse(full);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _infoRow(String label, dynamic value, {IconData? icon}) {
    final v = (value == null || value.toString().isEmpty) ? '-' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            SizedBox(width: 6),
          ],
          SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_profile == null) {
      return EmptyStateWidget(
        title: context.l10n.noData,
        description: 'تعذر تحميل بيانات الموظف',
        icon: Icons.person_off_outlined,
        onRefresh: _loadAll,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // هيدر الموظف
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              backgroundImage: (_profile!['photo'] != null && _profile!['photo'].toString().isNotEmpty)
                  ? NetworkImage('https://jssolutions-eg.com${_profile!['photo']}')
                  : null,
              child: (_profile!['photo'] == null || _profile!['photo'].toString().isEmpty)
                  ? Icon(Icons.person, size: 34, color: Color(0xFF6A1B9A))
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_profile!['full_name_ar'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(_profile!['job_title'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: Text(_profile!['employee_code'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ]),
        ),
        SizedBox(height: 12),
        // أزرار الإجراءات - صف علوي
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmployeeSummaryScreen(
                      employeeId: widget.employeeId,
                      employeeName: widget.employeeName,
                    ),
                  ),
                ),
                icon: Icon(Icons.analytics, color: Colors.white, size: 18),
                label: Text('الملخص', style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _editEmployee,
                icon: Icon(Icons.edit, color: Colors.white, size: 18),
                label: Text(context.l10n.edit, style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        // أزرار الإجراءات - صف سفلي
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _transferEmployee,
                icon: Icon(Icons.swap_horiz, color: Colors.white, size: 18),
                label: Text('نقل', style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _resetPassword,
                icon: Icon(Icons.lock_reset, color: Colors.white, size: 18),
                label: Text('Reset', style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        _sectionCard(Localizations.localeOf(context).languageCode == 'ar' ? 'البيانات الشخصية' : 'Personal Info', Icons.person, const Color(0xFF1976D2), [
          _infoRow(context.l10n.nationalId, _profile!['national_id'], icon: Icons.badge),
          _infoRow(context.l10n.birthDate, _profile!['birth_date'], icon: Icons.cake),
          _infoRow(context.l10n.gender, _profile!['gender']),
          _infoRow(context.l10n.status, _profile!['marital_status']),
          _infoRow('الجنسية', _profile!['nationality']),
        ]),
        _sectionCard('التواصل', Icons.phone, const Color(0xFF388E3C), [
          _infoRow(context.l10n.phone, _profile!['phone'], icon: Icons.phone_android),
          _infoRow('البريد', _profile!['email'], icon: Icons.email),
          _infoRow(context.l10n.address, _profile!['address'], icon: Icons.location_on),
        ]),
        _sectionCard(Localizations.localeOf(context).languageCode == 'ar' ? 'البيانات الوظيفية' : 'Job Info', Icons.work, const Color(0xFFE65100), [
          _infoRow(context.l10n.branch, _profile!['branch'], icon: Icons.business),
          _infoRow(context.l10n.department, _profile!['department']),
          _infoRow('المدير', _profile!['direct_manager']?['name']),
          _infoRow(context.l10n.hireDate, _profile!['hire_date'], icon: Icons.calendar_today),
          _infoRow('نوع العقد', _profile!['contract_type']),
          _infoRow(context.l10n.status, _profile!['status']),
        ]),
        _sectionCard(Localizations.localeOf(context).languageCode == 'ar' ? 'البيانات البنكية' : 'Bank Info', Icons.account_balance, const Color(0xFF6A1B9A), [
          _infoRow('البنك', _profile!['bank_name']),
          _infoRow('رقم الحساب', _profile!['bank_account']),
          _infoRow('IBAN', _profile!['iban']),
          _infoRow(context.l10n.basicSalary, _profile!['basic_salary']),
        ]),
      ],
    );
  }

  IconData _docIcon(String type) {
    switch (type) {
      case 'national_id': return Icons.badge;
      case 'passport': return Icons.book;
      case 'contract': return Icons.description;
      case 'certificate': return Icons.school;
      case 'cv': return Icons.assignment_ind;
      case 'medical': return Icons.local_hospital;
      case 'license': return Icons.card_membership;
      case 'insurance': return Icons.shield;
      default: return Icons.folder;
    }
  }

  Widget _buildDocumentsTab() {
    if (_documents.isEmpty) {
      return EmptyStateWidget(
        title: 'لا توجد مستندات',
        description: 'لم يتم إضافة أي مستندات لهذا الموظف بعد',
        icon: Icons.folder_open_outlined,
        iconColor: Colors.orange,
        onRefresh: _loadAll,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _documents.length,
      itemBuilder: (context, i) {
        final doc = _documents[i] as Map<String, dynamic>;
        final expired = doc['is_expired'] == true;
        final soon = doc['expires_soon'] == true;
        final color = expired ? Colors.red : (soon ? Colors.orange : const Color(0xFF388E3C));
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(_docIcon(doc['document_type_code'] ?? ''), color: color),
            ),
            title: Text(doc['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['document_type'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                if (doc['expiry_date'] != null)
                  Text('ينتهي: ${doc['expiry_date']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                if (expired)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('منتهي', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                else if (soon)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('ينتهي قريباً', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            trailing: doc['file_url'] != null ? Icon(Icons.download, color: color) : null,
            onTap: () => _openFile(doc['file_url']),
          ),
        );
      },
    );
  }

  Widget _buildMovementsTab() {
    if (_movements.isEmpty) {
      return EmptyStateWidget(
        title: 'لا توجد حركات',
        description: 'لم يتم تسجيل أي حركات وظيفية لهذا الموظف',
        icon: Icons.history_outlined,
        iconColor: Colors.blueGrey,
        onRefresh: _loadAll,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _movements.length,
      itemBuilder: (context, i) {
        final mv = _movements[i] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.history, size: 16, color: Color(0xFFE65100)),
                SizedBox(width: 6),
                Text(mv['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Text((mv['date'] ?? '').toString().split('T').first,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ]),
              if ((mv['notes'] ?? '').toString().isNotEmpty) ...[
                SizedBox(height: 6),
                Text(mv['notes'], style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        );
      },
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
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          title: Text(widget.employeeName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          actions: [
            IconButton(onPressed: _loadAll, icon: Icon(Icons.refresh)),
          ],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'الملف'),
              Tab(icon: Icon(Icons.folder), text: 'المستندات'),
              Tab(icon: Icon(Icons.history), text: context.l10n.date),
            ],
          ),
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? EmptyStateWidget(
                    title: 'خطأ في التحميل',
                    description: _error!,
                    icon: Icons.error_outline,
                    iconColor: Colors.red,
                    onRefresh: _loadAll,
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProfileTab(),
                      _buildDocumentsTab(),
                      _buildMovementsTab(),
                    ],
                  ),
      ),
    );
  }
}

// ── شاشة تعديل بيانات الموظف ──
class _EditEmployeeSheet extends StatefulWidget {
  final Map<String, dynamic> profile;
  final int employeeId;
  final VoidCallback onSaved;

  const _EditEmployeeSheet({
    required this.profile,
    required this.employeeId,
    required this.onSaved,
  });

  @override
  State<_EditEmployeeSheet> createState() => _EditEmployeeSheetState();
}

class _EditEmployeeSheetState extends State<_EditEmployeeSheet> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _bankAccountCtrl;
  late TextEditingController _ibanCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.profile['phone'] ?? '');
    _emailCtrl = TextEditingController(text: widget.profile['email'] ?? '');
    _addressCtrl = TextEditingController(text: widget.profile['address'] ?? '');
    _bankNameCtrl = TextEditingController(text: widget.profile['bank_name'] ?? '');
    _bankAccountCtrl = TextEditingController(text: widget.profile['bank_account'] ?? '');
    _ibanCtrl = TextEditingController(text: widget.profile['iban'] ?? '');
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _bankNameCtrl.dispose();
    _bankAccountCtrl.dispose();
    _ibanCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.patch(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/employees/${widget.employeeId}/update/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
          'bank_name': _bankNameCtrl.text.trim(),
          'bank_account': _bankAccountCtrl.text.trim(),
          'iban': _ibanCtrl.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التعديلات'), backgroundColor: Colors.green),
        );
      } else {
        final d = json.decode(response.body);
        setState(() => _error = d['message'] ?? 'فشل الحفظ');
      }
    } catch (e) {
      setState(() => _error = 'خطأ في الاتصال');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboardType, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? context.l10n.required : null : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF6A1B9A)),
                  SizedBox(width: 8),
                  Text(context.l10n.editEmployee,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAr ? 'بيانات التواصل' : 'Contact Info',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF388E3C))),
                      SizedBox(height: 8),
                      _field(context.l10n.phone, _phoneCtrl, keyboardType: TextInputType.phone),
                      _field(context.l10n.email, _emailCtrl, keyboardType: TextInputType.emailAddress),
                      _field(context.l10n.address, _addressCtrl),
                      SizedBox(height: 8),
                      Text(isAr ? 'البيانات البنكية' : 'Bank Info',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
                      SizedBox(height: 8),
                      _field('اسم البنك', _bankNameCtrl),
                      _field('رقم الحساب', _bankAccountCtrl),
                      _field('IBAN', _ibanCtrl),
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A1B9A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('حفظ التعديلات',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}