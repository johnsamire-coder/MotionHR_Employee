$ErrorActionPreference = "Stop"

$projectRoot = "C:\MotionHR\motionhr_employee\motionhr_employee"
if (-not (Test-Path "$projectRoot\pubspec.yaml")) {
    Write-Host "❌ pubspec.yaml not found in: $projectRoot" -ForegroundColor Red
    exit 1
}

Set-Location $projectRoot

New-Item -ItemType Directory -Force -Path "lib\services" | Out-Null
New-Item -ItemType Directory -Force -Path "lib\screens\manager\reports" | Out-Null

Set-Content -Path "lib\services\reports_service.dart" -Encoding UTF8 -Value @'
import '../core/api_service.dart';

class ReportsService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> _getMap(String url) async {
    final response = await _api.get(url);
    if (response is Map<String, dynamic>) {
      return response;
    }
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> getAttendanceReport({int? year, int? month, int? employeeId}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '/attendance/api/mobile/manager/reports/attendance/?year=$y&month=$m';
    if (employeeId != null) {
      url += '&employee_id=$employeeId';
    }
    return _getMap(url);
  }

  Future<Map<String, dynamic>> getLateReport({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _getMap('/attendance/api/mobile/manager/reports/late/?year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getAbsenceReport({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _getMap('/attendance/api/mobile/manager/reports/absence/?year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getRequestsReport({int? year, int? month, String? status}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    var url = '/attendance/api/mobile/manager/reports/requests/?year=$y&month=$m';
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }
    return _getMap(url);
  }

  Future<Map<String, dynamic>> getLeavesReport({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _getMap('/attendance/api/mobile/manager/reports/leaves/?year=$y&month=$m');
  }

  Future<Map<String, dynamic>> getWorkHoursReport({int? year, int? month}) async {
    final y = year ?? DateTime.now().year;
    final m = month ?? DateTime.now().month;
    return _getMap('/attendance/api/mobile/manager/reports/work-hours/?year=$y&month=$m');
  }
}
'@

Set-Content -Path "lib\screens\manager\reports\reports_hub_screen.dart" -Encoding UTF8 -Value @'
import 'package:flutter/material.dart';

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
      appBar: AppBar(
        title: const Text('التقارير'),
      ),
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
          _card(
            context,
            icon: Icons.calendar_month,
            title: 'تقرير الحضور الشهري',
            subtitle: 'عدد أيام الحضور والحضور/الانصراف لكل موظف',
            screen: const AttendanceReportScreen(),
          ),
          _card(
            context,
            icon: Icons.alarm,
            title: 'تقرير التأخير',
            subtitle: 'تفاصيل أيام التأخير وإجمالي الدقائق',
            screen: const LateReportScreen(),
          ),
          _card(
            context,
            icon: Icons.person_off,
            title: 'تقرير الغياب',
            subtitle: 'أيام الغياب خلال الشهر الحالي',
            screen: const AbsenceReportScreen(),
          ),
          _card(
            context,
            icon: Icons.request_page,
            title: 'تقرير الطلبات',
            subtitle: 'الطلبات المعلقة والموافق عليها والمرفوضة',
            screen: const RequestsReportScreen(),
          ),
          _card(
            context,
            icon: Icons.beach_access,
            title: 'تقرير الإجازات',
            subtitle: 'ملخص الإجازات وأيامها لكل موظف',
            screen: const LeavesReportScreen(),
          ),
          _card(
            context,
            icon: Icons.access_time,
            title: 'تقرير ساعات العمل',
            subtitle: 'إجمالي ساعات العمل الفعلية لكل موظف',
            screen: const WorkHoursReportScreen(),
          ),
          const SizedBox(height: 12),
          const Card(
            color: Color(0xFFF7F7F7),
            child: ListTile(
              leading: Icon(Icons.download),
              title: Text('Export PDF / Excel'),
              subtitle: Text('جاهز على السيرفر، وربط التحميل من التطبيق هيكون في باتش لاحق آمن بالتوكن'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          );
        },
      ),
    );
  }
}
'@

Write-Host "✅ Reports Flutter Batch 1 applied successfully" -ForegroundColor Green