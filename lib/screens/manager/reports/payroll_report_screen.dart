import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/report_month_picker.dart';

const String _kBase = 'https://motion.jssolutions-eg.com';

class PayrollReportScreen extends StatefulWidget {
  const PayrollReportScreen({super.key});
  @override
  State<PayrollReportScreen> createState() => _PayrollReportScreenState();
}

class _PayrollReportScreenState extends State<PayrollReportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _search = '';
  String? _error;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';
  static const _color = Color(0xFF1B5E20);

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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      if (token == null) {
        setState(() {
          _error = _isAr ? 'لا يوجد تسجيل دخول' : 'Not authenticated';
          _loading = false;
        });
        return;
      }
      final url =
          '$_kBase/attendance/api/mobile/manager/reports/payroll/?year=$_selectedYear&month=$_selectedMonth';
      final res = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _data = body is Map<String, dynamic> ? body : {};
          _loading = false;
        });
      } else {
        setState(() {
          _error = '${_isAr ? 'خطأ' : 'Error'} ${res.statusCode}';
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

  Future<void> _pickMonth() async {
    final result = await showReportMonthPicker(
      context,
      initialYear: _selectedYear,
      initialMonth: _selectedMonth,
    );
    if (result != null && mounted) {
      setState(() {
        _selectedYear = result.year;
        _selectedMonth = result.month;
      });
      _load();
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final all = (_data?['employees'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    if (_search.trim().isEmpty) return all;
    final s = _search.toLowerCase().trim();
    return all.where((r) {
      final name = (r['employee_name'] ?? '').toString().toLowerCase();
      final dept = (r['department'] ?? '').toString().toLowerCase();
      return name.contains(s) || dept.contains(s);
    }).toList();
  }

  String _monthName(int m) {
    const ar = [
      '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    const en = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return _isAr ? ar[m] : en[m];
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final d = double.tryParse(v.toString()) ?? 0.0;
    return d.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final totals = (_data?['totals'] as Map<String, dynamic>?) ?? {};
    final title = _isAr ? 'تقرير الرواتب الشهري' : 'Monthly Payroll Report';

    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(title,
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: _color,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                  // Month Picker
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickMonth,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_monthName(_selectedMonth)} $_selectedYear',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
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
                    onChanged: (v) => setState(() => _search = v),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isAr
                          ? 'بحث بالاسم أو القسم...'
                          : 'Search by name or dept...',
                      hintStyle: TextStyle(color: Colors.white70),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Stats chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(_isAr ? 'موظفين' : 'Employees',
                            '${_data?['total_employees'] ?? 0}'),
                        const SizedBox(width: 8),
                        _chip(
                          _isAr ? 'إجمالي صافي' : 'Total Net',
                          _fmt(totals['net_salary']),
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          _isAr ? 'إجمالي إجمالي' : 'Total Gross',
                          _fmt(totals['gross_salary']),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Totals Card
            if (_data != null && !_loading)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _color.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAr ? 'ملخص الشهر' : 'Month Summary',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                            child: _summaryItem(
                          _isAr ? 'إجمالي الرواتب' : 'Gross Total',
                          _fmt(totals['gross_salary']),
                          Colors.blue,
                        )),
                        Expanded(
                            child: _summaryItem(
                          _isAr ? 'إجمالي الخصومات' : 'Total Deductions',
                          _fmt(totals['total_deductions']),
                          Colors.red,
                        )),
                        Expanded(
                            child: _summaryItem(
                          _isAr ? 'صافي الرواتب' : 'Net Total',
                          _fmt(totals['net_salary']),
                          _color,
                        )),
                      ],
                    ),
                  ],
                ),
              ),

            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _color))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(_error!),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _load,
                                child: Text(
                                    _isAr ? 'إعادة المحاولة' : 'Retry'),
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
                                  Icon(Icons.payments_outlined,
                                      size: 64,
                                      color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isAr
                                        ? 'لا توجد بيانات'
                                        : 'No data found',
                                    style: TextStyle(
                                        color: Colors.grey[600],
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
                                padding: const EdgeInsets.all(12),
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

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(width: 6),
          Text(label,
              style:
                  TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> emp) {
    final name = (emp['employee_name'] ?? '').toString();
    final dept = (emp['department'] ?? '').toString();
    final net = _fmt(emp['net_salary']);
    final gross = _fmt(emp['gross_salary']);
    final basic = _fmt(emp['basic_salary']);
    final deductions = _fmt(emp['total_deductions']);
    final currency = (emp['currency'] ?? 'EGP').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.1),
          child: Text(name.isNotEmpty ? name[0] : '?',
              style: TextStyle(
                  color: _color, fontWeight: FontWeight.bold)),
        ),
        title: Text(
          name.isNotEmpty ? name : (_isAr ? 'بدون اسم' : 'No name'),
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          dept.isNotEmpty ? dept : '',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$net $currency',
              style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            Text(
              _isAr ? 'صافي' : 'Net',
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // الإيرادات
                _sectionTitle(_isAr ? '📈 الإيرادات' : '📈 Earnings'),
                _row(_isAr ? 'الراتب الأساسي' : 'Basic Salary',
                    '$basic $currency'),
                _row(_isAr ? 'البدلات' : 'Allowances',
                    '${_fmt(emp['allowances_total'])} $currency'),
                _row(_isAr ? 'أوفرتايم' : 'Overtime',
                    '${_fmt(emp['overtime_bonus'])} $currency'),
                _row(_isAr ? 'مكافآت' : 'Bonuses',
                    '${_fmt(emp['bonuses_total'])} $currency'),
                if ((emp['night_allowance'] ?? 0) > 0)
                  _row(_isAr ? 'بدل ليلي' : 'Night Allowance',
                      '${_fmt(emp['night_allowance'])} $currency'),
                if ((emp['weekend_allowance'] ?? 0) > 0)
                  _row(
                      _isAr ? 'بدل إجازة أسبوعية' : 'Weekend Allowance',
                      '${_fmt(emp['weekend_allowance'])} $currency'),
                _row(
                  _isAr ? 'الإجمالي' : 'Gross',
                  '$gross $currency',
                  bold: true,
                  valueColor: Colors.blue[700],
                ),
                const SizedBox(height: 8),
                // الخصومات
                _sectionTitle(
                    _isAr ? '📉 الخصومات' : '📉 Deductions'),
                _row(_isAr ? 'تأخير' : 'Late',
                    '${_fmt(emp['late_deduction'])} $currency',
                    valueColor: Colors.red),
                _row(_isAr ? 'غياب' : 'Absence',
                    '${_fmt(emp['absence_deduction'])} $currency',
                    valueColor: Colors.red),
                _row(_isAr ? 'تأمينات' : 'Insurance',
                    '${_fmt(emp['insurance_deduction'])} $currency',
                    valueColor: Colors.red),
                if ((emp['flex_shortage_deduction'] ?? 0) > 0)
                  _row(
                      _isAr ? 'نقص مرن' : 'Flex Shortage',
                      '${_fmt(emp['flex_shortage_deduction'])} $currency',
                      valueColor: Colors.red),
                if ((emp['installments_total'] ?? 0) > 0)
                  _row(_isAr ? 'أقساط' : 'Installments',
                      '${_fmt(emp['installments_total'])} $currency',
                      valueColor: Colors.red),
                if ((emp['penalties_total'] ?? 0) > 0)
                  _row(_isAr ? 'جزاءات' : 'Penalties',
                      '${_fmt(emp['penalties_total'])} $currency',
                      valueColor: Colors.red),
                _row(
                  _isAr ? 'إجمالي الخصومات' : 'Total Deductions',
                  '$deductions $currency',
                  bold: true,
                  valueColor: Colors.red[700],
                ),
                const Divider(),
                _row(
                  _isAr ? '✅ الصافي' : '✅ Net Salary',
                  '$net $currency',
                  bold: true,
                  valueColor: _color,
                ),
                const SizedBox(height: 8),
                // الحضور
                _sectionTitle(
                    _isAr ? '📅 الحضور' : '📅 Attendance'),
                _row(_isAr ? 'أيام العمل' : 'Working Days',
                    '${emp['total_working_days'] ?? 0}'),
                _row(_isAr ? 'حضر' : 'Attended',
                    '${emp['attended_days'] ?? 0}'),
                _row(_isAr ? 'غاب' : 'Absent',
                    '${emp['absent_days'] ?? 0}'),
                _row(_isAr ? 'متأخر' : 'Late Days',
                    '${emp['late_days'] ?? 0}'),
                _row(_isAr ? 'إجمالي دقائق التأخير' : 'Late Minutes',
                    '${emp['total_late_minutes'] ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Align(
        alignment:
            _isAr ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(title,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700])),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[700])),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? _color,
            ),
          ),
        ],
      ),
    );
  }
}
