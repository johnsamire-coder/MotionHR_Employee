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
  String _shiftMode = 'fixed';
  String _timePreset = 'custom';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _gracePeriod = 15;
  int _graceEarlyLeave = 0;
  int _earlyCheckinMinutes = 30;
  int _breakDuration = 60;
  double _requiredDailyHours = 8.0;
  bool _crossesMidnight = false;
  bool _isDefault = false;
  bool _allowPartialCheckout = false;
  int _maxSessionsPerDay = 1;
  String _variableScheduleType = 'none';
  bool _workSunday = true;
  bool _workMonday = true;
  bool _workTuesday = true;
  bool _workWednesday = true;
  bool _workThursday = true;
  bool _workFriday = false;
  bool _workSaturday = false;
  bool _saving = false;

  List<Map<String, String>> _splitPeriods = [
    {'name': 'فترة 1', 'start': '09:00', 'end': '13:00'},
    {'name': 'فترة 2', 'start': '14:00', 'end': '18:00'},
  ];

  final List<Map<String, String>> _shiftModes = [
    {'value': 'fixed', 'ar': '🕐 ثابت', 'en': '🕐 Fixed'},
    {'value': 'flex_fixed', 'ar': '⏱ مرن ثابت', 'en': '⏱ Flex Fixed'},
    {'value': 'flex_split', 'ar': '✂⏱ مرن مقسم', 'en': '✂⏱ Flex Split'},
    {'value': 'variable_daily', 'ar': '📅 متغير يومي', 'en': '📅 Variable Daily'},
    {'value': 'variable_weekly', 'ar': '🔄 متغير أسبوعي', 'en': '🔄 Variable Weekly'},
    {'value': 'variable_weekly_flex', 'ar': '🔄⏱ متغير أسبوعي مرن', 'en': '🔄⏱ Variable Weekly Flex'},
    {'value': 'split_fixed', 'ar': '✂ مقسم ثابت', 'en': '✂ Split Fixed'},
  ];

  final List<Map<String, String>> _timePresets = [
    {'value': 'custom', 'ar': '⚙️ مخصص', 'en': '⚙️ Custom'},
    {'value': 'morning', 'ar': '🌅 صباحي (8-4)', 'en': '🌅 Morning (8-4)'},
    {'value': 'evening', 'ar': '🌆 مسائي (2-10)', 'en': '🌆 Evening (2-10)'},
    {'value': 'night', 'ar': '🌙 ليلي (10-6)', 'en': '🌙 Night (10-6)'},
  ];

  bool get _isFlexMode => _shiftMode == 'flex_fixed' || _shiftMode == 'flex_split';
  bool get _isSplitMode => _shiftMode == 'flex_split' || _shiftMode == 'split_fixed';
  bool get _isVariableMode => _shiftMode.startsWith('variable');

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final s = widget.existingShift!;
      _nameCtrl.text = (s['name'] ?? '').toString();
      _shiftType = (s['shift_type'] ?? 'fixed').toString();
      _shiftMode = (s['shift_mode'] ?? 'fixed').toString();
      _timePreset = (s['time_preset'] ?? 'custom').toString();
      _gracePeriod = (s['grace_period'] ?? 15) as int;
      _graceEarlyLeave = (s['grace_early_leave'] ?? 0) as int;
      _earlyCheckinMinutes = (s['early_checkin_minutes'] ?? 30) as int;
      _breakDuration = (s['break_duration'] ?? 60) as int;
      _requiredDailyHours = (s['required_daily_hours'] ?? 8.0).toDouble();
      _crossesMidnight = s['crosses_midnight'] == true;
      _isDefault = s['is_default'] == true;
      _allowPartialCheckout = s['allow_partial_checkout'] == true;
      _maxSessionsPerDay = (s['max_sessions_per_day'] ?? 1) as int;
      _variableScheduleType = (s['variable_schedule_type'] ?? 'none').toString();
      _workSunday = s['work_sunday'] != false;
      _workMonday = s['work_monday'] != false;
      _workTuesday = s['work_tuesday'] != false;
      _workWednesday = s['work_wednesday'] != false;
      _workThursday = s['work_thursday'] != false;
      _workFriday = s['work_friday'] == true;
      _workSaturday = s['work_saturday'] == true;
      if (s['start_time'] != null) {
        final parts = s['start_time'].toString().split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (s['end_time'] != null) {
        final parts = s['end_time'].toString().split(':');
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      // تحميل الفترات من schedule_config
      final scheduleConfig = (s['schedule_config'] as Map?) ?? {};
      final periods = (scheduleConfig['periods'] as List?) ?? [];
      if (periods.isNotEmpty) {
        _splitPeriods = periods.map<Map<String, String>>((p) {
          final m = Map<String, dynamic>.from(p as Map);
          return {
            'name': (m['name'] ?? '').toString(),
            'start': (m['start'] ?? '').toString(),
            'end': (m['end'] ?? '').toString(),
          };
        }).toList();
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _applyTimePreset(String preset) {
    setState(() {
      _timePreset = preset;
      switch (preset) {
        case 'morning':
          _startTime = const TimeOfDay(hour: 8, minute: 0);
          _endTime = const TimeOfDay(hour: 16, minute: 0);
          _crossesMidnight = false;
          break;
        case 'evening':
          _startTime = const TimeOfDay(hour: 14, minute: 0);
          _endTime = const TimeOfDay(hour: 22, minute: 0);
          _crossesMidnight = false;
          break;
        case 'night':
          _startTime = const TimeOfDay(hour: 22, minute: 0);
          _endTime = const TimeOfDay(hour: 6, minute: 0);
          _crossesMidnight = true;
          break;
      }
    });
  }

  void _onShiftModeChanged(String mode) {
    setState(() {
      _shiftMode = mode;
      _shiftType = mode;
      if (mode == 'flex_split' || mode == 'split_fixed') {
        _allowPartialCheckout = true;
        _maxSessionsPerDay = _splitPeriods.length;
      } else {
        _allowPartialCheckout = false;
        _maxSessionsPerDay = 1;
      }
      if (mode.startsWith('variable')) {
        if (mode == 'variable_daily') _variableScheduleType = 'daily';
        else if (mode == 'variable_weekly') _variableScheduleType = 'weekly';
        else if (mode == 'variable_weekly_flex') _variableScheduleType = 'weekly_flex';
      } else {
        _variableScheduleType = 'none';
      }
    });
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
        _timePreset = 'custom';
      });
    }
  }

  Future<TimeOfDay?> _pickPeriodTime(TimeOfDay initial) async {
    return showTimePicker(context: context, initialTime: initial);
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    try {
      final lang = isAr ? 'ar' : 'en';
      final body = {
        'name': _nameCtrl.text.trim(),
        'shift_type': _shiftType,
        'shift_mode': _shiftMode,
        'time_preset': _timePreset,
        'start_time': _fmtTime(_startTime),
        'end_time': _fmtTime(_endTime),
        'crosses_midnight': _crossesMidnight,
        'grace_period': _gracePeriod,
        'grace_early_leave': _graceEarlyLeave,
        'early_checkin_minutes': _earlyCheckinMinutes,
        'break_duration': _breakDuration,
        'is_default': _isDefault,
        'required_daily_hours': _requiredDailyHours,
        'allow_partial_checkout': _allowPartialCheckout,
        'max_sessions_per_day': _maxSessionsPerDay,
        'variable_schedule_type': _variableScheduleType,
        'schedule_config': _isSplitMode ? {'periods': _splitPeriods} : {},
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
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _sectionTitle(String ar, String en) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(isAr ? ar : en,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kShiftColor)),
    );
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
        child: Text(isAr ? ar : en,
            style: TextStyle(
              color: value ? Colors.white : Colors.grey[700],
              fontSize: 12,
              fontWeight: value ? FontWeight.bold : FontWeight.normal,
            )),
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
            isEdit ? (isAr ? 'تعديل الشيفت' : 'Edit Shift') : (isAr ? 'شيفت جديد' : 'New Shift'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: kShiftColor, foregroundColor: Colors.white,
        ),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            // ── اسم الشيفت ──
            Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionTitle('اسم الشيفت', 'Shift Name'),
                  TextFormField(controller: _nameCtrl,
                    decoration: InputDecoration(labelText: isAr ? 'اسم الشيفت *' : 'Shift Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.label, color: kShiftColor)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? (isAr ? 'مطلوب' : 'Required') : null),
                ]))),
            const SizedBox(height: 12),

            // ── نمط الشيفت ──
            Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionTitle('نمط الشيفت', 'Shift Mode'),
                  DropdownButtonFormField<String>(initialValue: _shiftMode,
                    decoration: InputDecoration(labelText: isAr ? 'اختر النمط' : 'Select Mode',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.category, color: kShiftColor)),
                    items: _shiftModes.map((m) => DropdownMenuItem<String>(
                      value: m['value'], child: Text(isAr ? m['ar']! : m['en']!))).toList(),
                    onChanged: (v) => _onShiftModeChanged(v ?? 'fixed')),
                  const SizedBox(height: 8),
                  _buildModeDescription(),
                ]))),
            const SizedBox(height: 12),

            // ── التوقيت ──
            if (!_isFlexMode && !_isSplitMode)
              Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(padding: const EdgeInsets.all(16), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionTitle('التوقيت', 'Time'),
                    DropdownButtonFormField<String>(initialValue: _timePreset,
                      decoration: InputDecoration(labelText: isAr ? 'توقيت سريع' : 'Quick Preset',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.flash_on, color: Colors.amber)),
                      items: _timePresets.map((p) => DropdownMenuItem<String>(
                        value: p['value'], child: Text(isAr ? p['ar']! : p['en']!))).toList(),
                      onChanged: (v) => _applyTimePreset(v ?? 'custom')),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: InkWell(onTap: () => _pickTime(isStart: true),
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: isAr ? 'بداية' : 'Start',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.login, color: Colors.green)),
                          child: Text(_fmtTime(_startTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))),
                      const SizedBox(width: 12),
                      Expanded(child: InkWell(onTap: () => _pickTime(isStart: false),
                        child: InputDecorator(
                          decoration: InputDecoration(labelText: isAr ? 'نهاية' : 'End',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.logout, color: Colors.red)),
                          child: Text(_fmtTime(_endTime), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))))),
                    ]),
                    const SizedBox(height: 12),
                    SwitchListTile(title: Text(isAr ? 'يمتد لليوم التالي (ليلي)' : 'Crosses midnight'),
                      secondary: const Icon(Icons.nights_stay, color: kShiftColor),
                      value: _crossesMidnight, activeThumbColor: kShiftColor,
                      onChanged: (v) => setState(() => _crossesMidnight = v)),
                  ]))),

            // ── ساعات العمل المرنة ──
            if (_isFlexMode)
              Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(padding: const EdgeInsets.all(16), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionTitle('ساعات العمل المرنة', 'Flexible Hours'),
                    Text(isAr ? 'عدد الساعات المطلوبة يوميًا: ${_requiredDailyHours.toStringAsFixed(1)} ساعة'
                        : 'Required daily hours: ${_requiredDailyHours.toStringAsFixed(1)} hrs',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    Slider(value: _requiredDailyHours, min: 1, max: 16, divisions: 30,
                      activeColor: kShiftColor, label: _requiredDailyHours.toStringAsFixed(1),
                      onChanged: (v) => setState(() => _requiredDailyHours = v)),
                  ]))),
            const SizedBox(height: 12),

            // ── فترات التقسيم (split_fixed) ──
            if (_isSplitMode)
              Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(padding: const EdgeInsets.all(16), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: _sectionTitle('فترات الشيفت', 'Shift Periods')),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            final n = _splitPeriods.length + 1;
                            _splitPeriods.add({'name': 'فترة $n', 'start': '09:00', 'end': '13:00'});
                            _maxSessionsPerDay = _splitPeriods.length;
                          });
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(isAr ? 'فترة جديدة' : 'Add Period')),
                    ]),
                    const SizedBox(height: 8),
                    ..._splitPeriods.asMap().entries.map((entry) {
                      final i = entry.key;
                      final period = entry.value;
                      return Card(
                        color: Colors.grey[50],
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
                          Row(children: [
                            Icon(Icons.schedule, color: kShiftColor, size: 18),
                            const SizedBox(width: 6),
                            Text('${isAr ? 'فترة' : 'Period'} ${i + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: kShiftColor)),
                            const Spacer(),
                            if (_splitPeriods.length > 1)
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                onPressed: () => setState(() {
                                  _splitPeriods.removeAt(i);
                                  _maxSessionsPerDay = _splitPeriods.length;
                                })),
                          ]),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: period['name'],
                            decoration: InputDecoration(
                              labelText: isAr ? 'اسم الفترة' : 'Period Name',
                              border: const OutlineInputBorder(), isDense: true),
                            onChanged: (v) => _splitPeriods[i]['name'] = v),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: InkWell(
                              onTap: () async {
                                final t = await _pickPeriodTime(_parseTime(period['start'] ?? '09:00'));
                                if (t != null) setState(() => _splitPeriods[i]['start'] = _fmtTime(t));
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: isAr ? 'بداية' : 'Start',
                                  border: const OutlineInputBorder(), isDense: true,
                                  prefixIcon: const Icon(Icons.login, color: Colors.green, size: 18)),
                                child: Text(period['start'] ?? '09:00',
                                    style: const TextStyle(fontWeight: FontWeight.bold))))),
                            const SizedBox(width: 8),
                            Expanded(child: InkWell(
                              onTap: () async {
                                final t = await _pickPeriodTime(_parseTime(period['end'] ?? '13:00'));
                                if (t != null) setState(() => _splitPeriods[i]['end'] = _fmtTime(t));
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: isAr ? 'نهاية' : 'End',
                                  border: const OutlineInputBorder(), isDense: true,
                                  prefixIcon: const Icon(Icons.logout, color: Colors.red, size: 18)),
                                child: Text(period['end'] ?? '13:00',
                                    style: const TextStyle(fontWeight: FontWeight.bold))))),
                          ]),
                        ])),
                      );
                    }),
                    const Divider(),
                    SwitchListTile(
                      title: Text(isAr ? 'يسمح بخروج جزئي' : 'Allow partial checkout'),
                      subtitle: Text(isAr ? 'الموظف يقدر يخرج ويرجع يكمل' : 'Employee can leave and return',
                          style: const TextStyle(fontSize: 12)),
                      secondary: const Icon(Icons.exit_to_app, color: kShiftColor),
                      value: _allowPartialCheckout, activeThumbColor: kShiftColor,
                      onChanged: (v) => setState(() => _allowPartialCheckout = v)),
                  ]))),

            // ── إعدادات المتغير ──
            if (_isVariableMode)
              Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(padding: const EdgeInsets.all(16), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionTitle('الجدول المتغير', 'Variable Schedule'),
                    Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.withAlpha(13),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue.withAlpha(50))),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(child: Text(isAr ? 'الجدول المتغير يتحدد بعد إنشاء الشيفت من شاشة التعيين'
                            : 'Variable schedule will be configured after creating the shift',
                            style: const TextStyle(fontSize: 12, color: Colors.blue))),
                      ])),
                  ]))),
            const SizedBox(height: 12),

            // ── السماحيات ──
            Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionTitle('السماحيات', 'Grace Periods'),
                  Text(isAr ? 'سماحية التأخير: $_gracePeriod دقيقة' : 'Late grace: $_gracePeriod min',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Slider(value: _gracePeriod.toDouble(), min: 0, max: 60, divisions: 12, activeColor: kShiftColor,
                      label: '$_gracePeriod', onChanged: (v) => setState(() => _gracePeriod = v.round())),
                  const SizedBox(height: 8),
                  Text(isAr ? 'سماحية الانصراف المبكر: $_graceEarlyLeave دقيقة' : 'Early leave grace: $_graceEarlyLeave min',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Slider(value: _graceEarlyLeave.toDouble(), min: 0, max: 60, divisions: 12, activeColor: Colors.orange,
                      label: '$_graceEarlyLeave', onChanged: (v) => setState(() => _graceEarlyLeave = v.round())),
                  const SizedBox(height: 8),
                  Text(isAr ? 'مسموح الحضور قبل الشيفت بـ: $_earlyCheckinMinutes دقيقة' : 'Early check-in: $_earlyCheckinMinutes min',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Slider(value: _earlyCheckinMinutes.toDouble(), min: 0, max: 120, divisions: 12, activeColor: Colors.blue,
                      label: '$_earlyCheckinMinutes', onChanged: (v) => setState(() => _earlyCheckinMinutes = v.round())),
                  const SizedBox(height: 8),
                  Text(isAr ? 'وقت الراحة: $_breakDuration دقيقة' : 'Break: $_breakDuration min',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Slider(value: _breakDuration.toDouble(), min: 0, max: 120, divisions: 12, activeColor: Colors.green,
                      label: '$_breakDuration', onChanged: (v) => setState(() => _breakDuration = v.round())),
                ]))),
            const SizedBox(height: 12),

            // ── أيام العمل ──
            Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(padding: const EdgeInsets.all(16), child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _sectionTitle('أيام العمل', 'Work Days'),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _dayToggle('أحد', 'Sun', _workSunday, (v) => setState(() => _workSunday = v)),
                    _dayToggle('اثنين', 'Mon', _workMonday, (v) => setState(() => _workMonday = v)),
                    _dayToggle('ثلاثاء', 'Tue', _workTuesday, (v) => setState(() => _workTuesday = v)),
                    _dayToggle('أربعاء', 'Wed', _workWednesday, (v) => setState(() => _workWednesday = v)),
                    _dayToggle('خميس', 'Thu', _workThursday, (v) => setState(() => _workThursday = v)),
                    _dayToggle('جمعة', 'Fri', _workFriday, (v) => setState(() => _workFriday = v)),
                    _dayToggle('سبت', 'Sat', _workSaturday, (v) => setState(() => _workSaturday = v)),
                  ]),
                ]))),
            const SizedBox(height: 12),

            // ── شيفت افتراضي ──
            Card(elevation: 1, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(padding: const EdgeInsets.all(8),
                child: SwitchListTile(
                  title: Text(isAr ? 'شيفت افتراضي للشركة' : 'Default company shift'),
                  subtitle: Text(isAr ? 'يُستخدم لو مفيش شيفت محدد للموظف' : 'Used when no shift is assigned',
                      style: const TextStyle(fontSize: 12)),
                  secondary: const Icon(Icons.star, color: Colors.amber),
                  value: _isDefault, activeThumbColor: kShiftColor,
                  onChanged: (v) => setState(() => _isDefault = v)))),
            const SizedBox(height: 12),

            // ── ملخص ──
            Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kShiftColor.withAlpha(13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kShiftColor.withAlpha(50))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isAr ? 'ملخص سريع' : 'Quick Summary',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: kShiftColor)),
                const SizedBox(height: 8),
                Text('${isAr ? 'النمط' : 'Mode'}: ${_shiftModes.firstWhere((m) => m['value'] == _shiftMode, orElse: () => _shiftModes.first)[isAr ? 'ar' : 'en']}'),
                if (!_isFlexMode && !_isSplitMode)
                  Text('${isAr ? 'الوقت' : 'Time'}: ${_fmtTime(_startTime)} → ${_fmtTime(_endTime)}${_crossesMidnight ? (isAr ? ' (+ يوم)' : ' (+1 day)') : ''}'),
                if (_isFlexMode)
                  Text('${isAr ? 'ساعات مطلوبة' : 'Required hours'}: ${_requiredDailyHours.toStringAsFixed(1)} ${isAr ? 'ساعة' : 'hrs'}'),
                if (_isSplitMode) ...[
                  Text('${isAr ? 'عدد الفترات' : 'Periods'}: ${_splitPeriods.length}'),
                  ..._splitPeriods.map((p) => Text(
                    '  • ${p['name']}: ${p['start']} → ${p['end']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                ],
                if (_isDefault)
                  Text(isAr ? '⭐ شيفت افتراضي' : '⭐ Default shift',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ])),
            const SizedBox(height: 20),

            SizedBox(width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: kShiftColor, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? (isAr ? 'حفظ التعديلات ✓' : 'Save ✓') : (isAr ? 'إنشاء الشيفت ✓' : 'Create ✓'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }

  Widget _buildModeDescription() {
    final descriptions = {
      'fixed': isAr ? 'وقت ثابت كل يوم — حضور وانصراف عادي' : 'Fixed daily time — regular check-in/out',
      'flex_fixed': isAr ? 'عدد ساعات ثابت يوميًا — يبدأ من أول حضور' : 'Fixed daily hours — starts from first check-in',
      'flex_split': isAr ? 'عدد ساعات ثابت — يقدر يقسمهم على أكتر من فترة' : 'Fixed hours — can split across multiple sessions',
      'variable_daily': isAr ? 'كل يوم ممكن يكون بتوقيت مختلف' : 'Each day can have different timing',
      'variable_weekly': isAr ? 'جدول أسبوعي ثابت — كل يوم بتوقيته' : 'Fixed weekly schedule — each day has its time',
      'variable_weekly_flex': isAr ? 'جدول أسبوعي — بعض الأيام ثابتة وبعضها مرنة' : 'Weekly schedule — some days fixed, some flex',
      'split_fixed': isAr ? 'فترات ثابتة في اليوم — كل فترة لها بداية ونهاية' : 'Fixed periods per day — each with start and end time',
    };
    return Container(padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: kShiftColor.withAlpha(13), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.info_outline, size: 16, color: kShiftColor),
        const SizedBox(width: 8),
        Expanded(child: Text(descriptions[_shiftMode] ?? '',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
      ]));
  }
}