import 'package:flutter/material.dart';
import '../../services/official_holidays_service.dart';

const Color kOfficialHolidayColor = Color(0xFF6A1B9A);

class OfficialHolidaysScreen extends StatefulWidget {
  const OfficialHolidaysScreen({super.key});

  @override
  State<OfficialHolidaysScreen> createState() => _OfficialHolidaysScreenState();
}

class _OfficialHolidaysScreenState extends State<OfficialHolidaysScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  List<Map<String, dynamic>> _holidays = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final holidays = await OfficialHolidaysService.getHolidays();
      setState(() {
        _holidays = holidays;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _delete(Map<String, dynamic> holiday) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'حذف الإجازة الرسمية' : 'Delete Holiday'),
          content: Text(
            '${isAr ? 'هل تريد حذف' : 'Delete'} "${holiday['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'تراجع' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                isAr ? 'حذف' : 'Delete',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await OfficialHolidaysService.deleteHoliday(holiday['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم حذف الإجازة' : 'Holiday deleted'),
          backgroundColor: Colors.green,
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _treatmentLabel(String t, bool ar) {
    switch (t) {
      case 'paid_leave':
        return ar ? 'إجازة مدفوعة' : 'Paid Leave';
      case 'work_with_bonus':
        return ar ? 'عمل بمقابل إضافي' : 'Work with Bonus';
      case 'normal_work':
        return ar ? 'يوم عمل عادي' : 'Normal Work';
      default:
        return t;
    }
  }

  Color _treatmentColor(String t) {
    switch (t) {
      case 'paid_leave':
        return Colors.green;
      case 'work_with_bonus':
        return Colors.orange;
      case 'normal_work':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'الإجازات الرسمية' : 'Official Holidays',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: kOfficialHolidayColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: kOfficialHolidayColor,
                ),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 60),
                        const SizedBox(height: 12),
                        Text(_error ?? ''),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kOfficialHolidayColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
                        ),
                      ],
                    ),
                  )
                : _holidays.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.celebration_outlined,
                                size: 80, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              isAr
                                  ? 'لا توجد إجازات رسمية'
                                  : 'No official holidays',
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isAr
                                  ? 'اضغط + لإضافة إجازة رسمية'
                                  : 'Press + to add a holiday',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _holidays.length,
                          itemBuilder: (_, i) => _buildCard(_holidays[i]),
                        ),
                      ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateEditOfficialHolidayScreen(),
              ),
            );
            if (result == true) _load();
          },
          backgroundColor: kOfficialHolidayColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            isAr ? 'إجازة رسمية جديدة' : 'New Holiday',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> holiday) {
    final rules = holiday['rules'] as List? ?? [];
    final daysCount = holiday['days_count'] ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: kOfficialHolidayColor.withAlpha(30),
                  child: const Icon(Icons.celebration,
                      color: kOfficialHolidayColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        holiday['name'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${holiday['start_date']} → ${holiday['end_date']}  ($daysCount ${isAr ? 'يوم' : 'days'})',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (rules.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: rules.map<Widget>((r) {
                  final treatment = r['treatment'] ?? 'paid_leave';
                  final scope = r['scope_display'] ?? '';
                  final color = _treatmentColor(treatment);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withAlpha(60)),
                    ),
                    child: Text(
                      '$scope: ${_treatmentLabel(treatment, isAr)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const Divider(height: 16),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateEditOfficialHolidayScreen(
                          holiday: holiday,
                        ),
                      ),
                    );
                    if (result == true) _load();
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(isAr ? 'تعديل' : 'Edit'),
                  style: TextButton.styleFrom(
                      foregroundColor: kOfficialHolidayColor),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () => _delete(holiday),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════
// شاشة إضافة / تعديل إجازة رسمية
// ══════════════════════════════════════════
class CreateEditOfficialHolidayScreen extends StatefulWidget {
  final Map<String, dynamic>? holiday;

  const CreateEditOfficialHolidayScreen({super.key, this.holiday});

  @override
  State<CreateEditOfficialHolidayScreen> createState() =>
      _CreateEditOfficialHolidayScreenState();
}

