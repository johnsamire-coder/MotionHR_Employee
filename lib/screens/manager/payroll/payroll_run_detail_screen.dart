import 'package:flutter/material.dart';
import '../../../services/payroll_run_service.dart';
import '../../../services/language_service.dart';
import 'payroll_bonus_penalty_screen.dart';
import 'payroll_payslip_screen.dart';

class PayrollRunDetailScreen extends StatefulWidget {
  final int runId;
  final int year;
  final int month;

  const PayrollRunDetailScreen({
    super.key,
    required this.runId,
    required this.year,
    required this.month,
  });

  @override
  State<PayrollRunDetailScreen> createState() => _PayrollRunDetailScreenState();
}

class _PayrollRunDetailScreenState extends State<PayrollRunDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool get _isAr => LanguageService.currentLanguage == 'ar';

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await PayrollRunService.getRunLines(widget.runId);
    if (!mounted) return;
    if (result.containsKey('error')) {
      setState(() { _error = result['error'] as String; _loading = false; });
    } else {
      setState(() { _data = result; _loading = false; });
    }
  }

  String _monthName(int m, bool ar) {
    const arN = ['','يناير','فبراير','مارس','ابريل','مايو','يونيو',
                  'يوليو','اغسطس','سبتمبر','اكتوبر','نوفمبر','ديسمبر'];
    const enN = ['','January','February','March','April','May','June',
                  'July','August','September','October','November','December'];
    return ar ? arN[m] : enN[m];
  }

  List<Map<String, dynamic>> get _filteredLines {
    final lines = (_data?['lines'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (_search.isEmpty) return lines;
    return lines
        .where((l) => (l['employee_name'] as String? ?? '')
            .toLowerCase()
            .contains(_search.toLowerCase()))
        .toList();
  }

  Widget _buildSummaryHeader(bool ar) {
    final totalGross = (_data?['total_gross'] as num?)?.toDouble() ?? 0.0;
    final totalNet = (_data?['total_net'] as num?)?.toDouble() ?? 0.0;
    final totalDeductions = (_data?['total_deductions'] as num?)?.toDouble() ?? 0.0;
    final totalBonuses = (_data?['total_bonuses'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '${_monthName(widget.month, ar)} ${widget.year}',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryItem(ar ? 'الاجمالي' : 'Gross', totalGross, Colors.white70, ar),
              _summaryItem(ar ? 'المكافات' : 'Bonuses', totalBonuses, Colors.greenAccent, ar),
              _summaryItem(ar ? 'الخصومات' : 'Deductions', totalDeductions, Colors.redAccent, ar),
              _summaryItem(ar ? 'الصافي' : 'Net', totalNet, Colors.yellowAccent, ar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double value, Color color, bool ar) {
    return Expanded(
      child: Column(
        children: [
          Text(value.toStringAsFixed(0),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildLineCard(Map<String, dynamic> line, bool ar) {
    final name = line['employee_name'] as String? ?? '';
    final basic = (line['basic_salary'] as num?)?.toDouble() ?? 0.0;
    final bonus = (line['total_bonuses'] as num?)?.toDouble() ?? 0.0;
    final deduction = (line['total_deductions'] as num?)?.toDouble() ?? 0.0;
    final net = (line['net_salary'] as num?)?.toDouble() ?? 0.0;
    final empId = line['employee_id'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Text(
                  '${net.toStringAsFixed(0)} ${ar ? 'ج.م' : 'EGP'}',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _lineItem(ar ? 'اساسي' : 'Basic', basic, Colors.blue),
                _lineItem(ar ? 'مكافات' : 'Bonus', bonus, Colors.green),
                _lineItem(ar ? 'خصومات' : 'Deduct', deduction, Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PayrollBonusPenaltyScreen(
                        runId: widget.runId,
                        employeeId: empId,
                        employeeName: name,
                      ),
                    ),
                  ).then((_) => _load()),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: Text(ar ? 'اضافة/خصم' : 'Add/Deduct',
                      style: const TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PayrollPayslipScreen(
                        employeeId: empId,
                        employeeName: name,
                        year: widget.year,
                        month: widget.month,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_outlined, size: 16),
                  label: Text(ar ? 'قسيمة الراتب' : 'Payslip',
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _lineItem(String label, double value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value.toStringAsFixed(0),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ar = _isAr;
    return Directionality(
      textDirection: ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(ar ? 'تفاصيل المسير' : 'Run Details'),
          centerTitle: true,
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(ar ? 'فشل التحميل' : 'Load failed'),
                        ElevatedButton(
                          onPressed: _load,
                          child: Text(ar ? 'اعادة المحاولة' : 'Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _buildSummaryHeader(ar),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: ar ? 'بحث عن موظف...' : 'Search employee...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onChanged: (v) => setState(() => _search = v),
                        ),
                      ),
                      Expanded(
                        child: _filteredLines.isEmpty
                            ? Center(
                                child: Text(
                                  ar ? 'لا توجد بيانات' : 'No data found',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: _filteredLines.length,
                                itemBuilder: (ctx, i) => _buildLineCard(_filteredLines[i], ar),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
