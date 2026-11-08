// lib/screens/manager/biometric_screen.dart
//
// أجهزة البصمة ZKTeco (زي صفحة "أجهزة البصمة" في الويب، لصاحب الشركة والـ HR):
//   1) الأجهزة: تسجيل جهاز بالرقم التسلسلي، الحالة، آخر اتصال، بصمات النهارده، إيقاف/تشغيل
//   2) ربط أرقام الجهاز بالموظفين
//   3) رفع ملف بصمات (attlog.dat أو Excel) للأجهزة اللي مش متوصلة بالنت
//   4) التقرير: أول وآخر بصمة لكل يوم قصاد حضور وانصراف البرنامج، وتصدير Excel
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/api_client.dart';
import 'reports/report_common.dart';

const String _kBio = 'https://jssolutions-eg.com/biometric/api';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({super.key});
  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);

  bool get isAr => reportIsAr(context);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'أجهزة البصمة' : 'Biometric Devices'),
        backgroundColor: kReportColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: const Icon(Icons.fingerprint), text: isAr ? 'الأجهزة' : 'Devices'),
            Tab(icon: const Icon(Icons.link), text: isAr ? 'ربط الأرقام' : 'Link'),
            Tab(icon: const Icon(Icons.upload_file), text: isAr ? 'رفع ملف' : 'Upload'),
            Tab(icon: const Icon(Icons.assessment), text: isAr ? 'التقرير' : 'Report'),
          ],
        ),
      ),
      body: TabBarView(controller: _tabs, children: const [
        _DevicesTab(),
        _MapTab(),
        _UploadTab(),
        _ReportTab(),
      ]),
    );
  }
}

Future<Map<String, dynamic>> _bio(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
  final uri = Uri.parse('$_kBio/$path');
  late http.Response res;
  if (method == 'GET') {
    res = await ApiClient.get(uri);
  } else if (method == 'POST') {
    res = await ApiClient.post(uri, body: jsonEncode(body ?? {}));
  } else {
    res = await ApiClient.patch(uri, body: jsonEncode(body ?? {}));
  }
  final d = decodeJson(res.bodyBytes);
  if (res.statusCode >= 400 || d['success'] == false) throw Exception(d['message'] ?? 'حصلت مشكلة');
  return d;
}

void _snack(BuildContext c, String m, {bool ok = false}) {
  if (!c.mounted) return;
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m), backgroundColor: ok ? Colors.green : null));
}

