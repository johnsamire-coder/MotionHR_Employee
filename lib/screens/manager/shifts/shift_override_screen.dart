import 'package:flutter/material.dart';
import '../../../services/shifts_service.dart';
import '../../../services/employee_management_service.dart';

const Color kOverrideColor = Color(0xFF382483);

class ShiftOverrideScreen extends StatefulWidget {
  const ShiftOverrideScreen({super.key});

  @override
  State<ShiftOverrideScreen> createState() => _ShiftOverrideScreenState();
}

class _ShiftOverrideScreenState extends State<ShiftOverrideScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  List<Map<String, dynamic>> _overrides = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _shifts = [];
  bool _loading = true;
  bool _showPast = false;
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
        ShiftsService.getShiftOverrides(showPast: _showPast),
        EmployeeManagementService.getEmployeesSimple(),
        ShiftsService.getShifts(),
      ]);
      setState(() {
        _overrides = List<Map<String, dynamic>>.from(results[0] as List);
        _employees = List<Map<String, dynamic>>.from(results[1] as List);
        _shifts = List<Map<String, dynamic>>.from(results[2] as List);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _deleteOverride(Map<String, dynamic> o) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'حذف الاستثناء' : 'Delete Override'),
          content: Text(
            isAr
                ? 'هل تريد حذف الاستثناء الخاص بـ "${o['employee_name']}" في ${o['override_date']}؟'
                : 'Delete override for "${o['employee_name']}" on ${o['override_date']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isAr ? 'تراجع' : 'Cancel'),
            ),
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
      await ShiftsService.deleteShiftOverride(o['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isAr ? 'تم الحذف' : 'Deleted'), backgroundColor: Colors.green),
        );
        _loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    int? selectedEmployeeId;
    int? selectedShiftId;
    DateTime selectedDate = DateTime.now();
    final reasonCtrl = TextEditingController();

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text(isAr ? 'إضافة استثناء شيفت' : 'Add Shift Override'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // اختيار الموظف
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: isAr ? 'الموظف *' : 'Employee *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person, color: kOverrideColor),
                    ),
                    items: _employees.map((e) => DropdownMenuItem<int>(
                      value: e['id'] as int,
                      child: Text(
                        '${e['full_name'] ?? ''} ${e['department'] != null && e['department'].toString().isNotEmpty ? '(${e['department']})' : ''}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedEmployeeId = v),
                  ),
                  const SizedBox(height: 12),
                  // اختيار الشيفت
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: isAr ? 'الشيفت البديل *' : 'Override Shift *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.schedule, color: kOverrideColor),
                    ),
                    items: _shifts.map((s) => DropdownMenuItem<int>(
                      value: s['id'] as int,
                      child: Text('${s['name'] ?? ''}'),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedShiftId = v),
                  ),
                  const SizedBox(height: 12),
                  // اختيار التاريخ
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isAr ? 'التاريخ *' : 'Date *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.calendar_today, color: kOverrideColor),
                      ),
                      child: Text(
                        fmt(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // تحذير لو التاريخ في الماضي
                  if (selectedDate.isBefore(DateTime.now().subtract(const Duration(days: 1))))
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAr
                                  ? '⚠️ التاريخ في الماضي — سيتم إشعار HR للموافقة'
                                  : '⚠️ Past date — HR will be notified for approval',
                              style: const TextStyle(fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  // السبب
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isAr ? 'السبب (اختياري)' : 'Reason (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.notes, color: kOverrideColor),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(isAr ? 'تراجع' : 'Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedEmployeeId == null || selectedShiftId == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        try {
                          await ShiftsService.createShiftOverride(
                            employeeId: selectedEmployeeId!,
                            shiftId: selectedShiftId!,
                            overrideDate: fmt(selectedDate),
                            reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isAr ? 'تم إضافة الاستثناء ✅' : 'Override added ✅'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _loadAll();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: kOverrideColor),
                child: Text(isAr ? 'حفظ' : 'Save', style: const TextStyle(color: Colors.white)),
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
          title: Text(
            isAr ? 'استثناءات الشيفتات' : 'Shift Overrides',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kOverrideColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadAll,
            ),
          ],
        ),
        body: Column(
          children: [
            // فلتر إظهار الماضي
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.history, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    isAr ? 'إظهار السابقة' : 'Show past',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Switch(
                    value: _showPast,
                    activeThumbColor: kOverrideColor,
                    onChanged: (v) {
                      setState(() => _showPast = v);
                      _loadAll();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // المحتوى
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kOverrideColor))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 50),
                              const SizedBox(height: 12),
                              Text(_error!, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _loadAll,
                                icon: const Icon(Icons.refresh),
                                label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kOverrideColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _overrides.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.swap_horiz, size: 80, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    isAr ? 'لا توجد استثناءات' : 'No overrides found',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isAr ? 'اضغط + لإضافة استثناء جديد' : 'Tap + to add a new override',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAll,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _overrides.length,
                                itemBuilder: (_, i) => _buildOverrideCard(_overrides[i]),
                              ),
                            ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateDialog,
          backgroundColor: kOverrideColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(isAr ? 'استثناء جديد' : 'New Override', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildOverrideCard(Map<String, dynamic> o) {
    final isPast = o['is_past'] == true;
    final dept = (o['department'] ?? '').toString();
    final branch = (o['branch'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.grey.withValues(alpha: 0.1)
                    : kOverrideColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.swap_horiz,
                color: isPast ? Colors.grey : kOverrideColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // التفاصيل
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // اسم الموظف
                  Text(
                    (o['employee_name'] ?? '').toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isPast ? Colors.grey[600] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // القسم والفرع
                  if (dept.isNotEmpty || branch.isNotEmpty)
                    Text(
                      [
                        if (dept.isNotEmpty) dept,
                        if (branch.isNotEmpty) branch,
                      ].join(' | '),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  const SizedBox(height: 4),
                  // الشيفت البديل
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: kOverrideColor),
                      const SizedBox(width: 4),
                      Text(
                        (o['shift_name'] ?? '').toString(),
                        style: const TextStyle(
                          color: kOverrideColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // التاريخ
                  Row(
                    children: [
                      Icon(
                        isPast ? Icons.history : Icons.calendar_today,
                        size: 13,
                        color: isPast ? Colors.grey : Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (o['override_date'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isPast ? Colors.grey : Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isPast) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAr ? 'انتهى' : 'Past',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  // السبب
                  if ((o['reason'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      (o['reason'] ?? '').toString(),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // زرار الحذف
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              tooltip: isAr ? 'حذف' : 'Delete',
              onPressed: () => _deleteOverride(o),
            ),
          ],
        ),
      ),
    );
  }
}