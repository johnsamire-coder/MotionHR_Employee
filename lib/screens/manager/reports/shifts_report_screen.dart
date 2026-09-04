import 'package:motionhr_employee/services/api_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kBaseSh = 'https://jssolutions-eg.com';

class ShiftsReportScreen extends StatefulWidget {
  const ShiftsReportScreen({super.key});
  @override
  State<ShiftsReportScreen> createState() =>
      _ShiftsReportScreenState();
}

class _ShiftsReportScreenState extends State<ShiftsReportScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String _search = '';
  String? _error;

  bool get _isAr =>
      Localizations.localeOf(context).languageCode == 'ar';
  static const _color = Color(0xFF37474F);

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
      const url =
          '$_kBaseSh/attendance/api/mobile/manager/reports/shifts/';
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

  List<Map<String, dynamic>> get _filteredShifts {
    final all = (_data?['shifts'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    if (_search.trim().isEmpty) return all;
    final s = _search.toLowerCase().trim();
    return all.where((r) {
      final name =
          (r['shift_name'] ?? '').toString().toLowerCase();
      final type =
          (r['shift_type'] ?? '').toString().toLowerCase();
      return name.contains(s) || type.contains(s);
    }).toList();
  }

  Color _shiftColor(String type) {
    switch (type.toLowerCase()) {
      case 'morning': return Colors.orange;
      case 'night': return Color(0xFF1A0A3E);
      case 'evening': return Color(0xFF382483);
      case 'flex_fixed':
      case 'flex_split': return Color(0xFF00C688);
      case 'split_fixed': return Color(0xFF382483);
      default: return _color;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredShifts = _filteredShifts;
    final noShift = (_data?['no_shift_employees'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final title =
        _isAr ? 'تقرير الشيفتات' : 'Shifts Report';

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
                  TextField(
                    onChanged: (v) =>
                        setState(() => _search = v),
                    style:
                        const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isAr
                          ? 'بحث بالاسم أو النوع...'
                          : 'Search by name or type...',
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
                          _isAr ? 'شيفتات' : 'Shifts',
                          '${_data?['total_shifts'] ?? 0}',
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          _isAr ? 'موظفين' : 'Employees',
                          '${_data?['total_employees'] ?? 0}',
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          _isAr ? 'بدون شيفت' : 'No Shift',
                          '${noShift.length}',
                          chipColor: noShift.isNotEmpty
                              ? Colors.orange
                              : null,
                        ),
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
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding:
                                const EdgeInsets.all(12),
                            children: [
                              ...filteredShifts
                                  .map(_buildShiftCard),
                              if (noShift.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                _buildNoShiftCard(noShift),
                              ],
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value,
      {Color? chipColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: (chipColor ?? Colors.white)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  color: chipColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: (chipColor ?? Colors.white70),
                  fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift) {
    final name = (shift['shift_name'] ?? '').toString();
    final type = (shift['shift_type'] ?? '').toString();
    final mode = (shift['shift_mode'] ?? '').toString();
    final start = (shift['start_time'] ?? '').toString();
    final end = (shift['end_time'] ?? '').toString();
    final count = shift['employees_count'] ?? 0;
    final employees =
        (shift['employees'] as List?) ?? [];
    final crossesMidnight =
        shift['crosses_midnight'] == true;
    final sColor = _shiftColor(type);

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
          backgroundColor: sColor.withValues(alpha: 0.1),
          child: Icon(Icons.access_time,
              color: sColor, size: 20),
        ),
        title: Text(
          name.isNotEmpty
              ? name
              : (_isAr ? 'بدون اسم' : 'No name'),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '$start → $end${crossesMidnight ? ' 🌙' : ''}',
          style: TextStyle(
              fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: sColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                color: sColor,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                _row(_isAr ? 'النوع' : 'Type', type),
                if (mode.isNotEmpty)
                  _row(_isAr ? 'الوضع' : 'Mode', mode),
                _row(_isAr ? 'عدد الموظفين' : 'Employees',
                    '$count'),
              ],
            ),
          ),
          if (employees.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              child: Align(
                alignment: _isAr
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Text(
                  _isAr ? 'الموظفين:' : 'Employees:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700]),
                ),
              ),
            ),
            ...employees.take(10).map<Widget>((e) {
              final ev =
                  Map<String, dynamic>.from(e as Map);
              return ListTile(
                dense: true,
                leading: Icon(Icons.person,
                    color: sColor, size: 16),
                title: Text(
                  ev['employee_name']?.toString() ?? '-',
                  style: const TextStyle(fontSize: 13),
                ),
                subtitle: Text(
                  ev['department']?.toString() ?? '',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600]),
                ),
                trailing: Text(
                  ev['source']?.toString() ?? '',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500]),
                ),
              );
            }),
            if (employees.length > 10)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '+${employees.length - 10} ${_isAr ? 'موظف آخر' : 'more employees'}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500]),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildNoShiftCard(
      List<Map<String, dynamic>> noShiftEmps) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.warning_amber,
              color: Colors.white, size: 20),
        ),
        title: Text(
          _isAr ? 'موظفين بدون شيفت' : 'Employees Without Shift',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.orange),
        ),
        subtitle: Text(
          '${noShiftEmps.length} ${_isAr ? 'موظف' : 'employees'}',
          style: TextStyle(
              fontSize: 12, color: Colors.grey[600]),
        ),
        children: noShiftEmps.map<Widget>((e) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.person_off,
                color: Colors.orange, size: 16),
            title: Text(
              e['employee_name']?.toString() ?? '-',
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              e['department']?.toString() ?? '',
              style: TextStyle(
                  fontSize: 11, color: Colors.grey[600]),
            ),
          );
        }).toList(),
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