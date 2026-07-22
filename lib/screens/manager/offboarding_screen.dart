import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';

class OffboardingScreen extends StatefulWidget {
  const OffboardingScreen({super.key});

  @override
  State<OffboardingScreen> createState() => _OffboardingScreenState();
}

class _OffboardingScreenState extends State<OffboardingScreen> {
  List<dynamic> _offboarded = [];
  List<dynamic> _activeEmployees = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final token = await AuthStorageService.getSavedToken() ?? '';
      final headers = {'Authorization': 'Token $token'};

      final r1 = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/offboarding/list/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      final r2 = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/manager/employees/'),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (r1.statusCode == 200) {
        final d = json.decode(utf8.decode(r1.bodyBytes));
        _offboarded = d['employees'] ?? [];
      }

      if (r2.statusCode == 200) {
        final d = json.decode(utf8.decode(r2.bodyBytes));
        _activeEmployees = d['employees'] ?? [];
      }
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  void _showOffboardSheet() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    List<dynamic> filtered = List.from(_activeEmployees);
    Map<String, dynamic>? selectedEmp;
    String selectedStatus = 'resigned';
    final reasonCtrl = TextEditingController();
    final searchCtrl = TextEditingController();

    final statusOptions = [
      {'code': 'resigned', 'ar': 'مستقيل', 'en': 'Resigned'},
      {'code': 'terminated', 'ar': 'مفصول', 'en': 'Terminated'},
      {'code': 'suspended', 'ar': 'موقوف', 'en': 'Suspended'},
      {'code': 'retired', 'ar': 'متقاعد', 'en': 'Retired'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.88,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isAr ? 'إنهاء خدمة موظف' : 'Offboard Employee',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (selectedEmp != null)
                      TextButton(
                        onPressed: () => setS(() => selectedEmp = null),
                        child: Text(isAr ? 'تغيير الموظف' : 'Change'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                if (selectedEmp == null) ...[
                  TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      labelText: isAr
                          ? 'ابحث بالاسم / الموبايل / الرقم القومي'
                          : 'Search by name / phone / national ID',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final q = v.toLowerCase().trim();
                      setS(() {
                        filtered = _activeEmployees.where((e) {
                          final name = '${e['full_name'] ?? ''}'.toLowerCase();
                          final phone = '${e['phone'] ?? ''}'.toLowerCase();
                          final natId = '${e['national_id'] ?? ''}'.toLowerCase();
                          return name.contains(q) ||
                              phone.contains(q) ||
                              natId.contains(q);
                        }).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAr
                        ? 'اختار الموظف من القايمة:'
                        : 'Select employee from list:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              isAr ? 'مفيش نتايج' : 'No results',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final emp = filtered[i] as Map<String, dynamic>;
                              final name = emp['full_name'] ?? '';
                              final dept = emp['department'] ?? '';
                              final phone = emp['phone'] ?? '';
                              final natId = emp['national_id'] ?? '';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF4A148C)
                                        .withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.person,
                                      color: Color(0xFF4A148C),
                                    ),
                                  ),
                                  title: Text(
                                    '$name',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (dept.isNotEmpty) Text(dept),
                                      Row(
                                        children: [
                                          if (phone.isNotEmpty)
                                            Text(
                                              phone,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          if (phone.isNotEmpty && natId.isNotEmpty)
                                            Text(
                                              ' • ',
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                              ),
                                            ),
                                          if (natId.isNotEmpty)
                                            Text(
                                              natId,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () => setS(() => selectedEmp = emp),
                                ),
                              );
                            },
                          ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4A148C).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.person,
                              color: Color(0xFF4A148C),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${selectedEmp!['full_name'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${selectedEmp!['department'] ?? ''} — ${selectedEmp!['job_title'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        if ((selectedEmp!['phone'] ?? '').isNotEmpty)
                          Text(
                            '📞 ${selectedEmp!['phone']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        if ((selectedEmp!['national_id'] ?? '').isNotEmpty)
                          Text(
                            '🪪 ${selectedEmp!['national_id']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: InputDecoration(
                      labelText: isAr ? 'سبب الإنهاء' : 'Termination reason',
                      border: const OutlineInputBorder(),
                    ),
                    items: statusOptions
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['code'],
                            child: Text(isAr ? s['ar']! : s['en']!),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setS(() => selectedStatus = v ?? 'resigned'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText:
                          isAr ? 'ملاحظات (اختياري)' : 'Notes (optional)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final empId = selectedEmp!['id'];
                        Navigator.pop(ctx);
                        await _offboard(
                          empId,
                          selectedStatus,
                          reasonCtrl.text.trim(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.person_remove),
                      label: Text(isAr ? 'إنهاء الخدمة' : 'Offboard'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _offboard(int empId, String status, String reason) async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final r = await http.post(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/offboarding/$empId/',
        ),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status, 'reason': reason}),
      );
      final d = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(d['message'] ?? d['error'] ?? ''),
          backgroundColor: d['success'] == true ? Colors.green : Colors.red,
        ),
      );
      if (d['success'] == true) _load();
    } catch (_) {}
  }

  Future<void> _reactivate(int empId) async {
    final token = await AuthStorageService.getSavedToken() ?? '';
    try {
      final r = await http.post(
        Uri.parse(
          'https://jssolutions-eg.com/attendance/api/mobile/manager/offboarding/$empId/reactivate/',
        ),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );
      final d = json.decode(utf8.decode(r.bodyBytes));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(d['message'] ?? ''),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    } catch (_) {}
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resigned':
        return Colors.orange;
      case 'terminated':
        return Colors.red;
      case 'suspended':
        return Colors.purple;
      case 'retired':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'إنهاء الخدمة' : 'Offboarding'),
        backgroundColor: const Color(0xFF4A148C),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showOffboardSheet,
        backgroundColor: Colors.red,
        child: const Icon(Icons.person_remove, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _offboarded.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 52,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isAr
                                  ? 'مفيش موظفين منتهية خدمتهم'
                                  : 'No offboarded employees',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offboarded.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final emp = _offboarded[index] as Map<String, dynamic>;
                      final statusColor = _statusColor(emp['status'] ?? '');

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x11000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: statusColor.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(Icons.person_off, color: statusColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${emp['name']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${emp['department']} — ${emp['job_title']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${emp['status_label']}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.restart_alt,
                                color: Colors.green,
                              ),
                              tooltip:
                                  isAr ? 'إعادة تفعيل' : 'Reactivate',
                              onPressed: () => _reactivate(emp['id']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
