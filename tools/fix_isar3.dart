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

  const getter = "\n  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';\n";

  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      print('⚠️ Not found: $path');
      continue;
    }

    var content = await file.readAsString();

    if (content.contains('bool get isAr =>')) {
      print('⏭️ Already fixed: ${path.split('/').last}');
      continue;
    }

    // امسح أي تعريف قديم لـ isAr
    content = content.replaceAll(
      "    final isAr = Localizations.localeOf(context).languageCode == 'ar';\n",
      '',
    );

    // أضف getter بعد extends State<...> {
    final stateMatch = RegExp(r'extends State<\w+>\s*\{').firstMatch(content);
    if (stateMatch != null) {
      final insertPos = stateMatch.end;
      content = content.substring(0, insertPos) + getter + content.substring(insertPos);
    }

    // امسح const من أي سطر فيه isAr
    final lines = content.split('\n');
    final fixed = lines.map((line) {
      if (line.contains('isAr')) {
        return line
            .replaceAll('const Text(', 'Text(')
            .replaceAll('const SizedBox(', 'SizedBox(')
            .replaceAll('const Padding(', 'Padding(')
            .replaceAll('const Row(', 'Row(')
            .replaceAll('const Column(', 'Column(')
            .replaceAll('const Container(', 'Container(')
            .replaceAll('const Card(', 'Card(')
            .replaceAll('const Center(', 'Center(')
            .replaceAll('const Icon(', 'Icon(');
      }
      return line;
    }).join('\n');

    await file.writeAsString(fixed);
    print('✅ Fixed: ${path.split('/').last}');
  }

  print('\n✅ Done!');
}