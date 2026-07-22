import 'package:flutter/material.dart';

class PermissionsExportScreen extends StatelessWidget {
  const PermissionsExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    void soon(String title) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'توصيل $title لسه الخطوة الجاية' : '$title connection is the next step',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تصدير الصلاحيات' : 'Export Permissions'),
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
                      ? 'تقدر تحمل تقرير دور معيّن أو مستخدم معيّن أو الشركة كلها PDF / Excel.'
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
            onPdf: () => soon(isAr ? 'PDF الدور' : 'Role PDF'),
            onExcel: () => soon(isAr ? 'Excel الدور' : 'Role Excel'),
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
            onPdf: () => soon(isAr ? 'PDF المستخدم' : 'User PDF'),
            onExcel: () => soon(isAr ? 'Excel المستخدم' : 'User Excel'),
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
            onPdf: () => soon(isAr ? 'PDF الشركة' : 'Company PDF'),
            onExcel: () => soon(isAr ? 'Excel الشركة' : 'Company Excel'),
          ),
        ],
      ),
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
          )
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
}
