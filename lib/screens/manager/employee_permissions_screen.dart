import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String _kBase = 'https://motion.jssolutions-eg.com';
const Color _kColor = Color(0xFF1565C0);

class EmployeePermissionsScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const EmployeePermissionsScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeePermissionsScreen> createState() =>
      _EmployeePermissionsScreenState();
}

class _EmployeePermissionsScreenState
    extends State<EmployeePermissionsScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      final res = await http.get(
        Uri.parse(
            '$_kBase/attendance/api/mobile/manager/employees/${widget.employeeId}/permission-balance/'),
        headers: {'Authorization': 'Token $token'},
      );
      if (res.statusCode == 200) {
        setState(() => _data = jsonDecode(res.body));
      } else {
        setState(() => _error = 'Error ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _grantPermission() async {
    final minutesCtrl = TextEditingController();
    final countCtrl = TextEditingController(text: '1');
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'منح إذن إضافي' : 'Grant Extra Permission'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minutesCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'عدد الدقائق' : 'Minutes',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: countCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isAr ? 'عدد المرات' : 'Count',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'السبب' : 'Reason',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'تراجع' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: _kColor),
              child: Text(isAr ? 'منح' : 'Grant',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse(
            '$_kBase/attendance/api/mobile/manager/employees/${widget.employeeId}/permission-grant/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'minutes': int.tryParse(minutesCtrl.text) ?? 0,
          'count': int.tryParse(countCtrl.text) ?? 1,
          'notes': notesCtrl.text,
        }),
      );

      if (mounted) {
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr ? 'تم منح الإذن ✅' : 'Permission granted ✅'),
            backgroundColor: Colors.green,
          ));
          _load();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: ${res.body}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rollbackLate() async {
    final dateCtrl = TextEditingController(
        text: DateTime.now().toString().substring(0, 10));
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(isAr ? 'إلغاء تأخير' : 'Cancel Late'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'تاريخ التأخير (YYYY-MM-DD)' : 'Late Date (YYYY-MM-DD)',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  labelText: isAr ? 'السبب' : 'Reason',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(isAr ? 'تراجع' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(isAr ? 'إلغاء التأخير' : 'Rollback',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      final token = await _getToken();
      final res = await http.post(
        Uri.parse(
            '$_kBase/attendance/api/mobile/manager/employees/${widget.employeeId}/permission-rollback/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'reference_date': dateCtrl.text,
          'notes': notesCtrl.text,
        }),
      );

      if (mounted) {
        if (res.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isAr ? 'تم إلغاء التأخير ✅' : 'Late cancelled ✅'),
            backgroundColor: Colors.green,
          ));
          _load();
        } else {
          final body = jsonDecode(res.body);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(body['error'] ?? 'Error ${res.statusCode}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
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
            isAr
                ? 'أذونات ${widget.employeeName}'
                : '${widget.employeeName} Permissions',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _kColor,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: _kColor))
            : _error != null
                ? _buildError()
                : _data == null
                    ? const SizedBox()
                    : _data!['enabled'] == false
                        ? _buildDisabled()
                        : _buildContent(),
        bottomNavigationBar: _data != null && _data!['enabled'] == true
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _grantPermission,
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(isAr ? 'منح إذن' : 'Grant'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _rollbackLate,
                      icon: const Icon(Icons.undo),
                      label: Text(isAr ? 'إلغاء تأخير' : 'Rollback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ]),
              )
            : null,
      ),
    );
  }

  Widget _buildContent() {
    final usedMinutes = _data!['used_minutes'] ?? 0;
    final remainingMinutes = _data!['remaining_minutes'] ?? 0;
    final monthlyMinutes = (_data!['monthly_hours'] ?? 0) * 60;
    final usedCount = _data!['used_count'] ?? 0;
    final remainingCount = _data!['remaining_count'] ?? 0;
    final monthlyCount = _data!['monthly_count'] ?? 0;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // بطاقة الرصيد
      Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: _kColor.withAlpha(15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              isAr ? 'رصيد الأذونات' : 'Permission Balance',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _kColor),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _box(isAr ? 'المتاح' : 'Total',
                  '${((monthlyMinutes) / 60).toStringAsFixed(1)}h', Colors.blue),
              const SizedBox(width: 8),
              _box(isAr ? 'المستخدم' : 'Used',
                  '${(usedMinutes / 60).toStringAsFixed(1)}h', Colors.orange),
              const SizedBox(width: 8),
              _box(isAr ? 'الباقي' : 'Left',
                  '${(remainingMinutes / 60).toStringAsFixed(1)}h', Colors.green),
            ]),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: monthlyMinutes > 0
                    ? usedMinutes / monthlyMinutes
                    : 0,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  usedMinutes >= monthlyMinutes ? Colors.red : Colors.orange,
                ),
              ),
            ),
            if (monthlyCount > 0) ...[
              const SizedBox(height: 12),
              Text(
                isAr
                    ? 'عدد المرات: $usedCount / $monthlyCount (باقي $remainingCount)'
                    : 'Count: $usedCount / $monthlyCount (left $remainingCount)',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        isAr ? 'سجل الحركات' : 'History',
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 16),
      ),
      const SizedBox(height: 8),
      Text(
        isAr
            ? 'اضغط "منح إذن" لإضافة إذن إضافي\nاضغط "إلغاء تأخير" لإرجاع خصم التأخير'
            : 'Press "Grant" to add extra permission\nPress "Rollback" to cancel a late deduction',
        style: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
    ]);
  }

  Widget _buildDisabled() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            isAr
                ? 'لا توجد سياسة أذونات مفعلة لهذا الموظف'
                : 'No permission policy activated for this employee',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? ''),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
                backgroundColor: _kColor, foregroundColor: Colors.white),
            child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _box(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(100)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ]),
      ),
    );
  }
}