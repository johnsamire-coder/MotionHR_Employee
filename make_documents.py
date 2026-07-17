import os

content = r'''import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class EmployeeDocumentsScreen extends StatefulWidget {
  const EmployeeDocumentsScreen({super.key});
  @override
  State<EmployeeDocumentsScreen> createState() => _EmployeeDocumentsScreenState();
}

class _EmployeeDocumentsScreenState extends State<EmployeeDocumentsScreen> {
  List<dynamic> _documents = [];
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await http.get(
        Uri.parse('https://jssolutions-eg.com/attendance/api/mobile/employee/documents/'),
        headers: {'Authorization': 'Token $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _documents = data['documents'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'تعذر التحميل (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'خطأ في الاتصال';
        _loading = false;
      });
    }
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    final fullUrl = url.startsWith('http') ? url : 'https://jssolutions-eg.com$url';
    final uri = Uri.parse(fullUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الملف')),
        );
      }
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'national_id': return Icons.badge;
      case 'passport': return Icons.book;
      case 'contract': return Icons.description;
      case 'certificate': return Icons.school;
      case 'cv': return Icons.assignment_ind;
      case 'medical': return Icons.local_hospital;
      case 'license': return Icons.card_membership;
      case 'insurance': return Icons.shield;
      default: return Icons.folder;
    }
  }

  Color _statusColor(Map<String, dynamic> doc) {
    if (doc['is_expired'] == true) return Colors.red;
    if (doc['expires_soon'] == true) return Colors.orange;
    return const Color(0xFF1976D2);
  }

  String? _statusLabel(Map<String, dynamic> doc) {
    if (doc['is_expired'] == true) return 'منتهي';
    if (doc['expires_soon'] == true) return 'ينتهي قريباً';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final expiredCount = _documents.where((d) => d['is_expired'] == true).length;
    final soonCount = _documents.where((d) => d['expires_soon'] == true).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF388E3C),
          foregroundColor: Colors.white,
          title: const Text('المستندات', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ]))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: Column(children: [
                      if (expiredCount > 0 || soonCount > 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.amber[50],
                          child: Row(children: [
                            Icon(Icons.warning_amber, color: Colors.orange[800]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$expiredCount منتهي • $soonCount ينتهي قريباً',
                                style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]),
                        ),
                      Expanded(
                        child: _documents.isEmpty
                            ? const Center(child: Text('لا توجد مستندات'))
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _documents.length,
                                itemBuilder: (context, i) {
                                  final doc = _documents[i] as Map<String, dynamic>;
                                  final color = _statusColor(doc);
                                  final label = _statusLabel(doc);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: color.withValues(alpha: 0.2)),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      leading: Container(
                                        width: 48, height: 48,
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(_iconForType(doc['document_type_code'] ?? ''), color: color),
                                      ),
                                      title: Text(
                                        doc['title'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(doc['document_type'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                          if (doc['expiry_date'] != null) ...[
                                            const SizedBox(height: 4),
                                            Row(children: [
                                              Icon(Icons.event, size: 12, color: Colors.grey[600]),
                                              const SizedBox(width: 4),
                                              Text('ينتهي: ${doc['expiry_date']}',
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                            ]),
                                          ],
                                          if (label != null) ...[
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(label,
                                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: doc['file_url'] != null
                                          ? Icon(Icons.download, color: color)
                                          : null,
                                      onTap: () => _openFile(doc['file_url']),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ]),
                  ),
      ),
    );
  }
}
'''

path = r'lib\screens\employee\employee_documents_screen.dart'
with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Created:', path)
print('Size:', os.path.getsize(path), 'bytes')