$ErrorActionPreference = "Stop"

$projectRoot = "C:\MotionHR\motionhr_employee\motionhr_employee"
if (-not (Test-Path "$projectRoot\pubspec.yaml")) {
    Write-Host "❌ pubspec.yaml not found in: $projectRoot" -ForegroundColor Red
    exit 1
}

Set-Location $projectRoot

$dashboardPath = "lib\screens\manager\manager_dashboard.dart"

if (Test-Path $dashboardPath) {
    Copy-Item $dashboardPath "$dashboardPath.bak_before_reports" -Force
    Write-Host "🟡 Backup created: $dashboardPath.bak_before_reports" -ForegroundColor Yellow
}

Set-Content -Path $dashboardPath -Encoding UTF8 -Value @'
import 'package:flutter/material.dart';

import 'manager_pending_screen.dart';
import 'manager_attendance_screen.dart';
import 'manager_live_locations_screen.dart';
import 'manager_geofence_screen.dart';
import 'manager_charter_screen.dart';
import 'charter_report_screen.dart';
import 'reports/reports_hub_screen.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة المدير'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(Icons.admin_panel_settings),
              ),
              title: Text('مرحباً بك'),
              subtitle: Text('يمكنك متابعة الموافقات والحضور واللائحة والتقارير من هنا'),
            ),
          ),
          const SizedBox(height: 12),
          _menuCard(
            context,
            icon: Icons.pending_actions,
            color: Colors.orange,
            title: 'الطلبات المعلقة',
            subtitle: 'اعتماد أو رفض الطلبات والإجازات',
            screen: const ManagerPendingScreen(),
          ),
          _menuCard(
            context,
            icon: Icons.fact_check,
            color: Colors.blue,
            title: 'متابعة الحضور',
            subtitle: 'عرض حضور وانصراف الموظفين',
            screen: const ManagerAttendanceScreen(),
          ),
          _menuCard(
            context,
            icon: Icons.location_on,
            color: Colors.red,
            title: 'المواقع الحية',
            subtitle: 'متابعة مواقع الموظفين الحالية',
            screen: const ManagerLiveLocationsScreen(),
          ),
          _menuCard(
            context,
            icon: Icons.my_location,
            color: Colors.green,
            title: 'إعدادات الجيوفينس',
            subtitle: 'تحديد أو تعديل نطاق الحضور',
            screen: const ManagerGeofenceScreen(),
          ),
          _menuCard(
            context,
            icon: Icons.gavel,
            color: Colors.deepPurple,
            title: 'إدارة اللائحة',
            subtitle: 'تعديل اللائحة ورفع المرفقات',
            screen: const ManagerCharterScreen(),
          ),
          _menuCard(
            context,
            icon: Icons.assignment_turned_in,
            color: Colors.teal,
            title: 'تقرير موافقات اللائحة',
            subtitle: 'عرض الموظفين الموافقين على اللائحة',
            screen: const CharterReportScreen(),
          ),
          _menuCard(
            context,
            icon: Icons.analytics,
            color: Colors.indigo,
            title: 'التقارير',
            subtitle: 'الحضور - التأخير - الغياب - الطلبات - الإجازات - ساعات العمل',
            screen: const ReportsHubScreen(),
          ),
        ],
      ),
    );
  }

  Widget _menuCard(
    BuildContext context, {
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
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
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

Write-Host "✅ Reports Flutter Batch 3 applied successfully" -ForegroundColor Green