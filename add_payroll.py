# -*- coding: utf-8 -*-
import os
import shutil
from datetime import datetime

BASE = r"C:\MotionHR\motionhr_employee\motionhr_employee\lib"

# ========================================
# 1) payroll_service.dart
# ========================================
service_content = '''import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrlPayroll = 'https://jssolutions-eg.com';

class PayrollService {
  Future<Map<String, dynamic>> _get(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final response = await http.get(
      Uri.parse('$kBaseUrlPayroll$url'),
      headers: {'Authorization': 'Token $token'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return Map<String, dynamic>.from(decoded as Map);
    } else {
      throw Exception('Failed: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getSummary({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get('/attendance/api/mobile/manager/payroll/summary/?year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getEmployeeDetail({
    required int employeeId,
    int? year,
    int? month,
  }) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _get('/attendance/api/mobile/manager/payroll/employee/?employee_id=$employeeId&year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getSettings() async {
    return _get('/attendance/api/mobile/manager/payroll/settings/');
  }
}
'''

# ========================================
# 2) payroll_hub_screen.dart
# ========================================
hub_content = '''import 'package:flutter/material.dart';
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
'''

# ========================================
# 3) payroll_summary_screen.dart
# ========================================
summary_content = '''import 'package:flutter/material.dart';
import '../../../services/payroll_service.dart';
import 'payroll_employee_detail_screen.dart';

class PayrollSummaryScreen extends StatefulWidget {
  const PayrollSummaryScreen({super.key});
  @override
  State<PayrollSummaryScreen> createState() => _PayrollSummaryScreenState();
}

class _PayrollSummaryScreenState extends State<PayrollSummaryScreen> {
  final _service = PayrollService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _data = await _service.getSummary(); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('ملخص الرواتب'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('الشهر: ${_data?['month'] ?? '-'} / ${_data?['year'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const Divider(),
                          _row('عدد الموظفين', '${_data?['total_employees'] ?? 0}'),
                          _row('إجمالي الرواتب', '${_data?['grand_total_salary'] ?? 0} ج'),
                          _row('إجمالي الخصومات', '${_data?['grand_total_deductions'] ?? 0} ج', color: Colors.red),
                          _row('إجمالي Overtime', '${_data?['grand_total_overtime'] ?? 0} ج', color: Colors.blue),
                          const Divider(),
                          _row('صافي الرواتب', '${_data?['grand_total_net'] ?? 0} ج', color: Colors.green, bold: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (employees.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('لا يوجد موظفين لعرضهم')))),
                  ...employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('حضور: ${item['attended_days'] ?? 0} | غياب: ${item['absent_days'] ?? 0} | تأخير: ${item['late_days'] ?? 0}'),
                            Text('ساعات: ${item['total_work_hours'] ?? 0} | OT: ${item['overtime_hours'] ?? 0}'),
                            Text('صافي: ${item['net_salary'] ?? 0} ج', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => PayrollEmployeeDetailScreen(
                            employeeId: item['employee_id'] as int,
                            employeeName: item['employee_name']?.toString() ?? '-',
                          )));
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}
'''

# ========================================
# 4) payroll_employee_detail_screen.dart
# ========================================
detail_content = '''import 'package:flutter/material.dart';
import '../../../services/payroll_service.dart';

class PayrollEmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  const PayrollEmployeeDetailScreen({super.key, required this.employeeId, required this.employeeName});

  @override
  State<PayrollEmployeeDetailScreen> createState() => _PayrollEmployeeDetailScreenState();
}

class _PayrollEmployeeDetailScreenState extends State<PayrollEmployeeDetailScreen> {
  final _service = PayrollService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getEmployeeDetail(employeeId: widget.employeeId); } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final daily = (_data?['daily_details'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(widget.employeeName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('لا توجد بيانات'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('الملخص المالي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            _row('الراتب الأساسي', '${_data?['basic_salary'] ?? 0} ج'),
                            _row('خصم التأخير', '${_data?['late_deduction'] ?? 0} ج', color: Colors.red),
                            _row('خصم الغياب', '${_data?['absence_deduction'] ?? 0} ج', color: Colors.red),
                            _row('إجمالي الخصومات', '${_data?['total_deductions'] ?? 0} ج', color: Colors.red),
                            _row('بونص Overtime', '${_data?['overtime_bonus'] ?? 0} ج', color: Colors.blue),
                            const Divider(),
                            _row('صافي الراتب', '${_data?['net_salary'] ?? 0} ج', color: Colors.green, bold: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ملخص الحضور', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Divider(),
                            _row('أيام الحضور', '${_data?['attended_days'] ?? 0}'),
                            _row('أيام الحاضر (present)', '${_data?['present_days'] ?? 0}'),
                            _row('أيام التأخير', '${_data?['late_days'] ?? 0}', color: Colors.orange),
                            _row('أيام الغياب', '${_data?['absent_days'] ?? 0}', color: Colors.red),
                            _row('أيام الإجازة', '${_data?['on_leave_days'] ?? 0}'),
                            _row('دقائق التأخير', '${_data?['total_late_minutes'] ?? 0} د'),
                            _row('إجمالي ساعات العمل', '${_data?['total_work_hours'] ?? 0} س'),
                            _row('ساعات Overtime', '${_data?['overtime_hours'] ?? 0} س'),
                          ],
                        ),
                      ),
                    ),
                    if (daily.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('التفاصيل اليومية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      ...daily.map<Widget>((d) {
                        final day = Map<String, dynamic>.from(d as Map);
                        final status = day['status']?.toString() ?? '-';
                        final color = status == 'present' ? Colors.green : status == 'late' ? Colors.orange : status == 'absent' ? Colors.red : Colors.grey;
                        return Card(
                          child: ListTile(
                            dense: true,
                            leading: Icon(Icons.circle, color: color, size: 16),
                            title: Text(day['date']?.toString() ?? '-'),
                            subtitle: Text('دخول: ${day['check_in'] ?? '-'} | خروج: ${day['check_out'] ?? '-'} | ساعات: ${day['work_hours'] ?? 0}'),
                            trailing: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
    );
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(color: color, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }
}
'''

