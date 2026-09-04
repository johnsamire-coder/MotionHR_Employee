import 'package:motionhr_employee/services/api_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:motionhr_employee/services/report_pdf_service.dart';
import 'package:motionhr_employee/services/report_excel_service.dart';

const String _kBaseD = 'https://jssolutions-eg.com';

class DailyAttendanceReportScreen extends StatefulWidget {
  const DailyAttendanceReportScreen({super.key});
  @override
  State<DailyAttendanceReportScreen> createState() =>
      _DailyAttendanceReportScreenState();
}

class _DailyAttendanceReportScreenState
    extends State<DailyAttendanceReportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _search = '';
  String? _error;
  String _statusFilter = 'all';
  bool _printing = false;
  bool _exporting = false;

  DateTime _selectedDate = DateTime.now();

  bool get _isAr =>
      Localizations.localeOf(context).languageCode == 'ar';
  static const _color = Color(0xFF00838F);

  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _load();
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? prefs.getString('auth_token');
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _error =
              _isAr ? 'لا يوجد تسجيل دخول' : 'Not authenticated';
          _loading = false;
        });
        return;
      }
      final dateStr = _formatDate(_selectedDate);
      final url =
          '$_kBaseD/attendance/api/mobile/manager/reports/daily-attendance/?date=$dateStr';
      final res = await http.get(
        Uri.parse(url),
        headers: await ApiClient.buildHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _data = body is Map<String, dynamic> ? body : {};
          _loading = false;
        });
      } else {
        setState(() {
          _error =
              '${_isAr ? 'خطأ' : 'Error'} ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _print() async {
    if (_data == null) return;
    setState(() => _printing = true);
    try {
      final rows = _filtered.map<List<String>>((e) {
        final item = Map<String, dynamic>.from(e as Map);
        return [
          item['employee_name']?.toString() ?? '-',
          item['department']?.toString() ?? '-',
          _statusLabel(item['status']?.toString() ?? 'no_data'),
          item['check_in']?.toString() ?? '-',
          item['check_out']?.toString() ?? '-',
          '${item['work_hours'] ?? 0}',
        ];
      }).toList();
      await ReportPdfService.printReport(
        title: _isAr
            ? '\u0627\u0644\u062a\u0642\u0631\u064a\u0631 \u0627\u0644\u064a\u0648\u0645\u064a \u0644\u0644\u062d\u0636\u0648\u0631'
            : 'Daily Attendance Report',
        subtitle: _formatDate(_selectedDate),
        headers: _isAr
            ? [
                '\u0627\u0644\u0645\u0648\u0638\u0641',
                '\u0627\u0644\u0642\u0633\u0645',
                '\u0627\u0644\u062d\u0627\u0644\u0629',
                '\u0627\u0644\u062d\u0636\u0648\u0631',
                '\u0627\u0644\u0627\u0646\u0635\u0631\u0627\u0641',
                '\u0633\u0627\u0639\u0627\u062a \u0627\u0644\u0639\u0645\u0644'
              ]
            : ['Employee', 'Department', 'Status', 'Check-in', 'Check-out', 'Hours'],
        rows: rows,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_isAr ? '\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u0637\u0628\u0627\u0639\u0629' : 'Print error'}: $e'),
          ),
        );
      }
    }
    if (mounted) setState(() => _printing = false);
  }

  Future<void> _exportExcel() async {
    if (_data == null) return;
    setState(() => _exporting = true);
    try {
      final rows = _filtered.map<List<String>>((e) {
        final item = Map<String, dynamic>.from(e as Map);
        return [
          item['employee_name']?.toString() ?? '-',
          item['department']?.toString() ?? '-',
          _statusLabel(item['status']?.toString() ?? 'no_data'),
          item['check_in']?.toString() ?? '-',
          item['check_out']?.toString() ?? '-',
          '${item['work_hours'] ?? 0}',
        ];
      }).toList();
      await ReportExcelService.exportAndShare(
        fileName: 'daily_attendance_${_formatDate(_selectedDate)}.xlsx',
        sheetName: _isAr
            ? '\u0627\u0644\u062d\u0636\u0648\u0631 \u0627\u0644\u064a\u0648\u0645\u064a'
            : 'Daily Attendance',
        headers: _isAr
            ? [
                '\u0627\u0644\u0645\u0648\u0638\u0641',
                '\u0627\u0644\u0642\u0633\u0645',
                '\u0627\u0644\u062d\u0627\u0644\u0629',
                '\u0627\u0644\u062d\u0636\u0648\u0631',
                '\u0627\u0644\u0627\u0646\u0635\u0631\u0627\u0641',
                '\u0633\u0627\u0639\u0627\u062a \u0627\u0644\u0639\u0645\u0644'
              ]
            : ['Employee', 'Department', 'Status', 'Check-in', 'Check-out', 'Hours'],
        rows: rows,
        title: _isAr
            ? '\u0627\u0644\u062a\u0642\u0631\u064a\u0631 \u0627\u0644\u064a\u0648\u0645\u064a \u0644\u0644\u062d\u0636\u0648\u0631'
            : 'Daily Attendance Report',
        subtitle: _formatDate(_selectedDate),
        shareText: _isAr
            ? '\u062a\u0642\u0631\u064a\u0631 \u0627\u0644\u062d\u0636\u0648\u0631 \u0627\u0644\u064a\u0648\u0645\u064a - ${_formatDate(_selectedDate)}'
            : 'Daily Attendance Report - ${_formatDate(_selectedDate)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_isAr ? '\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u062a\u0635\u062f\u064a\u0631' : 'Export error'}: $e'),
          ),
        );
      }
    }
    if (mounted) setState(() => _exporting = false);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final all = (_data?['employees'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    var list = all;
    if (_statusFilter != 'all') {
      list = list
          .where((r) => r['status'] == _statusFilter)
          .toList();
    }
    if (_search.trim().isNotEmpty) {
      final s = _search.toLowerCase().trim();
      list = list.where((r) {
        final name =
            (r['employee_name'] ?? '').toString().toLowerCase();
        final dept =
            (r['department'] ?? '').toString().toLowerCase();
        return name.contains(s) || dept.contains(s);
      }).toList();
    }
    return list;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'on_leave':
        return Colors.blue;
      case 'weekend':
        return Colors.purple;
      case 'mission':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    if (_isAr) {
      switch (status) {
        case 'present':
          return 'حاضر';
        case 'late':
          return 'متأخر';
        case 'absent':
          return 'غائب';
        case 'on_leave':
          return 'إجازة';
        case 'weekend':
          return 'إجازة أسبوعية';
        case 'mission':
          return 'مهمة';
        default:
          return 'لا بيانات';
      }
    } else {
      switch (status) {
        case 'present':
          return 'Present';
        case 'late':
          return 'Late';
        case 'absent':
          return 'Absent';
        case 'on_leave':
          return 'On Leave';
        case 'weekend':
          return 'Weekend';
        case 'mission':
          return 'Mission';
        default:
          return 'No Data';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final stats =
        (_data?['stats'] as Map<String, dynamic>?) ?? {};
    final title =
        _isAr ? 'التقرير اليومي للحضور' : 'Daily Attendance Report';

    return Directionality(
      textDirection:
          _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          backgroundColor: _color,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (!_loading && _data != null) ...[
              _exporting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _exportExcel,
                      icon: const Icon(Icons.table_chart_outlined),
                      tooltip: _isAr
                          ? '\u062a\u0635\u062f\u064a\u0631 Excel'
                          : 'Export Excel',
                    ),
              _printing
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _print,
                      icon: const Icon(Icons.print),
                    ),
            ],
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: _color.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Date Picker
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _formatDate(_selectedDate),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.w700),
                            ),
                          ),
                          Icon(
                            _isAr
                                ? Icons.arrow_back_ios_new
                                : Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Search
                  TextField(
                    onChanged: (v) =>
                        setState(() => _search = v),
                    style:
                        const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isAr
                          ? 'بحث بالاسم أو القسم...'
                          : 'Search by name or dept...',
                      hintStyle: const TextStyle(
                          color: Colors.white70),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white
                          .withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stats chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statChip('all',
                            _isAr ? 'الكل' : 'All',
                            '${_data?['total_employees'] ?? 0}'),
                        const SizedBox(width: 6),
                        _statChip('present',
                            _isAr ? 'حاضر' : 'Present',
                            '${stats['present'] ?? 0}'),
                        const SizedBox(width: 6),
                        _statChip('late',
                            _isAr ? 'متأخر' : 'Late',
                            '${stats['late'] ?? 0}'),
                        const SizedBox(width: 6),
                        _statChip('absent',
                            _isAr ? 'غائب' : 'Absent',
                            '${stats['absent'] ?? 0}'),
                        const SizedBox(width: 6),
                        _statChip('on_leave',
                            _isAr ? 'إجازة' : 'Leave',
                            '${stats['on_leave'] ?? 0}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: _color))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48,
                                  color: Colors.red),
                              const SizedBox(height: 12),
                              Text(_error!),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _load,
                                child: Text(_isAr
                                    ? 'إعادة المحاولة'
                                    : 'Retry'),
                              ),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(
                                      Icons
                                          .people_outline,
                                      size: 64,
                                      color:
                                          Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isAr
                                        ? 'لا توجد بيانات'
                                        : 'No data found',
                                    style: TextStyle(
                                        color:
                                            Colors.grey[600],
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.all(12),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildCard(filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(
      String statusKey, String label, String value) {
    final isSelected = _statusFilter == statusKey;
    return GestureDetector(
      onTap: () =>
          setState(() => _statusFilter = statusKey),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value,
                style: TextStyle(
                    color:
                        isSelected ? _color : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected
                        ? _color
                        : Colors.white70,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> emp) {
    final name = (emp['employee_name'] ?? '').toString();
    final dept = (emp['department'] ?? '').toString();
    final status = (emp['status'] ?? 'no_data').toString();
    final sColor = _statusColor(status);
    final checkIn = emp['check_in']?.toString();
    final checkOut = emp['check_out']?.toString();
    final workHours = emp['work_hours'] ?? 0;
    final lateMin = emp['late_minutes'] ?? 0;
    final shiftName = emp['shift_name']?.toString() ?? '';
    final branch = (emp['branch'] ?? '').toString();
    final earlyLeave = emp['early_leave_minutes'] ?? 0;
    final overtimeH = emp['overtime_hours'] ?? 0;
    final isNight = emp['is_night_shift'] == true;
    final isWeekend = emp['is_weekend_work'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: sColor.withValues(alpha: 0.1),
          child: Text(name.isNotEmpty ? name[0] : '?',
              style: TextStyle(
                  color: sColor,
                  fontWeight: FontWeight.bold)),
        ),
        title: Text(
          name.isNotEmpty
              ? name
              : (_isAr ? 'بدون اسم' : 'No name'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dept.isNotEmpty)
              Text(dept,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600])),
            Row(
              children: [
                if (checkIn != null)
                  Text('$checkIn → ${checkOut ?? '--'}',
                      style: const TextStyle(fontSize: 11)),
                if (lateMin > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${_isAr ? 'تأخير' : 'Late'}: $lateMin${_isAr ? 'د' : 'm'}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.orange),
                  ),
                ],
              ],
            ),
            if (shiftName.isNotEmpty)
              Text(shiftName,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500])),
            if (branch.isNotEmpty)
              Text(branch,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500])),
            Row(children: [
              if (earlyLeave > 0)
                Text(
                  '${_isAr ? '\u0627\u0646\u0635\u0631\u0627\u0641': 'Early'}: $earlyLeave${_isAr ? '\u062f' : 'm'}  ',
                  style: const TextStyle(fontSize: 10, color: Colors.deepOrange),
                ),
              if (overtimeH > 0)
                Text(
                  '${_isAr ? '\u0623\u0648\u0641\u0631': 'OT'}: $overtimeH${_isAr ? '\u0633' : 'h'}  ',
                  style: const TextStyle(fontSize: 10, color: Colors.green),
                ),
              if (isNight)
                Text('${_isAr ? '\u0644\u064a\u0644\u064a': 'Night'}  ',
                  style: const TextStyle(fontSize: 10, color: Colors.indigo)),
              if (isWeekend)
                Text('${_isAr ? '\u0646\u0647\u0627\u064a\u0629 \u0627\u0644\u0623\u0633\u0628\u0648\u0639': 'Weekend'}  ',
                  style: const TextStyle(fontSize: 10, color: Colors.purple)),
            ]),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: sColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(status),
                style: TextStyle(
                    color: sColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
            if (workHours > 0)
              Text(
                '$workHours${_isAr ? 'س' : 'h'}',
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600]),
              ),
          ],
        ),
      ),
    );
  }
}
