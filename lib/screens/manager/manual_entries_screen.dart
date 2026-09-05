import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_client.dart';
import '../../services/employee_management_service.dart';

const _kBase = 'https://jssolutions-eg.com';

class ManualEntriesScreen extends StatefulWidget {
  const ManualEntriesScreen({super.key});
  @override
  State<ManualEntriesScreen> createState() => _ManualEntriesScreenState();
}

class _ManualEntriesScreenState extends State<ManualEntriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool get isAr => WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar';
  List<dynamic> _penalties = [];
  List<dynamic> _bonuses = [];
  bool _loading = true;
  String _userRole = '';
  bool get _canApprove =>
      const {'super_admin', 'company_admin', 'hr_manager'}.contains(_userRole);

  final Map<String, String> _penaltyCategories = {
    'performance': 'قصور في الأداء',
    'discipline': 'مخالفة سلوكية',
    'attendance': 'مشكلة حضور',
    'safety': 'مخالفة سلامة',
    'quality': 'مشكلة جودة عمل',
    'other': 'أخرى',
  };
  final Map<String, String> _bonusCategories = {
    'performance': 'أداء متميز',
    'goal_achievement': 'تحقيق هدف',
    'project_completion': 'إتمام مشروع',
    'extra_effort': 'مجهود إضافي',
    'loyalty': 'ولاء وسنوات خدمة',
    'referral': 'ترشيح موظف جديد',
    'other': 'أخرى',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRoleAndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRoleAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('role') ?? '';
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final headers = await ApiClient.buildHeaders();
      final r1 = await http.get(
        Uri.parse('$_kBase/attendance/api/mobile/manager/entries/penalty/'),
        headers: headers,
      );
      final r2 = await http.get(
        Uri.parse('$_kBase/attendance/api/mobile/manager/entries/bonus/'),
        headers: headers,
      );
      if (r1.statusCode == 200) {
        final d = jsonDecode(utf8.decode(r1.bodyBytes));
        _penalties = d['results'] ?? [];
      }
      if (r2.statusCode == 200) {
        final d = jsonDecode(utf8.decode(r2.bodyBytes));
        _bonuses = d['results'] ?? [];
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
      case 'applied':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusLabel(String status) {
    const labels = {
      'pending': 'قيد الموافقة',
      'approved': 'تمت الموافقة',
      'rejected': 'مرفوض',
      'applied': 'مطبق في الرواتب',
      'cancelled': 'ملغي',
    };
    return labels[status] ?? status;
  }

  Widget _entryCard(Map<String, dynamic> entry, bool isPenalty) {
    final status = (entry['status'] ?? 'pending').toString();
    final color = _statusColor(status);
    final categories = isPenalty ? _penaltyCategories : _bonusCategories;
    final categoryLabel = categories[entry['category']] ?? entry['category'] ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (entry['employee_name'] ?? '').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel(status),
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(categoryLabel, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '${entry['amount_value'] ?? 0} ج.م - ${entry['target_month']}/${entry['target_year']}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if ((entry['reason'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text((entry['reason'] ?? '').toString(), style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
            if (status == 'pending') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_canApprove) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _approveOrReject(entry['id'], isPenalty, true),
                        icon: const Icon(Icons.check, size: 16, color: Colors.green),
                        label: Text(isAr ? 'موافقة' : 'Approve', style: const TextStyle(color: Colors.green)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _approveOrReject(entry['id'], isPenalty, false),
                        icon: const Icon(Icons.close, size: 16, color: Colors.red),
                        label: Text(isAr ? 'رفض' : 'Reject', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _deleteEntry(entry['id'], isPenalty),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: Text(isAr ? 'حذف' : 'Delete', style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approveOrReject(int entryId, bool isPenalty, bool approve) async {
    final type = isPenalty ? 'penalty' : 'bonus';
    final action = approve ? 'approve' : 'reject';
    try {
      final headers = await ApiClient.buildHeaders(includeContentType: true);
      final res = await http.post(
        Uri.parse('$_kBase/attendance/api/mobile/manager/entries/$type/$entryId/$action/'),
        headers: headers,
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? (isAr ? 'تم' : 'Done')),
        backgroundColor: data['success'] == true ? Colors.green : Colors.red,
      ));
      _load();
    } catch (_) {}
  }

  Future<void> _deleteEntry(int entryId, bool isPenalty) async {
    final type = isPenalty ? 'penalty' : 'bonus';
    try {
      final headers = await ApiClient.buildHeaders();
      final res = await http.delete(
        Uri.parse('$_kBase/attendance/api/mobile/manager/entries/$type/$entryId/'),
        headers: headers,
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? (isAr ? 'تم الحذف' : 'Deleted')),
        backgroundColor: data['success'] == true ? Colors.green : Colors.red,
      ));
      _load();
    } catch (_) {}
  }

  Future<void> _showCreateDialog(bool isPenalty) async {
    final categories = isPenalty ? _penaltyCategories : _bonusCategories;
    String category = categories.keys.first;
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final now = DateTime.now();
    int targetMonth = now.month;
    int targetYear = now.year;
    int? selectedEmployeeId;
    List<Map<String, dynamic>> employees = [];
    bool loadingEmployees = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (loadingEmployees) {
            EmployeeManagementService.getEmployeesSimple().then((list) {
              setDialogState(() {
                employees = list;
                loadingEmployees = false;
              });
            }).catchError((_) {
              setDialogState(() => loadingEmployees = false);
            });
          }
          return AlertDialog(
          title: Text(isPenalty
              ? (isAr ? 'إضافة جزاء' : 'Add Penalty')
              : (isAr ? 'إضافة مكافأة' : 'Add Bonus')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                loadingEmployees
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : DropdownButtonFormField<int>(
                        initialValue: selectedEmployeeId,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الموظف' : 'Employee',
                          border: const OutlineInputBorder(),
                        ),
                        items: employees
                            .map((e) => DropdownMenuItem<int>(
                                  value: e['id'] as int,
                                  child: Text((e['name'] ?? e['full_name'] ?? '').toString()),
                                ))
                            .toList(),
                        onChanged: (v) => setDialogState(() => selectedEmployeeId = v),
                      ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الفئة' : 'Category',
                    border: const OutlineInputBorder(),
                  ),
                  items: categories.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? categories.keys.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isAr ? 'المبلغ' : 'Amount',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isAr ? 'السبب' : 'Reason',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: targetMonth,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الشهر' : 'Month',
                          border: const OutlineInputBorder(),
                        ),
                        items: List.generate(12, (i) => i + 1)
                            .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                            .toList(),
                        onChanged: (v) => setDialogState(() => targetMonth = v ?? now.month),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: targetYear,
                        decoration: InputDecoration(
                          labelText: isAr ? 'السنة' : 'Year',
                          border: const OutlineInputBorder(),
                        ),
                        items: [now.year - 1, now.year, now.year + 1]
                            .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                            .toList(),
                        onChanged: (v) => setDialogState(() => targetYear = v ?? now.year),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text.trim());
                if (selectedEmployeeId == null || amount == null) return;
                Navigator.pop(ctx);
                await _createEntry(isPenalty, selectedEmployeeId!, category, amount, reasonCtrl.text.trim(), targetMonth, targetYear);
              },
              child: Text(isAr ? 'إرسال' : 'Submit'),
            ),
          ],
        );
        },
      ),
    );
  }

  Future<void> _createEntry(bool isPenalty, int employeeId, String category, double amount,
      String reason, int targetMonth, int targetYear) async {
    final type = isPenalty ? 'penalty' : 'bonus';
    try {
      final headers = await ApiClient.buildHeaders(includeContentType: true);
      final res = await http.post(
        Uri.parse('$_kBase/attendance/api/mobile/manager/entries/$type/'),
        headers: headers,
        body: jsonEncode({
          'employee_id': employeeId,
          'category': category,
          'amount_type': 'fixed',
          'amount_value': amount,
          'reason': reason,
          'target_month': targetMonth,
          'target_year': targetYear,
        }),
      );
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? (isAr ? 'تم' : 'Done')),
        backgroundColor: data['success'] == true ? Colors.green : Colors.red,
      ));
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'حدث خطأ' : 'Error occurred'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'الإدخالات اليدوية' : 'Manual Entries'),
          backgroundColor: const Color(0xFF382483),
          foregroundColor: Colors.white,
          actions: [
            if (_canApprove)
              IconButton(
                onPressed: _showApprovalSettingsDialog,
                icon: const Icon(Icons.settings),
                tooltip: isAr ? 'إعدادات الموافقة' : 'Approval Settings',
              ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: isAr ? 'الجزاءات' : 'Penalties'),
              Tab(text: isAr ? 'المكافآت' : 'Bonuses'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: _load,
                    child: _penalties.isEmpty
                        ? Center(child: Text(isAr ? 'لا توجد جزاءات' : 'No penalties'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _penalties.length,
                            itemBuilder: (c, i) => _entryCard(_penalties[i], true),
                          ),
                  ),
                  RefreshIndicator(
                    onRefresh: _load,
                    child: _bonuses.isEmpty
                        ? Center(child: Text(isAr ? 'لا توجد مكافآت' : 'No bonuses'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _bonuses.length,
                            itemBuilder: (c, i) => _entryCard(_bonuses[i], false),
                          ),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(_tabController.index == 0),
          backgroundColor: const Color(0xFF382483),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(isAr ? 'إضافة' : 'Add', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Future<void> _showApprovalSettingsDialog() async {
    List<dynamic> settings = [];
    bool loading = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (loading) {
            () async {
              try {
                final headers = await ApiClient.buildHeaders();
                final res = await http.get(
                  Uri.parse('$_kBase/attendance/api/mobile/manager/entries/approval-settings/'),
                  headers: headers,
                );
                final data = jsonDecode(utf8.decode(res.bodyBytes));
                setDialogState(() {
                  settings = data['settings'] ?? [];
                  loading = false;
                });
              } catch (_) {
                setDialogState(() => loading = false);
              }
            }();
          }
          return AlertDialog(
            title: Text(isAr ? 'إعدادات الموافقة' : 'Approval Settings'),
            content: SizedBox(
              width: double.maxFinite,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: settings.map((s) {
                          final isPenaltyType = s['entry_type'] == 'penalty';
                          final categories = isPenaltyType ? _penaltyCategories : _bonusCategories;
                          final label = categories[s['category']] ?? s['category'];
                          final typeLabel = isPenaltyType
                              ? (isAr ? 'جزاء' : 'Penalty')
                              : (isAr ? 'مكافأة' : 'Bonus');
                          return SwitchListTile(
                            title: Text('$typeLabel - $label'),
                            subtitle: Text(
                              s['requires_approval'] == true
                                  ? (isAr ? 'يحتاج موافقة' : 'Requires approval')
                                  : (isAr ? 'يتطبق تلقائيًا' : 'Auto-applied'),
                              style: TextStyle(
                                color: s['requires_approval'] == true ? Colors.orange : Colors.green,
                                fontSize: 12,
                              ),
                            ),
                            value: s['requires_approval'] == true,
                            onChanged: (v) => setDialogState(() => s['requires_approval'] = v),
                          );
                        }).toList(),
                      ),
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAr ? 'إلغاء' : 'Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    final headers = await ApiClient.buildHeaders(includeContentType: true);
                    await http.post(
                      Uri.parse('$_kBase/attendance/api/mobile/manager/entries/approval-settings/'),
                      headers: headers,
                      body: jsonEncode({'settings': settings}),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(isAr ? 'تم حفظ الإعدادات' : 'Settings saved'),
                      backgroundColor: Colors.green,
                    ));
                  } catch (_) {}
                },
                child: Text(isAr ? 'حفظ' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
