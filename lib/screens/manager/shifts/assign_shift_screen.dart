import 'package:flutter/material.dart';
import '../../../services/shifts_service.dart';
import '../../../services/employee_management_service.dart';

const Color kShiftColor = Color(0xFF6A1B9A);

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

  // Assignment type
  String _assignmentType = 'employee';

  // Data
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _shiftEmployees = [];

  // Loading
  bool _loadingData = true;
  bool _loadingShiftEmps = true;
  bool _assigning = false;

  // Selected values
  int? _selectedEmployeeId;
  int? _selectedDepartmentId;
  int? _selectedBranchId;

  // Dates
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // Reason
  final _reasonCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        EmployeeManagementService.getEmployeesSimple(),
        EmployeeManagementService.getDepartments(),
        EmployeeManagementService.getBranches(),
      ]);
      setState(() {
        _employees = List<Map<String, dynamic>>.from(results[0]);
        _departments = List<Map<String, dynamic>>.from(results[1]);
        _branches = List<Map<String, dynamic>>.from(results[2]);
        _loadingData = false;
      });
    } catch (_) {
      setState(() => _loadingData = false);
    }

    try {
      final shiftEmps = await ShiftsService.getShiftEmployees(widget.shift['id']);
      setState(() {
        _shiftEmployees = shiftEmps;
        _loadingShiftEmps = false;
      });
    } catch (_) {
      setState(() => _loadingShiftEmps = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? _startDate
          : (_endDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  bool get _canAssign {
    if (_assignmentType == 'employee' && _selectedEmployeeId == null) return false;
    if (_assignmentType == 'department' && _selectedDepartmentId == null) return false;
    if (_assignmentType == 'branch' && _selectedBranchId == null) return false;
    return true;
  }

  Future<void> _assign() async {
    if (!_canAssign) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'يرجى اختيار المستهدف' : 'Please select a target'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _assigning = true);

    try {
      final result = await ShiftsService.assignShift(
        shiftId: widget.shift['id'],
        startDate: _fmt(_startDate),
        endDate: _endDate != null ? _fmt(_endDate!) : null,
        reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
        lang: isAr ? 'ar' : 'en',
        employeeId: _assignmentType == 'employee' ? _selectedEmployeeId : null,
        departmentId: _assignmentType == 'department' ? _selectedDepartmentId : null,
        branchId: _assignmentType == 'branch' ? _selectedBranchId : null,
        assignToCompany: _assignmentType == 'company',
      );

      if (!mounted) return;

      final isPending = result['pending_approval'] == true;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isPending
              ? (isAr
                  ? 'تم إرسال طلب التغيير لـ HR للموافقة ✅'
                  : 'Change request sent to HR for approval ✅')
              : (result['message'] ?? (isAr ? 'تم التعيين ✅' : 'Assigned ✅')),
        ),
        backgroundColor: isPending ? Colors.orange : Colors.green,
      ));

      setState(() {
        _selectedEmployeeId = null;
        _selectedDepartmentId = null;
        _selectedBranchId = null;
        _reasonCtrl.clear();
        _assigning = false;
      });

      _loadData();
      if (_assignmentType == 'employee') {
        _tabController.animateTo(1);
      }
    } catch (e) {
      setState(() => _assigning = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr
                ? 'تعيين شيفت: ${widget.shift['name']}'
                : 'Assign Shift: ${widget.shift['name']}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kShiftColor,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: isAr ? 'تعيين' : 'Assign', icon: const Icon(Icons.assignment_ind)),
              Tab(text: isAr ? 'الموظفون الحاليون' : 'Current Employees', icon: const Icon(Icons.people)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAssignTab(),
            _buildCurrentEmployeesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignTab() {
    if (_loadingData) {
      return const Center(child: CircularProgressIndicator(color: kShiftColor));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // شرح الشيفت
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kShiftColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kShiftColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: kShiftColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.shift['name'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${widget.shift['start_time'] ?? ''} - ${widget.shift['end_time'] ?? ''}  |  ${isAr ? 'سماح' : 'Grace'}: ${widget.shift['grace_period'] ?? 0} ${isAr ? 'د' : 'min'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // نوع التعيين
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'نوع التعيين' : 'Assignment Type',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _typeChip('employee', Icons.person, isAr ? 'موظف' : 'Employee'),
                    _typeChip('department', Icons.apartment, isAr ? 'قسم' : 'Department'),
                    _typeChip('branch', Icons.business, isAr ? 'فرع' : 'Branch'),
                    _typeChip('company', Icons.corporate_fare, isAr ? 'الشركة كلها' : 'Whole Company'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // المستهدف
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'اختر المستهدف' : 'Select Target',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                if (_assignmentType == 'employee')
                  DropdownButtonFormField<int>(
                    initialValue: _selectedEmployeeId,
                    decoration: InputDecoration(
                      labelText: isAr ? 'اختر الموظف *' : 'Select Employee *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person, color: kShiftColor),
                    ),
                    isExpanded: true,
                    items: _employees.map((e) => DropdownMenuItem<int>(
                      value: e['id'] as int,
                      child: Text(
                        '${e['full_name'] ?? e['full_name_ar'] ?? ''} - ${e['job_title'] ?? ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedEmployeeId = v),
                  ),
                if (_assignmentType == 'department')
                  DropdownButtonFormField<int>(
                    initialValue: _selectedDepartmentId,
                    decoration: InputDecoration(
                      labelText: isAr ? 'اختر القسم *' : 'Select Department *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.apartment, color: kShiftColor),
                    ),
                    isExpanded: true,
                    items: _departments.map((d) => DropdownMenuItem<int>(
                      value: d['id'] as int,
                      child: Text(
                        isAr ? (d['name_ar'] ?? '') : (d['name_en'] ?? d['name_ar'] ?? ''),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedDepartmentId = v),
                  ),
                if (_assignmentType == 'branch')
                  DropdownButtonFormField<int>(
                    initialValue: _selectedBranchId,
                    decoration: InputDecoration(
                      labelText: isAr ? 'اختر الفرع *' : 'Select Branch *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.business, color: kShiftColor),
                    ),
                    isExpanded: true,
                    items: _branches.map((b) => DropdownMenuItem<int>(
                      value: b['id'] as int,
                      child: Text(
                        isAr ? (b['name_ar'] ?? '') : (b['name_en'] ?? b['name_ar'] ?? ''),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedBranchId = v),
                  ),
                if (_assignmentType == 'company')
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kShiftColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kShiftColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.corporate_fare, color: kShiftColor),
                        const SizedBox(width: 8),
                        Text(
                          isAr
                              ? 'سيتم تعيين الشيفت على مستوى الشركة كلها'
                              : 'Shift will be assigned to the whole company',
                          style: const TextStyle(color: kShiftColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // التواريخ
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'تواريخ السريان' : 'Effective Dates',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickDate(isStart: true),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: isAr ? 'تاريخ البداية *' : 'Start Date *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                    ),
                    child: Text(
                      _fmt(_startDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickDate(isStart: false),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: isAr ? 'تاريخ النهاية (اختياري)' : 'End Date (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.event, color: Colors.orange),
                      suffixIcon: _endDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _endDate = null),
                            )
                          : null,
                    ),
                    child: Text(
                      _endDate != null
                          ? _fmt(_endDate!)
                          : (isAr ? 'بدون تاريخ نهاية' : 'No end date'),
                      style: TextStyle(
                        color: _endDate != null ? Colors.black : Colors.grey[500],
                        fontWeight: _endDate != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // السبب
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isAr ? 'سبب التعيين (اختياري)' : 'Reason (optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.notes, color: kShiftColor),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // زرار التعيين
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _assigning ? null : _assign,
            icon: _assigning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.assignment_ind),
            label: Text(
              _assigning
                  ? (isAr ? 'جاري التعيين...' : 'Assigning...')
                  : (isAr ? 'تعيين الشيفت ✓' : 'Assign Shift ✓'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kShiftColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _typeChip(String type, IconData icon, String label) {
    final isSelected = _assignmentType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _assignmentType = type;
        _selectedEmployeeId = null;
        _selectedDepartmentId = null;
        _selectedBranchId = null;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kShiftColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? kShiftColor : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentEmployeesTab() {
    if (_loadingShiftEmps) {
      return const Center(child: CircularProgressIndicator(color: kShiftColor));
    }

    if (_shiftEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 70, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              isAr ? 'لا يوجد موظفون في هذا الشيفت' : 'No employees in this shift',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _shiftEmployees.length,
      itemBuilder: (_, i) {
        final emp = _shiftEmployees[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: kShiftColor.withValues(alpha: 0.1),
              child: Text(
                (emp['full_name'] ?? '?').toString().substring(0, 1),
                style: const TextStyle(color: kShiftColor, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              (emp['full_name'] ?? '').toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (emp['job_title'] ?? '').toString(),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  '${isAr ? 'من' : 'From'}: ${emp['start_date'] ?? ''}',
                  style: TextStyle(color: Colors.green[700], fontSize: 12),
                ),
              ],
            ),
            trailing: Text(
              (emp['employee_code'] ?? '').toString(),
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ),
        );
      },
    );
  }
}
