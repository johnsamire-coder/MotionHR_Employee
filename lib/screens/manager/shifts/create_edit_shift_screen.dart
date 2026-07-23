import 'package:flutter/material.dart';
import '../../../services/shifts_service.dart';

const Color kShiftColor = Color(0xFF6A1B9A);

class CreateEditShiftScreen extends StatefulWidget {
  final Map<String, dynamic>? existingShift;
  const CreateEditShiftScreen({super.key, this.existingShift});

  @override
  State<CreateEditShiftScreen> createState() => _CreateEditShiftScreenState();
}

class _CreateEditShiftScreenState extends State<CreateEditShiftScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  bool get isEdit => widget.existingShift != null;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  String _shiftType = 'fixed';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _gracePeriod = 15;
  int _graceEarlyLeave = 0;
  int _earlyCheckinMinutes = 30;
  int _breakDuration = 60;
  bool _crossesMidnight = false;
  bool _isDefault = false;
  bool _workSunday = true;
  bool _workMonday = true;
  bool _workTuesday = true;
  bool _workWednesday = true;
  bool _workThursday = true;
  bool _workFriday = false;
  bool _workSaturday = false;
  bool _saving = false;

  final List<Map<String, String>> _shiftTypes = [
    {'value': 'fixed', 'ar': '🕐 ثابت', 'en': '🕐 Fixed'},
    {'value': 'morning', 'ar': '🌅 صباحي', 'en': '🌅 Morning'},
    {'value': 'evening', 'ar': '🌆 مسائي', 'en': '🌆 Evening'},
    {'value': 'night', 'ar': '🌙 ليلي', 'en': '🌙 Night'},
    {'value': 'flexible', 'ar': '⏱ مرن', 'en': '⏱ Flexible'},
    {'value': 'rotating', 'ar': '🔄 متغير', 'en': '🔄 Rotating'},
    {'value': 'split', 'ar': '✂ مقسم', 'en': '✂ Split'},
  ];

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final s = widget.existingShift!;
      _nameCtrl.text = (s['name'] ?? '').toString();
      _shiftType = (s['shift_type'] ?? 'fixed').toString();
      _gracePeriod = (s['grace_period'] ?? 15) as int;
      _graceEarlyLeave = (s['grace_early_leave'] ?? 0) as int;
      _earlyCheckinMinutes = (s['early_checkin_minutes'] ?? 30) as int;
      _breakDuration = (s['break_duration'] ?? 60) as int;
      _crossesMidnight = s['crosses_midnight'] == true;
      _isDefault = s['is_default'] == true;
      _workSunday = s['work_sunday'] != false;
      _workMonday = s['work_monday'] != false;
      _workTuesday = s['work_tuesday'] != false;
      _workWednesday = s['work_wednesday'] != false;
      _workThursday = s['work_thursday'] != false;
      _workFriday = s['work_friday'] == true;
      _workSaturday = s['work_saturday'] == true;
      if (s['start_time'] != null) {
        final parts = s['start_time'].toString().split(':');
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (s['end_time'] != null) {
        final parts = s['end_time'].toString().split(':');
        _endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final lang = isAr ? 'ar' : 'en';
      final body = {
        'name': _nameCtrl.text.trim(),
        'shift_type': _shiftType,
        'start_time': _fmtTime(_startTime),
        'end_time': _fmtTime(_endTime),
        'crosses_midnight': _crossesMidnight,
        'grace_period': _gracePeriod,
        'grace_early_leave': _graceEarlyLeave,
        'early_checkin_minutes': _earlyCheckinMinutes,
        'break_duration': _breakDuration,
        'is_default': _isDefault,
        'work_sunday': _workSunday,
        'work_monday': _workMonday,
        'work_tuesday': _workTuesday,
        'work_wednesday': _workWednesday,
        'work_thursday': _workThursday,
        'work_friday': _workFriday,
        'work_saturday': _workSaturday,
        'lang': lang,
      };

      Map<String, dynamic> result;
      if (isEdit) {
        result = await ShiftsService.updateShift(widget.existingShift!['id'], body);
      } else {
        result = await ShiftsService.createShift(body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] ?? (isAr ? 'تم الحفظ' : 'Saved')),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _dayToggle(String ar, String en, bool value, ValueChanged<bool> onChange) {
    return InkWell(
      onTap: () => onChange(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? kShiftColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value ? kShiftColor : Colors.grey[300]!),
        ),
        child: Text(
          isAr ? ar : en,
          style: TextStyle(
            color: value ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: value ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String ar, String en) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        isAr ? ar : en,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: kShiftColor,
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
            isEdit
                ? (isAr ? 'تعديل الشيفت' : 'Edit Shift')
                : (isAr ? 'شيفت جديد' : 'New Shift'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kShiftColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── اسم الشيفت ──
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('معلومات الشيفت', 'Shift Info'),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: isAr ? 'اسم الشيفت *' : 'Shift Name *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.label, color: kShiftColor),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? (isAr ? 'مطلوب' : 'Required')
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _shiftType,
                        decoration: InputDecoration(
                          labelText: isAr ? 'نوع الشيفت' : 'Shift Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.category, color: kShiftColor),
                        ),
                        items: _shiftTypes
                            .map((t) => DropdownMenuItem<String>(
                                  value: t['value'],
                                  child: Text(isAr ? t['ar']! : t['en']!),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _shiftType = v ?? 'fixed'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── الأوقات ──
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('الأوقات', 'Times'),
                      Row(children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(isStart: true),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: isAr ? 'بداية الشيفت' : 'Start Time',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.login, color: Colors.green),
                              ),
                              child: Text(
                                _fmtTime(_startTime),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(isStart: false),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: isAr ? 'نهاية الشيفت' : 'End Time',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: const Icon(Icons.logout, color: Colors.red),
                              ),
                              child: Text(
                                _fmtTime(_endTime),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: Text(isAr ? 'الشيفت يمتد لليوم التالي (ليلي)' : 'Crosses midnight (night shift)'),
                        subtitle: Text(
                          isAr
                              ? 'فعّل لو الشيفت بيبدأ بالليل وبينتهي الصبح'
                              : 'Enable if shift starts at night and ends next morning',
                          style: const TextStyle(fontSize: 12),
                        ),
                        secondary: const Icon(Icons.nights_stay, color: kShiftColor),
                        value: _crossesMidnight,
                        activeThumbColor: kShiftColor,
                        onChanged: (v) => setState(() => _crossesMidnight = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── السماحيات ──
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('السماحيات', 'Grace Periods'),
                      Text(
                        isAr
                            ? 'سماحية التأخير: $_gracePeriod دقيقة'
                            : 'Late grace: $_gracePeriod min',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: _gracePeriod.toDouble(),
                        min: 0,
                        max: 60,
                        divisions: 12,
                        activeColor: kShiftColor,
                        label: '$_gracePeriod',
                        onChanged: (v) => setState(() => _gracePeriod = v.round()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'سماحية الانصراف المبكر: $_graceEarlyLeave دقيقة'
                            : 'Early leave grace: $_graceEarlyLeave min',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: _graceEarlyLeave.toDouble(),
                        min: 0,
                        max: 60,
                        divisions: 12,
                        activeColor: Colors.orange,
                        label: '$_graceEarlyLeave',
                        onChanged: (v) => setState(() => _graceEarlyLeave = v.round()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'مسموح الحضور قبل الشيفت بـ: $_earlyCheckinMinutes دقيقة'
                            : 'Early check-in allowed: $_earlyCheckinMinutes min',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: _earlyCheckinMinutes.toDouble(),
                        min: 0,
                        max: 120,
                        divisions: 12,
                        activeColor: Colors.blue,
                        label: '$_earlyCheckinMinutes',
                        onChanged: (v) => setState(() => _earlyCheckinMinutes = v.round()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'وقت الراحة: $_breakDuration دقيقة'
                            : 'Break duration: $_breakDuration min',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Slider(
                        value: _breakDuration.toDouble(),
                        min: 0,
                        max: 120,
                        divisions: 12,
                        activeColor: Colors.green,
                        label: '$_breakDuration',
                        onChanged: (v) => setState(() => _breakDuration = v.round()),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── أيام العمل ──
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('أيام العمل', 'Work Days'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _dayToggle('أحد', 'Sun', _workSunday, (v) => setState(() => _workSunday = v)),
                          _dayToggle('اثنين', 'Mon', _workMonday, (v) => setState(() => _workMonday = v)),
                          _dayToggle('ثلاثاء', 'Tue', _workTuesday, (v) => setState(() => _workTuesday = v)),
                          _dayToggle('أربعاء', 'Wed', _workWednesday, (v) => setState(() => _workWednesday = v)),
                          _dayToggle('خميس', 'Thu', _workThursday, (v) => setState(() => _workThursday = v)),
                          _dayToggle('جمعة', 'Fri', _workFriday, (v) => setState(() => _workFriday = v)),
                          _dayToggle('سبت', 'Sat', _workSaturday, (v) => setState(() => _workSaturday = v)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── إعدادات إضافية ──
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: SwitchListTile(
                    title: Text(isAr ? 'شيفت افتراضي للشركة' : 'Default company shift'),
                    subtitle: Text(
                      isAr
                          ? 'لو مفيش شيفت محدد للموظف هيستخدم الشيفت ده'
                          : 'Used when no specific shift is assigned to an employee',
                      style: const TextStyle(fontSize: 12),
                    ),
                    secondary: const Icon(Icons.star, color: Colors.amber),
                    value: _isDefault,
                    activeThumbColor: kShiftColor,
                    onChanged: (v) => setState(() => _isDefault = v),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── ملخص ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kShiftColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kShiftColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'ملخص سريع' : 'Quick Summary',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kShiftColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${isAr ? 'الوقت' : 'Time'}: ${_fmtTime(_startTime)} → ${_fmtTime(_endTime)}${_crossesMidnight ? (isAr ? ' (+ يوم)' : ' (+1 day)') : ''}'),
                    Text('${isAr ? 'سماحية التأخير' : 'Late grace'}: $_gracePeriod ${isAr ? 'دقيقة' : 'min'}'),
                    Text('${isAr ? 'سماحية الانصراف المبكر' : 'Early leave grace'}: $_graceEarlyLeave ${isAr ? 'دقيقة' : 'min'}'),
                    Text('${isAr ? 'الراحة' : 'Break'}: $_breakDuration ${isAr ? 'دقيقة' : 'min'}'),
                    if (_isDefault)
                      Text(
                        isAr ? '⭐ شيفت افتراضي للشركة' : '⭐ Default company shift',
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kShiftColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isEdit
                              ? (isAr ? 'حفظ التعديلات ✓' : 'Save Changes ✓')
                              : (isAr ? 'إنشاء الشيفت ✓' : 'Create Shift ✓'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

