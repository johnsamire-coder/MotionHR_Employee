import 'package:motionhr_employee/services/api_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/report_month_picker.dart';

const String _kBaseP = 'https://jssolutions-eg.com';

class PermissionsReportScreen extends StatefulWidget {
  const PermissionsReportScreen({super.key});
  @override
  State<PermissionsReportScreen> createState() =>
      _PermissionsReportScreenState();
}

class _PermissionsReportScreenState
    extends State<PermissionsReportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _search = '';
  String? _error;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  bool get _isAr =>
      Localizations.localeOf(context).languageCode == 'ar';
  static const _color = Color(0xFF4527A0);

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
          _error =
              _isAr ? 'لا يوجد تسجيل دخول' : 'Not authenticated';
          _loading = false;
        });
        return;
      }
      final url =
          '$_kBaseP/attendance/api/mobile/manager/reports/permissions/?year=$_selectedYear&month=$_selectedMonth';
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
      final name =
          (r['employee_name'] ?? '').toString().toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final title =
        _isAr ? 'تقرير الأذونات' : 'Permissions Report';

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
            IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh)),
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
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickMonth,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.18)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_monthName(_selectedMonth)} $_selectedYear',
                              style: const TextStyle(
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
                      fillColor:
                          Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _chip(
                            _isAr ? 'موظفين' : 'Employees',
                            '${_data?['total_employees'] ?? 0}'),
                        const SizedBox(width: 8),
                        _chip(
                            _isAr ? 'النتائج' : 'Results',
                            '${filtered.length}'),
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
                                  size: 48, color: Colors.red),
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
                                          .access_time_outlined,
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

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> emp) {
    final name = (emp['employee_name'] ?? '').toString();
    final dept = (emp['department'] ?? '').toString();
    final usedMin = emp['used_minutes'] ?? 0;
    final usedHrs = emp['used_hours'] ?? 0;
    final maxHrs = emp['max_hours_per_month'] ?? 0;
    final maxTimes = emp['max_times_per_month'] ?? 0;
    final count = emp['movements_count'] ?? 0;
    final movements = (emp['movements'] as List?) ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        childrenPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.1),
          child: Text(name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(
                  color: _color, fontWeight: FontWeight.bold)),
        ),
        title: Text(
          name.isNotEmpty
              ? name
              : (_isAr ? 'بدون اسم' : 'No name'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          _isAr
              ? 'مستخدم: $usedHrs س | $count حركة'
              : 'Used: ${usedHrs}h | $count movements',
          style:
              TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$usedMin${_isAr ? 'د' : 'm'}',
            style: const TextStyle(
                color: _color,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                if (dept.isNotEmpty)
                  _row(_isAr ? 'القسم' : 'Department', dept),
                _row(_isAr ? 'الحد الأقصى/شهر' : 'Max/Month',
                    '$maxHrs ${_isAr ? 'س' : 'h'}'),
                _row(
                    _isAr ? 'الحد الأقصى/مرات' : 'Max Times',
                    '$maxTimes'),
                _row(
                    _isAr
                        ? 'المستخدم (دقائق)'
                        : 'Used (minutes)',
                    '$usedMin'),
                _row(
                    _isAr
                        ? 'المستخدم (ساعات)'
                        : 'Used (hours)',
                    '$usedHrs'),
              ],
            ),
          ),
          if (movements.isNotEmpty) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: _isAr
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  _isAr ? 'الحركات:' : 'Movements:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700]),
                ),
              ),
            ),
            ...movements.map<Widget>((m) {
              final mv =
                  Map<String, dynamic>.from(m as Map);
              return ListTile(
                dense: true,
                leading: const Icon(Icons.circle,
                    color: _color, size: 8),
                title: Text(
                  mv['date']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  mv['notes']?.toString() ?? '',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600]),
                ),
                trailing: Text(
                  '${mv['minutes'] ?? 0} ${_isAr ? 'د' : 'm'}',
                  style: const TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[700])),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _color)),
        ],
      ),
    );
  }
}
