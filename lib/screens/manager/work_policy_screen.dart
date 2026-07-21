import 'package:flutter/material.dart';
import '../../../services/work_policy_service.dart';

class WorkPolicyScreen extends StatefulWidget {
  const WorkPolicyScreen({super.key});
  @override
  State<WorkPolicyScreen> createState() => _WorkPolicyScreenState();
}

class _WorkPolicyScreenState extends State<WorkPolicyScreen> {
  bool _loading = true;
  bool _saving = false;
  Map<String, bool> _days = {
    'work_sunday': true,
    'work_monday': true,
    'work_tuesday': true,
    'work_wednesday': true,
    'work_thursday': true,
    'work_friday': false,
    'work_saturday': true,
  };
  bool _is247 = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await WorkPolicyService.getPolicy();
    setState(() {
      _days = {
        'work_sunday': data['work_sunday'] ?? true,
        'work_monday': data['work_monday'] ?? true,
        'work_tuesday': data['work_tuesday'] ?? true,
        'work_wednesday': data['work_wednesday'] ?? true,
        'work_thursday': data['work_thursday'] ?? true,
        'work_friday': data['work_friday'] ?? false,
        'work_saturday': data['work_saturday'] ?? true,
      };
      _is247 = data['is_24_7'] ?? false;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final ok = await WorkPolicyService.savePolicy({..._days, 'is_24_7': _is247});
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (isAr ? 'تم الحفظ بنجاح' : 'Saved successfully')
          : (isAr ? 'حدث خطأ' : 'An error occurred')),
      backgroundColor: ok ? Colors.green : Colors.red,
    ));
  }

  String _dayName(String key, bool isAr) {
    const ar = {
      'work_sunday': 'الأحد',
      'work_monday': 'الاثنين',
      'work_tuesday': 'الثلاثاء',
      'work_wednesday': 'الأربعاء',
      'work_thursday': 'الخميس',
      'work_friday': 'الجمعة',
      'work_saturday': 'السبت',
    };
    const en = {
      'work_sunday': 'Sunday',
      'work_monday': 'Monday',
      'work_tuesday': 'Tuesday',
      'work_wednesday': 'Wednesday',
      'work_thursday': 'Thursday',
      'work_friday': 'Friday',
      'work_saturday': 'Saturday',
    };
    return isAr ? (ar[key] ?? key) : (en[key] ?? key);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
          title: Text(isAr ? 'إعدادات أيام العمل' : 'Work Days Settings'),
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
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr ? 'أيام العمل الأسبوعية' : 'Weekly Work Days',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._days.entries.map((e) => SwitchListTile(
                                title: Text(_dayName(e.key, isAr)),
                                value: e.value,
                                activeColor: const Color(0xFF1B5E20),
                                onChanged: _is247
                                    ? null
                                    : (v) => setState(() => _days[e.key] = v),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: SwitchListTile(
                      title: Text(isAr ? 'نظام 24/7' : '24/7 System'),
                      subtitle: Text(isAr
                          ? 'لا توجد أيام إجازة ثابتة'
                          : 'No fixed days off'),
                      value: _is247,
                      activeColor: const Color(0xFF1B5E20),
                      onChanged: (v) => setState(() => _is247 = v),
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
                        backgroundColor: const Color(0xFF1B5E20),
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