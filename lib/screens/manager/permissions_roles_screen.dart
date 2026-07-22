import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

class PermissionsRolesScreen extends StatefulWidget {
  const PermissionsRolesScreen({super.key});

  @override
  State<PermissionsRolesScreen> createState() => _PermissionsRolesScreenState();
}

class _PermissionsRolesScreenState extends State<PermissionsRolesScreen> {
  List<dynamic> _roles = [];
  List<dynamic> _availablePermissions = [];
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

      final r2 = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/available/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (r1.statusCode == 200 && r2.statusCode == 200) {
        final d1 = json.decode(utf8.decode(r1.bodyBytes));
        final d2 = json.decode(utf8.decode(r2.bodyBytes));
        setState(() {
          _roles = d1['roles'] ?? [];
          _availablePermissions = d2['permissions'] ?? [];
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

  Future<void> _createRole(String name, List<String> selectedPermissions) async {
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
          'permissions': selectedPermissions
              .map((code) => {'code': code, 'scope': 'company'})
              .toList(),
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message'] ??
                (response.statusCode == 200 || response.statusCode == 201
                    ? (isAr ? 'تم إنشاء الدور' : 'Role created')
                    : (isAr ? 'حصلت مشكلة' : 'Something went wrong')),
          ),
        ),
      );

      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'حصلت مشكلة في إنشاء الدور' : 'Failed to create role'),
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
    final selected = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'إنشاء دور جديد' : 'Create New Role',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: isAr ? 'اسم الدور' : 'Role name',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isAr ? 'اختار الصلاحيات' : 'Choose permissions',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _availablePermissions.isEmpty
                          ? Center(
                              child: Text(isAr ? 'مفيش صلاحيات' : 'No permissions'),
                            )
                          : ListView(
                              children: _availablePermissions.map((p) {
                                final item = p as Map<String, dynamic>;
                                final code = '${item['code']}';
                                final label = isAr
                                    ? '${item['label_ar'] ?? item['code']}'
                                    : '${item['code']}';

                                return CheckboxListTile(
                                  value: selected.contains(code),
                                  title: Text(label),
                                  controlAffinity: ListTileControlAffinity.leading,
                                  onChanged: (v) {
                                    setModalState(() {
                                      if (v == true) {
                                        selected.add(code);
                                      } else {
                                        selected.remove(code);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty || selected.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isAr
                                      ? 'اكتب اسم الدور واختار صلاحية واحدة على الأقل'
                                      : 'Enter role name and choose at least one permission',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          _createRole(name, selected.toList());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A148C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(isAr ? 'حفظ الدور' : 'Save Role'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoleSheet,
        backgroundColor: const Color(0xFF4A148C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          isAr ? 'حصلت مشكلة في تحميل الأدوار' : 'Failed to load roles',
                        ),
                      ),
                    ],
                  )
                : _roles.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 120),
                          Center(
                            child: Text(
                              isAr
                                  ? 'مفيش أدوار لسه — دوس +'
                                  : 'No roles yet — press +',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _roles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final role = _roles[index] as Map<String, dynamic>;
                          final permissions = (role['permissions'] as List?) ?? [];

                          return Container(
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
                                      backgroundColor: const Color(0xFF1A56DB)
                                          .withValues(alpha: 0.12),
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
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: permissions.map((p) {
                                    final item = p as Map<String, dynamic>;
                                    final label = isAr
                                        ? '${item['label_ar'] ?? item['code']}'
                                        : '${item['code']}';
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
                          );
                        },
                      ),
      ),
    );
  }
}
