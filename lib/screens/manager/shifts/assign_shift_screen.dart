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

  // Data
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _shiftEmployees = [];

  // Selected (Multi)
  Set<int> _selectedEmployeeIds = {};
  Set<int> _selectedDepartmentIds = {};
  Set<int> _selectedBranchIds = {};
  bool _assignToCompany = false;

  // Loading
  bool _loadingData = true;
  bool _loadingShiftEmps = true;
  bool _assigning = false;

  // Dates + Reason
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
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
    if (_assignToCompany) return true;
    return _selectedEmployeeIds.isNotEmpty ||
        _selectedDepartmentIds.isNotEmpty ||
        _selectedBranchIds.isNotEmpty;
  }

  int get _totalSelected {
    if (_assignToCompany) return _employees.length;
    int total = _selectedEmployeeIds.length;
    for (final deptId in _selectedDepartmentIds) {
      total += _employees.where((e) => e['department_id'] == deptId).length;
    }
    for (final branchId in _selectedBranchIds) {
      total += _employees.where((e) => e['branch_id'] == branchId).length;
    }
    return total;
  }

  Future<void> _assign() async {
    if (!_canAssign) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'يرجى اختيار المستهدفين' : 'Please select targets'),
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
        employeeIds: _selectedEmployeeIds.toList(),
        departmentIds: _selectedDepartmentIds.toList(),
        branchIds: _selectedBranchIds.toList(),
        assignToCompany: _assignToCompany,
      );

      if (!mounted) return;

      final isPending = result['pending_approval'] == true;
      final affectedCount = result['affected_employees_count'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isPending
              ? (isAr ? 'تم إرسال الطلب لـ HR ✅' : 'Request sent to HR ✅')
              : (isAr
                  ? 'تم تعيين الشيفت لـ $affectedCount موظف ✅'
                  : 'Shift assigned to $affectedCount employees ✅'),
        ),
        backgroundColor: isPending ? Colors.orange : Colors.green,
      ));

      setState(() {
        _selectedEmployeeIds = {};
        _selectedDepartmentIds = {};
        _selectedBranchIds = {};
        _assignToCompany = false;
        _reasonCtrl.clear();
        _assigning = false;
      });

      _loadData();
      _tabController.animateTo(1);
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
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: isAr ? 'تعيين' : 'Assign', icon: const Icon(Icons.assignment_ind)),
              Tab(text: isAr ? 'الحاليون' : 'Current', icon: const Icon(Icons.people)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAssignTab(),
            _buildCurrentTab(),
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
        _shiftSummaryCard(),
        const SizedBox(height: 12),

        // الشركة كلها
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SwitchListTile(
            title: Text(
              isAr ? '🏢 الشركة كلها' : '🏢 Whole Company',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              isAr
                  ? 'تعيين الشيفت لكل موظفي الشركة'
                  : 'Assign shift to all company employees',
              style: const TextStyle(fontSize: 12),
            ),
            value: _assignToCompany,
            activeThumbColor: kShiftColor,
            onChanged: (v) => setState(() {
              _assignToCompany = v;
              if (v) {
                _selectedEmployeeIds = {};
                _selectedDepartmentIds = {};
                _selectedBranchIds = {};
              }
            }),
          ),
        ),
        const SizedBox(height: 12),

        if (!_assignToCompany) ...[
          // الفروع
          if (_branches.isNotEmpty)
            _multiSelectCard(
              title: isAr ? '🏙️ الفروع' : '🏙️ Branches',
              icon: Icons.business,
              items: _branches,
              selectedIds: _selectedBranchIds,
              nameKey: isAr ? 'name_ar' : 'name_en',
              fallbackKey: 'name_ar',
              onToggle: (id) => setState(() {
                if (_selectedBranchIds.contains(id)) {
                  _selectedBranchIds.remove(id);
                } else {
                  _selectedBranchIds.add(id);
                }
              }),
              onSelectAll: () => setState(() {
                if (_selectedBranchIds.length == _branches.length) {
                  _selectedBranchIds = {};
                } else {
                  _selectedBranchIds = _branches.map((b) => b['id'] as int).toSet();
                }
              }),
            ),
          const SizedBox(height: 12),

          // الأقسام
          if (_departments.isNotEmpty)
            _multiSelectCard(
              title: isAr ? '🏛️ الأقسام' : '🏛️ Departments',
              icon: Icons.apartment,
              items: _departments,
              selectedIds: _selectedDepartmentIds,
              nameKey: isAr ? 'name_ar' : 'name_en',
              fallbackKey: 'name_ar',
              onToggle: (id) => setState(() {
                if (_selectedDepartmentIds.contains(id)) {
                  _selectedDepartmentIds.remove(id);
                } else {
                  _selectedDepartmentIds.add(id);
                }
              }),
              onSelectAll: () => setState(() {
                if (_selectedDepartmentIds.length == _departments.length) {
                  _selectedDepartmentIds = {};
                } else {
                  _selectedDepartmentIds = _departments.map((d) => d['id'] as int).toSet();
                }
              }),
            ),
          const SizedBox(height: 12),

          // الموظفين
          if (_employees.isNotEmpty)
            _multiSelectCard(
              title: isAr ? '👥 موظفين محددين' : '👥 Specific Employees',
              icon: Icons.person,
              items: _employees,
              selectedIds: _selectedEmployeeIds,
              nameKey: 'full_name',
              fallbackKey: 'full_name_ar',
              subtitle: 'job_title',
              onToggle: (id) => setState(() {
                if (_selectedEmployeeIds.contains(id)) {
                  _selectedEmployeeIds.remove(id);
                } else {
                  _selectedEmployeeIds.add(id);
                }
              }),
              onSelectAll: () => setState(() {
                if (_selectedEmployeeIds.length == _employees.length) {
                  _selectedEmployeeIds = {};
                } else {
                  _selectedEmployeeIds = _employees.map((e) => e['id'] as int).toSet();
                }
              }),
            ),
          const SizedBox(height: 12),
        ],

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
                    child: Text(_fmt(_startDate),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      _endDate != null ? _fmt(_endDate!) : (isAr ? 'بدون تاريخ نهاية' : 'No end date'),
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
        const SizedBox(height: 16),

        // ملخص التعيين
        if (_canAssign)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kShiftColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kShiftColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? 'ملخص التعيين' : 'Assignment Summary',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: kShiftColor),
                ),
                const SizedBox(height: 8),
                if (_assignToCompany)
                  Text(isAr ? '🏢 الشركة كلها' : '🏢 Whole Company'),
                if (_selectedBranchIds.isNotEmpty)
                  Text('🏙️ ${_selectedBranchIds.length} ${isAr ? 'فرع' : 'branch(es)'}'),
                if (_selectedDepartmentIds.isNotEmpty)
                  Text('🏛️ ${_selectedDepartmentIds.length} ${isAr ? 'قسم' : 'department(s)'}'),
                if (_selectedEmployeeIds.isNotEmpty)
                  Text('👥 ${_selectedEmployeeIds.length} ${isAr ? 'موظف مباشر' : 'direct employee(s)'}'),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // زرار التعيين
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: (_assigning || !_canAssign) ? null : _assign,
            icon: _assigning
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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

  Widget _multiSelectCard({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required Set<int> selectedIds,
    required String nameKey,
    required String fallbackKey,
    String? subtitle,
    required void Function(int) onToggle,
    required void Function() onSelectAll,
  }) {
    final allSelected = selectedIds.length == items.length;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: kShiftColor),
          title: Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              if (selectedIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kShiftColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${selectedIds.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: onSelectAll,
                    icon: Icon(allSelected ? Icons.deselect : Icons.select_all, size: 16),
                    label: Text(
                      allSelected
                          ? (isAr ? 'إلغاء الكل' : 'Deselect All')
                          : (isAr ? 'تحديد الكل' : 'Select All'),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((item) {
              final id = item['id'] as int;
              final name = (item[nameKey] ?? item[fallbackKey] ?? '').toString();
              final sub = subtitle != null ? (item[subtitle] ?? '').toString() : '';
              final isSelected = selectedIds.contains(id);
              return CheckboxListTile(
                dense: true,
                value: isSelected,
                activeColor: kShiftColor,
                title: Text(name, style: const TextStyle(fontSize: 13)),
                subtitle: sub.isNotEmpty ? Text(sub, style: const TextStyle(fontSize: 11)) : null,
                onChanged: (_) => onToggle(id),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _shiftSummaryCard() {
    return Container(
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
    );
  }

  Widget _buildCurrentTab() {
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
                Text((emp['job_title'] ?? '').toString(),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
