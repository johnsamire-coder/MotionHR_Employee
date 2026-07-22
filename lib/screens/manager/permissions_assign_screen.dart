import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

class PermissionsAssignScreen extends StatefulWidget {
  const PermissionsAssignScreen({super.key});

  @override
  State<PermissionsAssignScreen> createState() => _PermissionsAssignScreenState();
}

class _PermissionsAssignScreenState extends State<PermissionsAssignScreen> {
  List<dynamic> _users = [];
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
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/users/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      final r2 = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/roles/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (r1.statusCode == 200 && r2.statusCode == 200) {
        final d1 = json.decode(utf8.decode(r1.bodyBytes));
        final d2 = json.decode(utf8.decode(r2.bodyBytes));
        setState(() {
          _users = d1['users'] ?? [];
          _roles = d2['roles'] ?? [];
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

  void _showBulkAssignSheet(Map<String, dynamic> role) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final roleName = '${role['name']}';
    final roleId = role['id'] as int;
    final selectedUsers = <int>{};

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
                16, 16, 16,
                MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isAr
                                ? 'تعيين دور: $roleName'
                                : 'Assign Role: $roleName',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              if (selectedUsers.length == _users.length) {
                                selectedUsers.clear();
                              } else {
                                selectedUsers.addAll(
                                  _users.map((u) => u['id'] as int),
                                );
                              }
                            });
                          },
                          child: Text(
                            selectedUsers.length == _users.length
                                ? (isAr ? 'إلغاء الكل' : 'Deselect All')
                                : (isAr ? 'اختار الكل' : 'Select All'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAr
                          ? 'اختار الموظفين اللي هتديهم الدور ده:'
                          : 'Select users to assign this role to:',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        children: _users.map((u) {
                          final user = u as Map<String, dynamic>;
                          final userId = user['id'] as int;
                          final assignedRoles =
                              (user['assigned_roles'] as List?) ?? [];
                          final alreadyAssigned =
                              assignedRoles.contains(roleName);

                          return CheckboxListTile(
                            value: alreadyAssigned || selectedUsers.contains(userId),
                            title: Text(
                              '${user['full_name']?.toString().isNotEmpty == true ? user['full_name'] : user['username']}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '@${user['username']}${alreadyAssigned ? (isAr ? ' — معيّن بالفعل' : ' — already assigned') : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: alreadyAssigned
                                    ? Colors.green
                                    : Colors.grey.shade600,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: alreadyAssigned
                                ? null
                                : (v) {
                                    setModalState(() {
                                      if (v == true) {
                                        selectedUsers.add(userId);
                                      } else {
                                        selectedUsers.remove(userId);
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
                        onPressed: selectedUsers.isEmpty
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _assignBulk(roleId, selectedUsers.toList());
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A148C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          isAr
                              ? 'تعيين لـ ${selectedUsers.length} موظف'
                              : 'Assign to ${selectedUsers.length} users',
                        ),
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

  Future<void> _assignBulk(int roleId, List<int> userIds) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken() ?? '';
    int success = 0;

    for (final userId in userIds) {
      try {
        final r = await http.post(
          Uri.parse(
            'https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/assign-role/',
          ),
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
          body: json.encode({'user_id': userId, 'role_id': roleId}),
        );
        if (r.statusCode == 200) success++;
      } catch (_) {}
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'تم تعيين الدور لـ $success موظف'
              : 'Role assigned to $success users',
        ),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تعيين الأدوار' : 'Assign Roles'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
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
                        child: Text(isAr ? 'حصلت مشكلة' : 'Error'),
                      ),
                      Center(
                        child: TextButton(
                          onPressed: _load,
                          child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
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
                                  ? 'مفيش أدوار — ابدأ بإنشاء دور الأول'
                                  : 'No roles — create a role first',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              isAr
                                  ? 'دوس على الدور عشان تعيّنه لموظفين'
                                  : 'Tap a role to assign it to users',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _roles.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final role =
                                    _roles[index] as Map<String, dynamic>;
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x11000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    onTap: () => _showBulkAssignSheet(role),
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.teal
                                          .withValues(alpha: 0.12),
                                      child: const Icon(
                                        Icons.badge,
                                        color: Colors.teal,
                                      ),
                                    ),
                                    title: Text(
                                      '${role['name']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      isAr
                                          ? '${role['users_count'] ?? 0} مستخدم معيّن'
                                          : '${role['users_count'] ?? 0} users assigned',
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
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
