// lib/screens/manager/installments_screen.dart
//
// السلف والأقساط (زي تبويب "السلف والأقساط" في الإدخالات اليدوية بالويب):
// القائمة، إضافة سلفة جديدة، وإلغاء سلفة.
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_client.dart';

const String _kBase = 'https://jssolutions-eg.com/attendance/api/mobile/manager';
const Color _kPrimary = Color(0xFF382483);

Map<String, dynamic> _decode(List<int> b) {
  try {
    final d = jsonDecode(utf8.decode(b));
    return d is Map<String, dynamic> ? d : {};
  } catch (_) {
    return {};
  }
}

String _money(dynamic v) {
  final n = v is num ? v : num.tryParse('${v ?? ''}') ?? 0;
  return n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
}

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});
  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _search = '';

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get(Uri.parse('$_kBase/entries/installment/'));
      final d = _decode(res.bodyBytes);
      if (res.statusCode != 200 || d['success'] == false) {
        throw Exception(d['error'] ?? (isAr ? 'فشل التحميل' : 'Failed to load'));
      }
      _items = (d['results'] as List? ?? []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'.replaceFirst('Exception: ', ''))));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cancel(Map<String, dynamic> it) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(isAr
            ? 'متأكد إنك عايز تلغي السلفة دي؟ مش هتتخصم من المرتبات الجاية.'
            : 'Cancel this advance? It will not be deducted from future salaries.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAr ? 'لا' : 'No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isAr ? 'إلغاء السلفة' : 'Cancel advance', style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final res = await ApiClient.post(Uri.parse('$_kBase/entries/installment/${it['id']}/cancel/'));
      final d = _decode(res.bodyBytes);
      if (d['success'] != true) throw Exception(d['error'] ?? (isAr ? 'فشل الإلغاء' : 'Failed'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${d['message'] ?? (isAr ? 'تم الإلغاء' : 'Cancelled')}'), backgroundColor: Colors.green));
        if ('${d['warning'] ?? ''}'.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${d['warning']}'), backgroundColor: Colors.orange));
        }
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'.replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
  }

  String _status(String s) {
    switch (s) {
      case 'active': return isAr ? 'نشط' : 'Active';
      case 'completed': return isAr ? 'منتهي' : 'Completed';
      case 'cancelled': return isAr ? 'ملغي' : 'Cancelled';
      default: return s;
    }
  }

  Color _statusColor(String s) => s == 'active'
      ? Colors.green.shade700
      : s == 'cancelled' ? Colors.red.shade700 : Colors.grey.shade700;

  @override
  Widget build(BuildContext context) {
    final q = _search.trim().toLowerCase();
    final list = q.isEmpty
        ? _items
        : _items.where((i) => '${i['employee_name'] ?? ''}'.toLowerCase().contains(q) ||
            '${i['description'] ?? ''}'.toLowerCase().contains(q)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'السلف والأقساط' : 'Advances & Installments'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(isAr ? 'إضافة سلفة' : 'Add advance'),
        onPressed: () async {
          final saved = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => const AddInstallmentScreen()));
          if (saved == true) _load();
        },
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: isAr ? 'ابحث بالاسم...' : 'Search by name...',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: list.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 100),
                          Center(child: Text(isAr ? 'لا توجد سلف' : 'No advances')),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          itemCount: list.length,
                          itemBuilder: (_, i) {
                            final it = list[i];
                            final s = '${it['status'] ?? ''}';
                            final c = _statusColor(s);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text('${it['employee_name'] ?? ''}',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                      child: Text(_status(s), style: TextStyle(fontSize: 12, color: c)),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text('${it['description'] ?? ''}'),
                                  const SizedBox(height: 6),
                                  Wrap(spacing: 14, runSpacing: 4, children: [
                                    Text('${isAr ? 'الإجمالي' : 'Total'}: ${_money(it['total_amount'])} ${isAr ? 'ج.م' : 'EGP'}'),
                                    Text('${isAr ? 'القسط الشهري' : 'Monthly'}: ${_money(it['monthly_amount'])}'),
                                    Text('${isAr ? 'المتبقي' : 'Remaining'}: ${_money(it['remaining_amount'])}',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text('${isAr ? 'بداية الخصم' : 'Starts'}: ${it['start_month']}/${it['start_year']}'),
                                  ]),
                                  if ('${it['notes'] ?? ''}'.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text('${it['notes']}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    ),
                                  if (s == 'active')
                                    Align(
                                      alignment: AlignmentDirectional.centerEnd,
                                      child: TextButton(
                                        onPressed: () => _cancel(it),
                                        child: Text(isAr ? 'إلغاء' : 'Cancel',
                                            style: const TextStyle(color: Colors.red)),
                                      ),
                                    ),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ]),
    );
  }
}

class AddInstallmentScreen extends StatefulWidget {
  const AddInstallmentScreen({super.key});
  @override
  State<AddInstallmentScreen> createState() => _AddInstallmentScreenState();
}

class _AddInstallmentScreenState extends State<AddInstallmentScreen> {
  List<Map<String, dynamic>> _employees = [];
  int? _employeeId;
  final _desc = TextEditingController();
  final _total = TextEditingController();
  final _monthly = TextEditingController();
  final _notes = TextEditingController();
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _saving = false;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    for (final c in [_desc, _total, _monthly, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    try {
      final res = await ApiClient.get(Uri.parse('$_kBase/employees/?page_size=1000'));
      final d = _decode(res.bodyBytes);
      final list = (d['results'] ?? d['employees']) as List? ?? [];
      if (mounted) {
        setState(() => _employees = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList());
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    final total = double.tryParse(_total.text.trim());
    final monthly = double.tryParse(_monthly.text.trim());
    if (_employeeId == null || _desc.text.trim().isEmpty || total == null || monthly == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'من فضلك املأ كل الحقول المطلوبة' : 'Please fill all required fields')));
      return;
    }
    if (total <= 0 || monthly <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'المبلغ والقسط الشهري لازم يكونوا أكبر من صفر' : 'Amount and monthly installment must be greater than zero')));
      return;
    }
    if (monthly > total) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'القسط الشهري مينفعش يكون أكبر من إجمالي السلفة' : 'Monthly installment cannot exceed the total')));
      return;
    }
    setState(() => _saving = true);
    try {
      final res = await ApiClient.post(
        Uri.parse('$_kBase/entries/installment/'),
        body: jsonEncode({
          'employee_id': _employeeId,
          'description': _desc.text.trim(),
          'total_amount': total,
          'monthly_amount': monthly,
          'start_month': _month,
          'start_year': _year,
          'notes': _notes.text.trim(),
        }),
      );
      final d = _decode(res.bodyBytes);
      if (d['success'] != true) throw Exception(d['error'] ?? (isAr ? 'فشل الإضافة' : 'Failed'));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${d['message'] ?? (isAr ? 'تم إضافة السلفة' : 'Advance added')}'),
            backgroundColor: Colors.green));
        if ('${d['warning'] ?? ''}'.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${d['warning']}'), backgroundColor: Colors.orange));
        }
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'.replaceFirst('Exception: ', '')), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  InputDecoration _dec(String l, {String? hint}) =>
      InputDecoration(labelText: l, hintText: hint, border: const OutlineInputBorder(), isDense: true);

  @override
  Widget build(BuildContext context) {
    final years = [DateTime.now().year - 1, DateTime.now().year, DateTime.now().year + 1];
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إضافة سلفة جديدة' : 'New advance'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        DropdownButtonFormField<int>(
          isExpanded: true,
          value: _employeeId,
          decoration: _dec(isAr ? 'الموظف *' : 'Employee *'),
          items: _employees
              .where((e) => e['id'] is int)
              .map((e) => DropdownMenuItem(
                    value: e['id'] as int,
                    child: Text('${e['full_name'] ?? e['name'] ?? ''} (${e['employee_code'] ?? ''})',
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _employeeId = v),
        ),
        const SizedBox(height: 12),
        TextField(controller: _desc, decoration: _dec(isAr ? 'وصف السلفة *' : 'Description *', hint: isAr ? 'مثال: سلفة طارئة' : 'e.g. emergency advance')),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
                controller: _total,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec(isAr ? 'إجمالي المبلغ *' : 'Total amount *')),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
                controller: _monthly,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec(isAr ? 'القسط الشهري *' : 'Monthly installment *')),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _month,
              decoration: _dec(isAr ? 'شهر بداية الخصم' : 'Start month'),
              items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
              onChanged: (v) => setState(() => _month = v ?? _month),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _year,
              decoration: _dec(isAr ? 'سنة بداية الخصم' : 'Start year'),
              items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
              onChanged: (v) => setState(() => _year = v ?? _year),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(controller: _notes, maxLines: 2, decoration: _dec(isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)')),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(46)),
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isAr ? 'إضافة السلفة' : 'Add advance'),
        ),
      ]),
    );
  }
}
