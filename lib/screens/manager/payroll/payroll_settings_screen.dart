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

  String _insuranceMode = 'none';

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
          _lateCtrl.text =
              '${s['late_deduction_per_minute'] ?? 1.0}';
          _absenceCtrl.text =
              '${s['absence_deduction_per_day'] ?? 200.0}';
          _overtimeCtrl.text =
              '${s['overtime_rate_per_hour'] ?? 50.0}';
          _insuranceMode =
              s['insurance_mode']?.toString() ?? 'none';
          _insuranceFixedCtrl.text =
              '${s['insurance_fixed_amount'] ?? 0.0}';
          _insurancePercentCtrl.text =
              '${s['insurance_percent'] ?? 0.0}';
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
      });
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final token = await _getToken();
      final body = {
        'late_deduction_per_minute':
            double.tryParse(_lateCtrl.text) ?? 1.0,
        'absence_deduction_per_day':
            double.tryParse(_absenceCtrl.text) ?? 200.0,
        'overtime_rate_per_hour':
            double.tryParse(_overtimeCtrl.text) ?? 50.0,
        'insurance_mode': _insuranceMode,
        'insurance_fixed_amount':
            double.tryParse(_insuranceFixedCtrl.text) ?? 0.0,
        'insurance_percent':
            double.tryParse(_insurancePercentCtrl.text) ?? 0.0,
      };

      final res = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Token $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

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
          content:
              Text(isAr ? 'تعذر الاتصال' : 'Connection failed'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10)),
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
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _insuranceSection() {
    return Card(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('إعدادات التأمينات', 'Insurance Settings'),

            // Mode Selector
            Row(
              children: [
                Text(isAr ? 'نوع التأمين:' : 'Insurance Type:'),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _insuranceMode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'none',
                        child:
                            Text(isAr ? 'بدون تأمين' : 'No Insurance'),
                      ),
                      DropdownMenuItem(
                        value: 'fixed',
                        child: Text(
                            isAr ? 'مبلغ ثابت' : 'Fixed Amount'),
                      ),
                      DropdownMenuItem(
                        value: 'percent',
                        child: Text(
                            isAr ? 'نسبة من الراتب' : 'Percentage'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _insuranceMode = v ?? 'none'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Fixed Amount
            if (_insuranceMode == 'fixed')
              _field(
                isAr ? 'مبلغ التأمين الثابت' : 'Fixed Insurance Amount',
                _insuranceFixedCtrl,
                '0.0',
              ),

            // Percent
            if (_insuranceMode == 'percent')
              _field(
                isAr
                    ? 'نسبة التأمين % (من الراتب الأساسي)'
                    : 'Insurance % (of Basic Salary)',
                _insurancePercentCtrl,
                '0.0',
              ),

            // Info card
            if (_insuranceMode != 'none')
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  _insuranceMode == 'fixed'
                      ? (isAr
                          ? 'سيتم خصم ${_insuranceFixedCtrl.text} شهرياً من كل موظف مفعّل له التأمين'
                          : '${_insuranceFixedCtrl.text} will be deducted monthly from each insured employee')
                      : (isAr
                          ? 'سيتم خصم ${_insurancePercentCtrl.text}% من الراتب الأساسي لكل موظف مفعّل له التأمين'
                          : '${_insurancePercentCtrl.text}% of basic salary will be deducted from each insured employee'),
                  style: TextStyle(
                      color: Colors.orange.shade900, fontSize: 12),
                ),
              ),
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
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          title: Text(
              isAr ? 'إعدادات الرواتب' : 'Payroll Settings'),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _save,
                tooltip: isAr ? 'حفظ' : 'Save',
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Deduction Rules ─────────────────────────
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(
                              'قواعد الخصم', 'Deduction Rules'),
                          _field(
                            isAr
                                ? 'خصم التأخير (لكل دقيقة)'
                                : 'Late Deduction (per minute)',
                            _lateCtrl,
                            '1.0',
                          ),
                          _field(
                            isAr
                                ? 'خصم الغياب (لكل يوم)'
                                : 'Absence Deduction (per day)',
                            _absenceCtrl,
                            '200.0',
                          ),
                          _field(
                            isAr
                                ? 'بدل العمل الإضافي (لكل ساعة)'
                                : 'Overtime Rate (per hour)',
                            _overtimeCtrl,
                            '50.0',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Insurance ──────────────────────────────
                  _insuranceSection(),

                  const SizedBox(height: 12),

                  // ── Note ───────────────────────────────────
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isAr
                                  ? 'التغييرات تؤثر على حسابات الشهر الحالي فقط.'
                                  : 'Changes affect current month calculations only.',
                              style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Save Button ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save,
                          color: Colors.white),
                      label: Text(
                        isAr ? 'حفظ الإعدادات' : 'Save Settings',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF6A1B9A),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}