// ─────────────── 1) الأجهزة ───────────────
class _DevicesTab extends StatefulWidget {
  const _DevicesTab();
  @override
  State<_DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<_DevicesTab> {
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _branches = [];
  final _sn = TextEditingController();
  final _name = TextEditingController();
  int? _branchId;
  bool _loading = true;
  bool _busy = false;

  bool get isAr => reportIsAr(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _sn.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _devices = mapList((await _bio('devices/'))['devices']);
      if (_branches.isEmpty) {
        final b = await ApiClient.get(Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/branches/'));
        final bd = decodeJson(b.bodyBytes);
        _branches = mapList(bd['branches'] ?? bd['results']);
      }
    } catch (e) {
      _snack(context, '$e'.replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _add() async {
    if (_sn.text.trim().length < 4) {
      return _snack(context, isAr ? 'اكتب الرقم التسلسلي (SN) للجهاز' : 'Enter the device serial number');
    }
    setState(() => _busy = true);
    try {
      final d = await _bio('devices/', method: 'POST', body: {
        'serial_number': _sn.text.trim(),
        'name': _name.text.trim(),
        'branch_id': _branchId,
      });
      _snack(context, '${d['message'] ?? 'OK'}', ok: true);
      _sn.clear();
      _name.clear();
      setState(() => _branchId = null);
      _load();
    } catch (e) {
      _snack(context, '$e'.replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _patch(Map<String, dynamic> d, Map<String, dynamic> body) async {
    try {
      await _bio('devices/${d['id']}/', method: 'PATCH', body: body);
      _load();
    } catch (e) {
      _snack(context, '$e'.replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        Text(
          isAr
              ? 'البصمات بتيجي من أجهزة ZKTeco وبتتحول حضور وانصراف في البرنامج أوتوماتيك.'
              : 'Punches from ZKTeco devices are turned into attendance automatically.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
        Card(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isAr ? 'تسجيل جهاز' : 'Register a device', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _sn,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                    labelText: isAr ? 'الرقم التسلسلي (SN)' : 'Serial number (SN)',
                    border: const OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: InputDecoration(
                    labelText: isAr ? 'اسم الجهاز' : 'Device name',
                    hintText: isAr ? 'مثلاً: جهاز المدخل' : 'e.g. Entrance',
                    border: const OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                isExpanded: true,
                value: _branchId,
                decoration: InputDecoration(labelText: isAr ? 'الفرع' : 'Branch', border: const OutlineInputBorder(), isDense: true),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(isAr ? 'تلقائي' : 'Auto')),
                  ..._branches.where((b) => b['id'] is int).map((b) =>
                      DropdownMenuItem<int?>(value: b['id'] as int, child: Text('${b['name_ar'] ?? b['name'] ?? ''}'))),
                ],
                onChanged: (v) => setState(() => _branchId = v),
              ),
              const SizedBox(height: 6),
              Text(
                isAr
                    ? 'الرقم التسلسلي مكتوب على ملصق ورا الجهاز، أو في الجهاز من: القائمة ← معلومات النظام ← معلومات الجهاز.'
                    : 'The serial number is on a label at the back of the device, or in Menu > System Info > Device Info.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kReportColor, foregroundColor: Colors.white),
                  onPressed: _busy ? null : _add,
                  child: Text(isAr ? 'تسجيل' : 'Register'),
                ),
              ),
            ]),
          ),
        ),
        for (final d in _devices)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.circle, size: 12, color: d['online'] == true ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${d['name'] ?? ''}'.isEmpty ? '${d['serial_number']}' : '${d['name']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Text(d['online'] == true ? (isAr ? 'متصل' : 'Online') : (isAr ? 'لسه مااتصلش' : 'Not connected'),
                      style: TextStyle(fontSize: 12, color: d['online'] == true ? Colors.green : Colors.grey)),
                ]),
                const SizedBox(height: 4),
                Text('SN: ${d['serial_number'] ?? ''} • ${d['branch'] ?? ''}', style: const TextStyle(fontSize: 12)),
                Text('${isAr ? 'آخر اتصال' : 'Last seen'}: ${d['last_seen'] ?? '—'} • '
                    '${isAr ? 'بصمات النهارده' : 'Punches today'}: ${d['punches_today'] ?? 0}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                Row(children: [
                  Text(isAr ? 'شغال' : 'Active'),
                  Switch(value: d['is_active'] == true, onChanged: (v) => _patch(d, {'is_active': v})),
                ]),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ─────────────── 2) ربط الأرقام بالموظفين ───────────────
class _MapTab extends StatefulWidget {
  const _MapTab();
  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab> {
  List<Map<String, dynamic>> _pins = [];
  List<Map<String, dynamic>> _employees = [];
  bool _onlyUnmatched = false;
  bool _loading = true;

  bool get isAr => reportIsAr(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _pins = mapList((await _bio('user-map/'))['pins']);
      if (_employees.isEmpty) {
        final r = await ApiClient.get(
            Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/employees/?page_size=2000'));
        final d = decodeJson(r.bodyBytes);
        _employees = mapList(d['results'] ?? d['employees']);
      }
    } catch (e) {
      _snack(context, '$e'.replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _link(String pin, int? employeeId) async {
    try {
      await _bio('user-map/', method: 'POST', body: {'pin': pin, 'employee_id': employeeId});
      _snack(context, isAr ? 'اتحفظ الربط' : 'Saved', ok: true);
      _load();
    } catch (e) {
      _snack(context, '$e'.replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final shown = _onlyUnmatched ? _pins.where((p) => p['employee_id'] == null).toList() : _pins;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        Text(
          isAr
              ? 'رقم الموظف على الجهاز بيتربط لوحده لو هو نفس كوده في البرنامج (زي 15 = EMP00015). الأرقام اللي ماتربطتش اختار موظفها هنا، وبصماتها القديمة هتتربط على طول.'
              : 'Device user numbers link automatically when they match the employee code. Pick the employee for the others.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(isAr ? 'اللي محتاج ربط بس' : 'Unlinked only'),
          value: _onlyUnmatched,
          onChanged: (v) => setState(() => _onlyUnmatched = v),
        ),
        for (final p in shown)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${isAr ? 'رقم الجهاز' : 'Pin'}: ${p['pin']}  ${'${p['device_user_name'] ?? ''}'.isNotEmpty ? '(${p['device_user_name']})' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${isAr ? 'البصمات' : 'Punches'}: ${p['punches'] ?? 0} • ${isAr ? 'آخر بصمة' : 'Last'}: ${p['last_punch'] ?? '—'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  value: p['employee_id'] is int ? p['employee_id'] as int : null,
                  decoration: InputDecoration(
                    labelText: isAr ? 'الموظف' : 'Employee',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    helperText: p['employee_id'] == null
                        ? null
                        : (p['manual'] == true ? (isAr ? 'ربط يدوي' : 'Manual link') : (isAr ? 'تلقائي' : 'Auto')),
                  ),
                  items: [
                    DropdownMenuItem<int?>(value: null, child: Text(isAr ? '— مش مربوط —' : '— not linked —')),
                    ..._employees.where((e) => e['id'] is int).map((e) => DropdownMenuItem<int?>(
                          value: e['id'] as int,
                          child: Text('${e['full_name'] ?? e['name'] ?? ''} (${e['employee_code'] ?? ''})',
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) => _link('${p['pin']}', v),
                ),
              ]),
            ),
          ),
      ]),
    );
  }
}

// ─────────────── 3) رفع ملف بصمات ───────────────
class _UploadTab extends StatefulWidget {
  const _UploadTab();
  @override
  State<_UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<_UploadTab> {
  PlatformFile? _file;
  List<Map<String, dynamic>> _devices = [];
  int? _deviceId;
  String _result = '';
  bool _busy = false;

  bool get isAr => reportIsAr(context);

  @override
  void initState() {
    super.initState();
    _bio('devices/').then((d) {
      if (mounted) setState(() => _devices = mapList(d['devices']));
    }).catchError((_) {});
  }

  Future<void> _pick() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.any, allowMultiple: false);
    if (r != null && r.files.isNotEmpty && r.files.first.path != null) setState(() => _file = r.files.first);
  }

  Future<void> _upload() async {
    if (_file?.path == null) return _snack(context, isAr ? 'اختار الملف' : 'Choose a file');
    setState(() => _busy = true);
    try {
      final req = http.MultipartRequest('POST', Uri.parse('$_kBio/upload/'));
      req.headers.addAll(await ApiClient.buildHeaders());
      req.files.add(await http.MultipartFile.fromPath('file', _file!.path!, filename: _file!.name));
      if (_deviceId != null) req.fields['device_id'] = '$_deviceId';
      final res = await http.Response.fromStream(await req.send());
      final d = decodeJson(res.bodyBytes);
      if (res.statusCode >= 400 || d['success'] == false) throw Exception(d['message'] ?? 'حصلت مشكلة');
      setState(() => _result = '${d['message'] ?? ''}');
      _snack(context, '${d['message'] ?? 'OK'}', ok: true);
    } catch (e) {
      final m = '$e'.replaceFirst('Exception: ', '');
      setState(() => _result = m);
      _snack(context, m);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(12), children: [
      Text(
        isAr
            ? 'للأجهزة اللي مش متوصلة بالنت: نزّل البصمات على فلاشة من الجهاز (ملف attlog.dat)، أو صدّرها Excel من برنامج الجهاز، وارفعها هنا. البصمة المكررة مابتتسجلش مرتين.'
            : 'For offline devices: export punches to a USB stick (attlog.dat) or Excel and upload here. Duplicate punches are ignored.',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
      const SizedBox(height: 12),
      DropdownButtonFormField<int?>(
        isExpanded: true,
        value: _deviceId,
        decoration: InputDecoration(labelText: isAr ? 'الجهاز' : 'Device', border: const OutlineInputBorder(), isDense: true),
        items: [
          DropdownMenuItem<int?>(value: null, child: Text(isAr ? 'تلقائي' : 'Auto')),
          ..._devices.where((d) => d['id'] is int).map((d) => DropdownMenuItem<int?>(
              value: d['id'] as int,
              child: Text('${d['name'] ?? ''}'.isEmpty ? '${d['serial_number']}' : '${d['name']}'))),
        ],
        onChanged: (v) => setState(() => _deviceId = v),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _pick,
        icon: const Icon(Icons.attach_file),
        label: Text(_file?.name ?? (isAr ? 'اختار الملف' : 'Choose file')),
      ),
      const SizedBox(height: 12),
      ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: kReportColor, foregroundColor: Colors.white),
        onPressed: _busy ? null : _upload,
        icon: const Icon(Icons.upload),
        label: Text(isAr ? 'رفع' : 'Upload'),
      ),
      if (_result.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_result)),
    ]);
  }
}

// ─────────────── 4) التقرير والمقارنة ───────────────
class _ReportTab extends StatefulWidget {
  const _ReportTab();
  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  List<Map<String, dynamic>> _days = [];
  int _unmatched = 0;
  bool _loading = true;

  bool get isAr => reportIsAr(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _bio('report/?date_from=${fmtDate(_from)}&date_to=${fmtDate(_to)}');
      _days = mapList(d['days']);
      _unmatched = asNum(d['unmatched_punches']).toInt();
    } catch (e) {
      _snack(context, '$e'.replaceFirst('Exception: ', ''));
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _range() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (r != null) {
      setState(() { _from = r.start; _to = r.end; });
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(children: [
          ActionChip(
              avatar: const Icon(Icons.date_range, size: 18),
              label: Text('${fmtDate(_from)} → ${fmtDate(_to)}'),
              onPressed: _range),
          const Spacer(),
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            onSelected: (view) => downloadAndShare(
              context,
              Uri.parse('$_kBio/report/?date_from=${fmtDate(_from)}&date_to=${fmtDate(_to)}&view=$view&export=xlsx'),
              'biometric_${view}_${fmtDate(_from)}_${fmtDate(_to)}.xlsx',
            ),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'daily', child: Text(isAr ? 'Excel يومي (أول وآخر بصمة)' : 'Daily Excel')),
              PopupMenuItem(value: 'raw', child: Text(isAr ? 'Excel كل البصمات' : 'All punches Excel')),
            ],
          ),
        ]),
      ),
      if (_unmatched > 0)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
              isAr ? '$_unmatched بصمة لأرقام مش مربوطة بموظفين (اربطها من تبويب "ربط الأرقام")' : '$_unmatched punches are not linked to employees',
              style: TextStyle(color: Colors.orange.shade800)),
        ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _days.isEmpty
                    ? ListView(children: [
                        const SizedBox(height: 80),
                        Center(child: Text(isAr ? 'لا توجد بصمات في الفترة دي' : 'No punches in this period')),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _days.length,
                        itemBuilder: (_, i) {
                          final r = _days[i];
                          final diff = r['diff_in_minutes'];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('${r['employee_name'] ?? ''} • ${r['date'] ?? ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text('${isAr ? 'أول بصمة' : 'First'}: ${r['first_punch'] ?? '—'}   '
                                    '${isAr ? 'آخر بصمة' : 'Last'}: ${r['last_punch'] ?? '—'}   (${r['punches'] ?? 0})',
                                    style: const TextStyle(fontSize: 13)),
                                Text('${isAr ? 'حضور البرنامج' : 'App in'}: ${'${r['system_check_in'] ?? ''}'.isEmpty ? '—' : r['system_check_in']}   '
                                    '${isAr ? 'انصراف البرنامج' : 'App out'}: ${'${r['system_check_out'] ?? ''}'.isEmpty ? '—' : r['system_check_out']}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                Text('${isAr ? 'الحالة في البرنامج' : 'App status'}: ${r['system_status'] ?? '—'}'
                                    '${diff != null ? '   • ${isAr ? 'فرق الحضور' : 'In diff'}: $diff ${isAr ? 'د' : 'm'}' : ''}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
      ),
    ]);
  }
}
