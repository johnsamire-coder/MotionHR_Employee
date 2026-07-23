import 'package:flutter/material.dart';
import '../../../services/shifts_service.dart';
import 'create_edit_shift_screen.dart';
import 'assign_shift_screen.dart';

const Color kShiftColor = Color(0xFF6A1B9A);

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen>
    with SingleTickerProviderStateMixin {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  late TabController _tabController;
  List<Map<String, dynamic>> _shifts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lang = isAr ? 'ar' : 'en';
      final shifts = await ShiftsService.getShifts(lang: lang);
      setState(() {
        _shifts = shifts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _deleteShift(Map<String, dynamic> shift) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'حذف الشيفت' : 'Delete Shift'),
          content: Text(
            isAr
                ? 'هل تريد حذف شيفت "${shift['name']}"؟'
                : 'Delete shift "${shift['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'تراجع' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                isAr ? 'حذف' : 'Delete',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final msg = await ShiftsService.deleteShift(shift['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _shiftColor(String? type) {
    switch (type) {
      case 'morning': return Colors.orange;
      case 'evening': return Colors.blue;
      case 'night': return Colors.indigo;
      case 'flexible': return Colors.green;
      case 'rotating': return Colors.teal;
      case 'split': return Colors.purple;
      default: return kShiftColor;
    }
  }

  IconData _shiftIcon(String? type) {
    switch (type) {
      case 'morning': return Icons.wb_sunny;
      case 'evening': return Icons.wb_twilight;
      case 'night': return Icons.nights_stay;
      case 'flexible': return Icons.schedule;
      case 'rotating': return Icons.repeat;
      case 'split': return Icons.splitscreen;
      default: return Icons.access_time;
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
            isAr ? 'إدارة الشيفتات' : 'Shift Management',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kShiftColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load,
            ),
            IconButton(
              icon: const Icon(Icons.pending_actions, color: Colors.white),
              tooltip: isAr ? 'طلبات التغيير' : 'Change Requests',
              onPressed: _showChangeRequests,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                text: isAr ? 'الشيفتات' : 'Shifts',
                icon: const Icon(Icons.schedule),
              ),
              Tab(
                text: isAr ? 'شيفتي' : 'My Shift',
                icon: const Icon(Icons.person),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildShiftsTab(),
            _buildMyShiftTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateEditShiftScreen(),
              ),
            );
            if (result == true) _load();
          },
          backgroundColor: kShiftColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            isAr ? 'شيفت جديد' : 'New Shift',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildShiftsTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kShiftColor));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kShiftColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    if (_shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _shifts.length,
        itemBuilder: (_, i) => _buildShiftCard(_shifts[i]),
      ),
    );
  }

  Widget _buildShiftCard(Map<String, dynamic> shift) {
    final color = _shiftColor(shift['shift_type']?.toString());
    final icon = _shiftIcon(shift['shift_type']?.toString());
    final isActive = shift['is_active'] == true;
    final isDefault = shift['is_default'] == true;
    final crossesMidnight = shift['crosses_midnight'] == true;
    final workDays = shift['work_days'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              (shift['name'] ?? '').toString(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber[300]!),
                              ),
                              child: Text(
                                isAr ? '⭐ افتراضي' : '⭐ Default',
                                style: TextStyle(fontSize: 10, color: Colors.amber[700]),
                              ),
                            ),
                          if (!isActive) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red[200]!),
                              ),
                              child: Text(
                                isAr ? 'غير نشط' : 'Inactive',
                                style: TextStyle(fontSize: 10, color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (shift['shift_type_label'] ?? '').toString(),
                        style: TextStyle(color: color, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // الأوقات
                Row(
                  children: [
                    _infoChip(
                      Icons.login,
                      '${isAr ? 'بداية' : 'Start'}: ${shift['start_time'] ?? '-'}',
                      Colors.green,
                    ),
                    const SizedBox(width: 6),
                    _infoChip(
                      Icons.logout,
                      '${isAr ? 'نهاية' : 'End'}: ${shift['end_time'] ?? '-'}',
                      Colors.red,
                    ),
                    if (crossesMidnight) ...[
                      const SizedBox(width: 6),
                      _infoChip(Icons.nights_stay, isAr ? 'ليلي' : 'Night', Colors.indigo),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _infoChip(
                      Icons.timer,
                      '${isAr ? 'سماح' : 'Grace'}: ${shift['grace_period'] ?? 0} ${isAr ? 'د' : 'min'}',
                      Colors.orange,
                    ),
                    const SizedBox(width: 6),
                    _infoChip(
                      Icons.hourglass_empty,
                      '${isAr ? 'ساعات' : 'Hours'}: ${shift['work_hours'] ?? 0}',
                      Colors.blue,
                    ),
                  ],
                ),
                if (workDays.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: workDays
                        .map((d) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: color.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                d.toString(),
                                style: TextStyle(fontSize: 11, color: color),
                              ),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Buttons
                Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${shift['employee_count'] ?? 0} ${isAr ? 'موظف' : 'employees'}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const Spacer(),
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
                      label: Text(
                        isAr ? 'تعيين' : 'Assign',
                        style: TextStyle(color: color, fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue[600], size: 20),
                      tooltip: isAr ? 'تعديل' : 'Edit',
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateEditShiftScreen(existingShift: shift),
                          ),
                        );
                        if (result == true) _load();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      tooltip: isAr ? 'حذف' : 'Delete',
                      onPressed: () => _deleteShift(shift),
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

  Widget _buildMyShiftTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ShiftsService.getMyShift(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kShiftColor));
        }
        if (snap.hasError) {
          return Center(child: Text(snap.error.toString()));
        }
        final data = snap.data ?? {};
        if (data['has_shift'] != true) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  isAr ? 'لا يوجد شيفت محدد لك' : 'No shift assigned to you',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final todayShift = data['today_shift'] as Map<String, dynamic>? ?? {};
        final schedule = data['schedule'] as List? ?? [];

        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // شيفت اليوم
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [kShiftColor, kShiftColor.withValues(alpha: 0.7)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'شيفت اليوم' : 'Today\'s Shift',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (todayShift['name'] ?? '').toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.login, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          (todayShift['start_time'] ?? '').toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.logout, color: Colors.white70, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          (todayShift['end_time'] ?? '').toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        if (todayShift['crosses_midnight'] == true) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.nights_stay, color: Colors.white70, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${isAr ? 'ساعات العمل' : 'Work hours'}: ${todayShift['work_hours'] ?? 0} ${isAr ? 'ساعة' : 'hrs'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // جدول الأسبوعين
            Text(
              isAr ? 'الجدول الأسبوعي القادم' : 'Upcoming Schedule',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...schedule.map((day) {
              final dayMap = day as Map<String, dynamic>;
              final isWorkDay = dayMap['is_work_day'] == true;
              final hasShift = dayMap['shift_name'] != null;
              final isToday = dayMap['date'] == DateTime.now().toIso8601String().substring(0, 10);

              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                color: isToday ? kShiftColor.withValues(alpha: 0.08) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: isToday
                      ? BorderSide(color: kShiftColor.withValues(alpha: 0.3))
                      : BorderSide.none,
                ),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isWorkDay
                          ? kShiftColor.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isWorkDay ? Icons.work : Icons.weekend,
                      color: isWorkDay ? kShiftColor : Colors.grey,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    dayMap['date']?.toString() ?? '',
                    style: TextStyle(
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    hasShift && isWorkDay
                        ? '${dayMap['shift_name']} | ${dayMap['start_time']} - ${dayMap['end_time']}'
                        : (isAr ? 'راحة' : 'Day off'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isWorkDay ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  trailing: isToday
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kShiftColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isAr ? 'اليوم' : 'Today',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )
                      : null,
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showChangeRequests() async {
    final requests = await ShiftsService.getShiftChangeRequests(status: 'pending');
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, ctrl) => Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isAr ? 'طلبات تغيير الشيفت المعلقة' : 'Pending Shift Change Requests',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: requests.isEmpty
                    ? Center(
                        child: Text(
                          isAr ? 'لا توجد طلبات معلقة' : 'No pending requests',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: ctrl,
                        itemCount: requests.length,
                        itemBuilder: (_, i) {
                          final req = requests[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: kShiftColor.withValues(alpha: 0.1),
                                child: const Icon(Icons.person, color: kShiftColor),
                              ),
                              title: Text(
                                (req['employee_name'] ?? '').toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${req['old_shift'] ?? '-'} → ${req['new_shift'] ?? ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () async {
                                      await ShiftsService.handleShiftChangeRequest(
                                        requestId: req['id'],
                                        action: 'approve',
                                      );
                                      if (mounted) Navigator.pop(context);
                                      _load();
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel, color: Colors.red),
                                    onPressed: () async {
                                      await ShiftsService.handleShiftChangeRequest(
                                        requestId: req['id'],
                                        action: 'reject',
                                      );
                                      if (mounted) Navigator.pop(context);
                                      _load();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
