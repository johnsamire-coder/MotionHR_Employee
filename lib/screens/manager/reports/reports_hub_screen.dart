import 'package:flutter/material.dart';
import 'attendance_report_screen.dart';
import 'late_report_screen.dart';
import 'absence_report_screen.dart';
import 'requests_report_screen.dart';
import 'leaves_report_screen.dart';
import 'work_hours_report_screen.dart';
import '../location_report_screen.dart';
import 'package:motionhr_employee/l10n/l10n.dart';


class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.reports)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('تقارير المدير'),
              subtitle: Text('الحضور - التأخير - الغياب - الطلبات - الإجازات - ساعات العمل'),
            ),
          ),
          SizedBox(height: 8),
          _card(context, Icons.calendar_month, 'تقرير الحضور الشهري', 'عدد أيام الحضور لكل موظف', const AttendanceReportScreen()),
          _card(context, Icons.alarm, 'تقرير التأخير', 'تفاصيل أيام التأخير', const LateReportScreen()),
          _card(context, Icons.person_off, 'تقرير الغياب', 'أيام الغياب الشهرية', const AbsenceReportScreen()),
          _card(context, Icons.request_page, 'تقرير الطلبات', 'كل الطلبات والحالات', const RequestsReportScreen()),
          _card(context, Icons.beach_access, 'تقرير الإجازات', 'ملخص إجازات الموظفين', const LeavesReportScreen()),
          _card(context, Icons.access_time, 'تقرير ساعات العمل', 'ساعات العمل الفعلية', const WorkHoursReportScreen()),
          _card(context, Icons.location_on, 'تقرير المواقع اليومية', 'أماكن تواجد الموظف خلال اليوم', const LocationReportScreen()),
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
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
