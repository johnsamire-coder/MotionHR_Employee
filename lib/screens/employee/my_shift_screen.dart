import 'package:flutter/material.dart';
import '../../services/shifts_service.dart';

const Color kPrimaryColor = Color(0xFF6A1B9A);

class MyShiftScreen extends StatefulWidget {
  const MyShiftScreen({super.key});

  @override
  State<MyShiftScreen> createState() => _MyShiftScreenState();
}

class _MyShiftScreenState extends State<MyShiftScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ShiftsService.getMyShift();
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(isAr ? 'شيفتي' : 'My Shift',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            : _error != null
                ? _buildError()
                : _data == null || _data!['has_shift'] != true
                    ? _buildNoShift()
                    : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final todayShift = _data!['today_shift'] as Map<String, dynamic>? ?? {};
    final schedule = _data!['schedule'] as List? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(12), children: [
        // شيفت اليوم
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [kPrimaryColor, kPrimaryColor.withAlpha(180)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isAr ? 'شيفت اليوم' : "Today's Shift",
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Text((todayShift['name'] ?? '').toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.login, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text((todayShift['start_time'] ?? '').toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(width: 16),
                const Icon(Icons.logout, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Text((todayShift['end_time'] ?? '').toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                if (todayShift['crosses_midnight'] == true) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.nights_stay, color: Colors.white70, size: 16),
                ],
              ]),
              const SizedBox(height: 8),
              Text(
                '${isAr ? 'ساعات العمل' : 'Work hours'}: ${todayShift['work_hours'] ?? 0} ${isAr ? 'ساعة' : 'hrs'}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // معلومات إضافية
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            _infoRow(Icons.schedule, isAr ? 'نوع الشيفت' : 'Shift Type',
                todayShift['shift_type']?.toString() ?? '-'),
            _infoRow(Icons.timelapse, isAr ? 'سماحية التأخير' : 'Grace Period',
                '${todayShift['grace_minutes'] ?? 0} ${isAr ? 'دقيقة' : 'min'}'),
            _infoRow(Icons.access_time, isAr ? 'مدة الشيفت' : 'Duration',
                '${todayShift['work_hours'] ?? 0} ${isAr ? 'ساعة' : 'hours'}'),
          ])),
        ),
        const SizedBox(height: 16),

        // جدول الأسبوعين
        Text(isAr ? 'الجدول القادم' : 'Upcoming Schedule',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...schedule.map((day) {
          final d = day as Map<String, dynamic>;
          final isWorkDay = d['is_work_day'] == true;
          final hasShift = d['shift_name'] != null;
          final isToday = d['date'] == DateTime.now().toIso8601String().substring(0, 10);

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            color: isToday ? kPrimaryColor.withAlpha(20) : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: isToday ? BorderSide(color: kPrimaryColor.withAlpha(80)) : BorderSide.none,
            ),
            child: ListTile(
              dense: true,
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: isWorkDay ? kPrimaryColor.withAlpha(25) : Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(isWorkDay ? Icons.work : Icons.weekend,
                    color: isWorkDay ? kPrimaryColor : Colors.grey, size: 20),
              ),
              title: Text(d['date']?.toString() ?? '',
                  style: TextStyle(fontWeight: isToday ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
              subtitle: Text(
                hasShift && isWorkDay
                    ? '${d['shift_name']} | ${d['start_time']} - ${d['end_time']}'
                    : (isAr ? 'راحة' : 'Day off'),
                style: TextStyle(fontSize: 12, color: isWorkDay ? Colors.black87 : Colors.grey),
              ),
              trailing: isToday
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: kPrimaryColor, borderRadius: BorderRadius.circular(10)),
                      child: Text(isAr ? 'اليوم' : 'Today',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    )
                  : null,
            ),
          );
        }),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: kPrimaryColor),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.black54)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildNoShift() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.schedule_outlined, size: 80, color: Colors.grey[300]),
      const SizedBox(height: 16),
      Text(isAr ? 'لا يوجد شيفت محدد لك' : 'No shift assigned to you',
          style: TextStyle(fontSize: 16, color: Colors.grey[600])),
    ]));
  }

  Widget _buildError() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.error_outline, size: 60, color: Colors.red),
      const SizedBox(height: 12),
      Text(_error ?? ''),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: _load,
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, foregroundColor: Colors.white),
          child: Text(isAr ? 'إعادة المحاولة' : 'Retry')),
    ]));
  }
}