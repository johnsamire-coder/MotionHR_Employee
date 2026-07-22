import 'package:flutter/material.dart';
import 'permissions_roles_screen.dart';
import 'permissions_assign_screen.dart';
import 'permissions_overrides_screen.dart';
import 'permissions_export_screen.dart';

class PermissionsManagementScreen extends StatelessWidget {
  const PermissionsManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إدارة الصلاحيات' : 'Permissions Management'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      body: ListView(
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
                  isAr ? 'التحكم الكامل في الصلاحيات' : 'Full Permissions Control',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr
                      ? 'اعمل أدوار مخصصة، عيّنها للمستخدمين، واعمل استثناءات خاصة لأي شخص.'
                      : 'Create custom roles, assign them to users, and add user-specific overrides.',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _item(
            context: context,
            icon: Icons.badge,
            color: Colors.indigo,
            titleAr: 'الأدوار',
            titleEn: 'Roles',
            subAr: 'إنشاء وتعديل الأدوار المخصصة',
            subEn: 'Create and edit custom roles',
            isAr: isAr,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PermissionsRolesScreen(),
              ),
            ),
          ),
          _item(
            context: context,
            icon: Icons.people,
            color: Colors.teal,
            titleAr: 'تعيين الأدوار',
            titleEn: 'Assign Roles',
            subAr: 'ربط الأدوار بالمستخدمين',
            subEn: 'Assign roles to users',
            isAr: isAr,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PermissionsAssignScreen(),
              ),
            ),
          ),
          _item(
            context: context,
            icon: Icons.tune,
            color: Colors.orange,
            titleAr: 'استثناءات المستخدمين',
            titleEn: 'User Overrides',
            subAr: 'منح أو منع صلاحيات خاصة لشخص معيّن',
            subEn: 'Grant or block special permissions for a specific user',
            isAr: isAr,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PermissionsOverridesScreen(),
              ),
            ),
          ),
          _item(
            context: context,
            icon: Icons.download,
            color: Colors.green,
            titleAr: 'التصدير',
            titleEn: 'Export',
            subAr: 'تحميل PDF و Excel للصلاحيات',
            subEn: 'Download permissions as PDF and Excel',
            isAr: isAr,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PermissionsExportScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String titleAr,
    required String titleEn,
    required String subAr,
    required String subEn,
    required bool isAr,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          isAr ? titleAr : titleEn,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(isAr ? subAr : subEn),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
