import 'package:motionhr_employee/services/api_client.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _kBase = 'https://motion.jssolutions-eg.com';

class BaseReportScreen extends StatefulWidget {
  final String title;
  final String titleEn;
  final String endpoint;
  final Color color;
  final IconData icon;
  final List<ReportColumn> columns;
  final String dataKey;

  const BaseReportScreen({
    super.key,
    required this.title,
    required this.titleEn,
    required this.endpoint,
    required this.color,
    required this.icon,
    required this.columns,
    required this.dataKey,
  });

  @override
  State<BaseReportScreen> createState() => _BaseReportScreenState();
}

class ReportColumn {
  final String key;
  final String labelAr;
  final String labelEn;
  final bool isNumeric;
  final String Function(dynamic value)? formatter;

  const ReportColumn({
    required this.key,
    required this.labelAr,
    required this.labelEn,
    this.isNumeric = false,
    this.formatter,
  });
}

class _BaseReportScreenState extends State<BaseReportScreen> {
  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  DateTime _selectedDate = DateTime.now();

  List<Map<String, dynamic>> _data = [];
  Map<String, dynamic> _meta = {};
  bool _loading = false;
  String _search = '';
  String? _error;
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
    return prefs.getString('token');
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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

      final dateStr = _formatDate(_selectedDate);
      final year = _selectedDate.year;
      final month = _selectedDate.month;

      final url =
          '$_kBase/attendance/api/mobile/${widget.endpoint}?year=$year&month=$month&date=$dateStr';

      final res = await http.get(
        Uri.parse(url),
        headers: await ApiClient.buildHeaders(includeContentType: true),
      ).timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        final body = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{};

        final rawList = body[widget.dataKey];
        final list = rawList is List
            ? rawList
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : <Map<String, dynamic>>[];

        setState(() {
          _data = list;
          _meta = body;
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

  List<Map<String, dynamic>> get _filteredData {
    if (_search.trim().isEmpty) return _data;

    final s = _search.toLowerCase().trim();

    return _data.where((row) {
      final name =
          (row['employee_name'] ?? row['name'] ?? '').toString().toLowerCase();
      final dept = (row['department'] ?? '').toString().toLowerCase();
      final branch = (row['branch'] ?? '').toString().toLowerCase();
      return name.contains(s) || dept.contains(s) || branch.contains(s);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredData;
    final title = _isAr ? widget.title : widget.titleEn;

    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: widget.color,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDatePicker(),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _isAr
                          ? 'بحث بالاسم أو القسم أو الفرع...'
                          : 'Search by name, department or branch...',
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statChip(
                          _isAr ? 'الإجمالي' : 'Total',
                          '${filtered.length}',
                          Colors.white,
                        ),
                        if (_meta['stats'] is Map<String, dynamic>) ...[
                          const SizedBox(width: 8),
                          ...(_meta['stats'] as Map<String, dynamic>)
                              .entries
                              .take(3)
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 8,
                                  ),
                                  child: _statChip(
                                    e.key,
                                    '${e.value}',
                                    Colors.white70,
                                  ),
                                ),
                              ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: widget.color),
                    )
                  : _error != null
                      ? _buildErrorState()
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) => _buildRow(filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2024, 1, 1),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );

        if (picked != null) {
          setState(() => _selectedDate = picked);
          _load();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _formatDate(_selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              _isAr ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 54,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              child: Text(_isAr ? 'إعادة المحاولة' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _isAr ? 'لا توجد بيانات' : 'No data found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> row) {
    final name = (row['employee_name'] ?? row['name'] ?? '').toString();
    final dept = (row['department'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        childrenPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: widget.color.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0] : '?',
            style: TextStyle(
              color: widget.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name.isNotEmpty ? name : (_isAr ? 'بدون اسم' : 'No name'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: dept.isNotEmpty
            ? Text(
                dept,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              )
            : null,
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: widget.columns.map((col) {
                final value = row[col.key];
                final displayValue = col.formatter != null
                    ? col.formatter!(value)
                    : (value ?? '-').toString();
                final label = _isAr ? col.labelAr : col.labelEn;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          displayValue,
                          textAlign: _isAr ? TextAlign.left : TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: col.isNumeric
                                ? widget.color
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}