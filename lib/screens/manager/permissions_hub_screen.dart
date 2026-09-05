import 'package:flutter/material.dart';
import '../../services/permissions_service.dart';

const Color kPermColor = Color(0xFF37474F);

// ══════════════════════════════════════════
// شاشة الصلاحيات الرئيسية
// ══════════════════════════════════════════
class PermissionsHubScreen extends StatefulWidget {
  const PermissionsHubScreen({super.key});

  @override
  State<PermissionsHubScreen> createState() => _PermissionsHubScreenState();
}

class _PermissionsHubScreenState extends State<PermissionsHubScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'إدارة الصلاحيات' : 'Permissions',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPermColor,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _targetCard(
              context,
              icon: Icons.person,
              title: isAr ? 'موظف أو مدير محدد' : 'Specific User',
              subtitle: isAr ? 'تعديل صلاحيات موظف أو مدير بالاسم' : 'Edit permissions for a specific person',
              color: const Color(0xFF00C688),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const PermissionsTargetScreen(targetType: 'user'),
              )),
            ),
            const SizedBox(height: 12),
            _targetCard(
              context,
              icon: Icons.business,
              title: isAr ? 'قسم كامل' : 'Department',
              subtitle: isAr ? 'تعديل صلاحيات كل موظفي قسم' : 'Edit permissions for a whole department',
              color: const Color(0xFF2E7D32),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const PermissionsTargetScreen(targetType: 'department'),
              )),
            ),
            const SizedBox(height: 12),
            _targetCard(
              context,
              icon: Icons.location_city,
              title: isAr ? 'فرع كامل' : 'Branch',
              subtitle: isAr ? 'تعديل صلاحيات كل موظفي فرع' : 'Edit permissions for a whole branch',
              color: const Color(0xFF382483),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const PermissionsTargetScreen(targetType: 'branch'),
              )),
            ),
            const SizedBox(height: 12),
            _targetCard(
              context,
              icon: Icons.admin_panel_settings,
              title: isAr ? 'صلاحيات الأدوار الافتراضية' : 'Default Role Permissions',
              subtitle: isAr ? 'عرض الصلاحيات الافتراضية لكل دور' : 'View default permissions per role',
              color: const Color(0xFFE65100),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const DefaultRolePermissionsScreen(),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withAlpha(30),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[500], size: 18),
            ],
          ),
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════
// شاشة اختيار Target وتعديل صلاحياته
// ══════════════════════════════════════════
class PermissionsTargetScreen extends StatefulWidget {
  final String targetType;
  const PermissionsTargetScreen({super.key, required this.targetType});

  @override
  State<PermissionsTargetScreen> createState() => _PermissionsTargetScreenState();
}

