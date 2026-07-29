import 'package:motionhr_employee/services/api_client.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const Color kCompanyPoliciesColor = Color(0xFF1565C0);
const String _base = 'https://motion.jssolutions-eg.com/attendance/api/mobile/manager';

class CompanyPoliciesScreen extends StatefulWidget {
  const CompanyPoliciesScreen({super.key});
  @override
  State<CompanyPoliciesScreen> createState() => _CompanyPoliciesScreenState();
}

class _CompanyPoliciesScreenState extends State<CompanyPoliciesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'السياسات العامة' : 'Company Policies',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kCompanyPoliciesColor,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabs,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: isAr ? 'البدلات' : 'Allowances'),
              Tab(text: isAr ? 'الخصومات' : 'Deductions'),
              Tab(text: isAr ? 'المكافآت' : 'Bonuses'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabs,
          children: const [
            _PolicyTab(type: 'allowance'),
            _PolicyTab(type: 'deduction'),
            _PolicyTab(type: 'bonus'),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
class _PolicyTab extends StatefulWidget {
  final String type;
  const _PolicyTab({required this.type});
  @override
  State<_PolicyTab> createState() => _PolicyTabState();
}

class _PolicyTabState extends State<_PolicyTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  String get _endpoint {
    switch (widget.type) {
      case 'allowance': return '$_base/allowance-policies/';
      case 'deduction': return '$_base/deduction-policies/';
      default:          return '$_base/bonus-policies/';
    }
  }

  String get _title {
    switch (widget.type) {
      case 'allowance': return isAr ? 'بدل عام' : 'Allowance Policy';
      case 'deduction': return isAr ? 'خصم عام' : 'Deduction Policy';
      default:          return isAr ? 'مكافأة عامة' : 'Bonus Policy';
    }
  }

  Color get _color {
    switch (widget.type) {
      case 'allowance': return Colors.green;
      case 'deduction': return Colors.red;
      default:          return Colors.amber.shade700;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case 'allowance': return Icons.add_circle_outline;
      case 'deduction': return Icons.remove_circle_outline;
      default:          return Icons.card_giftcard;
    }
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    return ApiClient.buildHeaders(includeContentType: true);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final headers = await _headers();
      final res = await http.get(Uri.parse(_endpoint), headers: headers);
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        setState(() {
          _items = List<Map<String, dynamic>>.from(data['results'] ?? []);
          _loading = false;
        });
      } else {
        setState(() { _error = 'Error ${res.statusCode}'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _delete(int id) async {
    try {
      final headers = await _headers();
      await http.delete(Uri.parse('$_endpoint$id/'), headers: headers);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> item) async {
    try {
      final headers = await _headers();
      await http.put(
        Uri.parse('$_endpoint${item['id']}/'),
        headers: headers,
        body: json.encode({'is_active': !(item['is_active'] as bool)}),
      );
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) return Center(child: CircularProgressIndicator(color: _color));
    if (_error != null) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _load, child: Text(isAr ? 'إعادة المحاولة' : 'Retry')),
      ],
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _items.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_icon, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(isAr ? 'لا يوجد بعد' : 'Nothing yet',
                    style: const TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _items.length,
                itemBuilder: (_, i) => _buildCard(_items[i]),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push(context, MaterialPageRoute(
            builder: (_) => AddEditPolicyScreen(type: widget.type, endpoint: _endpoint),
          ));
          if (added == true) _load();
        },
        backgroundColor: _color,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_title, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final isActive = item['is_active'] as bool? ?? true;
    final scope = item['scope_display'] ?? item['scope'] ?? '';
    final amount = item['amount'] ?? 0;
    final typeDisplay = item['allowance_type_display']
        ?? item['deduction_type_display']
        ?? item['bonus_type_display']
        ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _color.withOpacity(0.12),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['name_ar'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(typeDisplay, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ])),
            Switch(
              value: isActive,
              activeColor: _color,
              onChanged: (_) => _toggleActive(item),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _chip(scope, kCompanyPoliciesColor),
            const SizedBox(width: 6),
            _chip(
              '${isAr ? 'المبلغ' : 'Amount'}: $amount ${isAr ? 'جنيه' : 'EGP'}',
              _color,
            ),
            if (item['is_monthly'] == true) ...[
              const SizedBox(width: 6),
              _chip(isAr ? 'شهري' : 'Monthly', Colors.teal),
            ],
          ]),
          const SizedBox(height: 4),
          Text(
            '${isAr ? 'من' : 'From'}: ${item['start_date'] ?? ''}${item['end_date'] != null ? '  ${isAr ? 'إلى' : 'To'}: ${item['end_date']}' : ''}',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
          const Divider(height: 16),
          Row(children: [
            TextButton.icon(
              onPressed: () async {
                final edited = await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AddEditPolicyScreen(
                    type: widget.type,
                    endpoint: _endpoint,
                    existing: item,
                  ),
                ));
                if (edited == true) _load();
              },
              icon: const Icon(Icons.edit, size: 16),
              label: Text(isAr ? 'تعديل' : 'Edit'),
              style: TextButton.styleFrom(foregroundColor: kCompanyPoliciesColor),
            ),
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text(isAr ? 'تأكيد الحذف' : 'Confirm Delete'),
                    content: Text(isAr ? 'هتحذف السياسة دي؟' : 'Delete this policy?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(isAr ? 'لا' : 'No')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: Text(isAr ? 'احذف' : 'Delete'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) _delete(item['id']);
              },
              icon: const Icon(Icons.delete_outline, size: 16),
              label: Text(isAr ? 'حذف' : 'Delete'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}

// ══════════════════════════════════════════════
// شاشة إضافة / تعديل سياسة
// ══════════════════════════════════════════════
class AddEditPolicyScreen extends StatefulWidget {
  final String type;
  final String endpoint;
  final Map<String, dynamic>? existing;
  const AddEditPolicyScreen({
    super.key,
    required this.type,
    required this.endpoint,
    this.existing,
  });
  @override
  State<AddEditPolicyScreen> createState() => _AddEditPolicyScreenState();
}

class _AddEditPolicyScreenState extends State<AddEditPolicyScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';
  bool get isEdit => widget.existing != null;

  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  final _nameArCtrl = TextEditingController();
  final _nameEnCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _startCtrl = TextEditingController();
  final _endCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _scope = 'company';
  bool _isMonthly = true;
  bool _isActive = true;

  String _selectedType = '';

  final _allowanceTypes = [
    'transport','housing','phone','meal','performance','clothing','risk',
    'supervision','shift_night','travel','remote_work','childcare','education',
    'medical','social','technical','representation','nature_of_work',
    'overtime_fixed','field','other',
  ];
  final _deductionTypes = [
    'social_insurance','health_insurance','tax','union_fee','savings',
    'parking','uniform','tools','loan_recovery','other',
  ];
  final _bonusTypes = [
    'incentive','eid','annual','performance','profit_share','attendance_bonus',
    'project_completion','referral','loyalty','ramadan','back_to_school',
    'marriage','newborn','other',
  ];

  List<String> get _types {
    switch (widget.type) {
      case 'allowance': return _allowanceTypes;
      case 'deduction': return _deductionTypes;
      default:          return _bonusTypes;
    }
  }

  String get _typeKey {
    switch (widget.type) {
      case 'allowance': return 'allowance_type';
      case 'deduction': return 'deduction_type';
      default:          return 'bonus_type';
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _nameArCtrl.text = e['name_ar'] ?? '';
      _nameEnCtrl.text = e['name_en'] ?? '';
      _amountCtrl.text = e['amount'].toString();
      _startCtrl.text = e['start_date'] ?? '';
      _endCtrl.text = e['end_date'] ?? '';
      _notesCtrl.text = e['notes'] ?? '';
      _scope = e['scope'] ?? 'company';
      _isMonthly = e['is_monthly'] ?? true;
      _isActive = e['is_active'] ?? true;
      _selectedType = e[_typeKey] ?? _types.first;
    } else {
      _selectedType = _types.first;
      _startCtrl.text = DateTime.now().toIso8601String().substring(0, 10);
    }
  }

  @override
  void dispose() {
    _nameArCtrl.dispose(); _nameEnCtrl.dispose();
    _amountCtrl.dispose(); _startCtrl.dispose();
    _endCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? prefs.getString('token') ?? '';
    return ApiClient.buildHeaders(includeContentType: true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final headers = await _headers();
      final body = json.encode({
        _typeKey: _selectedType,
        'name_ar': _nameArCtrl.text.trim(),
        'name_en': _nameEnCtrl.text.trim(),
        'amount': double.tryParse(_amountCtrl.text) ?? 0,
        'scope': _scope,
        'start_date': _startCtrl.text.trim(),
        'end_date': _endCtrl.text.trim().isEmpty ? null : _endCtrl.text.trim(),
        'is_monthly': _isMonthly,
        'is_active': _isActive,
        'notes': _notesCtrl.text.trim(),
      });

      http.Response res;
      if (isEdit) {
        res = await http.put(
          Uri.parse('${widget.endpoint}${widget.existing!['id']}/'),
          headers: headers, body: body,
        );
      } else {
        res = await http.post(Uri.parse(widget.endpoint), headers: headers, body: body);
      }

      if ((res.statusCode == 200 || res.statusCode == 201) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'تم الحفظ بنجاح ✅' : 'Saved ✅'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context, true);
      } else {
        setState(() => _saving = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error ${res.statusCode}: ${res.body}'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.type == 'allowance' ? Colors.green
        : widget.type == 'deduction' ? Colors.red
        : Colors.amber.shade700;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isEdit ? (isAr ? 'تعديل السياسة' : 'Edit Policy')
                   : (isAr ? 'إضافة سياسة جديدة' : 'Add Policy'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
        body: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            _field(_nameArCtrl, isAr ? 'الاسم بالعربي' : 'Name (Arabic)', required: true),
            const SizedBox(height: 12),
            _field(_nameEnCtrl, isAr ? 'الاسم بالإنجليزي' : 'Name (English)'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                labelText: isAr ? 'النوع' : 'Type',
                border: const OutlineInputBorder(),
                filled: true, fillColor: Colors.white,
              ),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedType = v ?? _types.first),
            ),
            const SizedBox(height: 12),
            _field(_amountCtrl, isAr ? 'المبلغ' : 'Amount',
                keyboardType: TextInputType.number, required: true),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _scope,
              decoration: InputDecoration(
                labelText: isAr ? 'نطاق التطبيق' : 'Scope',
                border: const OutlineInputBorder(),
                filled: true, fillColor: Colors.white,
              ),
              items: [
                DropdownMenuItem(value: 'company', child: Text(isAr ? 'الشركة كلها' : 'Whole Company')),
                DropdownMenuItem(value: 'branch', child: Text(isAr ? 'فرع محدد' : 'Specific Branch')),
                DropdownMenuItem(value: 'department', child: Text(isAr ? 'إدارة محددة' : 'Specific Department')),
                DropdownMenuItem(value: 'employees', child: Text(isAr ? 'موظفين محددين' : 'Specific Employees')),
              ],
              onChanged: (v) => setState(() => _scope = v ?? 'company'),
            ),
            const SizedBox(height: 12),
            _field(_startCtrl, isAr ? 'من تاريخ (YYYY-MM-DD)' : 'Start Date', required: true),
            const SizedBox(height: 12),
            _field(_endCtrl, isAr ? 'لحد تاريخ (اختياري)' : 'End Date (optional)'),
            const SizedBox(height: 12),
            _field(_notesCtrl, isAr ? 'ملاحظات' : 'Notes', maxLines: 2),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(isAr ? 'شهري' : 'Monthly'),
              subtitle: Text(isAr ? 'يتحسب كل شهر' : 'Applied every month'),
              value: _isMonthly,
              activeColor: color,
              onChanged: (v) => setState(() => _isMonthly = v),
            ),
            SwitchListTile(
              title: Text(isAr ? 'نشط' : 'Active'),
              value: _isActive,
              activeColor: color,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 80),
          ]),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: color, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 24, height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isAr ? 'حفظ ✔' : 'Save ✔',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) => TextFormField(
    controller: ctrl,
    keyboardType: keyboardType,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true, fillColor: Colors.white,
    ),
    validator: required ? (v) => (v == null || v.trim().isEmpty)
        ? (isAr ? 'مطلوب' : 'Required') : null : null,
  );
}
