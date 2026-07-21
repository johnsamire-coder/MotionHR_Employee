// lib/services/report_excel_service.dart
// Phase 16 — Excel Export Service
// Fixed: share_plus API compatibility

import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

class ReportExcelService {

  // ─────────────────────────────────────────
  //  CORE: Generate + Save + Return path
  // ─────────────────────────────────────────
  static Future<String> _buildAndSave({
    required String fileName,
    required String sheetName,
    required List<String> headers,
    required List<List<String>> rows,
    String? title,
    String? subtitle,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel[sheetName];

    if (title != null) {
      sheet.appendRow([TextCellValue(title)]);
      sheet.appendRow([TextCellValue(subtitle ?? '')]);
      sheet.appendRow([TextCellValue('')]);
    }

    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (final row in rows) {
      sheet.appendRow(row.map((c) => TextCellValue(c)).toList());
    }

    if (sheetName != 'Sheet1' && excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final fileBytes = excel.save();
    if (fileBytes == null) throw Exception('Failed to generate Excel file');
    File(path).writeAsBytesSync(fileBytes);
    return path;
  }

  // ─────────────────────────────────────────
  //  PUBLIC: Export + Open
  // ─────────────────────────────────────────
  static Future<void> exportAndOpen({
    required String fileName,
    required String sheetName,
    required List<String> headers,
    required List<List<String>> rows,
    String? title,
    String? subtitle,
  }) async {
    final path = await _buildAndSave(
      fileName: fileName,
      sheetName: sheetName,
      headers: headers,
      rows: rows,
      title: title,
      subtitle: subtitle,
    );
    await OpenFile.open(path);
  }

  // ─────────────────────────────────────────
  //  PUBLIC: Export + Share
  // ─────────────────────────────────────────
  static Future<void> exportAndShare({
    required String fileName,
    required String sheetName,
    required List<String> headers,
    required List<List<String>> rows,
    String? title,
    String? subtitle,
    String shareText = '',
  }) async {
    final path = await _buildAndSave(
      fileName: fileName,
      sheetName: sheetName,
      headers: headers,
      rows: rows,
      title: title,
      subtitle: subtitle,
    );
    final xFile = XFile(path);
    await Share.shareXFiles(
      [xFile],
      text: shareText.isNotEmpty ? shareText : fileName,
    );
  }

  // ─────────────────────────────────────────
  //  ATTENDANCE REPORT
  // ─────────────────────────────────────────
  static Future<void> exportAttendanceReport({
    required List<Map<String, dynamic>> employees,
    required int year,
    required int month,
    required bool isAr,
  }) async {
    final monthLabel = _monthName(month, isAr);
    final fileName =
        'attendance_${year}_${month.toString().padLeft(2, '0')}.xlsx';
    final headers = isAr
        ? ['اسم الموظف', 'أيام العمل', 'الحضور', 'الانصراف', 'الغياب']
        : ['Employee', 'Working Days', 'Check-ins', 'Check-outs', 'Absences'];
    final rows = employees.map<List<String>>((e) => [
          e['employee_name']?.toString() ?? '-',
          '${e['working_days'] ?? 0}',
          '${e['total_checkins'] ?? 0}',
          '${e['total_checkouts'] ?? 0}',
          '${e['absent_days'] ?? 0}',
        ]).toList();
    await exportAndShare(
      fileName: fileName,
      sheetName: isAr ? 'تقرير الحضور' : 'Attendance',
      headers: headers,
      rows: rows,
      title: isAr ? 'تقرير الحضور الشهري' : 'Monthly Attendance Report',
      subtitle: '$monthLabel $year',
      shareText: isAr
          ? 'تقرير الحضور - $monthLabel $year'
          : 'Attendance Report - $monthLabel $year',
    );
  }

  // ─────────────────────────────────────────
  //  LATE REPORT
  // ─────────────────────────────────────────
  static Future<void> exportLateReport({
    required List<Map<String, dynamic>> employees,
    required int year,
    required int month,
    required bool isAr,
  }) async {
    final monthLabel = _monthName(month, isAr);
    final fileName =
        'late_report_${year}_${month.toString().padLeft(2, '0')}.xlsx';
    final headers = isAr
        ? ['اسم الموظف', 'مرات التأخير', 'إجمالي الدقائق', 'الخصم']
        : ['Employee', 'Late Count', 'Total Minutes', 'Deduction'];
    final rows = employees.map<List<String>>((e) => [
          e['employee_name']?.toString() ?? '-',
          '${e['late_count'] ?? 0}',
          '${e['total_late_minutes'] ?? 0}',
          '${e['late_deduction'] ?? 0}',
        ]).toList();
    await exportAndShare(
      fileName: fileName,
      sheetName: isAr ? 'تقرير التأخير' : 'Late Report',
      headers: headers,
      rows: rows,
      title: isAr ? 'تقرير التأخير الشهري' : 'Monthly Late Report',
      subtitle: '$monthLabel $year',
      shareText: isAr
          ? 'تقرير التأخير - $monthLabel $year'
          : 'Late Report - $monthLabel $year',
    );
  }

  // ─────────────────────────────────────────
  //  ABSENCE REPORT
  // ─────────────────────────────────────────
  static Future<void> exportAbsenceReport({
    required List<Map<String, dynamic>> employees,
    required int year,
    required int month,
    required bool isAr,
  }) async {
    final monthLabel = _monthName(month, isAr);
    final fileName =
        'absence_${year}_${month.toString().padLeft(2, '0')}.xlsx';
    final headers = isAr
        ? ['اسم الموظف', 'أيام الغياب', 'الخصم']
        : ['Employee', 'Absent Days', 'Deduction'];
    final rows = employees.map<List<String>>((e) => [
          e['employee_name']?.toString() ?? '-',
          '${e['absent_days'] ?? 0}',
          '${e['absence_deduction'] ?? 0}',
        ]).toList();
    await exportAndShare(
      fileName: fileName,
      sheetName: isAr ? 'تقرير الغياب' : 'Absence Report',
      headers: headers,
      rows: rows,
      title: isAr ? 'تقرير الغياب الشهري' : 'Monthly Absence Report',
      subtitle: '$monthLabel $year',
      shareText: isAr
          ? 'تقرير الغياب - $monthLabel $year'
          : 'Absence Report - $monthLabel $year',
    );
  }

  // ─────────────────────────────────────────
  //  REQUESTS REPORT
  // ─────────────────────────────────────────
  static Future<void> exportRequestsReport({
    required List<Map<String, dynamic>> requests,
    required int year,
    required int month,
    required bool isAr,
  }) async {
    final monthLabel = _monthName(month, isAr);
    final fileName =
        'requests_${year}_${month.toString().padLeft(2, '0')}.xlsx';
    final headers = isAr
        ? ['اسم الموظف', 'نوع الطلب', 'التاريخ', 'الحالة']
        : ['Employee', 'Type', 'Date', 'Status'];
    final rows = requests.map<List<String>>((e) => [
          e['employee_name']?.toString() ?? '-',
          e['request_type']?.toString() ?? '-',
          e['date']?.toString() ?? '-',
          _translateStatus(e['status']?.toString() ?? '', isAr),
        ]).toList();
    await exportAndShare(
      fileName: fileName,
      sheetName: isAr ? 'تقرير الطلبات' : 'Requests',
      headers: headers,
      rows: rows,
      title: isAr ? 'تقرير الطلبات الشهري' : 'Monthly Requests Report',
      subtitle: '$monthLabel $year',
      shareText: isAr
          ? 'تقرير الطلبات - $monthLabel $year'
          : 'Requests Report - $monthLabel $year',
    );
  }

  // ─────────────────────────────────────────
  //  LEAVES REPORT
  // ─────────────────────────────────────────
  static Future<void> exportLeavesReport({
    required List<Map<String, dynamic>> leaves,
    required int year,
    required int month,
    required bool isAr,
  }) async {
    final monthLabel = _monthName(month, isAr);
    final fileName =
        'leaves_${year}_${month.toString().padLeft(2, '0')}.xlsx';
    final headers = isAr
        ? ['اسم الموظف', 'نوع الإجازة', 'من', 'إلى', 'الأيام', 'الحالة']
        : ['Employee', 'Leave Type', 'From', 'To', 'Days', 'Status'];
    final rows = leaves.map<List<String>>((e) => [
          e['employee_name']?.toString() ?? '-',
          e['leave_type']?.toString() ?? '-',
          e['start_date']?.toString() ?? '-',
          e['end_date']?.toString() ?? '-',
          '${e['days'] ?? 0}',
          _translateStatus(e['status']?.toString() ?? '', isAr),
        ]).toList();
    await exportAndShare(
      fileName: fileName,
      sheetName: isAr ? 'تقرير الإجازات' : 'Leaves',
      headers: headers,
      rows: rows,
      title: isAr ? 'تقرير الإجازات الشهري' : 'Monthly Leaves Report',
      subtitle: '$monthLabel $year',
      shareText: isAr
          ? 'تقرير الإجازات - $monthLabel $year'
          : 'Leaves Report - $monthLabel $year',
    );
  }

  // ─────────────────────────────────────────
  //  WORK HOURS REPORT
  // ─────────────────────────────────────────
  static Future<void> exportWorkHoursReport({
    required List<Map<String, dynamic>> employees,
    required int year,
    required int month,
    required bool isAr,
  }) async {
    final monthLabel = _monthName(month, isAr);
    final fileName =
        'work_hours_${year}_${month.toString().padLeft(2, '0')}.xlsx';
    final headers = isAr
        ? ['اسم الموظف', 'إجمالي الساعات', 'ساعات إضافية', 'متوسط يومي']
        : ['Employee', 'Total Hours', 'Overtime', 'Daily Average'];
    final rows = employees.map<List<String>>((e) => [
          e['employee_name']?.toString() ?? '-',
          '${e['total_hours'] ?? 0}',
          '${e['overtime_hours'] ?? 0}',
          '${e['daily_average'] ?? 0}',
        ]).toList();
    await exportAndShare(
      fileName: fileName,
      sheetName: isAr ? 'ساعات العمل' : 'Work Hours',
      headers: headers,
      rows: rows,
      title: isAr ? 'تقرير ساعات العمل' : 'Work Hours Report',
      subtitle: '$monthLabel $year',
      shareText: isAr
          ? 'ساعات العمل - $monthLabel $year'
          : 'Work Hours - $monthLabel $year',
    );
  }

  // ─────────────────────────────────────────
  //  LOCATION REPORT
  // ─────────────────────────────────────────
  static Future<void> exportLocationReport({
    required List<Map<String, dynamic>> points,
    required String employeeName,
    required String date,
    required bool isAr,
  }) async {
    final fileName = 'location_${date.replaceAll('-', '_')}.xlsx';
    final headers = isAr
        ? ['#', 'العنوان', 'الوقت', 'خط العرض', 'خط الطول']
        : ['#', 'Address', 'Time', 'Latitude', 'Longitude'];
    final rows = points.asMap().entries.map<List<String>>((entry) {
      final i = entry.key;
      final p = entry.value;
      return [
        '${i + 1}',
        p['address']?.toString().isNotEmpty == true
            ? p['address']
            : (isAr ? 'موقع غير معروف' : 'Unknown'),
        p['recorded_at']?.toString() ?? '-',
        '${p['latitude'] ?? ''}',
        '${p['longitude'] ?? ''}',
      ];
    }).toList();
    await exportAndShare(
      fileName: fileName,
      sheetName: isAr ? 'تقرير المواقع' : 'Location Report',
      headers: headers,
      rows: rows,
      title: isAr ? 'تقرير المواقع اليومي' : 'Daily Location Report',
      subtitle: '$employeeName | $date',
      shareText: isAr
          ? 'تقرير مواقع $employeeName - $date'
          : 'Location Report $employeeName - $date',
    );
  }

  // ─────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────
  static String _translateStatus(String status, bool isAr) {
    if (!isAr) return status;
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'approved':
        return 'موافق عليه';
      case 'rejected':
        return 'مرفوض';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  static String _monthName(int month, bool isAr) {
    const ar = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    const en = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return isAr ? ar[month] : en[month];
  }
}
