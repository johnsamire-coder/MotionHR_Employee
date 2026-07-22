import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/auth_storage_service.dart';

class PermissionsExportScreen extends StatefulWidget {
  const PermissionsExportScreen({super.key});

  @override
  State<PermissionsExportScreen> createState() => _PermissionsExportScreenState();
}

class _PermissionsExportScreenState extends State<PermissionsExportScreen> {
  List<dynamic> _roles = [];
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final headers = {'Authorization': 'Token $token'};

      final rolesResponse = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/roles/'),
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      final usersResponse = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/users/'),
        headers: headers,
      ).timeout(const Duration(seconds: 20));

      if (rolesResponse.statusCode == 200) {
        final data = json.decode(utf8.decode(rolesResponse.bodyBytes));
        _roles = data['roles'] ?? [];
      }

      if (usersResponse.statusCode == 200) {
        final data = json.decode(utf8.decode(usersResponse.bodyBytes));
        _users = data['users'] ?? [];
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadExport({
    required String type,
    required String format,
    int? id,
    String? fileName,
  }) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final token = await AuthStorageService.getSavedToken() ?? '';

    try {
      final query = <String, String>{
        'type': type,
        'format': format,
        if (id != null) 'id': '$id',
      };

      final uri = Uri.parse(
        'https://jssolutions-eg.com/attendance/api/mobile/manager/permissions/export/',
      ).replace(queryParameters: query);

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode != 200) {
        String errorMessage = isAr ? 'فشل في التصدير' : 'Export failed';
        try {
          final data = json.decode(utf8.decode(response.bodyBytes));
          errorMessage = data['error'] ?? errorMessage;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final dir = await getTemporaryDirectory();
      final ext = format == 'pdf' ? 'pdf' : 'xlsx';
      final safeName = (fileName ?? '${type}_permissions').replaceAll(' ', '_');
      final file = File('${dir.path}/$safeName.$ext');

      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تم تحميل الملف، جاري فتحه...' : 'File downloaded, opening...',
          ),
          backgroundColor: Colors.green,
        ),
      );

      if (!mounted) return;
      await OpenFile.open(file.path);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'حصلت مشكلة أثناء التحميل' : 'Download failed',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickRoleAndExport(String format) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'مفيش أدوار متاحة' : 'No roles available'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAr ? 'اختار الدور' : 'Select Role',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final role = _roles[i] as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.withValues(alpha: 0.12),
                        child: const Icon(Icons.badge, color: Colors.indigo),
                      ),
                      title: Text('${role['name'] ?? ''}'),
                      subtitle: Text(
                        isAr
                            ? '${role['users_count'] ?? 0} مستخدم'
                            : '${role['users_count'] ?? 0} users',
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _downloadExport(
                          type: 'role',
                          format: format,
                          id: role['id'],
                          fileName: 'role_${role['id']}',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickUserAndExport(String format) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'مفيش مستخدمين متاحين' : 'No users available'),
        ),
      );
      return;
    }

    final searchCtrl = TextEditingController();
    List<dynamic> filtered = List.from(_users);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'اختار المستخدم' : 'Select User',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    labelText: isAr ? 'ابحث بالاسم أو اليوزرنيم' : 'Search by name or username',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    final q = v.toLowerCase().trim();
                    setS(() {
                      filtered = _users.where((u) {
                        final fullName = '${u['full_name'] ?? ''}'.toLowerCase();
                        final username = '${u['username'] ?? ''}'.toLowerCase();
                        return fullName.contains(q) || username.contains(q);
                      }).toList();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final user = filtered[i] as Map<String, dynamic>;
                      final assignedRoles = (user['assigned_roles'] as List?) ?? [];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.withValues(alpha: 0.12),
                          child: const Icon(Icons.person, color: Colors.orange),
                        ),
                        title: Text(
                          ('${user['full_name'] ?? ''}').trim().isEmpty
                              ? '${user['username'] ?? ''}'
                              : '${user['full_name']}',
                        ),
                        subtitle: Text(
                          assignedRoles.isEmpty
                              ? (isAr ? 'بدون أدوار معيّنة' : 'No assigned roles')
                              : assignedRoles.join(' - '),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _downloadExport(
                            type: 'user',
                            format: format,
                            id: user['id'],
                            fileName: 'user_${user['id']}_permissions',
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportCompany(String format) async {
    await _downloadExport(
      type: 'company',
      format: format,
      fileName: 'company_permissions',
    );
  }

  Widget _card({
    required BuildContext context,
    required bool isAr,
    required String titleAr,
    required String titleEn,
    required String subAr,
    required String subEn,
    required IconData icon,
    required Color color,
    required VoidCallback onPdf,
    required VoidCallback onExcel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isAr ? titleAr : titleEn,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isAr ? subAr : subEn,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Excel'),
                ),
              ),
            ],
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
        title: Text(isAr ? 'تصدير الصلاحيات' : 'Export Permissions'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? 'تحميل الصلاحيات' : 'Download Permissions',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr
                              ? 'تقدر تحمل صلاحيات دور معيّن أو مستخدم معيّن أو الشركة كلها PDF / Excel.'
                              : 'You can export a specific role, a specific user, or the whole company as PDF / Excel.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _card(
                    context: context,
                    isAr: isAr,
                    titleAr: 'تصدير دور معيّن',
                    titleEn: 'Export Specific Role',
                    subAr: 'تحميل صلاحيات دور واحد PDF أو Excel',
                    subEn: 'Download one role permissions as PDF or Excel',
                    icon: Icons.badge,
                    color: Colors.indigo,
                    onPdf: () => _pickRoleAndExport('pdf'),
                    onExcel: () => _pickRoleAndExport('excel'),
                  ),
                  _card(
                    context: context,
                    isAr: isAr,
                    titleAr: 'تصدير مستخدم معيّن',
                    titleEn: 'Export Specific User',
                    subAr: 'تحميل صلاحيات مستخدم واحد PDF أو Excel',
                    subEn: 'Download one user permissions as PDF or Excel',
                    icon: Icons.person,
                    color: Colors.orange,
                    onPdf: () => _pickUserAndExport('pdf'),
                    onExcel: () => _pickUserAndExport('excel'),
                  ),
                  _card(
                    context: context,
                    isAr: isAr,
                    titleAr: 'تصدير الشركة كلها',
                    titleEn: 'Export Whole Company',
                    subAr: 'تحميل كل الصلاحيات في الشركة PDF أو Excel',
                    subEn: 'Download all company permissions as PDF or Excel',
                    icon: Icons.business,
                    color: Colors.green,
                    onPdf: () => _exportCompany('pdf'),
                    onExcel: () => _exportCompany('excel'),
                  ),
                ],
              ),
      ),
    );
  }
}