class _PermissionsTargetScreenState extends State<PermissionsTargetScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final _idCtrl = TextEditingController();
  Map<String, dynamic>? _summary;
  bool _loading = false;
  String? _error;

  final Map<String, Map<String, String>> _permGroups = {
    'الموظفين': {
      'employees.view': 'عرض الموظفين',
      'employees.add': 'إضافة موظف',
      'employees.edit': 'تعديل موظف',
      'employees.delete': 'حذف موظف',
      'employees.transfer': 'نقل موظف',
    },
    'الحضور': {
      'attendance.view': 'عرض الحضور',
      'attendance.edit': 'تعديل الحضور',
      'attendance.checkin': 'تسجيل الحضور',
    },
    'الإجازات': {
      'leaves.view': 'عرض الإجازات',
      'leaves.approve': 'اعتماد الإجازات',
      'leaves.request': 'تقديم طلب إجازة',
    },
    'الطلبات': {
      'requests.view': 'عرض الطلبات',
      'requests.approve': 'اعتماد الطلبات',
      'requests.submit': 'تقديم طلبات',
    },
    'المرتبات': {
      'payroll.view': 'عرض المرتبات',
      'payroll.edit': 'تعديل المرتبات',
      'payroll.view_own': 'عرض مرتبي فقط',
    },
    'التقارير': {
      'reports.view': 'عرض التقارير',
      'reports.export': 'تصدير التقارير',
    },
    'المهام': {
      'missions.view': 'عرض المهام',
      'missions.manage': 'إدارة المهام',
      'missions.view_own': 'عرض مهامي فقط',
    },
    'الشيفتات': {
      'shifts.view': 'عرض الشيفتات',
      'shifts.manage': 'إدارة الشيفتات',
    },
    'السياسات': {
      'policies.view': 'عرض السياسات',
      'policies.manage': 'إدارة السياسات',
    },
    'الإجازات الرسمية': {
      'holidays.view': 'عرض الإجازات الرسمية',
      'holidays.manage': 'إدارة الإجازات الرسمية',
    },
    'التتبع': {
      'tracking.view': 'عرض التتبع',
      'tracking.manage': 'إدارة التتبع',
    },
    'الشركة والأقسام': {
      'company.view': 'عرض إعدادات الشركة',
      'company.edit': 'تعديل إعدادات الشركة',
      'departments.view': 'عرض الأقسام',
      'departments.add': 'إضافة قسم',
      'departments.edit': 'تعديل قسم',
      'departments.delete': 'حذف قسم',
      'departments.transfer_employees': 'نقل موظفين',
    },
    'أخرى': {
      'offboarding.execute': 'إنهاء خدمة موظف',
      'roles.manage': 'إدارة الأدوار',
      'profile.view': 'عرض الملف الشخصي',
      'profile.edit_basic': 'تعديل البيانات الأساسية',
    },
  };

  Map<String, bool> _checkedPerms = {};
  bool _saving = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    super.dispose();
  }

  String _typeLabel() {
    switch (widget.targetType) {
      case 'user': return isAr ? 'موظف / مدير' : 'User';
      case 'department': return isAr ? 'قسم' : 'Department';
      case 'branch': return isAr ? 'فرع' : 'Branch';
      default: return widget.targetType;
    }
  }

  Future<void> _load() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) {
      setState(() => _error = isAr ? 'ادخل الرقم أولاً' : 'Enter ID first');
      return;
    }

    setState(() { _loading = true; _error = null; _summary = null; });

    try {
      final result = await PermissionsService.getTargetPermissionsSummary(
        type: widget.targetType,
        id: id,
      );
      final perms = List<Map<String, dynamic>>.from(result['permissions'] ?? []);
      final checked = <String, bool>{};

      for (final group in _permGroups.values) {
        for (final code in group.keys) {
          checked[code] = perms.any((p) => p['code'] == code);
        }
      }

      setState(() {
        _summary = result;
        _checkedPerms = checked;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _save() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty || _summary == null) return;

    setState(() => _saving = true);

    try {
      final permissions = <Map<String, dynamic>>[];
      for (final entry in _checkedPerms.entries) {
        permissions.add({
          'code': entry.key,
          'scope': 'company',
          'is_granted': entry.value,
        });
      }

      await PermissionsService.setRoleOverride(
        targetType: widget.targetType,
        targetId: id,
        permissions: permissions.where((p) => p['is_granted'] == true).toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم حفظ الصلاحيات بنجاح' : 'Permissions saved'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            '${isAr ? 'صلاحيات' : 'Permissions'}: ${_typeLabel()}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPermColor,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _idCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'ID ${_typeLabel()}',
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _load,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPermColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isAr ? 'جلب' : 'Load'),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_summary != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.person, color: kPermColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      _summary!['full_name'] ?? _summary!['username'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kPermColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _summary!['role'] ?? '',
                        style: TextStyle(color: kPermColor, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _permGroups.entries.map((group) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: kPermColor,
                              ),
                            ),
                            const Divider(height: 12),
                            ...group.value.entries.map((perm) {
                              return CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                title: Text(perm.value, style: const TextStyle(fontSize: 13)),
                                value: _checkedPerms[perm.key] ?? false,
                                activeColor: kPermColor,
                                onChanged: (v) => setState(() => _checkedPerms[perm.key] = v ?? false),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPermColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            isAr ? 'حفظ الصلاحيات' : 'Save Permissions',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


// ══════════════════════════════════════════
// شاشة عرض الصلاحيات الافتراضية لكل Role
// ══════════════════════════════════════════
class DefaultRolePermissionsScreen extends StatefulWidget {
  const DefaultRolePermissionsScreen({super.key});

  @override
  State<DefaultRolePermissionsScreen> createState() => _DefaultRolePermissionsScreenState();
}

class _DefaultRolePermissionsScreenState extends State<DefaultRolePermissionsScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  final List<String> _roles = ['company_admin', 'hr_manager', 'manager', 'employee'];
  String _selectedRole = 'hr_manager';
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _permissions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await PermissionsService.getDefaultRolePermissions(_selectedRole);
      setState(() {
        _permissions = List<Map<String, dynamic>>.from(result['permissions'] ?? []);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _roleLabel(String r) {
    switch (r) {
      case 'company_admin': return isAr ? 'صاحب الشركة' : 'Company Admin';
      case 'hr_manager': return isAr ? 'مدير HR' : 'HR Manager';
      case 'manager': return isAr ? 'مدير' : 'Manager';
      case 'employee': return isAr ? 'موظف' : 'Employee';
      default: return r;
    }
  }

  Color _scopeColor(String s) {
    switch (s) {
      case 'company': return Color(0xFF382483);
      case 'team': return Colors.green;
      case 'dept': return Colors.orange;
      case 'self': return Color(0xFF382483);
      default: return Colors.grey;
    }
  }

  String _scopeLabel(String s) {
    switch (s) {
      case 'company': return isAr ? 'الشركة كلها' : 'Company';
      case 'team': return isAr ? 'فريقه' : 'Team';
      case 'dept': return isAr ? 'قسمه' : 'Dept';
      case 'self': return isAr ? 'نفسه' : 'Self';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'الصلاحيات الافتراضية' : 'Default Permissions',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE65100),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(
                  labelText: isAr ? 'اختر الدور' : 'Select Role',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _roles.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text(_roleLabel(r)),
                )).toList(),
                onChanged: (v) {
                  setState(() => _selectedRole = v ?? 'hr_manager');
                  _load();
                },
              ),
            ),
            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFE65100)),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _permissions.length,
                  itemBuilder: (_, i) {
                    final perm = _permissions[i];
                    final scope = perm['scope'] ?? '';
                    final color = _scopeColor(scope);
                    return ListTile(
                      leading: Icon(Icons.check_circle, color: color, size: 20),
                      title: Text(perm['label_ar'] ?? perm['code'] ?? '', style: const TextStyle(fontSize: 13)),
                      subtitle: Text(perm['code'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: color.withAlpha(60)),
                        ),
                        child: Text(
                          _scopeLabel(scope),
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}


