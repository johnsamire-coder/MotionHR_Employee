import os

content = r'''import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeMovementsScreen extends StatefulWidget {
  const EmployeeMovementsScreen({super.key});
  @override
  State<EmployeeMovementsScreen> createState() => _EmployeeMovementsScreenState();
}

class _EmployeeMovementsScreenState extends State<EmployeeMovementsScreen> {
  List<dynamic> _movements = [];
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
      final response = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/employee/movements/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _movements = data['movements'] ?? [];
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

  IconData _iconForType(String type) {
    switch (type) {
      case 'promotion': return Icons.arrow_upward;
      case 'transfer': return Icons.swap_horiz;
      case 'salary_change': return Icons.attach_money;
      case 'department_change': return Icons.business;
      case 'branch_change': return Icons.location_city;
      case 'job_title_change': return Icons.work;
      case 'contract_renewal': return Icons.autorenew;
      case 'warning': return Icons.warning;
      case 'suspension': return Icons.pause_circle;
      case 'resignation': return Icons.exit_to_app;
      case 'termination': return Icons.cancel;
      case 'return_from_leave': return Icons.assignment_turned_in;
      default: return Icons.history;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'promotion':
      case 'salary_change':
      case 'return_from_leave':
        return Colors.green;
      case 'warning':
      case 'suspension':
        return Colors.orange;
      case 'resignation':
      case 'termination':
        return Colors.red;
      case 'transfer':
      case 'department_change':
      case 'branch_change':
      case 'job_title_change':
        return Colors.blue;
      case 'contract_renewal':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr.split('T').first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE65100),
          foregroundColor: Colors.white,
          title: const Text('تاريخ الموظف', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ]))
                : _movements.isEmpty
                    ? const Center(child: Text('لا توجد حركات'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _movements.length,
                          itemBuilder: (context, i) {
                            final mv = _movements[i] as Map<String, dynamic>;
                            final typeCode = mv['type_code'] ?? '';
                            final color = _colorForType(typeCode);
                            final icon = _iconForType(typeCode);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: color.withValues(alpha: 0.2)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(icon, color: color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(mv['type'] ?? '',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          Icon(Icons.event, size: 12, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(_formatDate(mv['date']),
                                              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                        ]),
                                        if ((mv['notes'] ?? '').toString().isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(mv['notes'],
                                              style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ]),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
'''

path = r'lib\screens\employee\employee_movements_screen.dart'
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Created:', path)
print('Size:', os.path.getsize(path), 'bytes')