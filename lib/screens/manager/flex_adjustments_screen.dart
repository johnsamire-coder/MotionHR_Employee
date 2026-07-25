import 'package:flutter/material.dart';
import '../../services/flex_adjustment_service.dart';

const Color kFlexColor = Color(0xFF1565C0);

class FlexAdjustmentsScreen extends StatefulWidget {
  const FlexAdjustmentsScreen({super.key});

  @override
  State<FlexAdjustmentsScreen> createState() => _FlexAdjustmentsScreenState();
}

class _FlexAdjustmentsScreenState extends State<FlexAdjustmentsScreen>
    with SingleTickerProviderStateMixin {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  late TabController _tabController;
  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _all = [];
  bool _loadingPending = true;
  bool _loadingAll = true;

  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      _loadPending();
      _loadAll();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPending() async {
    setState(() => _loadingPending = true);
    try {
      final data = await FlexAdjustmentService.getFlexAdjustments(
          status: 'pending');
      setState(() {
        _pending = data;
        _loadingPending = false;
      });
    } catch (e) {
      setState(() => _loadingPending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loadingAll = true);
    try {
      final data =
          await FlexAdjustmentService.getFlexAdjustments(status: 'all');
      setState(() {
        _all = data;
        _loadingAll = false;
      });
    } catch (e) {
      setState(() => _loadingAll = false);
    }
  }

  Future<void> _review(Map<String, dynamic> adj, String action) async {
    String? notes;

    if (action == 'reject') {
      notes = await showDialog<String>(
        context: context,
        builder: (_) => _NotesDialog(isAr: isAr),
      );
      if (notes == null) return;
    }

    try {
      final msg = await FlexAdjustmentService.reviewFlexAdjustment(
        adjustmentId: adj['id'],
        action: action,
        notes: notes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.green),
        );
        _loadPending();
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'تسويات الشيفت المرن' : 'Flex Shift Adjustments',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kFlexColor,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                _loadPending();
                _loadAll();
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(
                text: isAr
                    ? 'قيد المراجعة (${_pending.length})'
                    : 'Pending (${_pending.length})',
                icon: const Icon(Icons.pending_actions),
              ),
              Tab(
                text: isAr ? 'الكل' : 'All',
                icon: const Icon(Icons.list_alt),
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildList(_pending, _loadingPending, showActions: true),
            _buildList(_all, _loadingAll, showActions: false),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, bool loading,
      {required bool showActions}) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: kFlexColor));
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              isAr ? 'لا توجد تسويات' : 'No adjustments found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadPending();
        _loadAll();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i], showActions: showActions),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> adj, {required bool showActions}) {
    final type = adj['adjustment_type'] as String? ?? '';
    final isOvertime = type == 'overtime';
    final status = adj['status'] as String? ?? '';
    final delta = adj['delta_hours'] as num? ?? 0;

    final typeColor = isOvertime ? Colors.green[700]! : Colors.red[700]!;
    final typeIcon = isOvertime ? Icons.trending_up : Icons.trending_down;

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: typeColor.withValues(alpha: 0.1),
                  child: Icon(typeIcon, color: typeColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (adj['employee_name'] ?? '').toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${adj['date'] ?? ''} — ${adj['shift_name'] ?? ''}',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    (adj['status_label'] ?? '').toString(),
                    style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // الأرقام
            Row(
              children: [
                _statChip(
                  isAr ? 'المطلوب' : 'Required',
                  '${adj['required_hours']}h',
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _statChip(
                  isAr ? 'الفعلي' : 'Actual',
                  '${adj['actual_hours']}h',
                  Colors.teal,
                ),
                const SizedBox(width: 8),
                _statChip(
                  isAr ? 'الفرق' : 'Delta',
                  '${delta > 0 ? '+' : ''}${delta}h',
                  typeColor,
                ),
              ],
            ),

            // ملاحظات الرفض
            if ((adj['review_notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notes, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        (adj['review_notes']).toString(),
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // أزرار الموافقة والرفض
            if (showActions && status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _review(adj, 'reject'),
                      icon: const Icon(Icons.close, size: 16),
                      label: Text(isAr ? 'رفض' : 'Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _review(adj, 'approve'),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(isAr ? 'موافقة' : 'Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _NotesDialog extends StatefulWidget {
  final bool isAr;
  const _NotesDialog({required this.isAr});

  @override
  State<_NotesDialog> createState() => _NotesDialogState();
}

class _NotesDialogState extends State<_NotesDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.isAr ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        title: Text(widget.isAr ? 'سبب الرفض' : 'Rejection Reason'),
        content: TextField(
          controller: _ctrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: widget.isAr
                ? 'اكتب سبب الرفض (اختياري)...'
                : 'Enter rejection reason (optional)...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(widget.isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _ctrl.text),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              widget.isAr ? 'تأكيد الرفض' : 'Confirm Reject',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}