import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'manager_employee_detail_screen.dart';
import '../../widgets/empty_state_widget.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class ManagerEmployeesListScreen extends StatefulWidget {
  const ManagerEmployeesListScreen({super.key});
  @override
  State<ManagerEmployeesListScreen> createState() =>
      _ManagerEmployeesListScreenState();
}

class _ManagerEmployeesListScreenState
    extends State<ManagerEmployeesListScreen> {
  List<dynamic> _employees = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _statusFilter = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final queryParams = <String, String>{};
      if (_search.isNotEmpty) queryParams['search'] = _search;
      if (_statusFilter.isNotEmpty)
        queryParams['status'] = _statusFilter;

      final uri = Uri.parse(
              'https://motion.jssolutions-eg.com/attendance/api/mobile/manager/employees/')
          .replace(
              queryParameters:
                  queryParams.isEmpty ? null : queryParams);

      final response = await http
          .get(uri, headers: {'Authorization': 'Token $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _employees = data['employees'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = response.statusCode.toString();
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'connection';
        _loading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() => _search = value);
      _load();
    });
  }

  Color _statusColor(String? code) {
    switch (code) {
      case 'active':
        return Colors.green;
      case 'on_leave':
        return Colors.blue;
      case 'suspended':
        return Colors.orange;
      case 'resigned':
      case 'terminated':
        return Colors.red;
      case 'retired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr =
        Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection:
          isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          title: Text(
            isAr
                ? 'الموظفين${_employees.isNotEmpty ? " (${_employees.length})" : ""}'
                : 'Employees${_employees.isNotEmpty ? " (${_employees.length})" : ""}',
            style:
                const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh)),
          ],
        ),
        body: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(children: [
              TextField(
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: isAr
                      ? 'بحث بالاسم / الكود / الموبايل'
                      : 'Search by name / code / phone',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _filterChip(
                      isAr ? 'الكل' : 'All', '', isAr),
                  _filterChip(context.l10n.active, 'active',
                      isAr),
                  _filterChip(context.l10n.onLeave,
                      'on_leave', isAr),
                  _filterChip(
                      isAr ? 'موقوف' : 'Suspended',
                      'suspended',
                      isAr),
                  _filterChip(
                      isAr ? 'مستقيل' : 'Resigned',
                      'resigned',
                      isAr),
                  _filterChip(
                      isAr ? 'مفصول' : 'Terminated',
                      'terminated',
                      isAr),
                ]),
              ),
            ]),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          isAr
                              ? 'تعذر التحميل ($_error)'
                              : 'Failed to load ($_error)',
                          style: const TextStyle(
                              color: Colors.red),
                        ),
                      )
                    : _employees.isEmpty
                        ? EmptyStateWidget(
                            title: isAr
                                ? 'لا يوجد موظفين'
                                : 'No Employees',
                            description: isAr
                                ? 'لم يتم العثور على موظفين بهذه المعايير.\nجرب تغيير الفلتر أو البحث.'
                                : 'No employees found with these criteria.\nTry changing the filter or search.',
                            icon: Icons.people_outline,
                            iconColor:
                                const Color(0xFF6A1B9A),
                            onRefresh: _load,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.all(12),
                              itemCount: _employees.length,
                              itemBuilder: (context, i) {
                                final emp = _employees[i]
                                    as Map<String, dynamic>;
                                final color = _statusColor(
                                    emp['status_code']);
                                return Container(
                                  margin: const EdgeInsets
                                      .only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(
                                            14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.04),
                                        blurRadius: 6,
                                        offset:
                                            const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets
                                            .symmetric(
                                                horizontal: 12,
                                                vertical: 6),
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: const Color(
                                              0xFF6A1B9A)
                                          .withOpacity(0.15),
                                      backgroundImage: (emp[
                                                      'photo'] !=
                                                  null &&
                                              emp['photo']
                                                  .toString()
                                                  .isNotEmpty)
                                          ? NetworkImage(
                                              'https://jssolutions-eg.com${emp['photo']}')
                                          : null,
                                      child: (emp['photo'] ==
                                                  null ||
                                              emp['photo']
                                                  .toString()
                                                  .isEmpty)
                                          ? const Icon(
                                              Icons.person,
                                              color: Color(
                                                  0xFF6A1B9A))
                                          : null,
                                    ),
                                    title: Text(
                                      emp['full_name'] ?? '',
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        const SizedBox(
                                            height: 4),
                                        Text(
                                          '${emp['job_title'] ?? '-'}  •  ${emp['department'] ?? '-'}',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors
                                                  .grey[700]),
                                        ),
                                        const SizedBox(
                                            height: 2),
                                        Row(children: [
                                          Icon(Icons.badge,
                                              size: 12,
                                              color: Colors
                                                  .grey[500]),
                                          const SizedBox(
                                              width: 4),
                                          Text(
                                            emp['employee_code'] ??
                                                '',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors
                                                    .grey[600]),
                                          ),
                                          const SizedBox(
                                              width: 12),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                    horizontal:
                                                        6,
                                                    vertical: 2),
                                            decoration:
                                                BoxDecoration(
                                              color: color
                                                  .withOpacity(
                                                      0.15),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          8),
                                            ),
                                            child: Text(
                                              emp['status'] ??
                                                  '',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: color,
                                                  fontWeight:
                                                      FontWeight
                                                          .bold),
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                    trailing: Icon(
                                        Icons.arrow_back_ios,
                                        size: 14,
                                        color:
                                            Colors.grey[400]),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ManagerEmployeeDetailScreen(
                                          employeeId:
                                              emp['id'],
                                          employeeName:
                                              emp['full_name'] ??
                                                  '',
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ]),
      ),
    );
  }

  Widget _filterChip(
      String label, String value, bool isAr) {
    final selected = _statusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected
                    ? Colors.white
                    : Colors.black87)),
        selected: selected,
        selectedColor: const Color(0xFF6A1B9A),
        backgroundColor: Colors.grey[200],
        onSelected: (_) {
          setState(() => _statusFilter = value);
          _load();
        },
      ),
    );
  }
}