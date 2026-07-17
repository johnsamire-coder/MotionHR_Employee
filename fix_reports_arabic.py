# -*- coding: utf-8 -*-
import os
from datetime import datetime

folder = r"C:\MotionHR\motionhr_employee\motionhr_employee\lib\screens\manager\reports"

if not os.path.exists(folder):
    print(f"ERROR: Folder not found: {folder}")
    exit(1)

# ==============================================
# 1) reports_hub_screen.dart
# ==============================================
hub = '''import 'package:flutter/material.dart';
import 'attendance_report_screen.dart';
import 'late_report_screen.dart';
import 'absence_report_screen.dart';
import 'requests_report_screen.dart';
import 'leaves_report_screen.dart';
import 'work_hours_report_screen.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('تقارير المدير'),
              subtitle: Text('الحضور - التأخير - الغياب - الطلبات - الإجازات - ساعات العمل'),
            ),
          ),
          const SizedBox(height: 8),
          _card(context, Icons.calendar_month, 'تقرير الحضور الشهري', 'عدد أيام الحضور لكل موظف', const AttendanceReportScreen()),
          _card(context, Icons.alarm, 'تقرير التأخير', 'تفاصيل أيام التأخير', const LateReportScreen()),
          _card(context, Icons.person_off, 'تقرير الغياب', 'أيام الغياب الشهرية', const AbsenceReportScreen()),
          _card(context, Icons.request_page, 'تقرير الطلبات', 'كل الطلبات والحالات', const RequestsReportScreen()),
          _card(context, Icons.beach_access, 'تقرير الإجازات', 'ملخص إجازات الموظفين', const LeavesReportScreen()),
          _card(context, Icons.access_time, 'تقرير ساعات العمل', 'ساعات العمل الفعلية', const WorkHoursReportScreen()),
        ],
      ),
    );
  }

  Widget _card(BuildContext ctx, IconData icon, String title, String subtitle, Widget screen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
'''

# ==============================================
# 2) attendance_report_screen.dart
# ==============================================
attendance = '''import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});
  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _service.getAttendanceReport();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الحضور'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: employees.isEmpty
                  ? ListView(children: const [SizedBox(height: 120), Center(child: Text('لا توجد بيانات'))])
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.calendar_month),
                            title: Text('الشهر: ${_data?['month'] ?? '-'} / ${_data?['year'] ?? '-'}'),
                            subtitle: Text('عدد الموظفين: ${_data?['total_employees'] ?? 0}'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...employees.map<Widget>((e) {
                          final item = Map<String, dynamic>.from(e as Map);
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(item['employee_name']?.toString() ?? '-'),
                              subtitle: Text('أيام الحضور: ${item['working_days'] ?? 0}'),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
'''

# ==============================================
# 3) late_report_screen.dart
# ==============================================
late_report = '''import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class LateReportScreen extends StatefulWidget {
  const LateReportScreen({super.key});
  @override
  State<LateReportScreen> createState() => _LateReportScreenState();
}

class _LateReportScreenState extends State<LateReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getLateReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير التأخير'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? const Center(child: Text('لا توجد حالات تأخير'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    final details = (item['details'] as List?) ?? const [];
                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text('أيام التأخير: ${item['total_late_days'] ?? 0} - ${item['total_late_hours'] ?? 0} س'),
                        children: details.map<Widget>((d) {
                          final detail = Map<String, dynamic>.from(d as Map);
                          return ListTile(
                            dense: true,
                            title: Text('${detail['date']} - ${detail['time']}'),
                            trailing: Text('${detail['minutes_late']} دقيقة'),
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
'''

# ==============================================
# 4) absence_report_screen.dart
# ==============================================
absence = '''import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class AbsenceReportScreen extends StatefulWidget {
  const AbsenceReportScreen({super.key});
  @override
  State<AbsenceReportScreen> createState() => _AbsenceReportScreenState();
}

class _AbsenceReportScreenState extends State<AbsenceReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getAbsenceReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الغياب'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? const Center(child: Text('لا توجد حالات غياب'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    final absentDates = (item['absent_dates'] as List?) ?? const [];
                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.event_busy, color: Colors.white)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text('غياب: ${item['absent_days'] ?? 0} / ${item['total_working_days'] ?? 0}'),
                        children: absentDates.map<Widget>((d) => ListTile(dense: true, title: Text(d.toString()))).toList(),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
'''

