import 'package:flutter/material.dart';
import '../../../services/manual_entries_service.dart';
import '../../../services/lookups_service.dart';

const Color kManualColor = Color(0xFF37474F);

class ManualEntriesScreen extends StatefulWidget {
  const ManualEntriesScreen({super.key});

  @override
  State<ManualEntriesScreen> createState() => _ManualEntriesScreenState();
}

class _ManualEntriesScreenState extends State<ManualEntriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = false;

  List<dynamic> _penalties  = [];
  List<dynamic> _bonuses    = [];
  List<dynamic> _allowances = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ManualEntriesService.listPenalties(),
        ManualEntriesService.listBonuses(),
        ManualEntriesService.listAllowances(),
      ]);
      if (!mounted) return;
      setState(() {
        _penalties  = results[0];
        _bonuses    = results[1];
        _allowances = results[2];
        _loading    = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(String type, int id) async {
    final notesCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الموافقة'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('هل تريد الموافقة على هذا الإدخال؟'),
            const SizedBox(height: 10),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('موافقة'),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    try {
      if (type == 'penalty') {
        await ManualEntriesService.approvePenalty(id, notes: notesCtrl.text);
      } else if (type == 'bonus') {
        await ManualEntriesService.approveBonus(id, notes: notesCtrl.text);
      } else {
        await ManualEntriesService.approveAllowance(id, notes: notesCtrl.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت الموافقة'), backgroundColor: Colors.green),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject(String type, int id) async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الرفض'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('هل تريد رفض هذا الإدخال؟'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'سبب الرفض *',
                border: OutlineInputBorder(),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('رفض'),
            ),
          ],
        ),
      ),
    );
    if (confirm != true) return;

    try {
      if (type == 'penalty') {
        await ManualEntriesService.rejectPenalty(id, reason: reasonCtrl.text);
      } else if (type == 'bonus') {
        await ManualEntriesService.rejectBonus(id, reason: reasonCtrl.text);
      } else {
        await ManualEntriesService.rejectAllowance(id, reason: reasonCtrl.text);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الرفض'), backgroundColor: Colors.orange),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showCreateDialog(String type) async {
    final employees = await LookupsService.listEmployeesSimple();
    if (!mounted) return;

    int? selectedEmp;
    String amountType = 'fixed';
    double amountValue = 0;
    String reason = '';
    String category = type == 'penalty' ? 'performance' : type == 'bonus' ? 'performance' : 'travel';
    int targetYear  = DateTime.now().year;
    int targetMonth = DateTime.now().month;

    final amountTypes = [
      {'value': 'fixed',         'label': 'مبلغ ثابت'},
      {'value': 'quarter_day',   'label': 'ربع يوم'},
      {'value': 'half_day',      'label': 'نصف يوم'},
      {'value': 'full_day',      'label': 'يوم كامل'},
      {'value': 'two_days',      'label': 'يومين'},
      {'value': 'three_days',    'label': '3 أيام'},
      {'value': 'percent_basic', 'label': '% من الراتب الأساسي'},
    ];

    final penaltyCategories = [
      {'value': 'performance', 'label': 'قصور في الأداء'},
      {'value': 'discipline',  'label': 'مخالفة سلوكية'},
      {'value': 'attendance',  'label': 'مشكلة حضور'},
      {'value': 'safety',      'label': 'مخالفة سلامة'},
      {'value': 'quality',     'label': 'مشكلة جودة عمل'},
      {'value': 'other',       'label': 'أخرى'},
    ];

    final bonusCategories = [
      {'value': 'performance',       'label': 'أداء متميز'},
      {'value': 'goal_achievement',  'label': 'تحقيق هدف'},
      {'value': 'project_completion','label': 'إتمام مشروع'},
      {'value': 'extra_effort',      'label': 'مجهود إضافي'},
      {'value': 'loyalty',           'label': 'ولاء وسنوات خدمة'},
      {'value': 'referral',          'label': 'ترشيح موظف جديد'},
      {'value': 'other',             'label': 'أخرى'},
    ];

    final allowanceCategories = [
      {'value': 'travel',          'label': 'بدل سفر'},
      {'value': 'field_visit',     'label': 'بدل زيارة ميدانية'},
      {'value': 'overtime_meal',   'label': 'بدل وجبة أوفرتايم'},
      {'value': 'special_project', 'label': 'بدل مشروع خاص'},
      {'value': 'training',        'label': 'بدل تدريب'},
      {'value': 'conference',      'label': 'بدل مؤتمر/دورة'},
      {'value': 'other',           'label': 'أخرى'},
    ];

    final categories = type == 'penalty' ? penaltyCategories
        : type == 'bonus' ? bonusCategories : allowanceCategories;

    final typeLabel = type == 'penalty' ? 'جزاء' : type == 'bonus' ? 'مكافأة' : 'بدل';
    final typeColor = type == 'penalty' ? Colors.red : type == 'bonus' ? Colors.green : Colors.orange;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text('إضافة $typeLabel يدوي',
                style: TextStyle(color: typeColor, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // موظف
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'الموظف *', border: OutlineInputBorder(), isDense: true),
                  hint: const Text('-- اختر --'),
                  items: employees.map<DropdownMenuItem<int>>((e) => DropdownMenuItem(
                    value: e['id'] as int,
                    child: Text('${e['full_name'] ?? ''} (${e['employee_code'] ?? ''})'),
                  )).toList(),
                  onChanged: (v) => setS(() => selectedEmp = v),
                ),
                const SizedBox(height: 10),
                // النوع
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'النوع', border: OutlineInputBorder(), isDense: true),
                  items: categories.map((c) => DropdownMenuItem(
                    value: c['value'],
                    child: Text(c['label']!),
                  )).toList(),
                  onChanged: (v) => setS(() => category = v ?? category),
                ),
                const SizedBox(height: 10),
                // نوع المبلغ
                DropdownButtonFormField<String>(
                  initialValue: amountType,
                  decoration: const InputDecoration(labelText: 'نوع المبلغ', border: OutlineInputBorder(), isDense: true),
                  items: amountTypes.map((a) => DropdownMenuItem(
                    value: a['value'],
                    child: Text(a['label']!),
                  )).toList(),
                  onChanged: (v) => setS(() => amountType = v ?? amountType),
                ),
                const SizedBox(height: 10),
                // القيمة
                TextFormField(
                  initialValue: '0',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'القيمة (EGP أو %)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => amountValue = double.tryParse(v) ?? 0,
                ),
                const SizedBox(height: 10),
                // السنة والشهر
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: targetYear.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'السنة', border: OutlineInputBorder(), isDense: true),
                      onChanged: (v) => targetYear = int.tryParse(v) ?? targetYear,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: targetMonth.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'الشهر (1-12)', border: OutlineInputBorder(), isDense: true),
                      onChanged: (v) => targetMonth = int.tryParse(v) ?? targetMonth,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                // السبب
                TextFormField(
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'السبب *',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => reason = v,
                ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: typeColor),
                child: const Text('إضافة'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (saved != true) return;
    if (selectedEmp == null || reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الموظف والسبب مطلوبان'), backgroundColor: Colors.red),
      );
      return;
    }

    final data = {
      'employee': selectedEmp,
      'category': category,
      'amount_type': amountType,
      'amount_value': amountValue,
      'reason': reason.trim(),
      'target_year': targetYear,
      'target_month': targetMonth,
    };

    try {
      if (type == 'penalty') {
        await ManualEntriesService.createPenalty(data);
      } else if (type == 'bonus') {
        await ManualEntriesService.createBonus(data);
      } else {
        await ManualEntriesService.createAllowance(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إضافة $typeLabel'), backgroundColor: Colors.green),
      );
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _statusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':  color = Colors.orange; label = 'قيد الموافقة'; break;
      case 'approved': color = Colors.green;  label = 'تمت الموافقة'; break;
      case 'rejected': color = Colors.red;    label = 'مرفوض';        break;
      case 'applied':  color = Colors.blue;   label = 'مطبق';         break;
      default:         color = Colors.grey;   label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _entryCard(dynamic entry, String type) {
    final status    = entry['status'] ?? 'pending';
    final empName   = entry['employee_name'] ?? entry['employee'] ?? '';
    final reason    = entry['reason'] ?? '';
    final amount    = entry['amount_type'] ?? '';
    final value     = entry['amount_value'] ?? '';
    final month     = entry['target_month'] ?? '';
    final year      = entry['target_year'] ?? '';
    final isPending = status == 'pending';
    final typeColor = type == 'penalty' ? Colors.red : type == 'bonus' ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: typeColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(empName.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            _statusChip(status),
          ]),
          const SizedBox(height: 6),
          Text(reason.toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(Icons.calendar_month, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text('$year/$month', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(width: 12),
            Icon(Icons.attach_money, size: 13, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text('$amount${value.toString().isNotEmpty ? " — $value" : ""}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ]),
          if (isPending) ...[
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reject(type, entry['id'] as int),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('رفض', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approve(type, entry['id'] as int),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('موافقة', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  Widget _tabContent(List<dynamic> entries, String type, String emptyMsg) {
    final typeColor = type == 'penalty' ? Colors.red : type == 'bonus' ? Colors.green : Colors.orange;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: ElevatedButton.icon(
          onPressed: () => _showCreateDialog(type),
          icon: const Icon(Icons.add),
          label: Text(type == 'penalty' ? 'إضافة جزاء يدوي'
              : type == 'bonus' ? 'إضافة مكافأة يدوية' : 'إضافة بدل يدوي'),
          style: ElevatedButton.styleFrom(
            backgroundColor: typeColor,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 44),
          ),
        ),
      ),
      Expanded(
        child: entries.isEmpty
            ? Center(child: Text(emptyMsg, style: TextStyle(color: Colors.grey.shade500)))
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: entries.map((e) => _entryCard(e, type)).toList(),
              ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('الإدخالات اليدوية'),
          backgroundColor: kManualColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: TabBar(
            controller: _tabCtrl,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'جزاءات', icon: Icon(Icons.trending_down, size: 18)),
              Tab(text: 'مكافآت', icon: Icon(Icons.trending_up, size: 18)),
              Tab(text: 'بدلات',  icon: Icon(Icons.attach_money, size: 18)),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _tabContent(_penalties,  'penalty',  'لا توجد جزاءات'),
                  _tabContent(_bonuses,    'bonus',    'لا توجد مكافآت'),
                  _tabContent(_allowances, 'allowance','لا توجد بدلات'),
                ],
              ),
      ),
    );
  }
}
