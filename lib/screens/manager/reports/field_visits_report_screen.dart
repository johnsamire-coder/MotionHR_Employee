// lib/screens/manager/reports/field_visits_report_screen.dart
//
// تقرير الزيارات الميدانية (زي الويب، للـ HR وللمدير على فريقه):
// كل زيارة قعد قد إيه، وصل ومشي إمتى ومنين، وخط سيره خلال الزيارة على الخريطة،
// وملخص لكل موظف، وتصدير Excel و PDF.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'report_common.dart';

class FieldVisitsReportScreen extends StatefulWidget {
  const FieldVisitsReportScreen({super.key});
  @override
  State<FieldVisitsReportScreen> createState() => _FieldVisitsReportScreenState();
}

class _FieldVisitsReportScreenState extends State<FieldVisitsReportScreen> {
  DateTime _from = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _to = DateTime.now();
  String _status = '';
  int? _employeeId;
  Map<String, dynamic>? _data;
  String _error = '';
  bool _loading = true;

  bool get isAr => reportIsAr(context);

  Map<String, String> _params([Map<String, String> extra = const {}]) => {
        'date_from': fmtDate(_from),
        'date_to': fmtDate(_to),
        if (_employeeId != null) 'employee_id': '$_employeeId',
        if (_status.isNotEmpty) 'status': _status,
        ...extra,
      };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      _data = await getJson(Uri.parse('$kReportsApi/field-visits/').replace(queryParameters: _params()),
          fallbackError: isAr ? 'فشل تحميل التقرير' : 'Failed to load report');
    } catch (e) {
      _error = '$e'.replaceFirst('Exception: ', '');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickRange() async {
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

  String _dur(dynamic m) {
    final n = asNum(m).round();
    if (n <= 0) return '—';
    final h = n ~/ 60, mm = n % 60;
    if (h == 0) return isAr ? '$mm د' : '${mm}m';
    return isAr ? '$h س $mm د' : '${h}h ${mm}m';
  }

  Future<void> _open(String url) async {
    if (url.isEmpty) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // خط السير على جوجل ماب (نفس طريقة الويب: لحد 10 نقط)
  String _routeLink(List<Map<String, dynamic>> pts) {
    final p = pts.where((x) => x['latitude'] != null && x['longitude'] != null).toList();
    if (p.length < 2) return '';
    final step = (p.length / 10).ceil().clamp(1, 1 << 30);
    final picked = <Map<String, dynamic>>[];
    for (var i = 0; i < p.length; i += step) {
      picked.add(p[i]);
    }
    if (!identical(picked.last, p.last)) picked.add(p.last);
    return 'https://www.google.com/maps/dir/${picked.map((x) => '${x['latitude']},${x['longitude']}').join('/')}';
  }

  Future<void> _details(Map<String, dynamic> v) async {
    Map<String, dynamic> d;
    try {
      d = await getJson(Uri.parse('$kReportsApi/field-visits/${v['id']}/'));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isAr ? 'فشل تحميل التفاصيل' : 'Failed to load details')));
      }
      return;
    }
    if (!mounted) return;
    final visit = Map<String, dynamic>.from(d['visit'] as Map? ?? v);
    final track = mapList(d['tracking']);
    final route = _routeLink(track);
    Widget row(String l, dynamic val) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 120, child: Text(l, style: TextStyle(color: Colors.grey.shade600))),
            Expanded(child: Text('${val ?? '—'}'.isEmpty ? '—' : '${val ?? '—'}')),
          ]),
        );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, sc) => ListView(controller: sc, padding: const EdgeInsets.all(16), children: [
          Text('${visit['employee_name'] ?? ''} — ${visit['visit_type_display'] ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          row(isAr ? 'المكان' : 'Place', visit['location_name']),
          row(isAr ? 'التاريخ' : 'Date', visit['date']),
          row(isAr ? 'وصل' : 'Arrived', visit['arrival_time']),
          row(isAr ? 'مشي' : 'Left', visit['departure_time']),
          row(isAr ? 'قعد' : 'Stayed', _dur(visit['duration_minutes'])),
          row(isAr ? 'المسافة بين الوصول والمغادرة' : 'Arrival-departure distance',
              visit['distance_arrival_departure_m'] != null ? '${visit['distance_arrival_departure_m']} ${isAr ? 'م' : 'm'}' : '—'),
          row(isAr ? 'عنوان الوصول' : 'Arrival address', visit['arrival_address']),
          row(isAr ? 'الغرض' : 'Purpose', visit['purpose']),
          row(isAr ? 'ملاحظات' : 'Notes', visit['notes']),
          Wrap(spacing: 8, children: [
            if ('${visit['arrival_map'] ?? ''}'.isNotEmpty)
              OutlinedButton.icon(onPressed: () => _open('${visit['arrival_map']}'),
                  icon: const Icon(Icons.place), label: Text(isAr ? 'مكان الوصول' : 'Arrival')),
            if ('${visit['departure_map'] ?? ''}'.isNotEmpty)
              OutlinedButton.icon(onPressed: () => _open('${visit['departure_map']}'),
                  icon: const Icon(Icons.flag), label: Text(isAr ? 'مكان المغادرة' : 'Departure')),
            if (route.isNotEmpty)
              ElevatedButton.icon(onPressed: () => _open(route),
                  icon: const Icon(Icons.route), label: Text(isAr ? 'خط السير على الخريطة' : 'Route on map')),
          ]),
          const Divider(),
          if (track.isEmpty)
            Text(isAr ? 'مفيش نقاط تتبع اتسجلت خلال الزيارة دي' : 'No tracking points for this visit'),
          for (final p in track)
            ListTile(
              dense: true,
              leading: const Icon(Icons.my_location, size: 18),
              title: Text('${p['time'] ?? ''}'),
              subtitle: Text('${p['address'] ?? ''}'.isNotEmpty
                  ? '${p['address']}'
                  : '${p['latitude']}, ${p['longitude']}'),
              trailing: p['accuracy'] != null ? Text('±${fmtNum(p['accuracy'], digits: 0)}${isAr ? 'م' : 'm'}') : null,
              onTap: p['latitude'] != null
                  ? () => _open('https://www.google.com/maps?q=${p['latitude']},${p['longitude']}')
                  : null,
            ),
        ]),
      ),
    );
  }

  String _statusLabel(String s, String display) {
    if (display.isNotEmpty) return display;
    switch (s) {
      case 'completed': return isAr ? 'مكتملة' : 'Completed';
      case 'in_progress': return isAr ? 'جارية' : 'In progress';
      case 'arrived': return isAr ? 'وصل' : 'Arrived';
      case 'cancelled': return isAr ? 'ملغية' : 'Cancelled';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data ?? {};
    final per = mapList(d['per_employee']);
    final visits = mapList(d['visits']);
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'تقرير الزيارات الميدانية' : 'Field Visits Report'),
        backgroundColor: kReportColor,
        foregroundColor: Colors.white,
        actions: [
          exportMenu(context, (k) => downloadAndShare(
                context,
                Uri.parse('$kReportsApi/field-visits/').replace(
                    queryParameters: _params({'export': k == 'pdf' ? 'pdf' : 'xlsx'})),
                'field_visits_${fmtDate(_from)}_${fmtDate(_to)}.${k == 'pdf' ? 'pdf' : 'xlsx'}',
              )),
        ],
      ),
      body: Column(children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(children: [
            ActionChip(
              avatar: const Icon(Icons.date_range, size: 18),
              label: Text('${fmtDate(_from)} → ${fmtDate(_to)}'),
              onPressed: _pickRange,
            ),
            const SizedBox(width: 6),
            for (final s in const ['', 'completed', 'in_progress', 'arrived'])
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: ChoiceChip(
                  label: Text(s.isEmpty ? (isAr ? 'الكل' : 'All') : _statusLabel(s, '')),
                  selected: _status == s,
                  onSelected: (_) {
                    setState(() => _status = s);
                    _load();
                  },
                ),
              ),
            if (_employeeId != null)
              InputChip(
                label: Text(isAr ? 'موظف واحد' : 'One employee'),
                onDeleted: () {
                  setState(() => _employeeId = null);
                  _load();
                },
              ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
                  ? Center(child: Text(_error, style: const TextStyle(color: Colors.red)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(padding: const EdgeInsets.all(12), children: [
                        Row(children: [
                          statTile(isAr ? 'عدد الزيارات' : 'Visits', fmtNum(d['total_visits']), kReportColor),
                          statTile(isAr ? 'إجمالي الوقت' : 'Total time', _dur(d['total_minutes']), Colors.teal),
                          statTile(isAr ? 'زيارات لسه جارية' : 'Ongoing', fmtNum(d['ongoing']), Colors.orange.shade800),
                          statTile(isAr ? 'موظفين زاروا' : 'Employees', '${per.length}', Colors.blue.shade700),
                        ]),
                        if (per.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(isAr ? 'ملخص لكل موظف' : 'Per employee',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          for (final p in per)
                            ListTile(
                              dense: true,
                              title: Text('${p['employee_name'] ?? ''}'),
                              subtitle: Text(
                                  '${isAr ? 'الزيارات' : 'Visits'} ${fmtNum(p['visits'])} • ${isAr ? 'مكتملة' : 'Done'} ${fmtNum(p['completed'])}'
                                  ' • ${isAr ? 'جارية' : 'Ongoing'} ${fmtNum(p['ongoing'])}'),
                              trailing: Text('${_dur(p['total_minutes'])}\n${isAr ? 'متوسط' : 'avg'} ${_dur(p['avg_minutes'])}',
                                  textAlign: TextAlign.end, style: const TextStyle(fontSize: 11)),
                              onTap: () {
                                setState(() => _employeeId = asNum(p['employee_id']).toInt());
                                _load();
                              },
                            ),
                        ],
                        const Divider(),
                        Text(isAr ? 'كل الزيارات' : 'All visits', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (visits.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(child: Text(isAr ? 'مفيش زيارات في الفترة دي' : 'No visits in this period')),
                          ),
                        for (final v in visits)
                          Card(
                            margin: const EdgeInsets.only(top: 8),
                            child: ListTile(
                              title: Text('${v['employee_name'] ?? ''}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${v['visit_type_display'] ?? ''} • ${v['location_name'] ?? ''}\n'
                                '${v['date'] ?? ''}  ${isAr ? 'وصل' : 'In'} ${v['arrival_time'] ?? '—'}'
                                '  ${isAr ? 'مشي' : 'Out'} ${v['departure_time'] ?? (isAr ? 'لسه هناك' : 'still there')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(_dur(v['duration_minutes']), style: const TextStyle(fontSize: 12)),
                                  Text(_statusLabel('${v['status'] ?? ''}', '${v['status_display'] ?? ''}'),
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                ],
                              ),
                              onTap: () => _details(v),
                            ),
                          ),
                      ]),
                    ),
        ),
      ]),
    );
  }
}
