import 'package:flutter/material.dart';
import '../../../services/shifts_service.dart';

const Color kManagerColor = Color(0xFF6A1B9A);

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
  String _shiftType = 'morning';
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _gracePeriod = 15;
  int _breakDuration = 60;
  bool _workSunday = true;
  bool _workMonday = true;
  bool _workTuesday = true;
  bool _workWednesday = true;
  bool _workThursday = true;
  bool _workFriday = false;
  bool _workSaturday = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final s = widget.existingShift!;
      _nameCtrl.text = s['name'] ?? '';
      _shiftType = s['shift_type'] ?? 'morning';
      _gracePeriod = s['grace_period'] ?? 15;
      _breakDuration = s['break_duration'] ?? 60;
      _workSunday = s['work_sunday'] ?? true;
      _workMonday = s['work_monday'] ?? true;
      _workTuesday = s['work_tuesday'] ?? true;
      _workWednesday = s['work_wednesday'] ?? true;
      _workThursday = s['work_thursday'] ?? true;
      _workFriday = s['work_friday'] ?? false;
      _workSaturday = s['work_saturday'] ?? false;
      if (s['start_time'] != null) {
        final parts = s['start_time'].toString().split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (s['end_time'] != null) {
        final parts = s['end_time'].toString().split(':');
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
    if (picked != null) setState(() => isStart ? _startTime = picked : _endTime = picked);
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
        'grace_period': _gracePeriod,
        'break_duration': _breakDuration,
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _dayToggle(String labelAr, String labelEn, bool value, ValueChanged<bool> onChanged) =>
      InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: value ? kManagerColor : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: value ? kManagerColor : Colors.grey[300]!),
          ),
          child: Text(
            isAr ? labelAr : labelEn,
            style: TextStyle(
              color: value ? Colors.white : Colors.grey[700],
              fontSize: 12,
              fontWeight: value ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit
              ? (isAr ? 'تعديل الشيفت' : 'Edit Shift')
              : (isAr ? 'شيفت جديد' : 'New Shift')),
          backgroundColor: kManagerColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            // Name
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم الشيفت *' : 'Shift Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.label, color: kManagerColor),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? (isAr ? 'مطلوب' : 'Required') : null,
            ),
            const SizedBox(height: 14),
            // Shift type
            DropdownButtonFormField<String>(
              value: _shiftType,
              decoration: InputDecoration(
                labelText: isAr ? 'نوع الشيفت' : 'Shift Type',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.category, color: kManagerColor),
              ),
              items: [
                DropdownMenuItem(value: 'morning', child: Text(isAr ? '🌅 صباحي' : '🌅 Morning')),
                DropdownMenuItem(value: 'evening', child: Text(isAr ? '🌆 مسائي' : '🌆 Evening')),
                DropdownMenuItem(value: 'night', child: Text(isAr ? '🌙 ليلي' : '🌙 Night')),
                DropdownMenuItem(value: 'flexible', child: Text(isAr ? '⏱ مرن' : '⏱ Flexible')),
                DropdownMenuItem(value: 'split', child: Text(isAr ? '✂ مقسم' : '✂ Split')),
              ],
              onChanged: (v) => setState(() => _shiftType = v ?? 'morning'),
            ),
            const SizedBox(height: 14),
            // Times
            Row(children: [
              Expanded(child: InkWell(
                onTap: () => _pickTime(isStart: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: isAr ? 'وقت البداية' : 'Start Time',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.login, color: Colors.green),
                  ),
                  child: Text(_fmtTime(_startTime),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: InkWell(
                onTap: () => _pickTime(isStart: false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: isAr ? 'وقت النهاية' : 'End Time',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.logout, color: Colors.red),
                  ),
                  child: Text(_fmtTime(_endTime),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )),
            ]),
            const SizedBox(height: 14),
            // Grace period
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isAr ? 'فترة السماح (دقيقة): $_gracePeriod' : 'Grace Period (min): $_gracePeriod',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Slider(
                  value: _gracePeriod.toDouble(),
                  min: 0, max: 60, divisions: 12,
                  activeColor: kManagerColor,
                  onChanged: (v) => setState(() => _gracePeriod = v.round()),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(isAr ? 'فترة الراحة (دقيقة): $_breakDuration' : 'Break (min): $_breakDuration',
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                Slider(
                  value: _breakDuration.toDouble(),
                  min: 0, max: 120, divisions: 12,
                  activeColor: Colors.orange,
                  onChanged: (v) => setState(() => _breakDuration = v.round()),
                ),
              ])),
            ]),
            const SizedBox(height: 14),
            // Work days
            Text(isAr ? 'أيام العمل:' : 'Work Days:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _dayToggle('أحد', 'Sun', _workSunday, (v) => setState(() => _workSunday = v)),
              _dayToggle('اثنين', 'Mon', _workMonday, (v) => setState(() => _workMonday = v)),
              _dayToggle('ثلاثاء', 'Tue', _workTuesday, (v) => setState(() => _workTuesday = v)),
              _dayToggle('أربعاء', 'Wed', _workWednesday, (v) => setState(() => _workWednesday = v)),
              _dayToggle('خميس', 'Thu', _workThursday, (v) => setState(() => _workThursday = v)),
              _dayToggle('جمعة', 'Fri', _workFriday, (v) => setState(() => _workFriday = v)),
              _dayToggle('سبت', 'Sat', _workSaturday, (v) => setState(() => _workSaturday = v)),
            ]),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kManagerColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        isEdit
                            ? (isAr ? 'حفظ التعديلات ✓' : 'Save Changes ✓')
                            : (isAr ? 'إنشاء الشيفت ✓' : 'Create Shift ✓'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
