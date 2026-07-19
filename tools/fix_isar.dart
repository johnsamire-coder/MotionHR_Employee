import 'dart:io';

void main() async {
  final files = [
    'lib/screens/employee/employee_profile_screen.dart',
    'lib/screens/employee/employee_summary_screen.dart',
    'lib/screens/employee_mission_detail_screen.dart',
    'lib/screens/manager/create_announcement_screen.dart',
    'lib/screens/manager/create_employee_screen.dart',
    'lib/screens/manager/create_mission_screen.dart',
    'lib/screens/manager/location_report_screen.dart',
    'lib/screens/manager/manager_employee_detail_screen.dart',
    'lib/screens/manager/manager_employees_list_screen.dart',
    'lib/screens/manager/mission_detail_screen.dart',
    'lib/screens/manager/payroll/payroll_employee_detail_screen.dart',
    'lib/screens/manager/payroll/payroll_settings_screen.dart',
    'lib/screens/manager/payroll/payroll_summary_screen.dart',
    'lib/screens/manager/reports/absence_report_screen.dart',
    'lib/screens/manager/reports/attendance_report_screen.dart',
    'lib/screens/manager/reports/late_report_screen.dart',
    'lib/screens/manager/reports/leaves_report_screen.dart',
    'lib/screens/manager/reports/requests_report_screen.dart',
    'lib/screens/manager/reports/work_hours_report_screen.dart',
  ];

  const isArLine = "    final isAr = Localizations.localeOf(context).languageCode == 'ar';";

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      print('⚠️ Not found: $path');
      continue;
    }

    var content = await file.readAsString();

    // تحقق لو isAr معرّفة أصلاً
    if (content.contains("final isAr = Localizations.localeOf(context)")) {
      print('⏭️ Already has isAr: ${path.split('/').last}');
      continue;
    }

    // أضف isAr بعد أول { في build method
    content = content.replaceFirst(
      RegExp(r'Widget build\(BuildContext context\)\s*\{'),
      'Widget build(BuildContext context) {\n$isArLine',
    );

    await file.writeAsString(content);
    print('✅ Fixed: ${path.split('/').last}');
  }

  print('\n✅ Done!');
}