import 'dart:io';

void main() async {
  final files = [
    'lib/screens/employee_mission_detail_screen.dart',
    'lib/screens/manager/create_announcement_screen.dart',
    'lib/screens/manager/create_employee_screen.dart',
    'lib/screens/manager/create_mission_screen.dart',
    'lib/screens/manager/location_report_screen.dart',
    'lib/screens/manager/manager_employee_detail_screen.dart',
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

    // 1. إزالة const من أي widget فيه isAr
    content = content.replaceAllMapped(
      RegExp(r'const\s+(Text|SizedBox|Padding|Row|Column|Container|Card|Center|Icon)\('),
      (m) {
        return '${m.group(1)}(';
      },
    );

    // 2. إضافة isAr في كل build method مش عندها
    content = content.replaceAllMapped(
      RegExp(r'Widget build\(BuildContext context\)\s*\{(?!\s*\n\s*final isAr)'),
      (m) {
        return 'Widget build(BuildContext context) {\n$isArLine';
      },
    );

    // 3. إضافة isAr في أي method تانية بتاخد BuildContext وفيها isAr بدون تعريف
    // نضيف في أي function بتاخد context كـ parameter
    content = content.replaceAllMapped(
      RegExp(r'(Widget|void|Future<void>|Future<bool>|String)\s+\w+\(BuildContext context[^)]*\)\s*(async\s*)?\{(?!\s*\n\s*final isAr)'),
      (m) {
        return '${m.group(0)}\n$isArLine';
      },
    );

    await file.writeAsString(content);
    print('✅ Fixed: ${path.split('/').last}');
  }

  print('\n✅ Done!');
}