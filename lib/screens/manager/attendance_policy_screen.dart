import 'package:flutter/material.dart';
import '../../../services/attendance_policy_service.dart';
import '../../../services/employee_management_service.dart';

const Color kPolicyColor = Color(0xFF1565C0);

class AttendancePolicyScreen extends StatefulWidget {
  const AttendancePolicyScreen({super.key});

  @override
  State<AttendancePolicyScreen> createState() => _AttendancePolicyScreenState();
}

class _AttendancePolicyScreenState extends State<AttendancePolicyScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  List<Map<String, dynamic>> _policies = [];
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
      final policies = await AttendancePolicyService.getPolicies();
      setState(() { _policies = policies; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(Map<String, dynamic> policy) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف السياسة'),
          content: Text('هل تريد حذف "${policy['name']}"'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('تراجع')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    try {
      await AttendancePolicyService.deletePolicy(policy['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف السياسة'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _approve(Map<String, dynamic> policy) async {
    try {
      await AttendancePolicyService.approvePolicy(policy['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم اعتماد السياسة وتفعيلها ✅' : 'Policy approved and activated ✅'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'approved': return Colors.blue;
      case 'archived': return Colors.grey;
      default: return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'draft': return isAr ? 'مسودة' : 'Draft';
      case 'approved': return isAr ? 'معتمد' : 'Approved';
      case 'active': return isAr ? 'نشط' : 'Active';
      case 'archived': return isAr ? 'مؤرشف' : 'Archived';
      default: return status;
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
            isAr ? 'سياسات الحضور والخصم' : 'Attendance Policies',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPolicyColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _load),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kPolicyColor))
            : _error != null
                ? _buildError()
                : _policies.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _policies.length,
                          itemBuilder: (_, i) => _buildCard(_policies[i]),
                        ),
                      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateEditPolicyScreen()),
            );
            if (result == true) _load();
          },
          backgroundColor: kPolicyColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(isAr ? 'سياسة جديدة' : 'New Policy',
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> policy) {
    final status = policy['status'] ?? 'draft';
    final statusColor = _statusColor(status);
    final assignments = policy['assignments'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(policy['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(_statusLabel(status),
                    style: TextStyle(
                        color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${isAr ? 'من' : 'From'}: ${policy['effective_from'] ?? ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (policy['effective_to'] != null) ...[
                const SizedBox(width: 8),
                Text('${isAr ? 'لحد' : 'To'}: ${policy['effective_to']}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ]),
            // بيان الأذونات لو مفعلة
            if (policy['permission_enabled'] == true) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.access_time, size: 14, color: Colors.teal),
                const SizedBox(width: 4),
                Text(
                  isAr
                      ? 'أذونات: ${policy['permission_monthly_hours']} ساعة / ${policy['permission_monthly_count']} مرة'
                      : 'Permissions: ${policy['permission_monthly_hours']}h / ${policy['permission_monthly_count']} times',
                  style: const TextStyle(fontSize: 12, color: Colors.teal),
                ),
              ]),
            ],
            if (assignments.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: assignments.map((a) {
                  final label = a['assignment_type'] == 'company'
                      ? (isAr ? 'الشركة كلها' : 'Whole Company')
                      : a['assignment_type'] == 'branch'
                          ? (a['branch_name'] ?? '')
                          : (a['department_name'] ?? '');
                  return Chip(
                    label: Text(label, style: const TextStyle(fontSize: 11)),
                    backgroundColor: kPolicyColor.withValues(alpha: 0.08),
                    side: BorderSide(color: kPolicyColor.withValues(alpha: 0.2)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 16),
            Row(children: [
              TextButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => CreateEditPolicyScreen(policy: policy)));
                  if (result == true) _load();
                },
                icon: const Icon(Icons.edit, size: 16),
                label: Text(isAr ? 'تعديل' : 'Edit'),
                style: TextButton.styleFrom(foregroundColor: kPolicyColor),
              ),
              TextButton.icon(
                onPressed: () => _showAssignDialog(policy),
                icon: const Icon(Icons.link, size: 16),
                label: Text(isAr ? 'ربط' : 'Assign'),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
              ),
              const Spacer(),
              if (status == 'draft')
                ElevatedButton(
                  onPressed: () => _approve(policy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(isAr ? 'اعتماد' : 'Approve',
                      style: const TextStyle(fontSize: 12)),
                ),
              if (status != 'active')
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _delete(policy),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showAssignDialog(Map<String, dynamic> policy) async {
    final departments = await EmployeeManagementService.getDepartments();
    final branches = await EmployeeManagementService.getBranches();
    if (!mounted) return;

    String assignmentType = 'company';
    int? selectedDeptId;
    int? selectedBranchId;

    await showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Text(isAr ? 'ربط السياسة' : 'Assign Policy'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: assignmentType,
                  decoration: InputDecoration(
                    labelText: isAr ? 'نوع الربط' : 'Assignment Type',
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'company',
                        child: Text(isAr ? 'الشركة كلها' : 'Whole Company')),
                    DropdownMenuItem(value: 'branch',
                        child: Text(isAr ? 'فرع' : 'Branch')),
                    DropdownMenuItem(value: 'department',
                        child: Text(isAr ? 'قسم' : 'Department')),
                  ],
                  onChanged: (v) => setS(() => assignmentType = v ?? 'company'),
                ),
                const SizedBox(height: 12),
                if (assignmentType == 'branch')
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: isAr ? 'اختر الفرع' : 'Select Branch',
                      border: const OutlineInputBorder(),
                    ),
                    items: branches.map((b) => DropdownMenuItem<int>(
                      value: b['id'] as int,
                      child: Text(isAr
                          ? (b['name_ar'] ?? '')
                          : (b['name_en'] ?? b['name_ar'] ?? '')),
                    )).toList(),
                    onChanged: (v) => setS(() => selectedBranchId = v),
                  ),
                if (assignmentType == 'department')
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: isAr ? 'اختر القسم' : 'Select Department',
                      border: const OutlineInputBorder(),
                    ),
                    items: departments.map((d) => DropdownMenuItem<int>(
                      value: d['id'] as int,
                      child: Text(isAr
                          ? (d['name_ar'] ?? '')
                          : (d['name_en'] ?? d['name_ar'] ?? '')),
                    )).toList(),
                    onChanged: (v) => setS(() => selectedDeptId = v),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'تراجع' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await AttendancePolicyService.assignPolicy(
                      policyId: policy['id'],
                      assignmentType: assignmentType,
                      departmentId: selectedDeptId,
                      branchId: selectedBranchId,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isAr ? 'تم ربط السياسة ✅' : 'Policy assigned ✅'),
                        backgroundColor: Colors.green,
                      ));
                      _load();
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: kPolicyColor, foregroundColor: Colors.white),
                child: Text(isAr ? 'تأكيد' : 'Confirm'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? ''),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
                backgroundColor: kPolicyColor, foregroundColor: Colors.white),
            child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.policy_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(isAr ? 'لا توجد سياسات' : 'No policies',
              style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            isAr ? 'اضغط + لإنشاء سياسة جديدة' : 'Press + to create a new policy',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// شاشة إنشاء/تعديل السياسة
// ─────────────────────────────────────────────────────────
class CreateEditPolicyScreen extends StatefulWidget {
  final Map<String, dynamic>? policy;
  const CreateEditPolicyScreen({super.key, this.policy});

  @override
  State<CreateEditPolicyScreen> createState() => _CreateEditPolicyScreenState();
}

class _CreateEditPolicyScreenState extends State<CreateEditPolicyScreen>
    with SingleTickerProviderStateMixin {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  bool get isEdit => widget.policy != null;

  late TabController _tabController;
  final _nameCtrl = TextEditingController();
  DateTime _effectiveFrom = DateTime.now();
  DateTime? _effectiveTo;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  // Permission Settings
  bool _permissionEnabled = false;
  double _permissionMonthlyHours = 4.0;
  int _permissionMonthlyCount = 2;
  double _permissionMaxHoursPerRequest = 2.0;
  bool _permissionFractionAsFull = false;
  String _permissionResetCycle = 'calendar';

  // Late Rules
  List<Map<String, dynamic>> _lateRules = [
    {'from_minutes': 0, 'to_minutes': 15, 'deduction_type': 'none', 'deduction_value': 0.0},
    {'from_minutes': 16, 'to_minutes': 30, 'deduction_type': 'day_fraction', 'deduction_value': 0.25},
    {'from_minutes': 31, 'to_minutes': 60, 'deduction_type': 'day_fraction', 'deduction_value': 0.5},
    {'from_minutes': 61, 'to_minutes': 999, 'deduction_type': 'day_fraction', 'deduction_value': 1.0},
  ];

  // Absence Rules
  List<Map<String, dynamic>> _absenceRules = [
    {'absence_type': 'unexcused', 'deduction_type': 'day_fraction', 'deduction_value': 1.0},
  ];

  // Overtime Rules
  List<Map<String, dynamic>> _overtimeRules = [
    {'overtime_type': 'after_shift', 'multiplier': 1.5, 'min_minutes': 30},
    {'overtime_type': 'weekend', 'multiplier': 2.0, 'min_minutes': 60},
    {'overtime_type': 'holiday', 'multiplier': 2.5, 'min_minutes': 60},
  ];

  // Night Shift
  List<Map<String, dynamic>> _nightRules = [
    {'allowance_type': 'fixed_amount', 'amount': 50.0, 'percentage': 10.0,
      'night_start_hour': 20, 'min_night_hours': 4},
  ];

  // Weekend Work
  List<Map<String, dynamic>> _weekendRules = [
    {'compensation_type': 'overtime_multiplier', 'multiplier': 2.0, 'amount': 0.0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    if (isEdit) {
      final p = widget.policy!;
      _nameCtrl.text = p['name'] ?? '';
      _notesCtrl.text = p['notes'] ?? '';
      if (p['effective_from'] != null) {
        _effectiveFrom = DateTime.tryParse(p['effective_from']) ?? DateTime.now();
      }
      if (p['effective_to'] != null) {
        _effectiveTo = DateTime.tryParse(p['effective_to']);
      }
      if ((p['late_rules'] as List? ?? []).isNotEmpty) {
        _lateRules = List<Map<String, dynamic>>.from(p['late_rules']);
      }
      if ((p['absence_rules'] as List? ?? []).isNotEmpty) {
        _absenceRules = List<Map<String, dynamic>>.from(p['absence_rules']);
      }
      if ((p['overtime_rules'] as List? ?? []).isNotEmpty) {
        _overtimeRules = List<Map<String, dynamic>>.from(p['overtime_rules']);
      }
      if ((p['night_shift_rules'] as List? ?? []).isNotEmpty) {
        _nightRules = List<Map<String, dynamic>>.from(p['night_shift_rules']);
      }
      if ((p['weekend_work_rules'] as List? ?? []).isNotEmpty) {
        _weekendRules = List<Map<String, dynamic>>.from(p['weekend_work_rules']);
      }
      // Permission Settings
      _permissionEnabled = p['permission_enabled'] ?? false;
      _permissionMonthlyHours = double.tryParse(
          p['permission_monthly_hours']?.toString() ?? '4') ?? 4.0;
      _permissionMonthlyCount = p['permission_monthly_count'] ?? 2;
      _permissionMaxHoursPerRequest = double.tryParse(
          p['permission_max_hours_per_request']?.toString() ?? '2') ?? 2.0;
      _permissionFractionAsFull = p['permission_fraction_as_full'] ?? false;
      _permissionResetCycle = p['permission_reset_cycle'] ?? 'calendar';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _effectiveFrom : (_effectiveTo ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => isStart ? _effectiveFrom = picked : _effectiveTo = picked);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'اسم السياسة مطلوب' : 'Policy name is required'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _saving = true);

    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'effective_from': _fmt(_effectiveFrom),
        'effective_to': _effectiveTo != null ? _fmt(_effectiveTo!) : null,
        'notes': _notesCtrl.text.trim(),
        'late_rules': _lateRules,
        'absence_rules': _absenceRules,
        'overtime_rules': _overtimeRules,
        'night_shift_rules': _nightRules,
        'weekend_work_rules': _weekendRules,
        'permission_enabled': _permissionEnabled,
        'permission_monthly_hours': _permissionMonthlyHours,
        'permission_monthly_count': _permissionMonthlyCount,
        'permission_max_hours_per_request': _permissionMaxHoursPerRequest,
        'permission_fraction_as_full': _permissionFractionAsFull,
        'permission_reset_cycle': _permissionResetCycle,
      };

      if (isEdit) {
        await AttendancePolicyService.updatePolicy(widget.policy!['id'], body);
      } else {
        await AttendancePolicyService.createPolicy(body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم الحفظ بنجاح ✅' : 'Saved successfully ✅'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
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
            isEdit
                ? (isAr ? 'تعديل السياسة' : 'Edit Policy')
                : (isAr ? 'سياسة جديدة' : 'New Policy'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kPolicyColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            isScrollable: true,
            tabs: [
              Tab(text: isAr ? 'الأساسي' : 'Basic'),
              Tab(text: isAr ? 'التأخير' : 'Late'),
              Tab(text: isAr ? 'الغياب' : 'Absence'),
              Tab(text: isAr ? 'أوفر تايم' : 'Overtime'),
              Tab(text: isAr ? 'بدلات' : 'Allowances'),
              Tab(text: isAr ? 'الأذونات' : 'Permissions'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicTab(),
            _buildLateRulesTab(),
            _buildAbsenceTab(),
            _buildOvertimeTab(),
            _buildAllowancesTab(),
            _buildPermissionsTab(),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPolicyColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      isAr ? 'حفظ السياسة ✓' : 'Save Policy ✓',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isAr ? 'معلومات السياسة' : 'Policy Info',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: kPolicyColor)),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم السياسة *' : 'Policy Name *',
                prefixIcon: const Icon(Icons.policy, color: kPolicyColor),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(isStart: true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: isAr ? 'سارية من *' : 'Effective From *',
                  prefixIcon:
                      const Icon(Icons.calendar_today, color: Colors.green),
                  border: const OutlineInputBorder(),
                ),
                child: Text(_fmt(_effectiveFrom),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _pickDate(isStart: false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: isAr
                      ? 'سارية لحد (اختياري)'
                      : 'Effective To (optional)',
                  prefixIcon:
                      const Icon(Icons.event, color: Colors.orange),
                  border: const OutlineInputBorder(),
                  suffixIcon: _effectiveTo != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setState(() => _effectiveTo = null))
                      : null,
                ),
                child: Text(
                  _effectiveTo != null
                      ? _fmt(_effectiveTo!)
                      : (isAr ? 'بدون تاريخ نهاية' : 'No end date'),
                  style: TextStyle(
                      color: _effectiveTo != null
                          ? Colors.black
                          : Colors.grey[500]),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isAr ? 'ملاحظات' : 'Notes',
                prefixIcon: const Icon(Icons.notes, color: kPolicyColor),
                border: const OutlineInputBorder(),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildLateRulesTab() {
    final deductionTypes = [
      {'value': 'none', 'label': isAr ? 'لا خصم' : 'No deduction'},
      {'value': 'day_fraction', 'label': isAr ? 'نسبة من اليوم' : 'Day fraction'},
      {'value': 'fixed_amount', 'label': isAr ? 'مبلغ ثابت' : 'Fixed amount'},
      {'value': 'per_minute', 'label': isAr ? 'لكل دقيقة' : 'Per minute'},
    ];

    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Text(isAr ? 'قواعد خصم التأخير' : 'Late Deduction Rules',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: kPolicyColor)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => setState(() => _lateRules.add({
                'from_minutes': 0,
                'to_minutes': 30,
                'deduction_type': 'day_fraction',
                'deduction_value': 0.25
              })),
          icon: const Icon(Icons.add, size: 16),
          label: Text(isAr ? 'إضافة' : 'Add'),
        ),
      ]),
      const SizedBox(height: 8),
      ..._lateRules.asMap().entries.map((entry) {
        final i = entry.key;
        final rule = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${isAr ? 'قاعدة' : 'Rule'} ${i + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: kPolicyColor)),
                const Spacer(),
                if (_lateRules.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    onPressed: () =>
                        setState(() => _lateRules.removeAt(i)),
                  ),
              ]),
              Row(children: [
                Expanded(
                    child: TextFormField(
                  initialValue: rule['from_minutes'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'من دقيقة' : 'From min',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      _lateRules[i]['from_minutes'] = int.tryParse(v) ?? 0,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextFormField(
                  initialValue: rule['to_minutes'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'إلى دقيقة' : 'To min',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      _lateRules[i]['to_minutes'] = int.tryParse(v) ?? 999,
                )),
              ]),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: rule['deduction_type'] as String,
                decoration: InputDecoration(
                  labelText: isAr ? 'نوع الخصم' : 'Deduction Type',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: deductionTypes
                    .map((t) => DropdownMenuItem<String>(
                        value: t['value'], child: Text(t['label']!)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _lateRules[i]['deduction_type'] = v),
              ),
              if (rule['deduction_type'] != 'none') ...[
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: rule['deduction_value'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'القيمة' : 'Value',
                    helperText: rule['deduction_type'] == 'day_fraction'
                        ? (isAr
                            ? '0.25 = ربع يوم / 0.5 = نص يوم'
                            : '0.25 = quarter day')
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => _lateRules[i]['deduction_value'] =
                      double.tryParse(v) ?? 0,
                ),
              ],
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _buildAbsenceTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Text(isAr ? 'قواعد خصم الغياب' : 'Absence Rules',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: kPolicyColor)),
        const Spacer(),
        TextButton.icon(
          onPressed: () => setState(() => _absenceRules.add({
                'absence_type': 'unexcused',
                'deduction_type': 'day_fraction',
                'deduction_value': 1.0
              })),
          icon: const Icon(Icons.add, size: 16),
          label: Text(isAr ? 'إضافة' : 'Add'),
        ),
      ]),
      ..._absenceRules.asMap().entries.map((entry) {
        final i = entry.key;
        final rule = entry.value;
        return Card(
          margin: const EdgeInsets.only(bottom: 8, top: 4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${isAr ? 'قاعدة' : 'Rule'} ${i + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: kPolicyColor)),
                const Spacer(),
                if (_absenceRules.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    onPressed: () =>
                        setState(() => _absenceRules.removeAt(i)),
                  ),
              ]),
              DropdownButtonFormField<String>(
                initialValue: rule['absence_type'] as String,
                decoration: InputDecoration(
                  labelText: isAr ? 'نوع الغياب' : 'Absence Type',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                      value: 'unexcused',
                      child: Text(isAr ? 'بدون إذن' : 'Unexcused')),
                  DropdownMenuItem(
                      value: 'consecutive',
                      child: Text(isAr ? 'متتالي' : 'Consecutive')),
                  DropdownMenuItem(
                      value: 'repeated',
                      child: Text(
                          isAr ? 'متكرر في الشهر' : 'Repeated in month')),
                ],
                onChanged: (v) =>
                    setState(() => _absenceRules[i]['absence_type'] = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: rule['deduction_type'] as String,
                decoration: InputDecoration(
                  labelText: isAr ? 'نوع الخصم' : 'Deduction Type',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                      value: 'day_fraction',
                      child:
                          Text(isAr ? 'نسبة من اليوم' : 'Day fraction')),
                  DropdownMenuItem(
                      value: 'fixed_amount',
                      child: Text(isAr ? 'مبلغ ثابت' : 'Fixed amount')),
                  DropdownMenuItem(
                      value: 'warning',
                      child: Text(isAr ? 'إنذار فقط' : 'Warning only')),
                ],
                onChanged: (v) =>
                    setState(() => _absenceRules[i]['deduction_type'] = v),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: rule['deduction_value'].toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'القيمة' : 'Value',
                  helperText: isAr
                      ? '1 = يوم كامل / 1.5 = يوم ونص'
                      : '1 = full day / 1.5 = 1.5 days',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => _absenceRules[i]['deduction_value'] =
                    double.tryParse(v) ?? 1,
              ),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _buildOvertimeTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(isAr ? 'قواعد الأوفر تايم' : 'Overtime Rules',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: kPolicyColor)),
      const SizedBox(height: 8),
      ..._overtimeRules.asMap().entries.map((entry) {
        final i = entry.key;
        final rule = entry.value;
        final typeLabel = {
              'after_shift': isAr ? 'بعد الشيفت' : 'After shift',
              'weekend': isAr ? 'يوم الراحة' : 'Weekend',
              'holiday': isAr ? 'إجازة رسمية' : 'Holiday',
              'regular': isAr ? 'عادي' : 'Regular',
            }[rule['overtime_type']] ??
            '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(typeLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: kPolicyColor)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextFormField(
                  initialValue: rule['multiplier'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'المضاعف' : 'Multiplier',
                    helperText: '1.5x / 2x / 2.5x',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => _overtimeRules[i]['multiplier'] =
                      double.tryParse(v) ?? 1.5,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextFormField(
                  initialValue: rule['min_minutes'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'أقل دقائق' : 'Min minutes',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => _overtimeRules[i]['min_minutes'] =
                      int.tryParse(v) ?? 30,
                )),
              ]),
            ]),
          ),
        );
      }),
    ]);
  }

  Widget _buildAllowancesTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(isAr ? 'بدل الشيفت الليلي' : 'Night Shift Allowance',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: kPolicyColor)),
      const SizedBox(height: 8),
      if (_nightRules.isNotEmpty)
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              DropdownButtonFormField<String>(
                initialValue: _nightRules[0]['allowance_type'] as String,
                decoration: InputDecoration(
                  labelText: isAr ? 'نوع البدل' : 'Allowance Type',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                      value: 'fixed_amount',
                      child: Text(isAr ? 'مبلغ ثابت' : 'Fixed amount')),
                  DropdownMenuItem(
                      value: 'percentage',
                      child:
                          Text(isAr ? 'نسبة مئوية' : 'Percentage')),
                ],
                onChanged: (v) =>
                    setState(() => _nightRules[0]['allowance_type'] = v),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextFormField(
                  initialValue: _nightRules[0]['amount'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr
                        ? 'المبلغ الثابت (للليلة)'
                        : 'Fixed amount (per night)',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) =>
                      _nightRules[0]['amount'] = double.tryParse(v) ?? 0,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextFormField(
                  initialValue: _nightRules[0]['percentage'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'النسبة %' : 'Percentage %',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => _nightRules[0]['percentage'] =
                      double.tryParse(v) ?? 0,
                )),
              ]),
            ]),
          ),
        ),
      const SizedBox(height: 16),
      Text(isAr ? 'بدل العمل يوم الراحة' : 'Weekend Work Allowance',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: kPolicyColor)),
      const SizedBox(height: 8),
      if (_weekendRules.isNotEmpty)
        Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              DropdownButtonFormField<String>(
                initialValue:
                    _weekendRules[0]['compensation_type'] as String,
                decoration: InputDecoration(
                  labelText:
                      isAr ? 'نوع التعويض' : 'Compensation Type',
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                      value: 'overtime_multiplier',
                      child: Text(isAr
                          ? 'نسبة من المرتب'
                          : 'Salary multiplier')),
                  DropdownMenuItem(
                      value: 'fixed_amount',
                      child: Text(isAr ? 'مبلغ ثابت' : 'Fixed amount')),
                  DropdownMenuItem(
                      value: 'day_off',
                      child: Text(isAr
                          ? 'يوم إجازة بديل'
                          : 'Compensatory day off')),
                ],
                onChanged: (v) => setState(
                    () => _weekendRules[0]['compensation_type'] = v),
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: TextFormField(
                  initialValue: _weekendRules[0]['multiplier'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'المضاعف' : 'Multiplier',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => _weekendRules[0]['multiplier'] =
                      double.tryParse(v) ?? 2.0,
                )),
                const SizedBox(width: 8),
                Expanded(
                    child: TextFormField(
                  initialValue: _weekendRules[0]['amount'].toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'المبلغ الثابت' : 'Fixed amount',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => _weekendRules[0]['amount'] =
                      double.tryParse(v) ?? 0,
                )),
              ]),
            ]),
          ),
        ),
    ]);
  }

  Widget _buildPermissionsTab() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isAr ? 'إعدادات الأذونات' : 'Permission Settings',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: kPolicyColor)),
            const SizedBox(height: 12),

            // تفعيل الأذونات
            SwitchListTile(
              title: Text(isAr ? 'تفعيل نظام الأذونات' : 'Enable Permission System'),
              subtitle: Text(isAr
                  ? 'السماح للموظفين بأذونات شهرية'
                  : 'Allow employees monthly permissions'),
              value: _permissionEnabled,
              activeColor: kPolicyColor,
              onChanged: (v) => setState(() => _permissionEnabled = v),
            ),

            if (_permissionEnabled) ...[
              const Divider(),
              const SizedBox(height: 8),

              // رصيد الساعات الشهري
              TextFormField(
                initialValue: _permissionMonthlyHours.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'رصيد الساعات الشهري' : 'Monthly Hours Balance',
                  helperText: isAr ? 'مثال: 4 = 4 ساعات في الشهر' : 'Example: 4 = 4 hours per month',
                  prefixIcon: const Icon(Icons.access_time, color: kPolicyColor),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _permissionMonthlyHours = double.tryParse(v) ?? 4.0,
              ),
              const SizedBox(height: 12),

              // عدد المرات الشهري
              TextFormField(
                initialValue: _permissionMonthlyCount.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'عدد المرات في الشهر' : 'Monthly Count',
                  helperText: isAr ? 'مثال: 2 = مرتين في الشهر' : 'Example: 2 = twice per month',
                  prefixIcon: const Icon(Icons.repeat, color: kPolicyColor),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _permissionMonthlyCount = int.tryParse(v) ?? 2,
              ),
              const SizedBox(height: 12),

              // الحد الأقصى للمرة الواحدة
              TextFormField(
                initialValue: _permissionMaxHoursPerRequest.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'الحد الأقصى للإذن الواحد (ساعات)' : 'Max hours per permission',
                  helperText: isAr ? 'مثال: 2 = الإذن الواحد بحد أقصى ساعتين' : 'Example: 2 = max 2 hours per permission',
                  prefixIcon: const Icon(Icons.hourglass_top, color: Colors.orange),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _permissionMaxHoursPerRequest = double.tryParse(v) ?? 2.0,
              ),
              const SizedBox(height: 12),

              // الكسر بمرة كاملة
              SwitchListTile(
                title: Text(isAr ? 'الكسر يتحسب مرة كاملة' : 'Fraction counts as full'),
                subtitle: Text(isAr
                    ? 'لو استخدم نص ساعة بتحسب مرة كاملة'
                    : 'Using half hour counts as full permission'),
                value: _permissionFractionAsFull,
                activeColor: Colors.orange,
                onChanged: (v) => setState(() => _permissionFractionAsFull = v),
              ),
              const SizedBox(height: 12),

              // دورة التجديد
              DropdownButtonFormField<String>(
                value: _permissionResetCycle,
                decoration: InputDecoration(
                  labelText: isAr ? 'دورة تجديد الرصيد' : 'Balance Reset Cycle',
                  prefixIcon: const Icon(Icons.refresh, color: kPolicyColor),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                      value: 'calendar',
                      child: Text(isAr ? 'شهر ميلادي' : 'Calendar month')),
                  DropdownMenuItem(
                      value: 'payroll',
                      child: Text(isAr ? 'مع دورة المرتب' : 'Payroll cycle')),
                ],
                onChanged: (v) => setState(() => _permissionResetCycle = v ?? 'calendar'),
              ),
            ],
          ]),
        ),
      ),
    ]);
  }
}