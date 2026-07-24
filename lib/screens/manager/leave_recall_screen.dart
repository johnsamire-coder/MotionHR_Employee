import 'package:flutter/material.dart';
import '../../services/shifts_service.dart';
import '../../services/employee_management_service.dart';

const Color kRecallColor = Color(0xFFE65100);

class LeaveRecallScreen extends StatefulWidget {
  const LeaveRecallScreen({super.key});

  @override
  State<LeaveRecallScreen> createState() => _LeaveRecallScreenState();
}

class _LeaveRecallScreenState extends State<LeaveRecallScreen>
    with SingleTickerProviderStateMixin {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  late TabController _tabController;
  List<Map<String, dynamic>> _recalls = [];
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ShiftsService.getLeaveRecalls(),
        EmployeeManagementService.getEmployeesSimple(),
      ]);
      setState(() {
        _recalls = List<Map<String, dynamic>>.from(results[0] as List);
        _employees = List<Map<String, dynamic>>.from(results[1] as List);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Map<String, dynamic>> get _filteredRecalls {
    if (_filterStatus == 'all') return _recalls;
    return _recalls.where((r) => r['status'] == _filterStatus).toList();
  }

  Future<void> _showCreateDialog() async {
    int? selectedEmployeeId;
    DateTime recallDate = DateTime.now();
    final reasonCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: StatefulBuilder(
          builder: (ctx, setDs) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.person_search, color: kRecallColor),
                const SizedBox(width: 8),
                Text(isAr ? 'طلب استدعاء من إجازة' : 'Leave Recall Request'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kRecallColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kRecallColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: kRecallColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'سيتم إشعار HR للموافقة على الاستدعاء'
                                : 'HR will be notified to approve the recall',
                            style: const TextStyle(fontSize: 11, color: kRecallColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: isAr ? 'الموظف *' : 'Employee *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.person, color: kRecallColor),
                    ),
                    items: _employees
                        .map((e) => DropdownMenuItem<int>(
                              value: e['id'] as int,
                              child: Text(
                                '${e['full_name'] ?? ''} ${e['department'] != null && e['department'].toString().isNotEmpty ? "(${e['department']})" : ""}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setDs(() => selectedEmployeeId = v),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: recallDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setDs(() => recallDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isAr ? 'يوم الاستدعاء *' : 'Recall Date *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.calendar_today, color: kRecallColor),
                      ),
                      child: Text(
                        _fmt(recallDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: isAr ? 'سبب الاستدعاء *' : 'Recall Reason *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.notes, color: kRecallColor),
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
                onPressed: selectedEmployeeId == null || reasonCtrl.text.trim().isEmpty
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        try {
                          final result = await ShiftsService.createLeaveRecall(
                            employeeId: selectedEmployeeId!,
                            recallDate: _fmt(recallDate),
                            reason: reasonCtrl.text.trim(),
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(result['message'] ??
                                  (isAr ? 'تم إنشاء الطلب ✅' : 'Request created ✅')),
                              backgroundColor: Colors.green,
                            ));
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
                style: ElevatedButton.styleFrom(backgroundColor: kRecallColor),
                child: Text(
                  isAr ? 'إرسال الطلب' : 'Submit',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewRecall(Map<String, dynamic> recall, String action) async {
    final notesCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(action == 'approve'
              ? (isAr ? 'موافقة على الاستدعاء' : 'Approve Recall')
              : (isAr ? 'رفض الاستدعاء' : 'Reject Recall')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${recall['employee_name']} - ${recall['recall_date']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isAr ? 'تراجع' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'approve' ? Colors.green : Colors.red,
              ),
              child: Text(
                action == 'approve'
                    ? (isAr ? 'موافقة' : 'Approve')
                    : (isAr ? 'رفض' : 'Reject'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;
    try {
      final result = await ShiftsService.reviewLeaveRecall(
        recallId: recall['id'],
        action: action,
        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? (isAr ? 'تم ✅' : 'Done ✅')),
          backgroundColor: action == 'approve' ? Colors.green : Colors.orange,
        ));
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
            isAr ? 'استدعاء من الإجازة' : 'Leave Recall',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kRecallColor,
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
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('all', isAr ? 'الكل' : 'All'),
                    const SizedBox(width: 8),
                    _filterChip('pending', isAr ? 'معلق' : 'Pending'),
                    const SizedBox(width: 8),
                    _filterChip('approved', isAr ? 'موافق' : 'Approved'),
                    const SizedBox(width: 8),
                    _filterChip('rejected', isAr ? 'مرفوض' : 'Rejected'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kRecallColor))
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
                                  backgroundColor: kRecallColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _filteredRecalls.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_search, size: 80, color: Colors.grey[300]),
                                  const SizedBox(height: 16),
                                  Text(
                                    isAr ? 'لا توجد طلبات استدعاء' : 'No recall requests',
                                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadAll,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _filteredRecalls.length,
                                itemBuilder: (_, i) => _buildRecallCard(_filteredRecalls[i]),
                              ),
                            ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showCreateDialog,
          backgroundColor: kRecallColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            isAr ? 'طلب استدعاء' : 'New Recall',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String status, String label) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kRecallColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? kRecallColor : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildRecallCard(Map<String, dynamic> r) {
    final status = r['status']?.toString() ?? 'pending';
    final isPending = status == 'pending';
    final isApproved = status == 'approved';

    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.hourglass_top;

    if (isApproved) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    }
    if (status == 'rejected') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }
    if (status == 'cancelled') {
      statusColor = Colors.grey;
      statusIcon = Icons.block;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kRecallColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_search, color: kRecallColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['employee_name']?.toString() ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${isAr ? 'يوم' : 'Date'}: ${r['recall_date']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        r['status_display']?.toString() ?? status,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if ((r['reason'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                r['reason']?.toString() ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if ((r['requested_by'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '${isAr ? 'طلب بواسطة' : 'Requested by'}: ${r['requested_by']}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
            if (isApproved && r['balance_restored'] == true) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.account_balance_wallet, size: 13, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    isAr ? 'تم إرجاع يوم للرصيد ✅' : 'Balance day restored ✅',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _reviewRecall(r, 'reject'),
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: Text(
                      isAr ? 'رفض' : 'Reject',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _reviewRecall(r, 'approve'),
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      isAr ? 'موافقة' : 'Approve',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
}