# ========================================
# 5) payroll_settings_screen.dart
# ========================================
settings_content = '''import 'package:flutter/material.dart';
import '../../../services/payroll_service.dart';

class PayrollSettingsScreen extends StatefulWidget {
  const PayrollSettingsScreen({super.key});
  @override
  State<PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<PayrollSettingsScreen> {
  final _service = PayrollService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getSettings(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات الرواتب')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text('لا توجد بيانات'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.blue),
                        title: Text('ملاحظة'),
                        subtitle: Text('الإعدادات حالياً ثابتة وستكون قابلة للتعديل لاحقاً'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(Icons.money_off, 'خصم التأخير / دقيقة', '${_data?['late_deduction_per_minute'] ?? '-'} ج'),
                    _card(Icons.event_busy, 'خصم الغياب / يوم', '${_data?['absence_deduction_per_day'] ?? '-'} ج'),
                    _card(Icons.more_time, 'معدل Overtime / ساعة', '${_data?['overtime_rate_per_hour'] ?? '-'} ج'),
                  ],
                ),
    );
  }

  Widget _card(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon, size: 20)),
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
'''

# ========================================
# Save files
# ========================================
files = {
    r"services\payroll_service.dart": service_content,
    r"screens\manager\payroll\payroll_hub_screen.dart": hub_content,
    r"screens\manager\payroll\payroll_summary_screen.dart": summary_content,
    r"screens\manager\payroll\payroll_employee_detail_screen.dart": detail_content,
    r"screens\manager\payroll\payroll_settings_screen.dart": settings_content,
}

for rel_path, content in files.items():
    full_path = os.path.join(BASE, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    with open(full_path, "w", encoding="utf-8-sig") as f:
        f.write(content)
    print(f"[OK] {rel_path}")

# ========================================
# Update main.dart
# ========================================
main_file = os.path.join(BASE, "main.dart")
backup = main_file + ".bak_before_payroll_" + datetime.now().strftime("%Y%m%d_%H%M%S")
shutil.copy2(main_file, backup)
print(f"\n[BACKUP] {backup}")

with open(main_file, "r", encoding="utf-8") as f:
    content = f.read()

# Add import
import_line = "import 'screens/manager/payroll/payroll_hub_screen.dart';"
if import_line not in content:
    content = content.replace(
        "import 'screens/manager/reports/reports_hub_screen.dart';",
        "import 'screens/manager/reports/reports_hub_screen.dart';\n" + import_line,
        1
    )
    print("[OK] Import added to main.dart")

# Add payroll card after reports card
old = """() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen())))]));"""
new = """() => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsHubScreen()))),
      const SizedBox(height: 12),
      _card('الرواتب', 'عرض', Icons.account_balance_wallet, Colors.green,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollHubScreen())))]));"""

if "PayrollHubScreen()" in content:
    print("[SKIP] Payroll card already exists")
elif old in content:
    content = content.replace(old, new)
    print("[OK] Payroll card added to main.dart")
else:
    print("[WARNING] Could not find reports card pattern")

with open(main_file, "w", encoding="utf-8") as f:
    f.write(content)

print("")
print("=" * 50)
print("DONE!")
print("=" * 50)
print("Now run: flutter run")