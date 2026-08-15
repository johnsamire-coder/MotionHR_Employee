import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:motionhr_employee/services/api_client.dart';

class TrustedDevicesScreen extends StatefulWidget {
  const TrustedDevicesScreen({super.key});

  @override
  State<TrustedDevicesScreen> createState() => _TrustedDevicesScreenState();
}

class _TrustedDevicesScreenState extends State<TrustedDevicesScreen> {
  bool _loading = true;
  String? _error;
  String _statusFilter = 'pending';
  List<dynamic> _devices = [];

  bool get _isAr => Directionality.of(context) == TextDirection.rtl;

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
      final headers = await ApiClient.buildHeaders();
      final filter = _statusFilter == 'all' ? '' : '?status=$_statusFilter';
      final res = await http
          .get(
            Uri.parse(
              'https://jssolutions-eg.com/attendance/api/mobile/manager/devices/$filter',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 20));

      final data = json.decode(utf8.decode(res.bodyBytes));
      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          _devices = data['results'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = data['message']?.toString() ??
              (_isAr ? 'فشل تحميل الأجهزة' : 'Failed to load devices');
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = _isAr ? 'خطأ في تحميل الأجهزة' : 'Load error';
        _loading = false;
      });
    }
  }

  Future<void> _deviceAction(int id, String action) async {
    try {
      final headers = await ApiClient.buildHeaders(includeContentType: true);
      final res = await http
          .post(
            Uri.parse(
              'https://jssolutions-eg.com/attendance/api/mobile/manager/devices/$id/action/',
            ),
            headers: headers,
            body: jsonEncode({'action': action}),
          )
          .timeout(const Duration(seconds: 20));

      final data = json.decode(utf8.decode(res.bodyBytes));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data['message']?.toString() ??
                (_isAr ? 'تم التنفيذ' : 'Done'),
          ),
          backgroundColor:
              data['success'] == true ? Colors.green : Colors.red,
        ),
      );

      if (data['success'] == true) {
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isAr ? 'حدث خطأ أثناء التنفيذ' : 'Action failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'revoked':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return _isAr ? 'معتمد' : 'Approved';
      case 'pending':
        return _isAr ? 'معلق' : 'Pending';
      case 'rejected':
        return _isAr ? 'مرفوض' : 'Rejected';
      case 'revoked':
        return _isAr ? 'ملغي' : 'Revoked';
      default:
        return status;
    }
  }

  Widget _filterChip(String value, String label) {
    final selected = _statusFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _statusFilter = value);
        _load();
      },
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> d) {
    final status = (d['status'] ?? '').toString();
    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.12),
                  child: Icon(Icons.phone_android, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['employee_name']?.toString() ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        d['username']?.toString() ?? '',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('${_isAr ? 'الجهاز' : 'Device'}: ${d['device_name'] ?? ''}'),
            const SizedBox(height: 4),
            Text('${_isAr ? 'المنصة' : 'Platform'}: ${d['platform'] ?? ''}'),
            const SizedBox(height: 4),
            Text('${_isAr ? 'آخر دخول' : 'Last login'}: ${d['last_login_at'] ?? ''}'),
            const SizedBox(height: 4),
            Text('${_isAr ? 'أول جهاز' : 'First device'}: ${d['is_first_device'] == true ? (_isAr ? 'نعم' : 'Yes') : (_isAr ? 'لا' : 'No')}'),
            const SizedBox(height: 12),
            if (status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deviceAction(d['id'], 'approve'),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: Text(_isAr ? 'موافقة' : 'Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deviceAction(d['id'], 'reject'),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: Text(_isAr ? 'رفض' : 'Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            if (status == 'approved')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _deviceAction(d['id'], 'revoke'),
                  icon: const Icon(Icons.block),
                  label: Text(_isAr ? 'إلغاء الجهاز' : 'Revoke Device'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isAr ? 'الأجهزة المعتمدة' : 'Trusted Devices'),
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _filterChip('pending', _isAr ? 'معلقة' : 'Pending'),
                  const SizedBox(width: 8),
                  _filterChip('approved', _isAr ? 'معتمدة' : 'Approved'),
                  const SizedBox(width: 8),
                  _filterChip('rejected', _isAr ? 'مرفوضة' : 'Rejected'),
                  const SizedBox(width: 8),
                  _filterChip('revoked', _isAr ? 'ملغية' : 'Revoked'),
                  const SizedBox(width: 8),
                  _filterChip('all', _isAr ? 'الكل' : 'All'),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!))
                      : _devices.isEmpty
                          ? Center(
                              child: Text(
                                _isAr
                                    ? 'لا توجد أجهزة'
                                    : 'No devices found',
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                itemCount: _devices.length,
                                itemBuilder: (_, i) =>
                                    _buildDeviceCard(_devices[i] as Map<String, dynamic>),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
