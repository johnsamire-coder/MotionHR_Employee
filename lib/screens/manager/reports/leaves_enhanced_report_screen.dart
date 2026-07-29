import 'package:motionhr_employee/services/api_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/report_month_picker.dart';

const String _kBaseL = 'https://motion.jssolutions-eg.com';

class LeavesEnhancedReportScreen extends StatefulWidget {
  const LeavesEnhancedReportScreen({super.key});
  @override
  State<LeavesEnhancedReportScreen> createState() =>
      _LeavesEnhancedReportScreenState();
}

class _LeavesEnhancedReportScreenState
    extends State<LeavesEnhancedReportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _search = '';
  String? _error;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  bool get _isAr =>
      Localizations.localeOf(context).languageCode == 'ar';
  static const _color = Color(0xFF00695C);

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
          '$_kBaseL/attendance/api/mobile/manager/reports/leaves-enhanced/?year=$_selectedYear&month=$_selectedMonth';
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
      return name.contains(s);
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

  String _statusLabel(String s) {
    if (!_isAr) return s;
    switch (s.toLowerCase()) {
      case 'approved': return 'موافق';
      case 'pending': return 'معلق';
      case 'rejected': return 'مرفوض';
      default: return s;
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final title =
        _isAr ? 'تقرير الإجازات الشامل' : 'Enhanced Leaves Report';

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
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickMonth,
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
                          const Icon(Icons.calendar_month,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_monthName(_selectedMonth)} $_selectedYear',
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
                  TextField(
                    onChanged: (v) =>
                        setState(() => _search = v),
                    style:
                        const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isAr
                          ? 'بحث بالاسم...'
                          : 'Search by name...',
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
                                          .beach_access_outlined,
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
    final totalDays = emp['total_approved_days'] ?? 0;
    final unpaidDays = emp['unpaid_days'] ?? 0;
    final halfCount = emp['half_day_count'] ?? 0;
    final leaves = (emp['leaves'] as List?) ?? [];
    final balances = (emp['balances'] as List?) ?? [];

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
          dept.isNotEmpty ? dept : '',
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
            '$totalDays ${_isAr ? 'يوم' : 'd'}',
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
                _row(_isAr ? 'إجمالي موافق' : 'Total Approved',
                    '$totalDays'),
                _row(
                    _isAr ? 'بدون أجر' : 'Unpaid Days',
                    '$unpaidDays'),
                _row(
                    _isAr ? 'نصف يوم' : 'Half Days',
                    '$halfCount'),
              ],
            ),
          ),
          // Balances
          if (balances.isNotEmpty) ...[
            _subTitle(_isAr ? '💰 الأرصدة' : '💰 Balances'),
            ...balances.map<Widget>((b) {
              final bal =
                  Map<String, dynamic>.from(b as Map);
              return ListTile(
                dense: true,
                leading: const Icon(Icons.account_balance_wallet,
                    color: _color, size: 16),
                title: Text(
                  bal['leave_type']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '${_isAr ? 'متبقي' : 'Remaining'}: ${bal['remaining_days'] ?? 0}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600]),
                ),
                trailing: Text(
                  '${bal['used_days'] ?? 0} / ${bal['total_days'] ?? 0}',
                  style: const TextStyle(
                      color: _color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              );
            }),
          ],
          // Leaves
          if (leaves.isNotEmpty) ...[
            _subTitle(
                _isAr ? '📋 الطلبات' : '📋 Requests'),
            ...leaves.map<Widget>((l) {
              final lv =
                  Map<String, dynamic>.from(l as Map);
              final status =
                  lv['status']?.toString() ?? '-';
              final sColor = _statusColor(status);
              return ListTile(
                dense: true,
                leading: Icon(Icons.circle,
                    color: sColor, size: 8),
                title: Text(
                  '${lv['leave_type'] ?? '-'} — ${lv['days_count'] ?? 0} ${_isAr ? 'يوم' : 'd'}',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  '${lv['start_date'] ?? '-'} → ${lv['end_date'] ?? '-'}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600]),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                        color: sColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _subTitle(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Align(
        alignment:
            _isAr ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(t,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700])),
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