class _CreateEditOfficialHolidayScreenState
    extends State<CreateEditOfficialHolidayScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  bool get isEdit => widget.holiday != null;

  final _nameCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  bool _sendNotification = true;
  bool _remindDayBefore = false;
  bool _saving = false;

  List<Map<String, dynamic>> _rules = [
    {
      'scope': 'company',
      'treatment': 'paid_leave',
      'bonus_calc_method': '',
      'bonus_fixed_amount': 0.0,
      'bonus_salary_percentage': 0.0,
      'bonus_day_multiplier': 2.0,
      'priority': 1,
    }
  ];

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final h = widget.holiday!;
      _nameCtrl.text = h['name'] ?? '';
      _notesCtrl.text = h['notes'] ?? '';
      if (h['start_date'] != null) {
        _startDate = DateTime.tryParse(h['start_date']) ?? DateTime.now();
      }
      if (h['end_date'] != null) {
        _endDate = DateTime.tryParse(h['end_date']) ?? DateTime.now();
      }
      _sendNotification = h['send_notification'] ?? true;
      _remindDayBefore = h['remind_day_before'] ?? false;
      if ((h['rules'] as List? ?? []).isNotEmpty) {
        _rules = List<Map<String, dynamic>>.from(
          (h['rules'] as List).map((r) => Map<String, dynamic>.from(r)),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) _endDate = _startDate;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'اسم الإجازة مطلوب' : 'Holiday name required'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _saving = true);

    try {
      final body = {
        'name': _nameCtrl.text.trim(),
        'start_date': _fmt(_startDate),
        'end_date': _fmt(_endDate),
        'notes': _notesCtrl.text.trim(),
        'send_notification': _sendNotification,
        'remind_day_before': _remindDayBefore,
        'rules': _rules,
      };

      if (isEdit) {
        await OfficialHolidaysService.updateHoliday(
            widget.holiday!['id'], body);
      } else {
        await OfficialHolidaysService.createHoliday(body);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(isAr ? 'تم الحفظ بنجاح' : 'Saved successfully'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _scopeLabel(String s) {
    switch (s) {
      case 'company':
        return isAr ? 'الشركة كلها' : 'Whole Company';
      case 'branch':
        return isAr ? 'فرع محدد' : 'Specific Branch';
      case 'department':
        return isAr ? 'قسم محدد' : 'Specific Department';
      case 'employees':
        return isAr ? 'موظفين محددين' : 'Specific Employees';
      default:
        return s;
    }
  }

  String _treatmentLabel(String t) {
    switch (t) {
      case 'paid_leave':
        return isAr ? 'إجازة مدفوعة' : 'Paid Leave';
      case 'work_with_bonus':
        return isAr ? 'عمل بمقابل إضافي' : 'Work with Bonus';
      case 'normal_work':
        return isAr ? 'يوم عمل عادي' : 'Normal Work';
      default:
        return t;
    }
  }

  String _bonusMethodLabel(String m) {
    switch (m) {
      case 'fixed_amount':
        return isAr ? 'مبلغ ثابت' : 'Fixed Amount';
      case 'salary_percentage':
        return isAr ? 'نسبة من المرتب' : 'Salary Percentage';
      case 'day_multiplier':
        return isAr ? 'مضاعف أجر اليوم' : 'Day Multiplier';
      default:
        return isAr ? 'اختر طريقة الحساب' : 'Choose Method';
    }
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: kOfficialHolidayColor,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isEdit
                ? (isAr ? 'تعديل الإجازة الرسمية' : 'Edit Holiday')
                : (isAr ? 'إجازة رسمية جديدة' : 'New Official Holiday'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: kOfficialHolidayColor,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── البيانات الأساسية ──
            _sectionTitle(isAr ? 'البيانات الأساسية' : 'Basic Info'),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: isAr ? 'اسم الإجازة *' : 'Holiday Name *',
                prefixIcon: const Icon(Icons.celebration,
                    color: kOfficialHolidayColor),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isAr ? 'من تاريخ *' : 'From *',
                        prefixIcon: const Icon(Icons.calendar_today,
                            color: Colors.purple),
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        _fmt(_startDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _pickDate(isStart: false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: isAr ? 'إلى تاريخ *' : 'To *',
                        prefixIcon: const Icon(Icons.calendar_today,
                            color: Colors.purple),
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        _fmt(_endDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
                prefixIcon: const Icon(Icons.notes,
                    color: kOfficialHolidayColor),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(isAr ? 'إرسال إشعار للموظفين' : 'Notify Employees'),
              subtitle: Text(
                isAr
                    ? 'يتم الإرسال فور حفظ الإجازة'
                    : 'Sent immediately on save',
                style: const TextStyle(fontSize: 12),
              ),
              value: _sendNotification,
              activeThumbColor: kOfficialHolidayColor,
              onChanged: (v) => setState(() => _sendNotification = v),
            ),
            SwitchListTile(
              title: Text(
                  isAr ? 'تذكير قبل الإجازة بيوم' : 'Remind day before'),
              value: _remindDayBefore,
              activeThumbColor: kOfficialHolidayColor,
              onChanged: (v) => setState(() => _remindDayBefore = v),
            ),
            const SizedBox(height: 20),

            // ── القواعد ──
            Row(
              children: [
                Expanded(
                  child: _sectionTitle(
                      isAr ? 'القواعد والمعاملات' : 'Rules & Treatment'),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _rules.add({
                        'scope': 'company',
                        'treatment': 'paid_leave',
                        'bonus_calc_method': '',
                        'bonus_fixed_amount': 0.0,
                        'bonus_salary_percentage': 0.0,
                        'bonus_day_multiplier': 2.0,
                        'priority': _rules.length + 1,
                      })),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(isAr ? 'إضافة قاعدة' : 'Add Rule'),
                  style: TextButton.styleFrom(
                      foregroundColor: kOfficialHolidayColor),
                ),
              ],
            ),
            ..._rules.asMap().entries.map((e) {
              final i = e.key;
              final rule = e.value;
              final treatment = rule['treatment'] ?? 'paid_leave';

              return Card(
                color: Colors.grey[50],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: kOfficialHolidayColor.withAlpha(60),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${isAr ? 'قاعدة' : 'Rule'} ${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: kOfficialHolidayColor,
                            ),
                          ),
                          const Spacer(),
                          if (_rules.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                              onPressed: () =>
                                  setState(() => _rules.removeAt(i)),
                            ),
                        ],
                      ),
                      // النطاق
                      DropdownButtonFormField<String>(
                        initialValue: rule['scope'],
                        decoration: InputDecoration(
                          labelText: isAr ? 'يتطبق على' : 'Applies To',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: ['company', 'branch', 'department', 'employees']
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(_scopeLabel(s)),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => rule['scope'] = v ?? 'company'),
                      ),
                      const SizedBox(height: 10),
                      // المعاملة
                      DropdownButtonFormField<String>(
                        initialValue: treatment,
                        decoration: InputDecoration(
                          labelText: isAr ? 'نوع المعاملة' : 'Treatment',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          'paid_leave',
                          'work_with_bonus',
                          'normal_work',
                        ]
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(_treatmentLabel(t)),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                            () => rule['treatment'] = v ?? 'paid_leave'),
                      ),
                      // إعدادات المقابل الإضافي
                      if (treatment == 'work_with_bonus') ...[
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: rule['bonus_calc_method']?.isEmpty == true ? null : rule['bonus_calc_method'],
                          decoration: InputDecoration(
                            labelText: isAr
                                ? 'طريقة حساب المقابل'
                                : 'Bonus Calculation',
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          hint: Text(isAr
                              ? 'اختر طريقة الحساب'
                              : 'Choose method'),
                          items: [
                            'fixed_amount',
                            'salary_percentage',
                            'day_multiplier',
                          ]
                              .map((m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(_bonusMethodLabel(m)),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(
                              () => rule['bonus_calc_method'] = v ?? ''),
                        ),
                        const SizedBox(height: 10),
                        if (rule['bonus_calc_method'] == 'fixed_amount')
                          TextFormField(
                            initialValue:
                                rule['bonus_fixed_amount'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  isAr ? 'المبلغ الثابت' : 'Fixed Amount',
                              helperText: isAr
                                  ? 'مبلغ ثابت عن كل يوم اشتغله الموظف في الإجازة'
                                  : 'Fixed amount per worked holiday day',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => rule['bonus_fixed_amount'] =
                                double.tryParse(v) ?? 0.0,
                          ),
                        if (rule['bonus_calc_method'] == 'salary_percentage')
                          TextFormField(
                            initialValue:
                                rule['bonus_salary_percentage'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText:
                                  isAr ? 'النسبة % من المرتب' : 'Salary %',
                              helperText: isAr
                                  ? 'نسبة من المرتب الأساسي الشهري عن كل يوم'
                                  : 'Percentage of basic monthly salary per day',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) =>
                                rule['bonus_salary_percentage'] =
                                    double.tryParse(v) ?? 0.0,
                          ),
                        if (rule['bonus_calc_method'] == 'day_multiplier')
                          TextFormField(
                            initialValue:
                                rule['bonus_day_multiplier'].toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isAr
                                  ? 'مضاعف أجر اليوم'
                                  : 'Day Multiplier',
                              helperText: isAr
                                  ? 'مثال: 2 يعني ضعف أجر اليوم العادي'
                                  : 'e.g. 2 means double the daily rate',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (v) => rule['bonus_day_multiplier'] =
                                double.tryParse(v) ?? 2.0,
                          ),
                      ],
                      const SizedBox(height: 10),
                      TextFormField(
                        initialValue: rule['priority'].toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: isAr ? 'الأولوية' : 'Priority',
                          helperText: isAr
                              ? 'رقم أصغر = أولوية أعلى'
                              : 'Lower = higher priority',
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            rule['priority'] = int.tryParse(v) ?? 10,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kOfficialHolidayColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEdit
                          ? (isAr ? 'تعديل وحفظ' : 'Update & Save')
                          : (isAr ? 'حفظ الإجازة' : 'Save Holiday'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

