import 'package:flutter/material.dart';
import '../../services/employee_management_service.dart';
import '../../widgets/empty_state_widget.dart';

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({super.key});

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  Map<String, dynamic>? _company;
  bool _loading = true;
  String? _error;

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
      final data = await EmployeeManagementService.getCompanyInfo();
      if (!mounted) return;
      setState(() {
        _company = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('بيانات الشركة'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyStateWidget(
                  title: 'خطأ في التحميل',
                  description: _error!,
                  icon: Icons.error_outline,
                  iconColor: Colors.red,
                  onRefresh: _load,
                )
              : _company == null
                  ? EmptyStateWidget(
                      title: 'لا توجد بيانات',
                      description: 'تعذر جلب بيانات الشركة',
                      icon: Icons.business_outlined,
                      onRefresh: _load,
                    )
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final c = _company!;
    final stats = (c['stats'] as Map?) ?? {};
    final logoUrl = c['logo_url']?.toString() ?? '';

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A148C), Color(0xFF7B1FA2), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // ── لوجو ──
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(10),
                  child: logoUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business,
                              size: 60,
                              color: Color(0xFF6A1B9A),
                            ),
                          ),
                        )
                      : const Icon(Icons.business, size: 60, color: Color(0xFF6A1B9A)),
                ),
                const SizedBox(height: 16),
                Text(
                  c['name_ar']?.toString() ?? 'شركة',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if ((c['name_en'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    c['name_en'].toString(),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
                if ((c['industry'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c['industry'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── إحصائيات ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _statCard('${stats['branches'] ?? 0}', 'الفروع', Icons.business, Colors.blue),
                const SizedBox(width: 10),
                _statCard('${stats['departments'] ?? 0}', 'الإدارات', Icons.apartment, Colors.orange),
                const SizedBox(width: 10),
                _statCard('${stats['employees'] ?? 0}', 'الموظفين', Icons.people, Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── بيانات الاتصال ──
          _section(
            'بيانات الاتصال',
            Icons.phone,
            Colors.blue,
            [
              if ((c['phone'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.phone, 'الهاتف', c['phone'].toString()),
              if ((c['email'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.email, 'البريد', c['email'].toString()),
              if ((c['website'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.language, 'الموقع', c['website'].toString()),
              if ((c['address'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.location_on, 'العنوان', c['address'].toString()),
            ],
          ),

          // ── بيانات قانونية ──
          _section(
            'البيانات القانونية',
            Icons.gavel,
            Colors.purple,
            [
              if ((c['commercial_register'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.assignment, 'السجل التجاري', c['commercial_register'].toString()),
              if ((c['tax_number'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.receipt_long, 'الرقم الضريبي', c['tax_number'].toString()),
              if ((c['founded_date'] ?? '').toString().isNotEmpty)
                _infoRow(Icons.calendar_today, 'تاريخ التأسيس', c['founded_date'].toString()),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, Color color, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}