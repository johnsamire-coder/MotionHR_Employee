import 'package:flutter/material.dart';
import '../services/missions_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class EmployeeMissionDetailScreen extends StatefulWidget {
  final int assignmentId;
  final int missionId;

  const EmployeeMissionDetailScreen({
    super.key,
    required this.assignmentId,
    required this.missionId,
  });

  @override
  State<EmployeeMissionDetailScreen> createState() =>
      _EmployeeMissionDetailScreenState();
}

class _EmployeeMissionDetailScreenState
    extends State<EmployeeMissionDetailScreen> {
  bool _loading = true;
  Map<String, dynamic>? _mission;
  Map<String, dynamic>? _myAssignment;
  String? _error;
  bool _actionLoading = false;

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
      final result = await MissionsService.getMyMissions();
      final missions = result['missions'] as List? ?? [];
      final found = missions.firstWhere(
        (m) => m['assignment_id'] == widget.assignmentId,
        orElse: () => null,
      );
      setState(() {
        _mission = found;
        _myAssignment = found;
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            _mission?['title'] ?? context.l10n.missionDetails,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF6C3FC5),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadMission,
            ),
          ],
        ),
        body: _loading
            ? Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF6C3FC5)))
            : _error != null
                ? _buildError()
                : _mission == null
                    ? Center(child: Text('المهمة غير موجودة'))
                    : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final m = _mission!;
    final status = m['status'] ?? '';
    final isPending = status == 'pending';
    final isAccepted = status == 'accepted';
    final isActive = status == 'in_progress';
    final isCompleted = status == 'completed';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // هيدر المهمة
        _headerCard(m),

        SizedBox(height: 12),

        // التوقيت
        _infoCard(
          title: 'التوقيت والموقع',
          icon: Icons.schedule,
          children: [
            _infoRow(Icons.play_circle, 'البدء المخطط',
                _formatDateTime(m['planned_start_time'])),
            _infoRow(Icons.stop_circle, 'الانتهاء المخطط',
                _formatDateTime(m['planned_end_time'])),
            if (m['started_at'] != null)
              _infoRow(Icons.play_arrow, 'بدأت فعلياً',
                  _formatDateTime(m['started_at'])),
            if (m['ended_at'] != null)
              _infoRow(Icons.stop, 'انتهت فعلياً',
                  _formatDateTime(m['ended_at'])),
            if ((m['location_name'] ?? '').isNotEmpty)
              _infoRow(Icons.location_on, 'الموقع', m['location_name']),
          ],
        ),

        // العميل
        if ((m['client_name'] ?? '').isNotEmpty) ...[
          SizedBox(height: 12),
          _infoCard(
            title: 'بيانات العميل',
            icon: Icons.person,
            children: [
              _infoRow(Icons.person, 'الاسم', m['client_name']),
              if ((m['client_phone'] ?? '').isNotEmpty)
                _infoRow(Icons.phone, 'التليفون', m['client_phone']),
            ],
          ),
        ],

        SizedBox(height: 12),

        // أزرار الإجراءات
        if (isPending) _buildPendingActions(),
        if (isAccepted) _buildAcceptedActions(m),
        if (isActive) _buildActiveActions(m),
        if (isCompleted && m['is_lead'] == true && m['has_feedback'] != true)
          _buildFeedbackPrompt(),

        // طلب الانسحاب
        if (isPending || isAccepted) ...[
          SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showWithdrawDialog,
              icon: Icon(Icons.exit_to_app, color: Colors.orange),
              label: Text('طلب الانسحاب',
                  style: TextStyle(color: Colors.orange)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],

        SizedBox(height: 24),
      ],
    );
  }

  Widget _headerCard(Map<String, dynamic> m) {
    final Map<String, Color> statusColors = {
      'pending': Colors.grey,
      'accepted': Colors.blue,
      'in_progress': Colors.orange,
      'completed': Colors.green,
      'rejected': Colors.red,
    };
    final Map<String, Color> priorityColors = {
      'urgent': Colors.red,
      'high': Colors.orange,
      'normal': Colors.blue,
    };

    final statusColor = statusColors[m['status']] ?? Colors.grey;
    final priorityColor = priorityColors[m['priority']] ?? Colors.blue;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C3FC5), Color(0xFF9B6FE8)],
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
                    m['title'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: Text(
                    m['status_display'] ?? m['status'] ?? '',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            if ((m['description'] ?? '').isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                m['description'],
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: Text(
                    m['priority_display'] ?? m['priority'] ?? '',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
                if (m['is_lead'] == true) ...[
                  SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(context.l10n.missionLead,
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('الرد على المهمة',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C3FC5))),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _actionLoading
                        ? null
                        : () => _respond('accept'),
                    icon: Icon(Icons.check, color: Colors.white),
                    label: Text(context.l10n.acceptMission,
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _actionLoading
                        ? null
                        : () => _showRejectDialog(),
                    icon: Icon(Icons.close, color: Colors.red),
                    label: Text(context.l10n.rejectMission,
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedActions(Map<String, dynamic> m) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ابدأ المهمة',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6C3FC5))),
            SizedBox(height: 8),
            const Text(
              'عند الوصول للموقع، اضغط "بدء المهمة" لتسجيل حضورك تلقائياً',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _actionLoading ? null : _startMission,
                icon: _actionLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.play_arrow, color: Colors.white),
                label: Text(context.l10n.startMission,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveActions(Map<String, dynamic> m) {
    return Column(
      children: [
        Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: Colors.orange, size: 12),
                      SizedBox(width: 6),
                      Text('المهمة جارية الآن',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 12),
                  // تحديث الموقع
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showUpdateLocationDialog,
                      icon: Icon(Icons.my_location,
                          color: Color(0xFF6C3FC5)),
                      label: const Text('تحديث موقعي الحالي',
                          style: TextStyle(color: Color(0xFF6C3FC5))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6C3FC5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  // إنهاء المهمة
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _actionLoading ? null : _endMission,
                      icon: _actionLoading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(Icons.stop, color: Colors.white),
                      label: Text(context.l10n.endMission,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackPrompt() {
    return Card(
      color: const Color(0xFFF3E5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.feedback, color: Color(0xFF6C3FC5), size: 40),
            SizedBox(height: 8),
            const Text(
              'المهمة مكتملة! أضف فيدباك الزيارة',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF6C3FC5)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showFeedbackSheet(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3FC5),
                ),
                child: Text(context.l10n.writeFeedback,
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF6C3FC5))),
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
          Text('$label: ',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
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
              child: Text(context.l10n.retry)),
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

  Future<void> _respond(String action) async {
    setState(() => _actionLoading = true);
    final result = await MissionsService.respondToMission(
        widget.assignmentId, action);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: action == 'accept' ? Colors.green : Colors.red,
      ),
    );
    _loadMission();
  }

  void _showRejectDialog() async {
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
            maxLines: 3,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel)),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.l10n.confirm)),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      setState(() => _actionLoading = true);
      final result = await MissionsService.respondToMission(
          widget.assignmentId, 'reject',
          reason: ctrl.text);
      if (!mounted) return;
      setState(() => _actionLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'تم الرفض')),
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _startMission() async {
    setState(() => _actionLoading = true);
    final result =
        await MissionsService.startMission(widget.assignmentId);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    final autoCheckin = result['auto_checkin'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(autoCheckin
            ? '✅ تم بدء المهمة وتسجيل حضورك تلقائياً'
            : '✅ تم بدء المهمة'),
        backgroundColor: Colors.green,
      ),
    );
    _loadMission();
  }

  Future<void> _endMission() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(context.l10n.endMission),
          content: const Text('هل أنت متأكد من إنهاء المهمة؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('تراجع')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('إنهاء', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    setState(() => _actionLoading = true);
    final result = await MissionsService.endMission(widget.assignmentId);
    if (!mounted) return;
    setState(() => _actionLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'تم إنهاء المهمة'),
        backgroundColor: Colors.green,
      ),
    );
    _loadMission();
  }

  void _showUpdateLocationDialog() async {
    final labelCtrl = TextEditingController(text: 'انتقلنا لمكان جديد');
    await showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تحديث الموقع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('وصف الموقع الحالي:'),
              SizedBox(height: 8),
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(
                  hintText: 'مثال: انتقلنا للمعاينة، اجتماع العميل...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.cancel)),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await MissionsService.updateLocation(
                  widget.assignmentId,
                  lat: 0.0,
                  lng: 0.0,
                  label: labelCtrl.text,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'تم تحديث الموقع'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3FC5)),
              child: Text(context.l10n.refresh,
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog() async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('طلب الانسحاب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('سيتم إرسال طلب الانسحاب للمدير للموافقة'),
              SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: 'سبب الانسحاب *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.l10n.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('إرسال الطلب',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && ctrl.text.isNotEmpty) {
      final result = await MissionsService.withdrawFromMission(
          widget.assignmentId, ctrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'تم إرسال الطلب'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showFeedbackSheet() {
    int interestRating = 3;
    int dealProbability = 3;
    String clientStatus = 'thinking';
    final clientNeedsCtrl = TextEditingController();
    final internalNotesCtrl = TextEditingController();
    bool contractSigned = false;
    bool needsFollowup = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            expand: false,
            builder: (_, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Text(context.l10n.missionFeedback,
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),

                // حالة العميل
                const Text('حالة العميل:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: clientStatus,
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'very_interested', child: Text('🟢 مهتم جداً')),
                    DropdownMenuItem(value: 'interested', child: Text('🔵 مهتم')),
                    DropdownMenuItem(value: 'thinking', child: Text('🟡 يفكر')),
                    DropdownMenuItem(value: 'not_interested', child: Text('🔴 غير مهتم')),
                    DropdownMenuItem(value: 'postponed', child: Text('⚪ مؤجل')),
                  ],
                  onChanged: (v) => setSheetState(() => clientStatus = v!),
                ),
                SizedBox(height: 16),

                // تقييم الاهتمام
                const Text('تقييم اهتمام العميل:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(
                      i < interestRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () => setSheetState(() => interestRating = i + 1),
                  )),
                ),

                // احتمال الصفقة
                const Text('احتمال الصفقة:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => IconButton(
                    icon: Icon(
                      i < dealProbability ? Icons.star : Icons.star_border,
                      color: Colors.green,
                      size: 32,
                    ),
                    onPressed: () => setSheetState(() => dealProbability = i + 1),
                  )),
                ),
                SizedBox(height: 12),

                // احتياجات العميل
                TextField(
                  controller: clientNeedsCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'احتياجات العميل',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),

                // عقد
                CheckboxListTile(
                  title: Text(context.l10n.contractSigned),
                  value: contractSigned,
                  onChanged: (v) => setSheetState(() => contractSigned = v!),
                  activeColor: const Color(0xFF6C3FC5),
                ),

                // متابعة
                CheckboxListTile(
                  title: const Text('يحتاج متابعة'),
                  value: needsFollowup,
                  onChanged: (v) => setSheetState(() => needsFollowup = v!),
                  activeColor: const Color(0xFF6C3FC5),
                ),

                SizedBox(height: 12),

                // ملاحظات داخلية
                TextField(
                  controller: internalNotesCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات داخلية للفريق',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    final result = await MissionsService.submitFeedback(
                      widget.missionId,
                      interestRating: interestRating,
                      dealProbability: dealProbability,
                      clientStatus: clientStatus,
                      clientNeeds: clientNeedsCtrl.text,
                      contractSigned: contractSigned,
                      needsFollowup: needsFollowup,
                      internalNotes: internalNotesCtrl.text,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['success'] == true
                            ? '✅ تم حفظ الفيدباك'
                            : result['error'] ?? 'حدث خطأ'),
                        backgroundColor: result['success'] == true
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                    _loadMission();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C3FC5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ الفيدباك',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}