import 'package:flutter/material.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

import '../work_policy_screen.dart';
import 'payroll_settings_screen.dart';
import 'payroll_summary_screen.dart';

class PayrollHubScreen extends StatelessWidget {
  const PayrollHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.payroll),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(
                  isAr ? 'نظام الرواتب' : 'Payroll System',
                ),
                subtitle: Text(
                  isAr
                      ? 'ملخص الرواتب - الإعدادات - أيام العمل'
                      : 'Payroll Summary - Settings - Work Days',
                ),
              ),
            ),
            const SizedBox(height: 8),
            _card(
              context: context,
              isAr: isAr,
              icon: Icons.receipt_long,
              color: Colors.green,
              title: isAr
                  ? 'ملخص الرواتب الشهري'
                  : 'Monthly Payroll Summary',
              subtitle: isAr
                  ? 'كل الموظفين مع الخصومات والبونص'
                  : 'All employees with deductions and bonuses',
              screen: const PayrollSummaryScreen(),
            ),
            _card(
              context: context,
              isAr: isAr,
              icon: Icons.settings,
              color: Colors.blueGrey,
              title: isAr
                  ? 'إعدادات حساب الرواتب'
                  : 'Payroll Settings',
              subtitle: isAr
                  ? 'قواعد الخصومات والبونص'
                  : 'Deduction and bonus rules',
              screen: const PayrollSettingsScreen(),
            ),
            _card(
              context: context,
              isAr: isAr,
              icon: Icons.calendar_month,
              color: Colors.orange,
              title: isAr
                  ? 'أيام العمل والإجازات'
                  : 'Work Days & Holidays',
              subtitle: isAr
                  ? 'تحديد أيام العمل الأسبوعية'
                  : 'Define weekly work days',
              screen: const WorkPolicyScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required BuildContext context,
    required bool isAr,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          isAr ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }
}