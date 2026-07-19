import 'package:flutter/material.dart';
import 'payroll_summary_screen.dart';
import 'payroll_settings_screen.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

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
                title: Text(isAr ? 'نظام الرواتب' : 'Payroll System'),
                subtitle: Text(
                  isAr
                      ? 'ملخص الرواتب - تفاصيل الموظف - الإعدادات'
                      : 'Payroll Summary - Employee Details - Settings',
                ),
              ),
            ),
            const SizedBox(height: 8),
            _card(
              context,
              Icons.receipt_long,
              Colors.green,
              isAr ? 'ملخص الرواتب الشهري' : 'Monthly Payroll Summary',
              isAr ? 'كل الموظفين مع الخصومات والبونص' : 'All employees with deductions and bonuses',
              const PayrollSummaryScreen(),
            ),
            _card(
              context,
              Icons.settings,
              Colors.blueGrey,
              isAr ? 'إعدادات حساب الرواتب' : 'Payroll Calculation Settings',
              isAr ? 'قواعد الخصومات والبونص' : 'Deduction and bonus rules',
              const PayrollSettingsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext ctx,
    IconData icon,
    Color color,
    String title,
    String subtitle,
    Widget screen,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }
}