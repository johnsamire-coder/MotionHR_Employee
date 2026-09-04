import 'package:flutter/material.dart';
import '../../../services/shifts_service.dart';
import '../../../services/employee_management_service.dart';

const Color kRotationColor = Color(0xFF00C688);

class ShiftRotationScreen extends StatefulWidget {
  const ShiftRotationScreen({super.key});

  @override
  State<ShiftRotationScreen> createState() => _ShiftRotationScreenState();
}

class _ShiftRotationScreenState extends State<ShiftRotationScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  List<Map<String, dynamic>> _rotations = [];
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _branches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        ShiftsService.getRotations(),
        ShiftsService.getShifts(),
        EmployeeManagementService.getEmployeesSimple(),
        EmployeeManagementService.getDepartments(),
        EmployeeManagementService.getBranches(),
      ]);
      setState(() {
        _rotations = List<Map<String, dynamic>>.from(results[0] as List);
        _shifts = List<Map<String, dynamic>>.from(results[1] as List);
        _employees = List<Map<String, dynamic>>.from(results[2] as List);
        _departments = List<Map<String, dynamic>>.from(results[3] as List);
        _branches = List<Map<String, dynamic>>.from(results[4] as List);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _deleteRotation(Map<String, dynamic> r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'حذف التناوب' : 'Delete Rotation'),
          content: Text(isAr
              ? 'هل تريد حذف "${r['name']}"؟'
              : 'Delete "${r['name']}"?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'تراجع' : 'Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;
    try {
      await ShiftsService.deleteRotation(r['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'تم الحذف' : 'Deleted'), backgroundColor: Colors.green),
        );
        _loadAll();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    int cycleDays = 7;
    DateTime startDate = DateTime.now();
    List<Map<String, dynamic>> slots = [
      {'start_day_index': 0, 'end_day_index': 6, 'shift_id': null, 'shift_name': ''},
    ];

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (ctx, setDs) => AlertDialog(
            title: Text(isAr ? 'إنشاء تناوب جديد' : 'New Rotation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: isAr ? 'اسم التناوب *' : 'Rotation Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.repeat, color: kRotationColor),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(isAr ? 'طول الدورة: $cycleDays يوم' : 'Cycle: $cycleDays days',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Slider(
                    value: cycleDays.toDouble(),
                    min: 2,
                    max: 56,
                    divisions: 54,
                    activeColor: kRotationColor,
                    label: '$cycleDays',
                    onChanged: (v) => setDs(() => cycleDays = v.round()),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setDs(() => startDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isAr ? 'تاريخ بداية الدورة *' : 'Cycle Start Date *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.calendar_today, color: kRotationColor),
                      ),
                      child: Text(_fmt(startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(isAr ? 'الفترات:' : 'Slots:', style: const TextStyle(fontWeight: FontWeight.bold, color: kRotationColor)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setDs(() => slots.add({'start_day_index': 0, 'end_day_index': cycleDays - 1, 'shift_id': null, 'shift_name': ''})),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(isAr ? 'فترة' : 'Slot'),
                      ),
                    ],
                  ),
                  ...slots.asMap().entries.map((entry) {
                    final i = entry.key;
                    final slot = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('${isAr ? 'فترة' : 'Slot'} ${i + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: kRotationColor)),
                                const Spacer(),
                                if (slots.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    onPressed: () => setDs(() => slots.removeAt(i)),
                                  ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: slot['start_day_index'].toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: isAr ? 'من يوم' : 'From day',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) => slot['start_day_index'] = int.tryParse(v) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: slot['end_day_index'].toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: isAr ? 'إلى يوم' : 'To day',
                                      border: const OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) => slot['end_day_index'] = int.tryParse(v) ?? 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<int?>(
                              initialValue: slot['shift_id'],
                              decoration: InputDecoration(
                                labelText: isAr ? 'الشيفت (فارغ = راحة)' : 'Shift (empty = off)',
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: [
                                DropdownMenuItem<int?>(value: null, child: Text(isAr ? '🏖️ يوم راحة' : '🏖️ Day off')),
                                ..._shifts.map((s) => DropdownMenuItem<int?>(
                                  value: s['id'] as int,
                                  child: Text(s['name']?.toString() ?? ''),
                                )),
                              ],
                              onChanged: (v) => setDs(() {
                                slot['shift_id'] = v;
                                slot['shift_name'] = v != null ? (_shifts.firstWhere((s) => s['id'] == v, orElse: () => {})['name'] ?? '') : '';
                              }),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'تراجع' : 'Cancel')),
              ElevatedButton(
                onPressed: nameCtrl.text.trim().isEmpty ? null : () async {
                  Navigator.pop(ctx);
                  try {
                    await ShiftsService.createRotation(
                      name: nameCtrl.text.trim(),
                      cycleLengthDays: cycleDays,
                      startDate: _fmt(startDate),
                      slots: slots,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isAr ? 'تم إنشاء التناوب ✅' : 'Rotation created ✅'),
                        backgroundColor: Colors.green,
                      ));
                      _loadAll();
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kRotationColor),
                child: Text(isAr ? 'إنشاء' : 'Create', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAssignDialog(Map<String, dynamic> rotation) async {
    String assignType = 'employee';
    int? selectedEmployeeId;
    int? selectedDeptId;
    int? selectedBranchId;
    DateTime startDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (ctx, setDs) => AlertDialog(
            title: Text(isAr ? 'تعيين التناوب' : 'Assign Rotation'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(rotation['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: kRotationColor)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: assignType,
                    decoration: InputDecoration(
                      labelText: isAr ? 'نوع التعيين' : 'Assignment Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      DropdownMenuItem(value: 'employee', child: Text(isAr ? '👤 موظف' : '👤 Employee')),
                      DropdownMenuItem(value: 'department', child: Text(isAr ? '🏛️ قسم' : '🏛️ Department')),
                      DropdownMenuItem(value: 'branch', child: Text(isAr ? '🏙️ فرع' : '🏙️ Branch')),
                      DropdownMenuItem(value: 'company', child: Text(isAr ? '🏢 الشركة كلها' : '🏢 Whole Company')),
                    ],
                    onChanged: (v) => setDs(() { assignType = v!; selectedEmployeeId = null; selectedDeptId = null; selectedBranchId = null; }),
                  ),
                  const SizedBox(height: 12),
                  if (assignType == 'employee')
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(labelText: isAr ? 'الموظف *' : 'Employee *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      items: _employees.map((e) => DropdownMenuItem<int>(value: e['id'] as int, child: Text(e['full_name']?.toString() ?? ''))).toList(),
                      onChanged: (v) => setDs(() => selectedEmployeeId = v),
                    ),
                  if (assignType == 'department')
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(labelText: isAr ? 'القسم *' : 'Department *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      items: _departments.map((d) => DropdownMenuItem<int>(value: d['id'] as int, child: Text(d['name_ar']?.toString() ?? ''))).toList(),
                      onChanged: (v) => setDs(() => selectedDeptId = v),
                    ),
                  if (assignType == 'branch')
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(labelText: isAr ? 'الفرع *' : 'Branch *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                      items: _branches.map((b) => DropdownMenuItem<int>(value: b['id'] as int, child: Text(b['name_ar']?.toString() ?? ''))).toList(),
                      onChanged: (v) => setDs(() => selectedBranchId = v),
                    ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(context: ctx, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (picked != null) setDs(() => startDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isAr ? 'تاريخ البداية *' : 'Start Date *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.calendar_today, color: kRotationColor),
                      ),
                      child: Text(_fmt(startDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'تراجع' : 'Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await ShiftsService.assignRotation(
                      rotationId: rotation['id'],
                      assignmentType: assignType,
                      startDate: _fmt(startDate),
                      employeeId: selectedEmployeeId,
                      departmentId: selectedDeptId,
                      branchId: selectedBranchId,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(isAr ? 'تم التعيين ✅' : 'Assigned ✅'),
                        backgroundColor: Colors.green,
                      ));
                    }
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: kRotationColor),
                child: Text(isAr ? 'تعيين' : 'Assign', style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(isAr ? 'تناوب الشيفتات' : 'Shift Rotation', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: kRotationColor,
          foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadAll)],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kRotationColor))
            : _error != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(onPressed: _loadAll, icon: const Icon(Icons.refresh), label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                        style: ElevatedButton.styleFrom(backgroundColor: kRotationColor, foregroundColor: Colors.white)),
                  ]))
                : _rotations.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.repeat, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(isAr ? 'لا توجد دورات تناوب' : 'No rotations found', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text(isAr ? 'اضغط + لإنشاء دورة جديدة' : 'Tap + to create a new rotation', style: TextStyle(color: Colors.grey[500])),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _loadAll,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _rotations.length,
                          itemBuilder: (_, i) => _buildRotationCard(_rotations[i]),
                        ),
                      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateDialog,
          backgroundColor: kRotationColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(isAr ? 'تناوب جديد' : 'New Rotation', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildRotationCard(Map<String, dynamic> r) {
    final slots = (r['slots'] as List? ?? []);
    final isActive = r['is_active'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kRotationColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: kRotationColor.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: kRotationColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.repeat, color: kRotationColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        '${isAr ? 'دورة كل' : 'Every'} ${r['cycle_length_days']} ${isAr ? 'يوم' : 'days'}  |  ${isAr ? 'بداية:' : 'Start:'} ${r['start_date']}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red[200]!)),
                    child: Text(isAr ? 'غير نشط' : 'Inactive', style: TextStyle(fontSize: 10, color: Colors.red[700])),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (slots.isNotEmpty) ...[
                  Text(isAr ? 'الفترات:' : 'Slots:', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...slots.map((slot) {
                    final s = slot as Map<String, dynamic>;
                    final shiftName = s['shift_name']?.toString() ?? (isAr ? 'راحة' : 'Off');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(s['shift_id'] != null ? Icons.schedule : Icons.weekend, size: 14, color: s['shift_id'] != null ? kRotationColor : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '${isAr ? 'يوم' : 'Day'} ${s['start_day_index']} → ${s['end_day_index']}: $shiftName',
                            style: TextStyle(fontSize: 12, color: s['shift_id'] != null ? Colors.black87 : Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 16),
                ],
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _showAssignDialog(r),
                      icon: const Icon(Icons.person_add, size: 16, color: kRotationColor),
                      label: Text(isAr ? 'تعيين' : 'Assign', style: const TextStyle(color: kRotationColor, fontSize: 12)),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: isAr ? 'حذف' : 'Delete',
                      onPressed: () => _deleteRotation(r),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}