import 'package:flutter/material.dart';
import '../../services/missions_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';
import '../manager/create_mission_screen.dart';
import '../manager/mission_detail_screen.dart';

class ManagerMissionsScreen extends StatefulWidget {
  const ManagerMissionsScreen({super.key});

  @override
  State<ManagerMissionsScreen> createState() => _ManagerMissionsScreenState();
}

class _ManagerMissionsScreenState extends State<ManagerMissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _missions = [];
  String? _error;
  String _statusFilter = '';

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

  final Map<String, IconData> _priorityIcons = {
    'urgent': Icons.priority_high,
    'high': Icons.keyboard_arrow_up,
    'normal': Icons.remove,
  };

  Map<String, String> _getStatusLabels(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return {
      '': isAr ? 'ط§ظ„ظƒظ„' : 'All',
      'approved': context.l10n.approved,
      'in_progress': isAr ? 'ط¬ط§ط±ظٹط©' : 'In Progress',
      'completed': isAr ? 'ظ…ظƒطھظ…ظ„ط©' : 'Completed',
      'cancelled': context.l10n.cancelled,
      'pending_approval': isAr ? 'ط§ظ†طھط¸ط§ط± ظ…ظˆط§ظپظ‚ط©' : 'Pending Approval',
    };
  }

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
      final result = await MissionsService.getManagerMissions(
        statusFilter: _statusFilter.isEmpty ? null : _statusFilter,
      );
      setState(() {
        _missions = result['missions'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'ط¥ط¯ط§ط±ط© ط§ظ„ظ…ظ‡ظ…ط§طھ' : 'Missions Management',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF6C3FC5),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadMissions,
            ),
            IconButton(
              icon: const Icon(Icons.pending_actions, color: Colors.white),
              tooltip: isAr ? 'ط§ظ„ط·ظ„ط¨ط§طھ ط§ظ„ظ…ط¹ظ„ظ‚ط©' : 'Pending Requests',
              onPressed: _showPendingRequests,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: context.l10n.missions, icon: const Icon(Icons.assignment)),
              Tab(
                text: isAr ? 'ط§ظ„ظپظٹط¯ط¨ط§ظƒ' : 'Feedback',
                icon: const Icon(Icons.feedback),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMissionsTab(),
            _buildFeedbackTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateMissionScreen()),
            );
            if (result == true) _loadMissions();
          },
          backgroundColor: const Color(0xFF6C3FC5),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            context.l10n.newMission,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionsTab() {
    return Column(
      children: [
        Container(
          height: 50,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: _getStatusLabels(context).entries.map((entry) {
              final isSelected = _statusFilter == entry.key;
              return GestureDetector(
                onTap: () {
                  setState(() => _statusFilter = entry.key);
                  _loadMissions();
                },
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6C3FC5) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C3FC5)))
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

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final status = mission['status'] ?? '';
    final priority = mission['priority'] ?? 'normal';
    final statusColor = _statusColors[status] ?? Colors.grey;
    final priorityColor = _priorityColors[priority] ?? Colors.blue;
    final assignments = mission['assignments'] as List? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MissionDetailScreen(missionId: mission['id'], isManager: true),
            ),
          );
          if (result == true) _loadMissions();
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_priorityIcons[priority] ?? Icons.remove, color: priorityColor, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      mission['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      mission['status_display'] ?? status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if ((mission['description'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    mission['description'],
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if ((mission['location_name'] ?? '').isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mission['location_name'],
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDateTime(mission['planned_start_time']),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  if (assignments.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.group, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${assignments.length} ${isAr ? 'ظ…ط´ط§ط±ظƒ' : 'participants'}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
              if ((mission['client_name'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${isAr ? 'ط§ظ„ط¹ظ…ظٹظ„' : 'Client'}: ${mission['client_name']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackTab() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return FutureBuilder<Map<String, dynamic>>(
      future: MissionsService.getFeedbackDashboard(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF6C3FC5)));
        }
        if (!snap.hasData || snap.data == null) {
          return Center(child: Text(context.l10n.noData));
        }
        final summary = snap.data!['summary'] ?? {};
        final feedbacks = snap.data!['feedbacks'] as List? ?? [];
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                _statCard(context.l10n.veryInterested, '${summary['very_interested'] ?? 0}', Icons.thumb_up, Colors.green),
                _statCard(context.l10n.interested, '${summary['interested'] ?? 0}', Icons.sentiment_satisfied, Colors.blue),
                _statCard(isAr ? 'ط¹ظ‚ظˆط¯ ظ…ظˆظ‚ط¹ط©' : 'Contracts Signed', '${summary['contracts_signed'] ?? 0}', Icons.handshake, Colors.purple),
                _statCard(isAr ? 'طھط­طھط§ط¬ ظ…طھط§ط¨ط¹ط©' : 'Needs Follow-up', '${summary['needs_followup'] ?? 0}', Icons.follow_the_signs, Colors.orange),
              ],
            ),
            if (feedbacks.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                isAr ? 'ط¢ط®ط± ط§ظ„ظپظٹط¯ط¨ط§ظƒ' : 'Recent Feedback',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...feedbacks.map((fb) => _buildFeedbackCard(fb, isAr)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> fb, bool isAr) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          _showFeedbackDetail(fb, isAr);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment, size: 16, color: Color(0xFF6C3FC5)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fb['mission_title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 6),
              if ((fb['employee_name'] ?? '').toString().isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.person, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      fb['employee_name'],
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              if ((fb['client_name'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.business, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${isAr ? 'ط§ظ„ط¹ظ…ظٹظ„' : 'Client'}: ${fb['client_name']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              if ((fb['interest_level_display'] ?? '').toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      fb['interest_level_display'],
                      style: const TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackDetail(Map<String, dynamic> fb, bool isAr) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.feedback, color: Color(0xFF6C3FC5)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fb['mission_title'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(Icons.person, isAr ? 'ط§ظ„ظ…ظˆط¸ظپ' : 'Employee', fb['employee_name'] ?? '-'),
                _detailRow(Icons.business, isAr ? 'ط§ظ„ط¹ظ…ظٹظ„' : 'Client', fb['client_name'] ?? '-'),
                _detailRow(Icons.phone, isAr ? 'ظ‡ط§طھظپ ط§ظ„ط¹ظ…ظٹظ„' : 'Client Phone', fb['client_phone'] ?? '-'),
                _detailRow(Icons.star, isAr ? 'ظ…ط³طھظˆظ‰ ط§ظ„ط§ظ‡طھظ…ط§ظ…' : 'Interest Level', fb['interest_level_display'] ?? '-'),
                _detailRow(Icons.handshake, isAr ? 'طھظ… طھظˆظ‚ظٹط¹ ط¹ظ‚ط¯' : 'Contract Signed', (fb['contract_signed'] == true) ? (isAr ? 'ظ†ط¹ظ…' : 'Yes') : (isAr ? 'ظ„ط§' : 'No')),
                _detailRow(Icons.follow_the_signs, isAr ? 'ظٹط­طھط§ط¬ ظ…طھط§ط¨ط¹ط©' : 'Needs Follow-up', (fb['needs_followup'] == true) ? (isAr ? 'ظ†ط¹ظ…' : 'Yes') : (isAr ? 'ظ„ط§' : 'No')),
                _detailRow(Icons.calendar_today, isAr ? 'طھط§ط±ظٹط® ط§ظ„ظ…طھط§ط¨ط¹ط©' : 'Follow-up Date', fb['followup_date'] ?? '-'),
                if ((fb['notes'] ?? '').toString().isNotEmpty) ...[
                  const Divider(),
                  Text(
                    isAr ? 'ظ…ظ„ط§ط­ط¸ط§طھ:' : 'Notes:',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(fb['notes'], style: const TextStyle(fontSize: 13)),
                ],
                _detailRow(Icons.access_time, isAr ? 'طھط§ط±ظٹط® ط§ظ„ط¥ط±ط³ط§ظ„' : 'Submitted', _formatDateTime(fb['created_at'])),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isAr ? 'ط¥ط؛ظ„ط§ظ‚' : 'Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildError() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            _error ?? (isAr ? 'ط­ط¯ط« ط®ط·ط£' : 'An error occurred'),
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _loadMissions,
            icon: const Icon(Icons.refresh),
            label: Text(context.l10n.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C3FC5),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            context.l10n.noMissions,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'ط§ط¶ط؛ط· + ظ„ط¥ظ†ط´ط§ط، ظ…ظ‡ظ…ط© ط¬ط¯ظٹط¯ط©' : 'Press + to create a new mission',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
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

  void _showPendingRequests() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final result = await MissionsService.getPendingRequests();
    final requests = result['requests'] as List? ?? [];
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
          builder: (_, scrollCtrl) => Column(
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
                  isAr ? 'ط·ظ„ط¨ط§طھ ط§ظ„ظ…ظ‡ظ…ط§طھ ط§ظ„ظ…ط¹ظ„ظ‚ط©' : 'Pending Mission Requests',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: requests.isEmpty
                    ? Center(
                        child: Text(
                          isAr ? 'ظ„ط§ طھظˆط¬ط¯ ط·ظ„ط¨ط§طھ ظ…ط¹ظ„ظ‚ط©' : 'No pending requests',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: requests.length,
                        itemBuilder: (_, i) {
                          final req = requests[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF6C3FC5),
                                child: Icon(Icons.assignment, color: Colors.white, size: 20),
                              ),
                              title: Text(
                                req['mission_title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(req['employee_name'] ?? ''),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
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
}
