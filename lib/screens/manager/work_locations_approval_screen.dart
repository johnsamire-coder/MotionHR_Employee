// lib/screens/manager/work_locations_approval_screen.dart
import 'package:flutter/material.dart';
import '../../services/work_locations_service.dart';

class WorkLocationsApprovalScreen extends StatefulWidget {
  const WorkLocationsApprovalScreen({super.key});

  @override
  State<WorkLocationsApprovalScreen> createState() =>
      _WorkLocationsApprovalScreenState();
}

class _WorkLocationsApprovalScreenState
    extends State<WorkLocationsApprovalScreen>
    with SingleTickerProviderStateMixin {
  final _service = WorkLocationsService();
  late TabController _tabController;

  bool _loading = true;
  bool _processing = false;
  List<dynamic> _pending = [];
  List<dynamic> _allLocations = [];

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

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
    setState(() => _loading = true);
    try {
      final pending = await _service.getPendingLocations();
      final all = await _service.getAllLocations();
      if (mounted) {
        setState(() {
          _pending = pending['locations'] ?? [];
          _allLocations = all['locations'] ?? [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError(e.toString());
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  Future<void> _approve(Map<String, dynamic> loc) async {
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => _ApprovalDialog(
        title: isAr ? 'اعتماد الموقع' : 'Approve Location',
        locationName: loc['name'] ?? '',
        buttonLabel: isAr ? 'اعتماد' : 'Approve',
        buttonColor: Colors.green,
        promptLabel: isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
        required: false,
      ),
    );

    if (notes == null) return;

    setState(() => _processing = true);
    try {
      final r = await _service.approveLocation(
        locationId: loc['id'],
        notes: notes,
      );
      if (r['success'] == true) {
        _showSuccess(isAr ? 'تم الاعتماد' : 'Approved');
        await _load();
      } else {
        _showError(r['message'] ?? 'فشل الاعتماد');
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject(Map<String, dynamic> loc) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _ApprovalDialog(
        title: isAr ? 'رفض الموقع' : 'Reject Location',
        locationName: loc['name'] ?? '',
        buttonLabel: isAr ? 'رفض' : 'Reject',
        buttonColor: Colors.red,
        promptLabel: isAr ? 'سبب الرفض *' : 'Rejection reason *',
        required: true,
      ),
    );

    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _processing = true);
    try {
      final r = await _service.rejectLocation(
        locationId: loc['id'],
        reason: reason.trim(),
      );
      if (r['success'] == true) {
        _showSuccess(isAr ? 'تم الرفض' : 'Rejected');
        await _load();
      } else {
        _showError(r['message'] ?? 'فشل الرفض');
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'مواقع العمل' : 'Work Locations'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Badge(
                label: Text(_pending.length.toString()),
                isLabelVisible: _pending.isNotEmpty,
                child: const Icon(Icons.hourglass_empty),
              ),
              text: isAr ? 'قيد الموافقة' : 'Pending',
            ),
            Tab(
              icon: const Icon(Icons.list),
              text: isAr ? 'كل المواقع' : 'All',
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingTab(),
                _buildAllTab(),
              ],
            ),
    );
  }

  Widget _buildPendingTab() {
    if (_pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 80, color: Colors.green[300]),
            const SizedBox(height: 12),
            Text(
              isAr ? 'مفيش طلبات معلقة' : 'No pending requests',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pending.length,
        itemBuilder: (_, i) => _buildPendingCard(_pending[i]),
      ),
    );
  }

  Widget _buildAllTab() {
    if (_allLocations.isEmpty) {
      return Center(
        child: Text(isAr ? 'مفيش مواقع' : 'No locations'),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _allLocations.length,
        itemBuilder: (_, i) => _buildAllCard(_allLocations[i]),
      ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> loc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.hourglass_empty,
                      color: Colors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(loc['location_type_display'] ?? '',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _infoRow(Icons.person,
                isAr ? 'الموظف:' : 'Employee:', loc['employee_name'] ?? ''),
            const SizedBox(height: 6),
            if ((loc['address'] ?? '').toString().isNotEmpty)
              _infoRow(Icons.place, isAr ? 'الموقع:' : 'Location:',
                  loc['address']),
            if ((loc['client_name'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.business,
                  isAr ? 'العميل:' : 'Client:', loc['client_name']),
            ],
            if ((loc['project_code'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _infoRow(Icons.code,
                  isAr ? 'كود المشروع:' : 'Code:', loc['project_code']),
            ],
            const SizedBox(height: 6),
            _infoRow(Icons.radar,
                isAr ? 'النطاق:' : 'Radius:', '${loc['radius']} m'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : () => _reject(loc),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: Text(isAr ? 'رفض' : 'Reject',
                        style: const TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : () => _approve(loc),
                    icon: const Icon(Icons.check),
                    label: Text(isAr ? 'اعتماد' : 'Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
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

  Widget _buildAllCard(Map<String, dynamic> loc) {
    final status = loc['status'] ?? 'pending';
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.location_on, color: color),
        ),
        title: Text(loc['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc['employee_name'] ?? '',
                style: const TextStyle(fontSize: 12)),
            Text(loc['location_type_display'] ?? '',
                style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
        trailing: Chip(
          label: Text(loc['status_display'] ?? '',
              style: const TextStyle(fontSize: 10)),
          backgroundColor: color.withValues(alpha: 0.2),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 12)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// Approval/Rejection Dialog
// ═══════════════════════════════════════════════════
class _ApprovalDialog extends StatefulWidget {
  final String title;
  final String locationName;
  final String buttonLabel;
  final Color buttonColor;
  final String promptLabel;
  final bool required;

  const _ApprovalDialog({
    required this.title,
    required this.locationName,
    required this.buttonLabel,
    required this.buttonColor,
    required this.promptLabel,
    required this.required,
  });

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  final _ctrl = TextEditingController();

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.locationName,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              labelText: widget.promptLabel,
              border: const OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isAr ? 'إلغاء' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.required && _ctrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isAr
                      ? 'الحقل مطلوب'
                      : 'Field required'),
                ),
              );
              return;
            }
            Navigator.pop(context, _ctrl.text);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.buttonColor,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.buttonLabel),
        ),
      ],
    );
  }
}
