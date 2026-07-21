import 'package:flutter/material.dart';
import '../../../services/payroll_service.dart';
import 'dart:convert';
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
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final svc = PayrollService();
      final data = await svc.getSettings();
      final s = data['settings'] ?? data;
      setState(() {
        _lateCtrl.text = '${s['late_deduction_per_minute'] ?? 1.0}';
        _absenceCtrl.text = '${s['absence_deduction_per_day'] ?? 200.0}';
        _overtimeCtrl.text = '${s['overtime_rate_per_hour'] ?? 50.0}';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _lateCtrl.text = '1.0';
        _absenceCtrl.text = '200.0';
        _overtimeCtrl.text = '50.0';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token') ?? '';
      final res = await http.post(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/payroll/settings/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'late_deduction_per_minute': double.tryParse(_lateCtrl.text) ?? 1.0,
          'absence_deduction_per_day': double.tryParse(_absenceCtrl.text) ?? 200.0,
          'overtime_rate_per_hour': double.tryParse(_overtimeCtrl.text) ?? 50.0,
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      final ok = res.statusCode == 200;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? (isAr ? 'تم الحفظ بنجاح' : 'Saved successfully')
            : (isAr ? 'حدث خطأ' : 'An error occurred')),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
    } catch (_) {
      if (mounted) {
        final isAr2 = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr2 ? 'تعذر الاتصال' : 'Connection failed'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController ctrl, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          title: Text(isAr ? 'إعدادات الرواتب' : 'Payroll Settings'),
          actions: [
            if (_saving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              )
            else
              IconButton(icon: const Icon(Icons.save), onPressed: _save),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'قواعد الحساب' : 'Calculation Rules',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _field(
                            isAr ? 'خصم التأخير (لكل دقيقة)' : 'Late Deduction (per minute)',
                            _lateCtrl, '1.0',
                          ),
                          _field(
                            isAr ? 'خصم الغياب (لكل يوم)' : 'Absence Deduction (per day)',
                            _absenceCtrl, '200.0',
                          ),
                          _field(
                            isAr ? 'بدل العمل الإضافي (لكل ساعة)' : 'Overtime Rate (per hour)',
                            _overtimeCtrl, '50.0',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        isAr
                            ? 'ملاحظة: التغييرات تؤثر على حسابات الشهر الحالي فقط.'
                            : 'Note: Changes affect current month calculations only.',
                        style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
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
    );
  }
}