import 'package:flutter/material.dart';
import '../../../services/shifts_service.dart';
import 'create_edit_shift_screen.dart';
import 'assign_shift_screen.dart';

const Color kManagerColor = Color(0xFF6A1B9A);

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});
  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  List<Map<String, dynamic>> _shifts = [];
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
      final lang = isAr ? 'ar' : 'en';
      final shifts = await ShiftsService.getShifts(lang: lang);
      setState(() { _shifts = shifts; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _deleteShift(Map<String, dynamic> shift) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'حذف الشيفت' : 'Delete Shift'),
        content: Text(isAr
            ? 'هل تريد حذف شيفت "${shift['name']}"'
            : 'Delete shift "${shift['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAr ? 'حذف' : 'Delete',
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final msg = await ShiftsService.deleteShift(shift['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.green));
        _load();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Color _shiftColor(String? type) {
    switch (type) {
      case 'morning': return Colors.orange;
      case 'evening': return Colors.blue;
      case 'night': return Colors.indigo;
      case 'flexible': return Colors.green;
      case 'split': return Colors.purple;
      default: return kManagerColor;
    }
  }

  IconData _shiftIcon(String? type) {
    switch (type) {
      case 'morning': return Icons.wb_sunny;
      case 'evening': return Icons.wb_twilight;
      case 'night': return Icons.nights_stay;
      case 'flexible': return Icons.schedule;
      case 'split': return Icons.splitscreen;
      default: return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'إدارة الشيفتات' : 'Shift Management'),
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _load,
              tooltip: isAr ? 'تحديث' : 'Refresh',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CreateEditShiftScreen()));
            if (result == true) _load();
          },
          backgroundColor: kManagerColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(isAr ? 'شيفت جديد' : 'New Shift',
              style: const TextStyle(color: Colors.white)),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 50),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                    ),
                  ]))
                : _shifts.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.schedule, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          isAr ? 'لا توجد شيفتات بعد' : 'No shifts yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAr ? 'اضغط + لإنشاء شيفت جديد' : 'Tap + to create a new shift',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _shifts.length,
                          itemBuilder: (ctx, i) {
                            final shift = _shifts[i];
                            final color = _shiftColor(shift['shift_type']);
                            final icon = _shiftIcon(shift['shift_type']);
                            final isActive = shift['is_active'] == true;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              child: Column(children: [
                                // Header
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(14)),
                                    border: Border(
                                      bottom: BorderSide(color: color.withOpacity(0.2)),
                                    ),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(icon, color: color, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                      Row(children: [
                                        Expanded(child: Text(shift['name'] ?? '',
                                            style: const TextStyle(
                                                fontSize: 16, fontWeight: FontWeight.bold))),
                                        if (!isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.red[200]!),
                                            ),
                                            child: Text(
                                              isAr ? 'غير نشط' : 'Inactive',
                                              style: TextStyle(
                                                  fontSize: 10, color: Colors.red[700]),
                                            ),
                                          ),
                                      ]),
                                      const SizedBox(height: 4),
                                      Text(shift['shift_type_label'] ?? '',
                                          style: TextStyle(color: color, fontSize: 13)),
                                    ])),
                                  ]),
                                ),
                                // Details
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(children: [
                                    Row(children: [
                                      _infoChip(Icons.login,
                                          '${isAr ? 'بداية' : 'Start'}: ${shift['start_time'] ?? '-'}',
                                          Colors.green),
                                      const SizedBox(width: 8),
                                      _infoChip(Icons.logout,
                                          '${isAr ? 'نهاية' : 'End'}: ${shift['end_time'] ?? '-'}',
                                          Colors.red),
                                      const SizedBox(width: 8),
                                      _infoChip(Icons.timer,
                                          '${shift['grace_period'] ?? 0} ${isAr ? 'د' : 'min'}',
                                          Colors.orange),
                                    ]),
                                    const SizedBox(height: 10),
                                    // Work days
                                    if ((shift['work_days'] as List?)?.isNotEmpty == true)
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: (shift['work_days'] as List)
                                            .map((d) => Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(
                                                        color: color.withOpacity(0.3)),
                                                  ),
                                                  child: Text(d.toString(),
                                                      style: TextStyle(
                                                          fontSize: 11, color: color)),
                                                ))
                                            .toList(),
                                      ),
                                    const SizedBox(height: 12),
                                    // Stats + Actions
                                    Row(children: [
                                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${shift['employee_count'] ?? 0} ${isAr ? 'موظف' : 'employees'}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                      const Spacer(),
                                      // Assign button
                                      TextButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => AssignShiftScreen(shift: shift),
                                            ),
                                          );
                                          if (result == true) _load();
                                        },
                                        icon: Icon(Icons.person_add, size: 16, color: color),
                                        label: Text(isAr ? 'تعيين' : 'Assign',
                                            style: TextStyle(color: color, fontSize: 12)),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                      // Edit button
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue[600], size: 20),
                                        tooltip: isAr ? 'تعديل' : 'Edit',
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CreateEditShiftScreen(existingShift: shift),
                                            ),
                                          );
                                          if (result == true) _load();
                                        },
                                      ),
                                      // Delete button
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            color: Colors.red, size: 20),
                                        tooltip: isAr ? 'حذف' : 'Delete',
                                        onPressed: () => _deleteShift(shift),
                                      ),
                                    ]),
                                  ]),
                                ),
                              ]),
                            );
                          },
                        ),
                      ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ]),
      );
}
