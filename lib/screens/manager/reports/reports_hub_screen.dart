import 'package:flutter/material.dart';
import 'package:motionhr_employee/l10n/l10n.dart';
import 'package:motionhr_employee/screens/manager/location_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/absence_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/attendance_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/daily_attendance_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/late_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/leaves_enhanced_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/leaves_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/payroll_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/permissions_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/requests_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/shifts_report_screen.dart';
import 'package:motionhr_employee/screens/manager/reports/work_hours_report_screen.dart';

class ReportsHubScreen extends StatelessWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(context.l10n.reports),
          backgroundColor: const Color(0xFF37474F),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionHeader(
              isAr ? '📅 تقارير الحضور' : '📅 Attendance Reports',
            ),
            const SizedBox(height: 8),
            _card(
              context,
              Icons.people_alt_outlined,
              const Color(0xFF00838F),
              isAr ? 'التقرير اليومي للحضور' : 'Daily Attendance Report',
              isAr
                  ? 'حالة كل موظف في يوم محدد'
                  : 'Status of each employee on a specific day',
              const DailyAttendanceReportScreen(),
            ),
            _card(
              context,
              Icons.calendar_month,
              const Color(0xFF1565C0),
              isAr ? 'تقرير الحضور الشهري' : 'Monthly Attendance Report',
              isAr ? 'عدد أيام الحضور لكل موظف' : 'Attendance days per employee',
              const AttendanceReportScreen(),
            ),
            _card(
              context,
              Icons.alarm,
              const Color(0xFFE65100),
              isAr ? 'تقرير التأخير' : 'Late Report',
              isAr ? 'تفاصيل أيام التأخير' : 'Details of late days',
              const LateReportScreen(),
            ),
            _card(
              context,
              Icons.person_off,
              const Color(0xFFC62828),
              isAr ? 'تقرير الغياب' : 'Absence Report',
              isAr ? 'أيام الغياب الشهرية' : 'Monthly absence days',
              const AbsenceReportScreen(),
            ),
            _card(
              context,
              Icons.access_time,
              const Color(0xFF283593),
              isAr ? 'تقرير ساعات العمل' : 'Work Hours Report',
              isAr ? 'ساعات العمل الفعلية' : 'Actual work hours',
              const WorkHoursReportScreen(),
            ),
            const SizedBox(height: 16),
            _sectionHeader(
              isAr
                  ? '📋 تقارير الإجازات والطلبات'
                  : '📋 Leaves & Requests Reports',
            ),
            const SizedBox(height: 8),
            _card(
              context,
              Icons.beach_access,
              const Color(0xFF00695C),
              isAr ? 'تقرير الإجازات الشامل' : 'Enhanced Leaves Report',
              isAr
                  ? 'مع الأرصدة والتفاصيل الكاملة'
                  : 'With balances and full details',
              const LeavesEnhancedReportScreen(),
            ),
            _card(
              context,
              Icons.beach_access_outlined,
              const Color(0xFF00695C),
              isAr ? 'تقرير الإجازات' : 'Leaves Report',
              isAr ? 'ملخص إجازات الموظفين' : 'Employee leaves summary',
              const LeavesReportScreen(),
            ),
            _card(
              context,
              Icons.request_page,
              const Color(0xFF6A1B9A),
              isAr ? 'تقرير الطلبات' : 'Requests Report',
              isAr ? 'كل الطلبات والحالات' : 'All requests and statuses',
              const RequestsReportScreen(),
            ),
            _card(
              context,
              Icons.access_time_outlined,
              const Color(0xFF4527A0),
              isAr ? 'تقرير الأذونات' : 'Permissions Report',
              isAr ? 'رصيد الأذونات والحركات' : 'Permission balance and movements',
              const PermissionsReportScreen(),
            ),
            const SizedBox(height: 16),
            _sectionHeader(
              isAr
                  ? '💼 تقارير الشيفتات والرواتب'
                  : '💼 Shifts & Payroll Reports',
            ),
            const SizedBox(height: 8),
            _card(
              context,
              Icons.schedule,
              const Color(0xFF37474F),
              isAr ? 'تقرير الشيفتات' : 'Shifts Report',
              isAr ? 'توزيع الموظفين على الشيفتات' : 'Employee shift distribution',
              const ShiftsReportScreen(),
            ),
            _card(
              context,
              Icons.payments_outlined,
              const Color(0xFF1B5E20),
              isAr ? 'تقرير الرواتب الشهري' : 'Monthly Payroll Report',
              isAr ? 'تفاصيل رواتب كل الموظفين' : 'Detailed payroll for all employees',
              const PayrollReportScreen(),
            ),
            const SizedBox(height: 16),
            _sectionHeader(
              isAr ? '📍 تقارير المواقع' : '📍 Location Reports',
            ),
            const SizedBox(height: 8),
            _card(
              context,
              Icons.location_on,
              const Color(0xFF2E7D32),
              isAr ? 'تقرير المواقع اليومي' : 'Daily Location Report',
              isAr ? 'أماكن تواجد الموظف خلال اليوم' : 'Employee locations during the day',
              const LocationReportScreen(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF37474F),
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
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey[400],
        ),
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => screen),
        ),
      ),
    );
  }
}