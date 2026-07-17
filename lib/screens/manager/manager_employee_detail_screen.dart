import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../employee/employee_summary_screen.dart';

class ManagerEmployeeDetailScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;
  const ManagerEmployeeDetailScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<ManagerEmployeeDetailScreen> createState() => _ManagerEmployeeDetailScreenState();
}

class _ManagerEmployeeDetailScreenState extends State<ManagerEmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _profile;
  List<dynamic> _documents = [];
  List<dynamic> _movements = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final headers = {'Authorization': 'Token $token'};
      final base = 'https://jssolutions-eg.com/attendance/api/mobile/manager/employees/${widget.employeeId}';

      final results = await Future.wait([
        http.get(Uri.parse('$base/profile/'), headers: headers).timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$base/documents/'), headers: headers).timeout(const Duration(seconds: 15)),
        http.get(Uri.parse('$base/movements/'), headers: headers).timeout(const Duration(seconds: 15)),
      ]);

      if (results[0].statusCode == 200) {
        _profile = json.decode(utf8.decode(results[0].bodyBytes));
      }
      if (results[1].statusCode == 200) {
        final d = json.decode(utf8.decode(results[1].bodyBytes));
        _documents = d['documents'] ?? [];
      }
      if (results[2].statusCode == 200) {
        final d = json.decode(utf8.decode(results[2].bodyBytes));
        _movements = d['movements'] ?? [];
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'خطأ في التحميل';
        _loading = false;
      });
    }
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    final full = url.startsWith('http') ? url : 'https://jssolutions-eg.com$url';
    final uri = Uri.parse(full);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _infoRow(String label, dynamic value, {IconData? icon}) {
    final v = (value == null || value.toString().isEmpty) ? '-' : value.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 6),
          ],
          SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, IconData icon, Color color, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    if (_profile == null) return const Center(child: Text('لا توجد بيانات'));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF4A148C)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              backgroundImage: (_profile!['photo'] != null && _profile!['photo'].toString().isNotEmpty)
                  ? NetworkImage('https://jssolutions-eg.com${_profile!['photo']}')
                  : null,
              child: (_profile!['photo'] == null || _profile!['photo'].toString().isEmpty)
                  ? const Icon(Icons.person, size: 34, color: Color(0xFF6A1B9A))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_profile!['full_name_ar'] ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_profile!['job_title'] ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                    child: Text(_profile!['employee_code'] ?? '',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmployeeSummaryScreen(
                  employeeId: widget.employeeId,
                  employeeName: widget.employeeName,
                ),
              ),
            ),
            icon: const Icon(Icons.analytics, color: Colors.white),
            label: const Text('عرض الملخص', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A1B9A),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard('البيانات الشخصية', Icons.person, const Color(0xFF1976D2), [
          _infoRow('الرقم القومي', _profile!['national_id'], icon: Icons.badge),
          _infoRow('تاريخ الميلاد', _profile!['birth_date'], icon: Icons.cake),
          _infoRow('النوع', _profile!['gender']),
          _infoRow('الحالة', _profile!['marital_status']),
          _infoRow('الجنسية', _profile!['nationality']),
        ]),
        _sectionCard('التواصل', Icons.phone, const Color(0xFF388E3C), [
          _infoRow('الموبايل', _profile!['phone'], icon: Icons.phone_android),
          _infoRow('البريد', _profile!['email'], icon: Icons.email),
          _infoRow('العنوان', _profile!['address'], icon: Icons.location_on),
        ]),
        _sectionCard('البيانات الوظيفية', Icons.work, const Color(0xFFE65100), [
          _infoRow('الفرع', _profile!['branch'], icon: Icons.business),
          _infoRow('الإدارة', _profile!['department']),
          _infoRow('المدير', _profile!['direct_manager']?['name']),
          _infoRow('تاريخ التعيين', _profile!['hire_date'], icon: Icons.calendar_today),
          _infoRow('نوع العقد', _profile!['contract_type']),
          _infoRow('الحالة', _profile!['status']),
        ]),
        _sectionCard('البيانات البنكية', Icons.account_balance, const Color(0xFF6A1B9A), [
          _infoRow('البنك', _profile!['bank_name']),
          _infoRow('رقم الحساب', _profile!['bank_account']),
          _infoRow('IBAN', _profile!['iban']),
          _infoRow('الراتب الأساسي', _profile!['basic_salary']),
        ]),
      ],
    );
  }

  IconData _docIcon(String type) {
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

  Widget _buildDocumentsTab() {
    if (_documents.isEmpty) return const Center(child: Text('لا توجد مستندات'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _documents.length,
      itemBuilder: (context, i) {
        final doc = _documents[i] as Map<String, dynamic>;
        final expired = doc['is_expired'] == true;
        final soon = doc['expires_soon'] == true;
        final color = expired ? Colors.red : (soon ? Colors.orange : const Color(0xFF388E3C));
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(_docIcon(doc['document_type_code'] ?? ''), color: color),
            ),
            title: Text(doc['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc['document_type'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                if (doc['expiry_date'] != null) Text('ينتهي: ${doc['expiry_date']}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                if (expired) Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('منتهي', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                )
                else if (soon) Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: const Text('ينتهي قريباً', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            trailing: doc['file_url'] != null ? Icon(Icons.download, color: color) : null,
            onTap: () => _openFile(doc['file_url']),
          ),
        );
      },
    );
  }

  Widget _buildMovementsTab() {
    if (_movements.isEmpty) return const Center(child: Text('لا توجد حركات'));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _movements.length,
      itemBuilder: (context, i) {
        final mv = _movements[i] as Map<String, dynamic>;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.history, size: 16, color: Color(0xFFE65100)),
                const SizedBox(width: 6),
                Text(mv['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                Text((mv['date'] ?? '').toString().split('T').first,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ]),
              if ((mv['notes'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(mv['notes'], style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6A1B9A),
          foregroundColor: Colors.white,
          title: Text(widget.employeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          actions: [IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh))],
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'الملف'),
              Tab(icon: Icon(Icons.folder), text: 'المستندات'),
              Tab(icon: Icon(Icons.history), text: 'التاريخ'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : TabBarView(
                    controller: _tabController,
                    children: [_buildProfileTab(), _buildDocumentsTab(), _buildMovementsTab()],
                  ),
      ),
    );
  }
}
