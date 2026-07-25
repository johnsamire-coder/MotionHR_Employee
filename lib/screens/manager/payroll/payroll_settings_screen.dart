import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PayrollSettingsScreen extends StatefulWidget {
  const PayrollSettingsScreen({super.key});

  @override
  State<PayrollSettingsScreen> createState() => _PayrollSettingsScreenState();
}

class _PayrollSettingsScreenState extends State<PayrollSettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  final _lateCtrl = TextEditingController();
  final _absenceCtrl = TextEditingController();
  final _overtimeCtrl = TextEditingController();
  final _insuranceFixedCtrl = TextEditingController();
  final _insurancePercentCtrl = TextEditingController();
  final _cutoffDayCtrl = TextEditingController();
  final _payDayCtrl = TextEditingController();

  String _insuranceMode = 'none';
  String _payrollCycleType = 'calendar_month';
  String _payrollPayMonthOffset = 'same_month';
  String _payrollPeriodLabelMode = 'cutoff_month';

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  static const String _baseUrl =
      'https://jssolutions-eg.com/attendance/api/mobile/manager/payroll/settings/';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _lateCtrl.dispose();
    _absenceCtrl.dispose();
    _overtimeCtrl.dispose();
    _insuranceFixedCtrl.dispose();
    _insurancePercentCtrl.dispose();
    _cutoffDayCtrl.dispose();
    _payDayCtrl.dispose();
    super.dispose();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ??
        prefs.getString('auth_token') ??
        '';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final s = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _lateCtrl.text = '${s['late_deduction_per_minute'] ?? 1.0}';
          _absenceCtrl.text = '${s['absence_deduction_per_day'] ?? 200.0}';
          _overtimeCtrl.text = '${s['overtime_rate_per_hour'] ?? 50.0}';
          _insuranceMode = s['insurance_mode']?.toString() ?? 'none';
          _insuranceFixedCtrl.text = '${s['insurance_fixed_amount'] ?? 0.0}';
          _insurancePercentCtrl.text = '${s['insurance_percent'] ?? 0.0}';
          _payrollCycleType = s['payroll_cycle_type']?.toString() ?? 'calendar_month';
          _cutoffDayCtrl.text = '${s['payroll_cutoff_day'] ?? 1}';
          _payDayCtrl.text = '${s['payroll_pay_day'] ?? 1}';
          _payrollPayMonthOffset = s['payroll_pay_month_offset']?.toString() ?? 'same_month';
          _payrollPeriodLabelMode = s['payroll_period_label_mode']?.toString() ?? 'cutoff_month';
        });
      }
    } catch (_) {
      setState(() {
        _lateCtrl.text = '1.0';
        _absenceCtrl.text = '200.0';
        _overtimeCtrl.text = '50.0';
        _insuranceMode = 'none';
        _insuranceFixedCtrl.text = '0.0';
        _insurancePercentCtrl.text = '0.0';
        _payrollCycleType = 'calendar_month';
        _cutoffDayCtrl.text = '1';
        _payDayCtrl.text = '1';
        _payrollPayMonthOffset = 'same_month';
        _payrollPeriodLabelMode = 'cutoff_month';
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final token = await _getToken();
      final body = {
        'late_deduction_per_minute': double.tryParse(_lateCtrl.text) ?? 1.0,
        'absence_deduction_per_day': double.tryParse(_absenceCtrl.text) ?? 200.0,
        'overtime_rate_per_hour': double.tryParse(_overtimeCtrl.text) ?? 50.0,
        'insurance_mode': _insuranceMode,
        'insurance_fixed_amount': double.tryParse(_insuranceFixedCtrl.text) ?? 0.0,
        'insurance_percent': double.tryParse(_insurancePercentCtrl.text) ?? 0.0,
        'payroll_cycle_type': _payrollCycleType,
        'payroll_cutoff_day': int.tryParse(_cutoffDayCtrl.text) ?? 1,
        'payroll_pay_day': int.tryParse(_payDayCtrl.text) ?? 1,
        'payroll_pay_month_offset': _payrollPayMonthOffset,
        'payroll_period_label_mode': _payrollPeriodLabelMode,
      };

      final res = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      final ok = res.statusCode == 200;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (isAr ? 'تم الحفظ بنجاح ✅' : 'Saved successfully ✅')
            : (isAr ? 'حدث خطأ ❌' : 'An error occurred ❌')),
        backgroundColor: ok ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تعذر الاتصال' : 'Connection failed'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _sectionTitle(String ar, String en) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        isAr ? ar : en,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _payrollCycleSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF6A1B9A)),
                const SizedBox(width: 8),
                _sectionTitle('دورة المرتب', 'Payroll Cycle'),
              ],
            ),

            // نوع الدورة
            DropdownButtonFormField<String>(
              initialValue: _payrollCycleType,
              decoration: InputDecoration(
                labelText: isAr ? 'نوع الدورة' : 'Cycle Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                DropdownMenuItem(
                  value: 'calendar_month',
                  child: Text(isAr ? 'شهر ميلادي (1 → آخر الشهر)' : 'Calendar Month (1 → End)'),
                ),
                DropdownMenuItem(
                  value: 'cutoff_day',
                  child: Text(isAr ? 'يوم قفل ثابت' : 'Fixed Cutoff Day'),
                ),
              ],
              onChanged: (v) => setState(() => _payrollCycleType = v ?? 'calendar_month'),
            ),

            const SizedBox(height: 14),

            // يوم القفل - يظهر فقط لو cutoff_day
            if (_payrollCycleType == 'cutoff_day') ...[
              _field(
                isAr ? 'يوم القفل (1-28)' : 'Cutoff Day (1-28)',
                _cutoffDayCtrl,
                '20',
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Text(
                  isAr
                      ? 'مثال: يوم 20 → الدورة من 21 الشهر الفايت لـ 20 الشهر الحالي'
                      : 'Example: Day 20 → Period from 21st last month to 20th this month',
                  style: TextStyle(color: Colors.purple.shade700, fontSize: 12),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // يوم الصرف
            _field(
              isAr ? 'يوم صرف المرتب (1-31)' : 'Pay Day (1-31)',
              _payDayCtrl,
              '1',
            ),

            // شهر الصرف
            DropdownButtonFormField<String>(
              initialValue: _payrollPayMonthOffset,
              decoration: InputDecoration(
                labelText: isAr ? 'شهر الصرف' : 'Pay Month',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                DropdownMenuItem(
                  value: 'same_month',
                  child: Text(isAr ? 'نفس الشهر' : 'Same Month'),
                ),
                DropdownMenuItem(
                  value: 'next_month',
                  child: Text(isAr ? 'الشهر اللي بعده' : 'Next Month'),
                ),
              ],
              onChanged: (v) => setState(() => _payrollPayMonthOffset = v ?? 'same_month'),
            ),

            const SizedBox(height: 14),

            // طريقة التسمية
            DropdownButtonFormField<String>(
              initialValue: _payrollPeriodLabelMode,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم الدورة في التقارير' : 'Period Label Mode',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: [
                DropdownMenuItem(
                  value: 'cutoff_month',
                  child: Text(isAr ? 'حسب شهر القفل (الأكثر شيوعاً)' : 'By Cutoff Month (Most Common)'),
                ),
                DropdownMenuItem(
                  value: 'pay_month',
                  child: Text(isAr ? 'حسب شهر الصرف' : 'By Pay Month'),
                ),
              ],
              onChanged: (v) => setState(() => _payrollPeriodLabelMode = v ?? 'cutoff_month'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insuranceSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('إعدادات التأمينات', 'Insurance Settings'),
            Row(
              children: [
                Text(isAr ? 'نوع التأمين:' : 'Insurance Type:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _insuranceMode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'none', child: Text(isAr ? 'بدون تأمين' : 'No Insurance')),
                      DropdownMenuItem(value: 'fixed', child: Text(isAr ? 'مبلغ ثابت' : 'Fixed Amount')),
                      DropdownMenuItem(value: 'percent', child: Text(isAr ? 'نسبة من الراتب' : 'Percentage')),
                    ],
                    onChanged: (v) => setState(() => _insuranceMode = v ?? 'none'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_insuranceMode == 'fixed')
              _field(isAr ? 'مبلغ التأمين الثابت' : 'Fixed Insurance Amount', _insuranceFixedCtrl, '0.0'),
            if (_insuranceMode == 'percent')
              _field(isAr ? 'نسبة التأمين % (من الراتب الأساسي)' : 'Insurance % (of Basic Salary)', _insurancePercentCtrl, '0.0'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'إعدادات الرواتب' : 'Payroll Settings',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // دورة المرتب - جديد
                    _payrollCycleSection(),
                    const SizedBox(height: 12),

                    // قواعد الخصم
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('قواعد الخصم', 'Deduction Rules'),
                            _field(isAr ? 'خصم التأخير (لكل دقيقة)' : 'Late Deduction (per minute)', _lateCtrl, '1.0'),
                            _field(isAr ? 'خصم الغياب (لكل يوم)' : 'Absence Deduction (per day)', _absenceCtrl, '200.0'),
                            _field(isAr ? 'بدل العمل الإضافي (لكل ساعة)' : 'Overtime Rate (per hour)', _overtimeCtrl, '50.0'),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _insuranceSection(),

                    const SizedBox(height: 12),

                    Card(
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isAr
                                    ? 'التغييرات تؤثر على حسابات الشهر الحالي فقط.'
                                    : 'Changes affect current month calculations only.',
                                style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: Text(
                          isAr ? 'حفظ الإعدادات' : 'Save Settings',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
