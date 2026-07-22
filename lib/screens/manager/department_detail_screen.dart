import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

class DepartmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> department;
  final List<dynamic> roles;

  const DepartmentDetailScreen({
    super.key,
    required this.department,
    required this.roles,
  });

  @override
  State<DepartmentDetailScreen> createState() => _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState extends State<DepartmentDetailScreen> {
  List<dynamic> _employees = [];
  bool _loading = true;
  late Map<String, dynamic> _dept;

  @override
  void initState() {
    super.initState();
    _dept = Map.from(widget.department);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final deptId = _dept['id'];

      final r = await http.get(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/employees/?department_id=$deptId',
        ),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (r.statusCode == 200) {
        final d = json.decode(utf8.decode(r.bodyBytes));
        final all = (d['employees'] as List?) ?? [];
        setState(() {
          _employees = all.where((e) => e['department_id'] == deptId).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateDefaultRole(int? roleId) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final r = await http.put(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/departments/${_dept['id']}/edit/',
        ),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'default_role_id': roleId ?? 0}),
      );
      final d = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(d['message'] ?? (isAr ? 'تم' : 'Done'))),
      );

      // حدّث البيانات المحلية
      final selectedRole = roleId == null
          ? null
          : widget.roles.firstWhere(
              (r) => r['id'] == roleId,
              orElse: () => null,
            );

      setState(() {
        _dept['default_role'] = selectedRole != null
            ? {'id': selectedRole['id'], 'name': selectedRole['name']}
            : null;
      });
    } catch (_) {}
  }

  Future<void> _renameDepartment() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final nameCtrl = TextEditingController(text: _dept['name_ar']);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'تعديل اسم القسم' : 'Rename Department'),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: isAr ? 'اسم القسم' : 'Department Name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? 'حفظ' : 'Save'),
          ),
        ],
      ),
    );

    if (confirmed != true || nameCtrl.text.trim().isEmpty) return;

    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final r = await http.put(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/departments/${_dept['id']}/edit/',
        ),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'name_ar': nameCtrl.text.trim()}),
      );
      final d = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(d['message'] ?? '')),
      );
      setState(() => _dept['name_ar'] = nameCtrl.text.trim());
    } catch (_) {}
  }

  Future<void> _deleteDepartment() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final count = _employees.length;

    if (count > 0) {
      // لازم يختار قسم بديل
      final depts = await _fetchOtherDepartments();
      if (!mounted) return;

      if (depts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAr ? 'مفيش أقسام تانية للنقل' : 'No other departments',
            ),
          ),
        );
        return;
      }

      int? transferToId;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'نقل الموظفين أولًا' : 'Transfer Employees First'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAr
                    ? 'فيه $count موظف في القسم. اختار القسم البديل:'
                    : 'There are $count employees. Choose a department:',
              ),
              const SizedBox(height: 12),
              ...depts.map(
                (d) => ListTile(
                  title: Text('${d['name_ar']}'),
                  subtitle: Text(
                    isAr
                        ? '${d['employees_count']} موظف'
                        : '${d['employees_count']} employees',
                  ),
                  onTap: () {
                    transferToId = d['id'];
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (transferToId == null) return;
      await _confirmDelete(transferToId);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'حذف القسم' : 'Delete Department'),
          content: Text(
            isAr
                ? 'مؤكد عايز تحذف "${_dept['name_ar']}"؟'
                : 'Delete "${_dept['name_ar']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isAr ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isAr ? 'حذف' : 'Delete',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await _confirmDelete(null);
    }
  }

  Future<void> _confirmDelete(int? transferToId) async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final body = <String, dynamic>{};
      if (transferToId != null) body['transfer_to_department_id'] = transferToId;

      final r = await http.delete(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/departments/${_dept['id']}/delete/',
        ),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      final d = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(d['message'] ?? '')),
      );
      if (d['success'] == true) Navigator.pop(context);
    } catch (_) {}
  }

  Future<List<dynamic>> _fetchOtherDepartments() async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final r = await http.get(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/departments/list/',
        ),
        headers: {'Authorization': 'Token $token'},
      );
      if (r.statusCode == 200) {
        final d = json.decode(utf8.decode(r.bodyBytes));
        final all = (d['departments'] as List?) ?? [];
        return all.where((d) => d['id'] != _dept['id']).toList();
      }
    } catch (_) {}
    return [];
  }

  void _showRoleSheet() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    int? selectedRoleId = _dept['default_role']?['id'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'تغيير الدور الافتراضي' : 'Change Default Role',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isAr
                    ? 'الدور اللي هياخده أي موظف جديد في القسم تلقائي'
                    : 'The role any new employee in this department will get automatically',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Icon(
                  selectedRoleId == null
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: const Color(0xFF4A148C),
                ),
                title: Text(isAr ? 'بدون دور' : 'No role'),
                onTap: () {
                  setS(() => selectedRoleId = null);
                  Navigator.pop(ctx);
                  _updateDefaultRole(null);
                },
              ),
              ...widget.roles.map((role) => ListTile(
                    leading: Icon(
                      selectedRoleId == role['id']
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: const Color(0xFF4A148C),
                    ),
                    title: Text('${role['name']}'),
                    subtitle: Text(
                      isAr
                          ? '${(role['permissions'] as List?)?.length ?? 0} صلاحية'
                          : '${(role['permissions'] as List?)?.length ?? 0} permissions',
                    ),
                    onTap: () {
                      setS(() => selectedRoleId = role['id']);
                      Navigator.pop(ctx);
                      _updateDefaultRole(role['id']);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final hasRole = _dept['default_role'] != null;

    return Scaffold(
      appBar: AppBar(
        title: Text('${_dept['name_ar']}'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'rename') _renameDepartment();
              if (v == 'delete') _deleteDepartment();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit, size: 18),
                    const SizedBox(width: 8),
                    Text(isAr ? 'تعديل الاسم' : 'Rename'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      isAr ? 'حذف القسم' : 'Delete',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // كارت الدور الافتراضي
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: hasRole
                      ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                      : [Colors.orange.shade700, Colors.orange.shade400],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'الدور الافتراضي' : 'Default Role',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasRole
                              ? '${_dept['default_role']['name']}'
                              : (isAr ? 'مفيش دور محدد' : 'No role assigned'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAr
                              ? 'الدور اللي ياخده أي موظف جديد تلقائي'
                              : 'Auto-assigned to new employees',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _showRoleSheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4A148C),
                    ),
                    child: Text(isAr ? 'تغيير' : 'Change'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // عنوان الموظفين
            Row(
              children: [
                Text(
                  isAr ? 'الموظفين' : 'Employees',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_employees.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_employees.isEmpty)
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
                    isAr ? 'مفيش موظفين في القسم ده' : 'No employees in this department',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              )
            else
              ..._employees.map((emp) {
                final e = emp as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF4A148C).withValues(alpha: 0.1),
                        child: Text(
                          (e['full_name'] ?? '?').toString().characters.first,
                          style: const TextStyle(
                            color: Color(0xFF4A148C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e['full_name'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${e['job_title'] ?? ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if ((e['phone'] ?? '').isNotEmpty)
                              Text(
                                '📞 ${e['phone']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}


