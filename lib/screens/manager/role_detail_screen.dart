import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

class RoleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> role;

  const RoleDetailScreen({
    super.key,
    required this.role,
  });

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  final TextEditingController _nameCtrl = TextEditingController();

  List<dynamic> _availablePermissions = [];
  final Set<String> _selectedPermissions = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  int get _roleId => widget.role['id'] as int;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = '${widget.role['name'] ?? ''}';

    final currentPermissions = (widget.role['permissions'] as List?) ?? [];
    for (final item in currentPermissions) {
      final p = item as Map<String, dynamic>;
      final code = '${p['code'] ?? ''}'.trim();
      if (code.isNotEmpty) {
        _selectedPermissions.add(code);
      }
    }

    _loadAvailablePermissions();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePermissions() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final response = await http.get(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/available/',
        ),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _availablePermissions = data['permissions'] ?? [];
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

  Future<void> _saveRole() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final name = _nameCtrl.text.trim();

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

    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'اختار صلاحية واحدة على الأقل'
                : 'Choose at least one permission',
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final response = await http.put(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/roles/$_roleId/update/',
        ),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': name,
          'permissions': _selectedPermissions
              .map((code) => {'code': code, 'scope': 'company'})
              .toList(),
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (!mounted) return;

      setState(() => _saving = false);

      if (data['success'] == true) {
        widget.role['name'] = name;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  (isAr ? 'تم تحديث الدور' : 'Role updated successfully'),
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['error'] ?? (isAr ? 'حصلت مشكلة' : 'Something went wrong'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'حصلت مشكلة في حفظ الدور' : 'Failed to save role',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _permissionLabel(Map<String, dynamic> item, bool isAr) {
    if (isAr) {
      return '${item['label_ar'] ?? item['code'] ?? ''}';
    }
    return '${item['label_en'] ?? item['code'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تفاصيل الدور' : 'Role Details'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _saving ? null : _saveRole,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A148C),
              foregroundColor: Colors.white,
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(
              _saving
                  ? (isAr ? 'جاري الحفظ...' : 'Saving...')
                  : (isAr ? 'حفظ التعديلات' : 'Save Changes'),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailablePermissions,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          isAr
                              ? 'حصلت مشكلة في تحميل الصلاحيات'
                              : 'Failed to load permissions',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _loadAvailablePermissions,
                          child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
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
                              isAr ? 'تعديل الدور' : 'Edit Role',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'اكتب اسم الدور، وبعدها حدد الصلاحيات اللي تناسبه.'
                                  : 'Enter the role name, then choose the permissions that fit it.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: isAr ? 'اسم الدور' : 'Role Name',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            isAr ? 'الصلاحيات' : 'Permissions',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAr
                                  ? '${_selectedPermissions.length} محددة'
                                  : '${_selectedPermissions.length} selected',
                              style: const TextStyle(
                                color: Color(0xFF4A148C),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_availablePermissions.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
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
                              isAr ? 'مفيش صلاحيات متاحة' : 'No permissions available',
                            ),
                          ),
                        )
                      else
                        ..._availablePermissions.map((item) {
                          final perm = item as Map<String, dynamic>;
                          final code = '${perm['code'] ?? ''}';
                          final label = _permissionLabel(perm, isAr);
                          final selected = _selectedPermissions.contains(code);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
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
                            child: CheckboxListTile(
                              value: selected,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                code,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                              onChanged: (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedPermissions.add(code);
                                  } else {
                                    _selectedPermissions.remove(code);
                                  }
                                });
                              },
                            ),
                          );
                        }),
                    ],
                  ),
      ),
    );
  }
}