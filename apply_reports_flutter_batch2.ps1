$ErrorActionPreference = "Stop"

$projectRoot = "C:\MotionHR\motionhr_employee\motionhr_employee"
if (-not (Test-Path "$projectRoot\pubspec.yaml")) {
    Write-Host "❌ pubspec.yaml not found in: $projectRoot" -ForegroundColor Red
    exit 1
}

Set-Location $projectRoot
New-Item -ItemType Directory -Force -Path "lib\screens\manager\reports" | Out-Null

Set-Content -Path "lib\screens\manager\reports\attendance_report_screen.dart" -Encoding UTF8 -Value @'
import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final ReportsService _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getAttendanceReport();
      if (!mounted) return;
      setState(() {
        _data = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل تقرير الحضور: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الحضور'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: employees.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('لا توجد بيانات حضور')),
                      ],
                    )
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
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(item['employee_name']?.toString() ?? '-'),
                              subtitle: Text(
                                'أيام الحضور: ${item['working_days'] ?? 0} | '
                                'Check-in: ${item['total_checkins'] ?? 0} | '
                                'Check-out: ${item['total_checkouts'] ?? 0}',
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
'@

Set-Content -Path "lib\screens\manager\reports\late_report_screen.dart" -Encoding UTF8 -Value @'
import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class LateReportScreen extends StatefulWidget {
  const LateReportScreen({super.key});

  @override
  State<LateReportScreen> createState() => _LateReportScreenState();
}

class _LateReportScreenState extends State<LateReportScreen> {
  final ReportsService _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getLateReport();
      if (!mounted) return;
      setState(() {
        _data = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل تقرير التأخير: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير التأخير'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: employees.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('لا توجد حالات تأخير')),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.alarm),
                            title: Text('عدد الموظفين المتأخرين: ${_data?['total_employees_with_late'] ?? 0}'),
                            subtitle: Text('بداية الدوام: ${_data?['work_start_hour'] ?? 9}:00'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...employees.map<Widget>((e) {
                          final item = Map<String, dynamic>.from(e as Map);
                          final details = (item['details'] as List?) ?? const [];

                          return Card(
                            child: ExpansionTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(item['employee_name']?.toString() ?? '-'),
                              subtitle: Text(
                                'أيام التأخير: ${item['total_late_days'] ?? 0} | '
                                'إجمالي الساعات: ${item['total_late_hours'] ?? 0}',
                              ),
                              children: details.map<Widget>((d) {
                                final detail = Map<String, dynamic>.from(d as Map);
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.schedule, size: 18),
                                  title: Text('${detail['date'] ?? '-'} - ${detail['time'] ?? '-'}'),
                                  trailing: Text('${detail['minutes_late'] ?? 0} دقيقة'),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
'@

Set-Content -Path "lib\screens\manager\reports\absence_report_screen.dart" -Encoding UTF8 -Value @'
import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class AbsenceReportScreen extends StatefulWidget {
  const AbsenceReportScreen({super.key});

  @override
  State<AbsenceReportScreen> createState() => _AbsenceReportScreenState();
}

class _AbsenceReportScreenState extends State<AbsenceReportScreen> {
  final ReportsService _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getAbsenceReport();
      if (!mounted) return;
      setState(() {
        _data = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل تقرير الغياب: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الغياب'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: employees.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('لا توجد بيانات غياب')),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.person_off),
                            title: Text('عدد الموظفين لديهم غياب: ${_data?['total_employees_with_absence'] ?? 0}'),
                            subtitle: Text('إجمالي أيام العمل بالشهر: ${_data?['total_working_days_in_month'] ?? 0}'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...employees.map<Widget>((e) {
                          final item = Map<String, dynamic>.from(e as Map);
                          final absentDates = (item['absent_dates'] as List?) ?? const [];

                          return Card(
                            child: ExpansionTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.redAccent,
                                child: Icon(Icons.event_busy, color: Colors.white),
                              ),
                              title: Text(item['employee_name']?.toString() ?? '-'),
                              subtitle: Text(
                                'غياب: ${item['absent_days'] ?? 0} | '
                                'حضور: ${item['attended_days'] ?? 0} | '
                                'أيام العمل: ${item['total_working_days'] ?? 0}',
                              ),
                              children: absentDates.map<Widget>((d) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.date_range, size: 18),
                                  title: Text(d.toString()),
                                );
                              }).toList(),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
'@

Set-Content -Path "lib\screens\manager\reports\requests_report_screen.dart" -Encoding UTF8 -Value @'
import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class RequestsReportScreen extends StatefulWidget {
  const RequestsReportScreen({super.key});

  @override
  State<RequestsReportScreen> createState() => _RequestsReportScreenState();
}

class _RequestsReportScreenState extends State<RequestsReportScreen> {
  final ReportsService _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getRequestsReport();
      if (!mounted) return;
      setState(() {
        _data = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل تقرير الطلبات: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = (_data?['details'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الطلبات'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إجمالي الطلبات: ${_data?['total_requests'] ?? 0}'),
                          const SizedBox(height: 6),
                          Text('موافق: ${_data?['approved'] ?? 0}'),
                          Text('مرفوض: ${_data?['rejected'] ?? 0}'),
                          Text('معلق: ${_data?['pending'] ?? 0}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (details.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('لا توجد طلبات في الفترة الحالية')),
                      ),
                    ),
                  ...details.map<Widget>((r) {
                    final item = Map<String, dynamic>.from(r as Map);
                    final status = item['status']?.toString() ?? '-';

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.request_page),
                        ),
                        title: Text(item['employee_name']?.toString() ?? '-'),
                        subtitle: Text(
                          '${item['category'] ?? '-'}'
                          ' | '
                          '${item['subject'] ?? '-'}',
                        ),
                        trailing: Chip(
                          label: Text(status),
                          backgroundColor: _statusColor(status).withOpacity(0.15),
                          side: BorderSide(color: _statusColor(status)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
'@

Set-Content -Path "lib\screens\manager\reports\leaves_report_screen.dart" -Encoding UTF8 -Value @'
import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class LeavesReportScreen extends StatefulWidget {
  const LeavesReportScreen({super.key});

  @override
  State<LeavesReportScreen> createState() => _LeavesReportScreenState();
}

class _LeavesReportScreenState extends State<LeavesReportScreen> {
  final ReportsService _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getLeavesReport();
      if (!mounted) return;
      setState(() {
        _data = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل تقرير الإجازات: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير الإجازات'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إجمالي الإجازات: ${_data?['total_leaves'] ?? 0}'),
                          const SizedBox(height: 6),
                          Text('موافق: ${_data?['approved'] ?? 0}'),
                          Text('مرفوض: ${_data?['rejected'] ?? 0}'),
                          Text('معلق: ${_data?['pending'] ?? 0}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (employees.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('لا توجد بيانات إجازات')),
                      ),
                    ),
                  ...employees.map<Widget>((e) {
                    final item = Map<String, dynamic>.from(e as Map);
                    final leaves = (item['leaves'] as List?) ?? const [];

                    return Card(
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.beach_access),
                        ),
                        title: Text(item['name']?.toString() ?? '-'),
                        subtitle: Text(
                          'إجمالي الأيام: ${item['total_days'] ?? 0} | '
                          'الموافق عليها: ${item['approved_days'] ?? 0}',
                        ),
                        children: leaves.map<Widget>((l) {
                          final leave = Map<String, dynamic>.from(l as Map);
                          final status = leave['status']?.toString() ?? '-';

                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.event_note, size: 18),
                            title: Text('${leave['type'] ?? '-'} - ${leave['days'] ?? 0} يوم'),
                            subtitle: Text('من ${leave['from'] ?? '-'} إلى ${leave['to'] ?? '-'}'),
                            trailing: Chip(
                              label: Text(status),
                              backgroundColor: _statusColor(status).withOpacity(0.15),
                              side: BorderSide(color: _statusColor(status)),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
'@

Set-Content -Path "lib\screens\manager\reports\work_hours_report_screen.dart" -Encoding UTF8 -Value @'
import 'package:flutter/material.dart';
import '../../../services/reports_service.dart';

class WorkHoursReportScreen extends StatefulWidget {
  const WorkHoursReportScreen({super.key});

  @override
  State<WorkHoursReportScreen> createState() => _WorkHoursReportScreenState();
}

class _WorkHoursReportScreenState extends State<WorkHoursReportScreen> {
  final ReportsService _service = ReportsService();
  Map<String, dynamic>? _data;
  bool _loading = true;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _service.getWorkHoursReport();
      if (!mounted) return;
      setState(() {
        _data = result;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل تقرير ساعات العمل: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final employees = (_data?['employees'] as List?) ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('تقرير ساعات العمل'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: employees.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('لا توجد بيانات ساعات عمل')),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.people),
                            title: Text('إجمالي الموظفين: ${_data?['total_employees'] ?? 0}'),
                            subtitle: const Text('إجمالي ساعات العمل الفعلية لكل موظف'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...employees.map<Widget>((e) {
                          final item = Map<String, dynamic>.from(e as Map);

                          return Card(
                            child: ExpansionTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.access_time),
                              ),
                              title: Text(item['employee_name']?.toString() ?? '-'),
                              subtitle: Text(
                                'الإجمالي: ${item['total_hours'] ?? 0} س | '
                                'الأيام: ${item['total_days_worked'] ?? 0} | '
                                'المتوسط: ${item['average_hours_per_day'] ?? 0} س/يوم',
                              ),
                              children: [
                                ...(((item['daily_breakdown'] as List?) ?? const []).map<Widget>((d) {
                                  final day = Map<String, dynamic>.from(d as Map);
                                  return ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.calendar_today, size: 18),
                                    title: Text(day['date']?.toString() ?? '-'),
                                    trailing: Text('${day['hours'] ?? 0} س'),
                                  );
                                })),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),
    );
  }
}
'@

Write-Host "✅ Reports Flutter Batch 2 applied successfully" -ForegroundColor Green