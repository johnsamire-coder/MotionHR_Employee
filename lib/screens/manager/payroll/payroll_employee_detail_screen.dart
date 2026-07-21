import 'package:flutter/material.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

import '../../../services/payroll_service.dart';

class PayrollEmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const PayrollEmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<PayrollEmployeeDetailScreen> createState() =>
      _PayrollEmployeeDetailScreenState();
}

class _PayrollEmployeeDetailScreenState
    extends State<PayrollEmployeeDetailScreen> {
  final _service = PayrollService();

  Map<String, dynamic>? _data;
  bool _loading = true;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _data = await _service.getEmployeeDetail(employeeId: widget.employeeId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'خطأ: $e' : 'Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _money(dynamic value) {
    final numValue = (value is num) ? value.toDouble() : double.tryParse('$value') ?? 0.0;
    final currency = (_data?['currency'] ?? 'EGP').toString();
    return '${numValue.toStringAsFixed(2)} $currency';
  }

  String _value(dynamic value, [String fallback = '-']) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (isAr) {
      switch (s) {
        case 'present':
          return 'حاضر';
        case 'late':
          return 'متأخر';
        case 'absent':
          return 'غائب';
        case 'on_leave':
          return 'إجازة';
        case 'mission_day':
          return 'مهمة';
        default:
          return status;
      }
    } else {
      switch (s) {
        case 'present':
          return 'Present';
        case 'late':
          return 'Late';
        case 'absent':
          return 'Absent';
        case 'on_leave':
          return 'On Leave';
        case 'mission_day':
          return 'Mission';
        default:
          return status;
      }
    }
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'present') return Colors.green;
    if (s == 'late') return Colors.orange;
    if (s == 'absent') return Colors.red;
    if (s == 'on_leave') return Colors.blueGrey;
    if (s == 'mission_day') return Colors.indigo;
    return Colors.grey;
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _value(_data?['employee_name'], widget.employeeName),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _infoRow(
              isAr ? 'الكود' : 'Code',
              _value(_data?['employee_code']),
            ),
            _infoRow(
              isAr ? 'الفرع' : 'Branch',
              _value(_data?['branch_name']),
            ),
            _infoRow(
              isAr ? 'الإدارة' : 'Department',
              _value(_data?['department_name']),
            ),
            _infoRow(
              isAr ? 'المسمى الوظيفي' : 'Job Title',
              _value(_data?['job_title_name']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _financialSummaryCard() {
    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              isAr ? 'الملخص المالي' : 'Financial Summary',
              Icons.account_balance_wallet,
              Colors.green.shade800,
            ),
            _infoRow(
              isAr ? 'الراتب الأساسي' : 'Basic Salary',
              _money(_data?['basic_salary']),
            ),
            _infoRow(
              isAr ? 'إجمالي البدلات' : 'Allowances Total',
              _money(_data?['allowances_total']),
              color: Colors.blue,
            ),
            _infoRow(
              isAr ? 'أوفرتايم' : 'Overtime',
              _money(_data?['overtime_bonus']),
              color: Colors.indigo,
            ),
            _infoRow(
              isAr ? 'المكافآت' : 'Bonuses',
              _money(_data?['bonuses_total']),
              color: Colors.teal,
            ),
            const Divider(height: 20),
            _infoRow(
              isAr ? 'إجمالي الاستحقاقات' : 'Gross Salary',
              _money(_data?['gross_salary']),
              color: Colors.green.shade900,
              bold: true,
            ),
            const Divider(height: 20),
            _infoRow(
              isAr ? 'خصم التأخير' : 'Late Deduction',
              _money(_data?['late_deduction']),
              color: Colors.red,
            ),
            _infoRow(
              isAr ? 'خصم الغياب' : 'Absence Deduction',
              _money(_data?['absence_deduction']),
              color: Colors.red,
            ),
            _infoRow(
              isAr ? 'خصم التأمينات' : 'Insurance Deduction',
              _money(_data?['insurance_deduction']),
              color: Colors.red,
            ),
            _infoRow(
              isAr ? 'الأقساط / السلف' : 'Installments / Advances',
              _money(_data?['installments_total']),
              color: Colors.red,
            ),
            _infoRow(
              isAr ? 'الجزاءات' : 'Penalties',
              _money(_data?['penalties_total']),
              color: Colors.red,
            ),
            _infoRow(
              isAr ? 'خصومات إضافية' : 'Extra Deductions',
              _money(_data?['extra_deductions_total']),
              color: Colors.red,
            ),
            const Divider(height: 20),
            _infoRow(
              isAr ? 'إجمالي الخصومات' : 'Total Deductions',
              _money(_data?['total_deductions']),
              color: Colors.red.shade700,
              bold: true,
            ),
            const Divider(height: 20),
            _infoRow(
              isAr ? 'صافي الراتب' : 'Net Salary',
              _money(_data?['net_salary']),
              color: Colors.green.shade800,
              bold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _attendanceCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              isAr ? 'ملخص الحضور' : 'Attendance Summary',
              Icons.access_time,
              Colors.deepPurple,
            ),
            _infoRow(
              isAr ? 'أيام العمل' : 'Working Days',
              _value(_data?['total_working_days'], '0'),
            ),
            _infoRow(
              isAr ? 'أيام الحضور' : 'Attended Days',
              _value(_data?['attended_days'], '0'),
            ),
            _infoRow(
              isAr ? 'أيام الحضور الفعلي' : 'Present Days',
              _value(_data?['present_days'], '0'),
            ),
            _infoRow(
              isAr ? 'أيام التأخير' : 'Late Days',
              _value(_data?['late_days'], '0'),
              color: Colors.orange,
            ),
            _infoRow(
              isAr ? 'أيام الغياب' : 'Absent Days',
              _value(_data?['absent_days'], '0'),
              color: Colors.red,
            ),
            _infoRow(
              isAr ? 'أيام المهمة' : 'Mission Days',
              _value(_data?['mission_days'], '0'),
              color: Colors.indigo,
            ),
            _infoRow(
              isAr ? 'أيام الإجازة' : 'Leave Days',
              _value(_data?['on_leave_days'], '0'),
              color: Colors.blueGrey,
            ),
            _infoRow(
              isAr ? 'دقائق التأخير' : 'Late Minutes',
              _value(_data?['total_late_minutes'], '0'),
            ),
            _infoRow(
              isAr ? 'إجمالي ساعات العمل' : 'Total Work Hours',
              _value(_data?['total_work_hours'], '0'),
            ),
            _infoRow(
              isAr ? 'ساعات الأوفرتايم' : 'Overtime Hours',
              _value(_data?['overtime_hours'], '0'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listSection({
    required String titleAr,
    required String titleEn,
    required IconData icon,
    required Color color,
    required List items,
    required List<Widget> Function() builder,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(isAr ? titleAr : titleEn, icon, color),
            ...builder(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNamedMoneyItems(List items, {String valueKey = 'amount'}) {
    return items.map<Widget>((item) {
      final row = Map<String, dynamic>.from(item as Map);
      final title = isAr
          ? _value(row['name_ar'], _value(row['name']))
          : _value(row['name_en'], _value(row['name']));
      return ListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(title),
        subtitle: row['reason'] != null && row['reason'].toString().trim().isNotEmpty
            ? Text(row['reason'].toString())
            : null,
        trailing: Text(
          _money(row[valueKey]),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }).toList();
  }

  Widget _dailyDetailsSection() {
    final daily = (_data?['daily_details'] as List?) ?? const [];
    if (daily.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              isAr ? 'التفاصيل اليومية' : 'Daily Details',
              Icons.calendar_view_day,
              Colors.brown,
            ),
            const SizedBox(height: 4),
            ...daily.map<Widget>((d) {
              final day = Map<String, dynamic>.from(d as Map);
              final status = _value(day['effective_status'], _value(day['status']));
              final color = _statusColor(status);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: color.withValues(alpha: 0.06),
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.circle, color: color, size: 14),
                  title: Text(_value(day['date'])),
                  subtitle: Text(
                    isAr
                        ? 'دخول: ${_value(day['check_in'])} | خروج: ${_value(day['check_out'])} | ساعات: ${_value(day['work_hours'], '0')}'
                        : 'In: ${_value(day['check_in'])} | Out: ${_value(day['check_out'])} | Hours: ${_value(day['work_hours'], '0')}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if ((day['late_minutes'] ?? 0).toString() != '0')
                        Text(
                          isAr
                              ? '${day['late_minutes']} د'
                              : '${day['late_minutes']} min',
                          style: TextStyle(color: color, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowanceItems = (_data?['allowance_items'] as List?) ?? const [];
    final bonusItems = (_data?['bonus_items'] as List?) ?? const [];
    final insuranceItems = (_data?['insurance_items'] as List?) ?? const [];
    final installmentItems = (_data?['installment_items'] as List?) ?? const [];
    final penaltyItems = (_data?['penalty_items'] as List?) ?? const [];
    final extraDeductionItems =
        (_data?['extra_deduction_items'] as List?) ?? const [];

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.employeeName),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? Center(child: Text(context.l10n.noData))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: [
                        _headerCard(),
                        const SizedBox(height: 8),
                        _financialSummaryCard(),
                        const SizedBox(height: 8),
                        _attendanceCard(),
                        const SizedBox(height: 8),
                        _listSection(
                          titleAr: 'البدلات',
                          titleEn: 'Allowances',
                          icon: Icons.add_card,
                          color: Colors.blue,
                          items: allowanceItems,
                          builder: () => _buildNamedMoneyItems(allowanceItems),
                        ),
                        _listSection(
                          titleAr: 'المكافآت',
                          titleEn: 'Bonuses',
                          icon: Icons.emoji_events,
                          color: Colors.teal,
                          items: bonusItems,
                          builder: () => _buildNamedMoneyItems(bonusItems),
                        ),
                        _listSection(
                          titleAr: 'خصومات التأمينات',
                          titleEn: 'Insurance Deductions',
                          icon: Icons.health_and_safety,
                          color: Colors.red,
                          items: insuranceItems,
                          builder: () => _buildNamedMoneyItems(insuranceItems),
                        ),
                        _listSection(
                          titleAr: 'الأقساط والسلف',
                          titleEn: 'Installments & Advances',
                          icon: Icons.payments,
                          color: Colors.deepOrange,
                          items: installmentItems,
                          builder: () => installmentItems.map<Widget>((item) {
                            final row = Map<String, dynamic>.from(item as Map);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: Text(_value(row['description'])),
                              subtitle: row['remaining_amount'] != null
                                  ? Text(
                                      isAr
                                          ? 'المتبقي: ${_money(row['remaining_amount'])}'
                                          : 'Remaining: ${_money(row['remaining_amount'])}',
                                    )
                                  : null,
                              trailing: Text(
                                _money(row['monthly_amount'] ?? row['amount']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        _listSection(
                          titleAr: 'الجزاءات',
                          titleEn: 'Penalties',
                          icon: Icons.gpp_bad,
                          color: Colors.red.shade700,
                          items: penaltyItems,
                          builder: () => _buildNamedMoneyItems(penaltyItems),
                        ),
                        _listSection(
                          titleAr: 'خصومات إضافية',
                          titleEn: 'Extra Deductions',
                          icon: Icons.remove_circle_outline,
                          color: Colors.redAccent,
                          items: extraDeductionItems,
                          builder: () =>
                              _buildNamedMoneyItems(extraDeductionItems),
                        ),
                        const SizedBox(height: 8),
                        _dailyDetailsSection(),
                      ],
                    ),
                  ),
      ),
    );
  }
}