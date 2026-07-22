import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';
import 'role_detail_screen.dart';

class PermissionsRolesScreen extends StatefulWidget {
  const PermissionsRolesScreen({super.key});

  @override
  State<PermissionsRolesScreen> createState() => _PermissionsRolesScreenState();
}

class _PermissionsRolesScreenState extends State<PermissionsRolesScreen> {
  List<dynamic> _roles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final headers = {'Authorization': 'Token $token'};

      final r1 = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/roles/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (r1.statusCode == 200) {
        final d1 = json.decode(utf8.decode(r1.bodyBytes));
        setState(() {
          _roles = d1['roles'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'http';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'connection';
        _loading = false;
      });
    }
  }

  Future<void> _openRoleDetails(Map<String, dynamic> role) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RoleDetailScreen(role: role),
      ),
    );

    if (changed == true) {
      _load();
    }
  }

  Future<void> _createRole(String name) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken() ?? '';

    try {
      final response = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/roles/create/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'permissions': [],
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? (isAr ? 'تم إنشاء الدور' : 'Role created')),
            backgroundColor: Colors.green,
          ),
        );

        await _load();

        if (!mounted) return;

        await _openRoleDetails({
          'id': data['role_id'],
          'name': name,
          'permissions': [],
          'users_count': 0,
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['error'] ?? (isAr ? 'حصلت مشكلة' : 'Something went wrong')),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'حصلت مشكلة في إنشاء الدور' : 'Failed to create role'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRole(int roleId) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken() ?? '';

    try {
      await http.delete(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/roles/$roleId/delete/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'تم حذف الدور' : 'Role deleted')),
      );
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAr ? 'حصلت مشكلة' : 'Error')),
      );
    }
  }

  void _showCreateRoleSheet() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final nameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'إضافة دور جديد' : 'Add New Role',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'اكتب اسم الدور الأول وبعد الحفظ هتدخل تحدد صلاحياته'
                    : 'Enter the role name first, then you will define its permissions',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم الدور' : 'Role name',
                  hintText: isAr
                      ? 'مثال: مدير فرع / مدير مالي / HR'
                      : 'Example: Branch Manager / Finance Manager / HR',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isAr ? 'اكتب اسم الدور الأول' : 'Please enter role name first',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    _createRole(name);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A148C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isAr ? 'التالي' : 'Next'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _helperCard(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'يعني إيه دور' : 'What is a Role?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'الدور هو قالب صلاحيات. مثال: HR أو مدير مالي أو مدير فرع. اعمل الدور الأول وبعدها افتحه وحدد صلاحياته وبعد كده اربطه بالقسم أو الموظف.'
                : 'A role is a permissions template. Example: HR, Finance Manager, or Branch Manager. Create the role first, then open it and define its permissions, then link it to a department or employee.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'الأدوار' : 'Roles'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          isAr ? 'حصلت مشكلة في تحميل الأدوار' : 'Failed to load roles',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _helperCard(isAr),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _showCreateRoleSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A148C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(isAr ? 'إضافة دور جديد' : 'Add New Role'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAr
                            ? 'اضغط على أي دور عشان تفتح صلاحياته وتعدلها'
                            : 'Tap any role to open and edit its permissions',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_roles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              isAr
                                  ? 'مفيش أدوار لسه — اضغط "إضافة دور جديد"'
                                  : 'No roles yet — tap "Add New Role"',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._roles.map((roleItem) {
                          final role = roleItem as Map<String, dynamic>;
                          final permissions = (role['permissions'] as List?) ?? [];

                          return InkWell(
                            onTap: () => _openRoleDetails(role),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x11000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            const Color(0xFF1A56DB).withValues(alpha: 0.12),
                                        child: const Icon(
                                          Icons.admin_panel_settings,
                                          color: Color(0xFF1A56DB),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '${role['name'] ?? ''}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          isAr
                                              ? '${role['users_count'] ?? 0} مستخدم'
                                              : '${role['users_count'] ?? 0} users',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A56DB),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _deleteRole(role['id']),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (permissions.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        isAr
                                            ? 'لسه مفيش صلاحيات — اضغط على الدور وحددها'
                                            : 'No permissions yet — tap the role to define them',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: permissions.map((p) {
                                        final item = p as Map<String, dynamic>;
                                        final label = isAr
                                            ? '${item['label_ar'] ?? item['code']}'
                                            : '${item['label_en'] ?? item['code'] ?? item['code']}';
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF3F4F6),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            label,
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}
