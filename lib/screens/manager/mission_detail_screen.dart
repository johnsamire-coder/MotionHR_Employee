import 'package:flutter/material.dart';
import '../../services/missions_service.dart';
import '../../services/employee_management_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class MissionDetailScreen extends StatefulWidget {
  final int missionId;
  final bool isManager;

  const MissionDetailScreen({
    super.key,
    required this.missionId,
    this.isManager = false,
  });

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  bool _loading = true;
  Map<String, dynamic>? _mission;
  String? _error;

  final Map<String, Color> _statusColors = {
    'approved': Colors.blue,
    'in_progress': Colors.orange,
    'completed': Colors.green,
    'cancelled': Colors.red,
    'pending_approval': Colors.purple,
    'draft': Colors.grey,
  };

  final Map<String, Color> _priorityColors = {
    'urgent': Colors.red,
    'high': Colors.orange,
    'normal': Colors.blue,
  };

  @override
  void initState() {
    super.initState();
    _loadMission();
  }

  Future<void> _loadMission() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await MissionsService.getMissionDetail(widget.missionId);
      setState(() {
        _mission = result['mission'];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل المهمة';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            _mission?['title'] ?? context.l10n.missionDetails,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF6C3FC5),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadMission,
            ),
            if (widget.isManager && _mission != null)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) => _handleManagerAction(value),
                itemBuilder: (_) => [
                  if (_mission!['status'] != 'completed' &&
                      _mission!['status'] != 'cancelled')
                    PopupMenuItem(
                      value: 'force_cancel',
                      child: Row(children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text(context.l10n.cancelMission),
                      ]),
                    ),
                ],
              ),
          ],
        ),
        body: _loading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF6C3FC5)))
            : _error != null
                ? _buildError()
                : _mission == null
                    ? Center(child: Text('المهمة غير موجودة'))
                    : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final mission = _mission!;
    final status = mission['status'] ?? '';
    final priority = mission['priority'] ?? 'normal';
    final statusColor = _statusColors[status] ?? Colors.grey;
    final priorityColor = _priorityColors[priority] ?? Colors.blue;
    final assignments = mission['assignments'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _loadMission,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // هيدر المهمة
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [const Color(0xFF6C3FC5), const Color(0xFF9B6FE8)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mission['title'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          mission['status_display'] ?? status,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if ((mission['description'] ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        mission['description'],
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white54),
                        ),
                        child: Text(
                          mission['priority_display'] ?? priority,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12),

          // التوقيت والموقع
          _infoCard(
            title: 'التوقيت والموقع',
            icon: Icons.schedule,
            children: [
              _infoRow(Icons.play_circle, 'البدء المخطط', _formatDateTime(mission['planned_start_time'])),
              _infoRow(Icons.stop_circle, 'الانتهاء المخطط', _formatDateTime(mission['planned_end_time'])),
              if ((mission['location_name'] ?? '').isNotEmpty)
                _infoRow(Icons.location_on, 'الموقع', mission['location_name']),
            ],
          ),

          // العميل
          if ((mission['client_name'] ?? '').isNotEmpty ||
              mission['client_info'] != null) ...[
            SizedBox(height: 12),
            _infoCard(
              title: 'بيانات العميل',
              icon: Icons.person,
              children: [
                if ((mission['client_name'] ?? '').isNotEmpty)
                  _infoRow(Icons.person, 'الاسم', mission['client_name']),
                if ((mission['client_phone'] ?? '').isNotEmpty)
                  _infoRow(Icons.phone, 'التليفون', mission['client_phone']),
                if (mission['client_info'] != null) ...[
                  if ((mission['client_info']['company_name'] ?? '').isNotEmpty)
                    _infoRow(Icons.business, context.l10n.company, mission['client_info']['company_name']),
                  if ((mission['client_info']['email'] ?? '').isNotEmpty)
                    _infoRow(Icons.email, 'الإيميل', mission['client_info']['email']),
                ],
              ],
            ),
          ],

          // المشاركون
          if (assignments.isNotEmpty) ...[
            SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.group, color: Color(0xFF6C3FC5)),
                        SizedBox(width: 8),
                        Text(
                          'المشاركون (${assignments.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF6C3FC5),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 16),
                    ...assignments.map((a) => _assigneeRow(a)),
                  ],
                ),
              ),
            ),
          ],

          // أزرار المدير
          if (widget.isManager && _mission!['status'] != 'cancelled' &&
              _mission!['status'] != 'completed') ...[
            SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings, color: Color(0xFF6C3FC5)),
                        SizedBox(width: 8),
                        Text(
                          'إجراءات المدير',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF6C3FC5),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showReassignDialog,
                        icon: Icon(Icons.swap_horiz),
                        label: Text('استبدال موظف'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6C3FC5),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _handleManagerAction('force_cancel'),
                        icon: Icon(Icons.cancel, color: Colors.red),
                        label: Text(context.l10n.cancelMission, style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // الفيدباك
          if (mission['has_feedback'] == true) ...[
            SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.feedback, color: Color(0xFF6C3FC5)),
                title: Text('فيدباك الزيارة متاح'),
                subtitle: Text('اضغط لعرض التفاصيل'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showFeedbackDetail(),
              ),
            ),
          ],

          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF6C3FC5), size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF6C3FC5),
                  ),
                ),
              ],
            ),
            Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _assigneeRow(Map<String, dynamic> a) {
    final isLead = a['is_lead'] == true;
    final status = a['status'] ?? '';
    final statusColors = {
      'pending': Colors.grey,
      'accepted': Colors.blue,
      'in_progress': Colors.orange,
      'completed': Colors.green,
      'rejected': Colors.red,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF6C3FC5).withOpacity(0.15),
            child: Text(
              (a['employee_name'] ?? '?')[0],
              style: const TextStyle(color: Color(0xFF6C3FC5), fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      a['employee_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (isLead)
                      Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.star, color: Colors.amber, size: 14),
                      ),
                  ],
                ),
                Text(
                  a['role_display'] ?? '',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (statusColors[status] ?? Colors.grey).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              a['status_display'] ?? status,
              style: TextStyle(
                fontSize: 10,
                color: statusColors[status] ?? Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
          ElevatedButton(
            onPressed: _loadMission,
            child: Text(context.l10n.retry),
          ),
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

  void _handleManagerAction(String action) async {
    if (action == 'force_cancel') {
      final reasonCtrl = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(context.l10n.cancelMission),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('هل أنت متأكد من إلغاء هذه المهمة؟'),
                SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: InputDecoration(
                    labelText: 'سبب الإلغاء *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('تراجع'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text(context.l10n.cancelMission, style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );

      if (confirm == true && reasonCtrl.text.isNotEmpty) {
        final result = await MissionsService.forceCancelMission(
          widget.missionId,
          reasonCtrl.text,
        );
        if (!mounted) return;
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إلغاء المهمة'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    }
  }
void _showReassignDialog() async {
  final assignments = _mission!['assignments'] as List? ?? [];
  if (assignments.isEmpty) return;

  String? oldEmpId;
  String? newEmpId;
  String? newEmpName;
  String reason = '';

  // جيب قائمة الموظفين
  List<dynamic> allEmployees = [];
  try {
    final result = await EmployeeManagementService.getEmployeesSimple();
    allEmployees = result;
  } catch (_) {}

  if (!mounted) return;

  await showDialog(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('استبدال موظف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // الموظف الحالي
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'الموظف الحالي',
                    border: OutlineInputBorder(),
                  ),
                  items: assignments.map<DropdownMenuItem<String>>((a) {
                    return DropdownMenuItem<String>(
                      value: a['employee_id'].toString(),
                      child: Text(a['employee_name'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => oldEmpId = v),
                ),
                SizedBox(height: 12),
                // الموظف الجديد
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'الموظف الجديد',
                    border: OutlineInputBorder(),
                  ),
                  items: allEmployees.map<DropdownMenuItem<String>>((e) {
                    final alreadyAssigned = assignments.any(
                      (a) => a['employee_id'].toString() == e['id'].toString(),
                    );
                    return DropdownMenuItem<String>(
                      value: e['id'].toString(),
                      enabled: !alreadyAssigned,
                      child: Text(
                        '${e['full_name_ar'] ?? e['username'] ?? ''}${alreadyAssigned ? ' (مُعيَّن)' : ''}',
                        style: TextStyle(
                          color: alreadyAssigned ? Colors.grey : Colors.black,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setDialogState(() {
                      newEmpId = v;
                      newEmpName = allEmployees.firstWhere(
                        (e) => e['id'].toString() == v,
                        orElse: () => {},
                      )['full_name_ar'];
                    });
                  },
                ),
                SizedBox(height: 12),
                // السبب
                TextField(
                  decoration: InputDecoration(
                    labelText: 'سبب الاستبدال',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => reason = v,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: oldEmpId == null || newEmpId == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final result = await MissionsService.reassignEmployee(
                        widget.missionId,
                        oldEmployeeId: int.parse(oldEmpId!),
                        newEmployeeId: int.parse(newEmpId!),
                        reason: reason,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['success'] == true
                                ? '✅ تم استبدال الموظف بـ $newEmpName'
                                : result['error'] ?? isAr ? 'حدث خطأ' : 'An error occurred',
                          ),
                          backgroundColor: result['success'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
                      if (result['success'] == true) _loadMission();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3FC5),
              ),
              child: Text('تأكيد الاستبدال',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ),
  );
}


  void _showFeedbackDetail() async {
    final result = await MissionsService.getFeedbackDetail(widget.missionId);
    final feedback = result['feedback'];
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                isAr ? 'فيدباك الزيارة' : 'Visit Feedback',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              if (feedback != null) ...[
                _feedbackRow('حالة العميل', feedback['client_status_display'] ?? ''),
                _feedbackRow('تقييم الاهتمام', '${feedback['interest_rating']}/5'),
                _feedbackRow('احتمال الصفقة', '${feedback['deal_probability']}/5'),
                _feedbackRow('احتياجات العميل', feedback['client_needs'] ?? ''),
                _feedbackRow(context.l10n.contractSigned, feedback['contract_signed'] == true ? 'نعم ✅' : context.l10n.no),
                if (feedback['deal_value'] != null)
                  _feedbackRow('قيمة الصفقة', feedback['deal_value']),
                _feedbackRow('يحتاج متابعة', feedback['needs_followup'] == true ? context.l10n.yes : context.l10n.no),
                if (feedback['followup_date'] != null)
                  _feedbackRow(context.l10n.followupDate, feedback['followup_date']),
                if ((feedback['internal_notes'] ?? '').isNotEmpty)
                  _feedbackRow(context.l10n.internalNotes, feedback['internal_notes']),
                if ((feedback['warnings'] ?? '').isNotEmpty)
                  _feedbackRow('تحذيرات', feedback['warnings']),
              ] else
                Center(child: Text('لا يوجد فيدباك')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feedbackRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Divider(),
        ],
      ),
    );
  }
}