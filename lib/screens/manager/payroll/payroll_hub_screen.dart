import 'package:flutter/material.dart';
import 'payroll_summary_screen.dart';
import 'payroll_settings_screen.dart';

class PayrollHubScreen extends StatelessWidget {
  const PayrollHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الرواتب')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('نظام الرواتب'),
              subtitle: Text('ملخص الرواتب - تفاصيل الموظف - الإعدادات'),
            ),
          ),
          const SizedBox(height: 8),
          _card(context, Icons.receipt_long, Colors.green, 'ملخص الرواتب الشهري', 'كل الموظفين مع الخصومات والبونص', const PayrollSummaryScreen()),
          _card(context, Icons.settings, Colors.blueGrey, 'إعدادات حساب الرواتب', 'قواعد الخصومات والبونص', const PayrollSettingsScreen()),
        ],
      ),
    );
  }

  Widget _card(BuildContext ctx, IconData icon, Color color, String title, String subtitle, Widget screen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
