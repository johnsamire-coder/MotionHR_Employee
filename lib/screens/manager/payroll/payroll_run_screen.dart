import 'package:flutter/material.dart';
import '../../../services/payroll_run_service.dart';
import '../../../services/language_service.dart';
import '../../../services/report_excel_service.dart';
import 'payroll_run_detail_screen.dart';

class PayrollRunScreen extends StatefulWidget {
  const PayrollRunScreen({super.key});

  @override
  State<PayrollRunScreen> createState() => _PayrollRunScreenState();
}

class _PayrollRunScreenState extends State<PayrollRunScreen> {
  final _now = DateTime.now();
  late int _selectedYear;
  late int _selectedMonth;
  Map<String, dynamic>? _data;
  bool _loading = false;
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedYear = _now.year;
    _selectedMonth = _now.month;
    _load();
  }

  bool get _isAr => LanguageService.currentLanguage == 'ar';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await PayrollRunService.getPayrollRuns(
      year: _selectedYear, month: _selectedMonth,
    );
    if (!mounted) return;
    if (result.containsKey('error')) {
      setState(() { _error = result['error'] as String; _loading = false; });
    } else {
      setState(() { _data = result; _loading = false; });
    }
  }

  Future<void> _createRun() async {
    final ar = _isAr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'انشاء مسير راتب' : 'Create Payroll Run'),
        content: Text(ar
            ? 'هل تريد انشاء مسير راتب لـ ${_monthName(_selectedMonth, ar)} $_selectedYear؟'
            : 'Create payroll run for ${_monthName(_selectedMonth, ar)} $_selectedYear?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'الغاء' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ar ? 'انشاء' : 'Create'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _creating = true);
    final result = await PayrollRunService.createPayrollRun(
      year: _selectedYear, month: _selectedMonth,
    );
    if (!mounted) return;
    setState(() => _creating = false);
    if (result.containsKey('error')) {
      _showSnack(ar ? 'فشل انشاء المسير' : 'Failed to create run', error: true);
    } else {
      _showSnack(ar ? 'تم انشاء المسير بنجاح' : 'Run created successfully');
      _load();
    }
  }

  Future<void> _approveRun(int runId) async {
    final ar = _isAr;
    setState(() => _loading = true);
    final result = await PayrollRunService.approvePayrollRun(runId);
    if (!mounted) return;
    if (result['status'] == 'approved' || result['success'] == true) {
      _showSnack(ar ? 'تمت الموافقة' : 'Approved');
      _load();
    } else {
      setState(() => _loading = false);
      _showSnack(ar ? 'فشلت الموافقة' : 'Approval failed', error: true);
    }
  }

  Future<void> _lockRun(int runId) async {
    final ar = _isAr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ar ? 'قفل المسير' : 'Lock Payroll Run'),
        content: Text(ar
            ? 'بعد القفل لن تتمكن من التعديل. هل انت متاكد؟'
            : 'After locking, no changes can be made. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ar ? 'الغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ar ? 'قفل' : 'Lock'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _loading = true);
    final result = await PayrollRunService.lockPayrollRun(runId);
    if (!mounted) return;
    if (result['status'] == 'locked' || result['success'] == true) {
      _showSnack(ar ? 'تم قفل المسير' : 'Run locked');
      _load();
    } else {
      setState(() => _loading = false);
      _showSnack(ar ? 'فشل القفل' : 'Lock failed', error: true);
    }
  }

  Future<void> _exportExcel(Map<String, dynamic> run) async {
    final ar = _isAr;
    try {
      final lines = (run['lines'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      await ReportExcelService.exportPayrollRunReport(
        lines: lines,
        year: _selectedYear,
        month: _selectedMonth,
        isAr: ar,
      );
    } catch (e) {
      _showSnack(ar ? 'فشل التصدير' : 'Export failed', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  String _monthName(int m, bool ar) {
    const arN = ['','يناير','فبراير','مارس','ابريل','مايو','يونيو',
                  'يوليو','اغسطس','سبتمبر','اكتوبر','نوفمبر','ديسمبر'];
    const enN = ['','January','February','March','April','May','June',
                  'July','August','September','October','November','December'];
    return ar ? arN[m] : enN[m];
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'draft': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'locked': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s, bool ar) {
    if (ar) {
      switch (s) {
        case 'draft': return 'مسودة';
        case 'approved': return 'معتمد';
        case 'locked': return 'مقفول';
        default: return s;
      }
    }
    switch (s) {
      case 'draft': return 'Draft';
      case 'approved': return 'Approved';
      case 'locked': return 'Locked';
      default: return s;
    }
  }

  Widget _buildMonthSelector(bool ar) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: ar ? 'السنة' : 'Year',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isDense: true,
                    items: List.generate(5, (i) => _now.year - 2 + i)
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) { setState(() => _selectedYear = v); _load(); }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: ar ? 'الشهر' : 'Month',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isDense: true,
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(value: m, child: Text(_monthName(m, ar))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) { setState(() => _selectedMonth = v); _load(); }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunCard(Map<String, dynamic> run, bool ar) {
    final status = run['status'] as String? ?? 'draft';
    final runId = run['id'] as int? ?? 0;
    final total = (run['total_net'] as num?)?.toDouble() ?? 0.0;
    final count = run['employee_count'] as int? ?? 0;
    final createdAt = run['created_at'] as String? ?? '';
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  status == 'locked' ? Icons.lock
                      : status == 'approved' ? Icons.check_circle
                      : Icons.pending,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_monthName(_selectedMonth, ar)} $_selectedYear',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        ar ? 'انشئ: $createdAt' : 'Created: $createdAt',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    _statusLabel(status, ar),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _statItem(Icons.people, ar ? 'الموظفون' : 'Employees', '$count', Colors.blue),
                _statItem(Icons.attach_money, ar ? 'اجمالي الصافي' : 'Total Net',
                    '${total.toStringAsFixed(0)} ${ar ? 'ج.م' : 'EGP'}', Colors.green),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PayrollRunDetailScreen(
                          runId: runId,
                          year: _selectedYear,
                          month: _selectedMonth,
                        ),
                      ),
                    ).then((_) => _load()),
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: Text(ar ? 'التفاصيل' : 'Details'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _exportExcel(run),
                  icon: const Icon(Icons.table_chart_outlined),
                  tooltip: ar ? 'تصدير Excel' : 'Export Excel',
                  color: Colors.green[700],
                ),
                if (status == 'draft') ...[
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue, foregroundColor: Colors.white,
                    ),
                    onPressed: () => _approveRun(runId),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(ar ? 'اعتماد' : 'Approve'),
                  ),
                ],
                if (status == 'approved') ...[
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white,
                    ),
                    onPressed: () => _lockRun(runId),
                    icon: const Icon(Icons.lock, size: 18),
                    label: Text(ar ? 'قفل' : 'Lock'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = _isAr;
    final runs = (_data?['runs'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ar ? 'مسيرات الرواتب' : 'Payroll Runs'),
          centerTitle: true,
          actions: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            else
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: Column(
          children: [
            _buildMonthSelector(ar),
            Expanded(
              child: _error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 12),
                          Text(ar ? 'حدث خطا في التحميل' : 'Failed to load'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _load,
                            child: Text(ar ? 'اعادة المحاولة' : 'Retry'),
                          ),
                        ],
                      ),
                    )
                  : _loading && _data == null
                      ? const Center(child: CircularProgressIndicator())
                      : runs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    ar ? 'لا يوجد مسير راتب لهذا الشهر' : 'No payroll run for this month',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    ar ? 'اضغط + لانشاء مسير جديد' : 'Tap + to create a new run',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              children: runs.map((r) => _buildRunCard(r, ar)).toList(),
                            ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _creating ? null : _createRun,
          icon: _creating
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.add),
          label: Text(ar ? 'انشاء مسير' : 'Create Run'),
        ),
      ),
    );
  }
}