# ==============================================
# 5) requests_report_screen.dart
# ==============================================
requests = '''import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class RequestsReportScreen extends StatefulWidget {
  const RequestsReportScreen({super.key});
  @override
  State<RequestsReportScreen> createState() => _RequestsReportScreenState();
}

class _RequestsReportScreenState extends State<RequestsReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getRequestsReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final details = (_data?['details'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الطلبات'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('إجمالي الطلبات: ${_data?['total_requests'] ?? 0}'),
                        const SizedBox(height: 4),
                        Text('موافق: ${_data?['approved'] ?? 0} | مرفوض: ${_data?['rejected'] ?? 0} | معلق: ${_data?['pending'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...details.map<Widget>((r) {
                  final item = Map<String, dynamic>.from(r as Map);
                  return Card(
                    child: ListTile(
                      title: Text(item['employee_name']?.toString() ?? '-'),
                      subtitle: Text('${item['category']} - ${item['subject']}'),
                      trailing: Chip(label: Text(item['status']?.toString() ?? '-')),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
'''

# ==============================================
# 6) leaves_report_screen.dart
# ==============================================
leaves = '''import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class LeavesReportScreen extends StatefulWidget {
  const LeavesReportScreen({super.key});
  @override
  State<LeavesReportScreen> createState() => _LeavesReportScreenState();
}

class _LeavesReportScreenState extends State<LeavesReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getLeavesReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الإجازات'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('إجمالي الإجازات: ${_data?['total_leaves'] ?? 0}'),
                        const SizedBox(height: 4),
                        Text('موافق: ${_data?['approved'] ?? 0} | مرفوض: ${_data?['rejected'] ?? 0} | معلق: ${_data?['pending'] ?? 0}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...employees.map<Widget>((e) {
                  final item = Map<String, dynamic>.from(e as Map);
                  final lvs = (item['leaves'] as List?) ?? const [];
                  return Card(
                    child: ExpansionTile(
                      title: Text(item['name']?.toString() ?? '-'),
                      subtitle: Text('إجمالي: ${item['total_days'] ?? 0} - موافق: ${item['approved_days'] ?? 0}'),
                      children: lvs.map<Widget>((l) {
                        final lv = Map<String, dynamic>.from(l as Map);
                        return ListTile(
                          dense: true,
                          title: Text('${lv['type']} - ${lv['days']} يوم'),
                          subtitle: Text('من ${lv['from']} إلى ${lv['to']}'),
                          trailing: Chip(label: Text(lv['status']?.toString() ?? '-')),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
'''

# ==============================================
# 7) work_hours_report_screen.dart
# ==============================================
work_hours = '''import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class WorkHoursReportScreen extends StatefulWidget {
  const WorkHoursReportScreen({super.key});
  @override
  State<WorkHoursReportScreen> createState() => _WorkHoursReportScreenState();
}

class _WorkHoursReportScreenState extends State<WorkHoursReportScreen> {
  final _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try { _data = await _service.getWorkHoursReport(); } catch (e) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير ساعات العمل'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : employees.isEmpty
              ? const Center(child: Text('لا توجد بيانات'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.access_time)),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text('إجمالي: ${item['total_hours'] ?? 0} س - أيام: ${item['total_days_worked'] ?? 0}'),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
'''

files = {
    "reports_hub_screen.dart": hub,
    "attendance_report_screen.dart": attendance,
    "late_report_screen.dart": late_report,
    "absence_report_screen.dart": absence,
    "requests_report_screen.dart": requests,
    "leaves_report_screen.dart": leaves,
    "work_hours_report_screen.dart": work_hours,
}

for filename, content in files.items():
    filepath = os.path.join(folder, filename)
    # Backup
    if os.path.exists(filepath):
        backup = filepath + ".bak_" + datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename(filepath, backup)
    # Write with UTF-8 BOM
    with open(filepath, "w", encoding="utf-8-sig") as f:
        f.write(content)
    print(f"[OK] {filename}")

print("")
print("=" * 50)
print("DONE! All 7 files rewritten with correct Arabic")
print("=" * 50)
print("Now run: flutter run")