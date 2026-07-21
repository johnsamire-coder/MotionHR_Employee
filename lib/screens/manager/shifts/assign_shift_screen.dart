import 'package:flutter/material.dart';
import '../../../services/shifts_service.dart';
import '../../../services/employee_management_service.dart';

const Color kManagerColor = Color(0xFF6A1B9A);

class AssignShiftScreen extends StatefulWidget {
  final Map<String, dynamic> shift;
  const AssignShiftScreen({super.key, required this.shift});
  @override
  State<AssignShiftScreen> createState() => _AssignShiftScreenState();
}

class _AssignShiftScreenState extends State<AssignShiftScreen>
    with SingleTickerProviderStateMixin {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  late TabController _tabController;
  List<Map<String, dynamic>> _allEmployees = [];
  List<Map<String, dynamic>> _shiftEmployees = [];
  bool _loadingEmployees = true;
  bool _loadingShiftEmps = true;
  int? _selectedEmployeeId;
  String? _selectedEmployeeName;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _assigning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final emps = await EmployeeManagementService.getEmployeesSimple();
      setState(() { _allEmployees = emps; _loadingEmployees = false; });
    } catch (e) {
      setState(() => _loadingEmployees = false);
    }
    try {
      final shiftEmps = await ShiftsService.getShiftEmployees(widget.shift['id']);
      setState(() { _shiftEmployees = shiftEmps; _loadingShiftEmps = false; });
    } catch (e) {
      setState(() => _loadingShiftEmps = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _assign() async {
    if (_selectedEmployeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'يرجى اختيار موظف' : 'Please select an employee'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _assigning = true);
    try {
      final lang = isAr ? 'ar' : 'en';
      final result = await ShiftsService.assignShift(
        employeeId: _selectedEmployeeId!,
        shiftId: widget.shift['id'],
        startDate: _fmt(_startDate),
        endDate: _endDate != null ? _fmt(_endDate!) : null,
        lang: lang,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? (isAr ? 'تم التعيين' : 'Assigned')),
          backgroundColor: Colors.green,
        ));
        setState(() {
          _selectedEmployeeId = null;
          _selectedEmployeeName = null;
          _assigning = false;
        });
        _loadData();
        _tabController.animateTo(1);
      }
    } catch (e) {
      setState(() => _assigning = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr
              ? 'تعيين شيفت: ${widget.shift['name']}'
              : 'Assign Shift: ${widget.shift['name']}'),
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: isAr ? 'تعيين موظف' : 'Assign Employee'),
              Tab(text: isAr ? 'الموظفون الحاليون' : 'Current Employees'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 1: Assign ──
            _loadingEmployees
                ? const Center(child: CircularProgressIndicator())
                : ListView(padding: const EdgeInsets.all(16), children: [
                    // Shift summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: kManagerColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: kManagerColor.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.schedule, color: kManagerColor),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.shift['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(
                            '${widget.shift['start_time'] ?? ''} - ${widget.shift['end_time'] ?? ''}  |  ${isAr ? 'سماح' : 'Grace'}: ${widget.shift['grace_period'] ?? 0} ${isAr ? 'د' : 'min'}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ])),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    // Employee dropdown
                    DropdownButtonFormField<int>(
                      value: _selectedEmployeeId,
                      decoration: InputDecoration(
                        labelText: isAr ? 'اختر الموظف *' : 'Select Employee *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person, color: kManagerColor),
                      ),
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<int>(
                          value: null,
                          child: Text(isAr ? 'اختر موظفاً' : 'Select employee',
                              style: TextStyle(color: Colors.grey[500])),
                        ),
                        ..._allEmployees.map((e) => DropdownMenuItem<int>(
                          value: e['id'] as int,
                          child: Text('${e['full_name']} - ${e['job_title'] ?? ''}'),
                        )),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedEmployeeId = v;
                          _selectedEmployeeName = _allEmployees
                              .firstWhere((e) => e['id'] == v, orElse: () => {})['full_name']?.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    // Start date
                    InkWell(
                      onTap: () => _pickDate(isStart: true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: isAr ? 'تاريخ البداية *' : 'Start Date *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                        ),
                        child: Text(_fmt(_startDate),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // End date (optional)
                    InkWell(
                      onTap: () => _pickDate(isStart: false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: isAr ? 'تاريخ النهاية (اختياري)' : 'End Date (optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.event, color: Colors.orange),
                          suffixIcon: _endDate != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => setState(() => _endDate = null),
                                )
                              : null,
                        ),
                        child: Text(
                          _endDate != null ? _fmt(_endDate!) : (isAr ? 'بدون تاريخ نهاية' : 'No end date'),
                          style: TextStyle(
                            color: _endDate != null ? Colors.black : Colors.grey[500],
                            fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _assigning ? null : _assign,
                        icon: _assigning
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.assignment_ind),
                        label: Text(
                          isAr ? 'تعيين الشيفت ✓' : 'Assign Shift ✓',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kManagerColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ]),

            // ── Tab 2: Current Employees ──
            _loadingShiftEmps
                ? const Center(child: CircularProgressIndicator())
                : _shiftEmployees.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.people_outline, size: 70, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          isAr ? 'لا يوجد موظفون في هذا الشيفت' : 'No employees in this shift',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _shiftEmployees.length,
                        itemBuilder: (ctx, i) {
                          final emp = _shiftEmployees[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: kManagerColor.withOpacity(0.1),
                                child: Text(
                                  (emp['full_name'] ?? '?').toString().substring(0, 1),
                                  style: const TextStyle(
                                      color: kManagerColor, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(emp['full_name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(emp['job_title'] ?? '',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                Text(
                                  '${isAr ? 'من' : 'From'}: ${emp['start_date'] ?? ''}',
                                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                                ),
                              ]),
                              trailing: Text(emp['employee_code'] ?? '',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ),
                          );
                        },
                      ),
          ],
        ),
      ),
    );
  }
}
