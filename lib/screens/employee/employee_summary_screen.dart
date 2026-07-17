import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeSummaryScreen extends StatefulWidget {
  final int? employeeId;
  final String? employeeName;
  const EmployeeSummaryScreen({super.key, this.employeeId, this.employeeName});

  @override
  State<EmployeeSummaryScreen> createState() => _EmployeeSummaryScreenState();
}

class _EmployeeSummaryScreenState extends State<EmployeeSummaryScreen> {
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final url = widget.employeeId != null
          ? 'https://jssolutions-eg.com/attendance/api/mobile/manager/employees/${widget.employeeId}/summary/'
          : 'https://jssolutions-eg.com/attendance/api/mobile/employee/summary/';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() {
          _summary = json.decode(utf8.decode(response.bodyBytes));
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'تعذر التحميل (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في الاتصال';
        _loading = false;
      });
    }
  }

  Widget _statBox(String label, dynamic value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, child: Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color))),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, Color color, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _leaveBalanceRow(Map<String, dynamic> b) {
    final remaining = (b['remaining'] ?? 0).toDouble();
    final total = (b['total'] ?? 0).toDouble();
    final percent = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(b['leave_type'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('${remaining.toStringAsFixed(1)} / ${total.toStringAsFixed(1)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(Color(0xFF1976D2)),
            ),
          ),
          Text('مستخدم: ${b['used']}  •  معلق: ${b['pending']}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          title: Text(
            widget.employeeName != null ? 'ملخص: ${widget.employeeName}' : 'الملخص',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
                    ]))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_month, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('شهر: ${_summary!['month'] ?? ''}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ]),
                        ),
                        const SizedBox(height: 12),

                        // الحضور
                        _section('إحصائيات الحضور', Icons.event_available, const Color(0xFF388E3C),
                          Column(children: [
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: 1.6,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              children: [
                                _statBox('حاضر', _summary!['attendance']['present'], Icons.check_circle, const Color(0xFF388E3C)),
                                _statBox('متأخر', _summary!['attendance']['late'], Icons.access_time, const Color(0xFFFF9800)),
                                _statBox('غائب', _summary!['attendance']['absent'], Icons.cancel, const Color(0xFFD32F2F)),
                                _statBox('إجازة', _summary!['attendance']['on_leave'], Icons.beach_access, const Color(0xFF1976D2)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(),
                            const SizedBox(height: 4),
                            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                              Column(children: [
                                Text('${_summary!['attendance']['total_work_hours']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const Text('ساعات عمل', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ]),
                              Column(children: [
                                Text('${_summary!['attendance']['total_overtime_hours']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                                const Text('ساعات إضافية', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ]),
                              Column(children: [
                                Text('${_summary!['attendance']['total_late_minutes']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange)),
                                const Text('دقائق تأخير', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ]),
                            ]),
                          ]),
                        ),

                        // رصيد الإجازات
                        _section('رصيد الإجازات', Icons.beach_access, const Color(0xFF1976D2),
                          ((_summary!['leave_balances'] as List?)?.isEmpty ?? true)
                              ? const Padding(padding: EdgeInsets.all(8), child: Text('لا يوجد رصيد إجازات'))
                              : Column(children: [
                                  for (var b in (_summary!['leave_balances'] as List))
                                    _leaveBalanceRow(b as Map<String, dynamic>)
                                ]),
                        ),

                        // الطلبات
                        _section('الطلبات', Icons.assignment, const Color(0xFFE65100),
                          GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 0.9,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            children: [
                              _statBox('الكل', _summary!['requests']['total'], Icons.list, const Color(0xFF616161)),
                              _statBox('معلق', _summary!['requests']['pending'], Icons.schedule, const Color(0xFFFF9800)),
                              _statBox('موافق', _summary!['requests']['approved'], Icons.check, const Color(0xFF388E3C)),
                              _statBox('مرفوض', _summary!['requests']['rejected'], Icons.close, const Color(0xFFD32F2F)),
                            ],
                          ),
                        ),

                        // طلبات الإجازة
                        _section('طلبات الإجازة', Icons.beach_access, const Color(0xFF00838F),
                          GridView.count(
                            crossAxisCount: 4,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 0.9,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            children: [
                              _statBox('الكل', _summary!['leaves']['total'], Icons.list, const Color(0xFF616161)),
                              _statBox('معلق', _summary!['leaves']['pending'], Icons.schedule, const Color(0xFFFF9800)),
                              _statBox('موافق', _summary!['leaves']['approved'], Icons.check, const Color(0xFF388E3C)),
                              _statBox('مرفوض', _summary!['leaves']['rejected'], Icons.close, const Color(0xFFD32F2F)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}
