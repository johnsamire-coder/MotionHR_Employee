import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

class DepartmentsManagementScreen extends StatefulWidget {
  const DepartmentsManagementScreen({super.key});

  @override
  State<DepartmentsManagementScreen> createState() =>
      _DepartmentsManagementScreenState();
}

class _DepartmentsManagementScreenState
    extends State<DepartmentsManagementScreen> {
  List<dynamic> _departments = [];
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
      final r = await http.get(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/departments/list/',
        ),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (r.statusCode == 200) {
        final d = json.decode(utf8.decode(r.bodyBytes));
        setState(() {
          _departments = d['departments'] ?? [];
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

  void _showAddSheet() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final nameArCtrl = TextEditingController();
    final nameEnCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
                labelText: isAr ? 'اسم القسم بالعربي' : 'Department Name (Arabic)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameEnCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم القسم بالإنجليزي (اختياري)' : 'Department Name (English - optional)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameArCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  await _addDepartment(nameArCtrl.text.trim(), nameEnCtrl.text.trim());
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
    );
  }

  Future<void> _addDepartment(String nameAr, String nameEn) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final r = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/departments/add/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: json.encode({'name_ar': nameAr, 'name_en': nameEn}),
      );
      final d = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(d['message'] ?? (isAr ? 'تم' : 'Done'))),
      );
      _load();
    } catch (_) {}
  }

  Future<void> _deleteDepartment(Map<String, dynamic> dept) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken() ?? '';
    final deptId = dept['id'];
    final count = dept['employees_count'] ?? 0;

    if (count > 0) {
      // لازم يختار قسم بديل
      final otherDepts = _departments.where((d) => d['id'] != deptId).toList();
      if (otherDepts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'مفيش أقسام تانية للنقل إليها' : 'No other departments to transfer to')),
        );
        return;
      }

      int? selectedDeptId;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isAr ? 'نقل الموظفين' : 'Transfer Employees'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isAr
                  ? 'فيه $count موظف في القسم ده. اختار قسم بديل:'
                  : 'There are $count employees. Choose a department:'),
              const SizedBox(height: 12),
              ...otherDepts.map((d) => ListTile(
                    title: Text('${d['name_ar']}'),
                    onTap: () {
                      selectedDeptId = d['id'];
                      Navigator.pop(ctx);
                    },
                  )),
            ],
          ),
        ),
      );

      if (selectedDeptId == null) return;

      final r = await http.delete(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/departments/$deptId/delete/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: json.encode({'transfer_to_department_id': selectedDeptId}),
      );
      final data = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? '')),
      );
    } else {
      final r = await http.delete(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/departments/$deptId/delete/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: json.encode({}),
      );
      final data = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? '')),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إدارة الأقسام' : 'Departments Management'),
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
                    Center(child: TextButton(onPressed: _load, child: Text(isAr ? 'إعادة المحاولة' : 'Retry'))),
                  ])
                : _departments.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            isAr ? 'مفيش أقسام — دوس + عشان تضيف' : 'No departments — press + to add',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ])
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _departments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final dept = _departments[index] as Map<String, dynamic>;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF4A148C).withValues(alpha: 0.1),
                                  child: const Icon(Icons.business, color: Color(0xFF4A148C)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${dept['name_ar']}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      if ((dept['name_en'] ?? '').isNotEmpty)
                                        Text('${dept['name_en']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      Text(
                                        isAr ? '${dept['employees_count']} موظف' : '${dept['employees_count']} employees',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF4A148C)),
                                      ),
                                      if (dept['default_role'] != null)
                                        Text(
                                          isAr ? 'الدور: ${dept['default_role']['name']}' : 'Role: ${dept['default_role']['name']}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteDepartment(dept),
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
