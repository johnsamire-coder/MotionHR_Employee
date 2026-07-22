import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';
import 'department_detail_screen.dart';

class DepartmentsManagementScreen extends StatefulWidget {
  const DepartmentsManagementScreen({super.key});

  @override
  State<DepartmentsManagementScreen> createState() =>
      _DepartmentsManagementScreenState();
}

class _DepartmentsManagementScreenState
    extends State<DepartmentsManagementScreen> {
  List<dynamic> _departments = [];
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
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/departments/list/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      final r2 = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/roles/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (r1.statusCode == 200) {
        final d = json.decode(utf8.decode(r1.bodyBytes));
        setState(() => _departments = d['departments'] ?? []);
      }
      if (r2.statusCode == 200) {
        final d = json.decode(utf8.decode(r2.bodyBytes));
        setState(() => _roles = d['roles'] ?? []);
      }
      setState(() => _loading = false);
    } catch (_) {
      setState(() {
        _error = 'connection';
        _loading = false;
      });
    }
  }

  void _showAddSheet() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();
    int? selectedRoleId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'إضافة قسم جديد' : 'Add New Department',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameArCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم القسم بالعربي' : 'Name (Arabic)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameEnCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'اسم القسم بالإنجليزي (اختياري)' : 'Name (English - optional)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: isAr ? 'الدور الافتراضي (اختياري)' : 'Default Role (optional)',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(isAr ? 'بدون دور' : 'No role'),
                  ),
                  ..._roles.map((r) => DropdownMenuItem(
                    value: r['id'] as int,
                    child: Text('${r['name']}'),
                  )),
                ],
                onChanged: (v) => setS(() => selectedRoleId = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameArCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    await _addDepartment(
                      nameArCtrl.text.trim(),
                      nameEnCtrl.text.trim(),
                      selectedRoleId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A148C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isAr ? 'إضافة' : 'Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addDepartment(String nameAr, String nameEn, int? roleId) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final body = <String, dynamic>{'name_ar': nameAr};
      if (nameEn.isNotEmpty) body['name_en'] = nameEn;
      if (roleId != null) body['default_role_id'] = roleId;

      final r = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/departments/add/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      final d = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(d['message'] ?? (isAr ? 'تم' : 'Done'))),
      );
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إدارة الأقسام' : 'Departments'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: const Color(0xFF4A148C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(children: [
                    const SizedBox(height: 120),
                    Center(child: Text(isAr ? 'حصلت مشكلة' : 'Error')),
                    Center(
                      child: TextButton(
                        onPressed: _load,
                        child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ),
                  ])
                : _departments.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.business, size: 52, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              Text(
                                isAr ? 'مفيش أقسام — دوس + عشان تضيف' : 'No departments — press + to add',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _departments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final dept = _departments[index] as Map<String, dynamic>;
                          final hasRole = dept['default_role'] != null;

                          return InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DepartmentDetailScreen(
                                  department: dept,
                                  roles: _roles,
                                ),
                              ),
                            ).then((_) => _load()),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4A148C).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.business,
                                      color: Color(0xFF4A148C),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${dept['name_ar']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if ((dept['name_en'] ?? '').isNotEmpty)
                                          Text(
                                            '${dept['name_en']}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEEF2FF),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isAr
                                                    ? '${dept['employees_count']} موظف'
                                                    : '${dept['employees_count']} employees',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF4A148C),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            if (hasRole)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${dept['default_role']['name']}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.green.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  isAr ? 'بدون دور' : 'No role',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.orange.shade700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
