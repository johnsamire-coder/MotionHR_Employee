import 'package:flutter/material.dart';
import '../../services/missions_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

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

  final Map<String, String> _statusLabels = {
    '': 'الكل',
    'approved': 'معتمدة',
    'in_progress': 'جارية',
    'completed': 'مكتملة',
    'cancelled': 'ملغية',
    'pending_approval': 'انتظار موافقة',
  };

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
            'إدارة المهمات',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF6C3FC5),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadMissions,
            ),
            IconButton(
              icon: Icon(Icons.pending_actions, color: Colors.white),
              tooltip: 'الطلبات المعلقة',
              onPressed: _showPendingRequests,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: context.l10n.missions, icon: Icon(Icons.assignment)),
              Tab(text: 'الفيدباك', icon: Icon(Icons.feedback)),
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
          onPressed: () {
            // سيتم ربطها لاحقاً
          },
          backgroundColor: const Color(0xFF6C3FC5),
          icon: Icon(Icons.add, color: Colors.white),
          label: Text(context.l10n.newMission, style: TextStyle(color: Colors.white)),
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
            children: _statusLabels.entries.map((entry) {
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
                  child: Text(
                    entry.value,
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

  Widget _buildMissionCard(Map<String, dynamic> mission) {
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
        onTap: () {
          // سيتم ربطها لاحقاً
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_priorityIcons[priority] ?? Icons.remove, color: priorityColor, size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      mission['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      mission['status_display'] ?? status,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if ((mission['location_name'] ?? '').isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey),
                    SizedBox(width: 4),
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
              SizedBox(height: 8),
              Divider(height: 1),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _formatDateTime(mission['planned_start_time']),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  if (assignments.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.group, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          '${assignments.length} مشارك',
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: MissionsService.getFeedbackDashboard(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Color(0xFF6C3FC5)));
        }
        if (!snap.hasData || snap.data == null) {
          return Center(child: Text(context.l10n.noData));
        }
        final summary = snap.data!['summary'] ?? {};
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
                _statCard('عقود موقعة', '${summary['contracts_signed'] ?? 0}', Icons.handshake, Colors.purple),
                _statCard('تحتاج متابعة', '${summary['needs_followup'] ?? 0}', Icons.follow_the_signs, Colors.orange),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
    final result = await MissionsService.getPendingRequests();
    final requests = result['requests'] as List? ?? [];
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Padding(padding: EdgeInsets.all(16), child: Text('طلبات المهمات المعلقة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: requests.length,
                itemBuilder: (_, i) => ListTile(title: Text(requests[i]['mission_title'] ?? '')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}