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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.reports),
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
                  isAr ? 'تقارير المدير' : 'Manager Reports',
                ),
                subtitle: Text(
                  isAr
                      ? 'الحضور - التأخير - الغياب - الطلبات - الإجازات - ساعات العمل'
                      : 'Attendance - Late - Absence - Requests - Leaves - Work Hours',
                ),
              ),
            ),
            const SizedBox(height: 8),
            _card(
              context,
              Icons.calendar_month,
              Colors.blue,
              isAr ? 'تقرير الحضور الشهري' : 'Monthly Attendance Report',
              isAr ? 'عدد أيام الحضور لكل موظف' : 'Attendance days per employee',
              const AttendanceReportScreen(),
            ),
            _card(
              context,
              Icons.alarm,
              Colors.orange,
              isAr ? 'تقرير التأخير' : 'Late Report',
              isAr ? 'تفاصيل أيام التأخير' : 'Details of late days',
              const LateReportScreen(),
            ),
            _card(
              context,
              Icons.person_off,
              Colors.red,
              isAr ? 'تقرير الغياب' : 'Absence Report',
              isAr ? 'أيام الغياب الشهرية' : 'Monthly absence days',
              const AbsenceReportScreen(),
            ),
            _card(
              context,
              Icons.request_page,
              Colors.purple,
              isAr ? 'تقرير الطلبات' : 'Requests Report',
              isAr ? 'كل الطلبات والحالات' : 'All requests and statuses',
              const RequestsReportScreen(),
            ),
            _card(
              context,
              Icons.beach_access,
              Colors.teal,
              isAr ? 'تقرير الإجازات' : 'Leaves Report',
              isAr ? 'ملخص إجازات الموظفين' : 'Employee leaves summary',
              const LeavesReportScreen(),
            ),
            _card(
              context,
              Icons.access_time,
              Colors.indigo,
              isAr ? 'تقرير ساعات العمل' : 'Work Hours Report',
              isAr ? 'ساعات العمل الفعلية' : 'Actual work hours',
              const WorkHoursReportScreen(),
            ),
            _card(
              context,
              Icons.location_on,
              Colors.green,
              isAr ? 'تقرير المواقع اليومي' : 'Daily Location Report',
              isAr
                  ? 'أماكن تواجد الموظف خلال اليوم'
                  : 'Employee locations during the day',
              const LocationReportScreen(),
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
          backgroundColor: color.withOpacity(0.15),
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