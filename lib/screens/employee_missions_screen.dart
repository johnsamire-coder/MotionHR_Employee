import 'package:flutter/material.dart';
import '../services/missions_service.dart';
import 'employee_mission_detail_screen.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class EmployeeMissionsScreen extends StatefulWidget {
  const EmployeeMissionsScreen({super.key});

  @override
  State<EmployeeMissionsScreen> createState() => _EmployeeMissionsScreenState();
}

class _EmployeeMissionsScreenState extends State<EmployeeMissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _missions = [];
  String? _error;

  final Map<String, Color> _statusColors = {
    'pending': Colors.grey,
    'accepted': Colors.blue,
    'in_progress': Colors.orange,
    'completed': Colors.green,
    'rejected': Colors.red,
  };

  final Map<String, Color> _priorityColors = {
    'urgent': Colors.red,
    'high': Colors.orange,
    'normal': Colors.blue,
  };

  final List<Map<String, String>> _filters = [
    {'key': 'all', 'label': 'الكل'},
    {'key': 'active', 'label': 'جارية'},
    {'key': 'today', 'label': 'اليوم'},
    {'key': 'upcoming', 'label': 'القادمة'},
    {'key': 'completed', 'label': 'المكتملة'},
  ];

  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMissions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await MissionsService.getMyMissions(filter: _currentFilter);
      setState(() {
        _missions = result['missions'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل المهمات';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text(
            'مهماتي',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF6C3FC5),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadMissions,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: context.l10n.myMissions, icon: Icon(Icons.assignment)),
              Tab(text: 'طلب مهمة', icon: Icon(Icons.add_task)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMissionsTab(),
            _buildRequestTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionsTab() {
    return Column(
      children: [
        // فلتر
        Container(
          height: 50,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: _filters.map((f) {
              final isSelected = _currentFilter == f['key'];
              return GestureDetector(
                onTap: () {
                  setState(() => _currentFilter = f['key']!);
                  _loadMissions();
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6C3FC5) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    f['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF6C3FC5)))
              : _error != null
                  ? _buildError()
                  : _missions.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadMissions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _missions.length,
                            itemBuilder: (ctx, i) => _buildMissionCard(_missions[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> m) {
    final status = m['status'] ?? '';
    final priority = m['priority'] ?? 'normal';
    final statusColor = _statusColors[status] ?? Colors.grey;
    final priorityColor = _priorityColors[priority] ?? Colors.blue;
    final isActive = status == 'in_progress';
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? const BorderSide(color: Colors.orange, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmployeeMissionDetailScreen(
                assignmentId: m['assignment_id'],
                missionId: m['mission_id'],
              ),
            ),
          );
          if (result == true) _loadMissions();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // العنوان + الحالة
              Row(
                children: [
                  if (isActive)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      m['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      m['status_display'] ?? status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // الموقع
              if ((m['location_name'] ?? '').isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 13, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        m['location_name'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // العميل
              if ((m['client_name'] ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 13, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(m['client_name'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),

              SizedBox(height: 8),
              Divider(height: 1),
              SizedBox(height: 8),

              // الوقت + الأولوية
              Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDateTime(m['planned_start_time']),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      m['priority_display'] ?? priority,
                      style: TextStyle(fontSize: 10, color: priorityColor),
                    ),
                  ),
                ],
              ),

              // أزرار سريعة للمهمة المعلقة
              if (isPending) ...[
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _quickRespond(m['assignment_id'], 'accept'),
                        icon: Icon(Icons.check, size: 16, color: Colors.green),
                        label: Text(context.l10n.acceptMission, style: TextStyle(color: Colors.green, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _quickRespond(m['assignment_id'], 'reject'),
                        icon: Icon(Icons.close, size: 16, color: Colors.red),
                        label: Text(context.l10n.rejectMission, style: TextStyle(color: Colors.red, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestTab() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final clientNameCtrl = TextEditingController();
    final clientPhoneCtrl = TextEditingController();
    DateTime? startTime;
    DateTime? endTime;
    String priority = 'normal';

    return StatefulBuilder(
      builder: (ctx, setTabState) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Color(0xFFF3E5F5),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF6C3FC5)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'لو رتبت مع عميل مباشرة، ابعت الطلب هنا للمدير للموافقة',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6C3FC5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: titleCtrl,
            decoration: InputDecoration(
              labelText: 'عنوان المهمة *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: descCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.requestDetails,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: locationCtrl,
            decoration: InputDecoration(
              labelText: 'الموقع / العنوان',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: clientNameCtrl,
            decoration: InputDecoration(
              labelText: context.l10n.clientName,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          SizedBox(height: 12),
          TextField(
            controller: clientPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: context.l10n.clientPhone,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          SizedBox(height: 12),
          // وقت البدء
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d == null) return;
              final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
              if (t == null) return;
              setTabState(() => startTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle, color: Color(0xFF6C3FC5)),
                  SizedBox(width: 10),
                  Text(
                    startTime == null ? 'وقت البدء *' : _formatDateTime(startTime!.toIso8601String()),
                    style: TextStyle(color: startTime == null ? Colors.grey : Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          // وقت الانتهاء
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: ctx,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d == null) return;
              final t = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
              if (t == null) return;
              setTabState(() => endTime = DateTime(d.year, d.month, d.day, t.hour, t.minute));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.stop_circle, color: Color(0xFF6C3FC5)),
                  SizedBox(width: 10),
                  Text(
                    endTime == null ? 'وقت الانتهاء *' : _formatDateTime(endTime!.toIso8601String()),
                    style: TextStyle(color: endTime == null ? Colors.grey : Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || startTime == null || endTime == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('يرجى تعبئة الحقول المطلوبة')),
                );
                return;
              }
              final result = await MissionsService.requestMission(
                title: titleCtrl.text.trim(),
                description: descCtrl.text.trim(),
                priority: priority,
                plannedStartTime: startTime!.toIso8601String(),
                plannedEndTime: endTime!.toIso8601String(),
                locationName: locationCtrl.text.trim(),
                clientName: clientNameCtrl.text.trim(),
                clientPhone: clientPhoneCtrl.text.trim(),
              );
              if (!mounted) return;
              if (result['success'] == true) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('✅ تم إرسال الطلب للمدير'),
                    backgroundColor: Colors.green,
                  ),
                );
                titleCtrl.clear();
                descCtrl.clear();
                locationCtrl.clear();
                clientNameCtrl.clear();
                clientPhoneCtrl.clear();
                setTabState(() {
                  startTime = null;
                  endTime = null;
                });
                _tabController.animateTo(0);
                _loadMissions();
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(result['error'] ?? 'حدث خطأ')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3FC5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'إرسال الطلب للمدير',
              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _quickRespond(int assignmentId, String action) async {
    String reason = '';
    if (action == 'reject') {
      final ctrl = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('سبب الرفض'),
            content: TextField(
              controller: ctrl,
              decoration: InputDecoration(hintText: 'اكتب السبب...'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(context.l10n.confirm)),
            ],
          ),
        ),
      );
      if (confirmed != true) return;
      reason = ctrl.text;
    }

    final result = await MissionsService.respondToMission(assignmentId, action, reason: reason);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? (action == 'accept' ? 'تم القبول' : 'تم الرفض')),
        backgroundColor: action == 'accept' ? Colors.green : Colors.red,
      ),
    );
    _loadMissions();
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 12),
          Text(_error ?? context.l10n.error),
          SizedBox(height: 12),
          ElevatedButton(onPressed: _loadMissions, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(context.l10n.noMissions, style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          const Text('اضغط على تبويب "طلب مهمة" لإضافة مهمة جديدة',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  String _formatDateTime(String? dt) {
    if (dt == null) return '';
    try {
      final d = DateTime.parse(dt).toLocal();
      return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dt;
    }
  }
}