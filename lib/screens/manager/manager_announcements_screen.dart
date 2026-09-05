import 'package:motionhr_employee/services/api_client.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_storage_service.dart';
import 'create_announcement_screen.dart';

const _kColor = Color(0xFF5A43B5);
const _kBase = 'https://jssolutions-eg.com';

class ManagerAnnouncementsScreen extends StatefulWidget {
  const ManagerAnnouncementsScreen({super.key});

  @override
  State<ManagerAnnouncementsScreen> createState() =>
      _ManagerAnnouncementsScreenState();
}

class _ManagerAnnouncementsScreenState
    extends State<ManagerAnnouncementsScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  List<dynamic> _announcements = [];
  bool _loading = true;
  String? _error;
  String _search = '';

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
      final res = await http.get(
        Uri.parse('$_kBase/attendance/api/mobile/announcements/list/'),
        headers: await ApiClient.buildHeaders(),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _announcements = data['announcements'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = isAr
              ? 'خطأ في تحميل الإعلانات'
              : 'Failed to load announcements';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = isAr ? 'خطأ في الاتصال' : 'Connection error';
        _loading = false;
      });
    }
  }

  // ─── الإحصائيات ───
  int get _totalCount => _announcements.length;

  int get _todayCount {
    final today = DateTime.now();
    return _announcements.where((a) {
      final raw = (a['publish_at'] ?? '').toString();
      try {
        final d = DateTime.parse(raw);
        return d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
      } catch (_) {
        return false;
      }
    }).length;
  }

  // ─── فلترة البحث ───
  List<dynamic> get _filtered {
    if (_search.trim().isEmpty) return _announcements;
    final s = _search.toLowerCase().trim();
    return _announcements.where((a) {
      final title = (a['title'] ?? '').toString().toLowerCase();
      final msg = (a['message'] ?? '').toString().toLowerCase();
      return title.contains(s) || msg.contains(s);
    }).toList();
  }

  Future<void> _delete(Map<String, dynamic> ann) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الإعلان'),
          content: Text('هل أنت متأكد من حذف "${ann['title']}"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('تراجع'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.delete(
        Uri.parse(
          '$_kBase/attendance/api/mobile/manager/announcements/${ann['id']}/delete/',
        ),
        headers: await ApiClient.buildHeaders(includeContentType: true),
        body: jsonEncode({'send_deletion_notice': true}),
      );

      if (!mounted) return;

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isAr ? 'تم حذف الإعلان' : 'Announcement deleted'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (data['error'] ??
                      (isAr ? 'حدث خطأ' : 'An error occurred'))
                  .toString(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAr ? 'خطأ في الاتصال' : 'Connection error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'high':
        return Colors.red;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(String type) {
    if (type.contains('holiday')) return Icons.beach_access;
    if (type.contains('meeting')) return Icons.people;
    if (type.contains('event') || type.contains('celebration')) {
      return Icons.celebration;
    }
    if (type.contains('urgent')) return Icons.warning;
    return Icons.campaign;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'إدارة الإعلانات' : 'Manage Announcements',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _kColor,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _load,
            ),
          ],
        ),
        body: Column(
          children: [
            // ─── Header: إحصائيات + بحث ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: BoxDecoration(
                color: _kColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kColor.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // إحصائيات
                  if (!_loading)
                    Row(
                      children: [
                        _chip(
                          isAr ? 'الإجمالي' : 'Total',
                          '$_totalCount',
                          Icons.campaign,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          isAr ? 'اليوم' : 'Today',
                          '$_todayCount',
                          Icons.today,
                        ),
                        const SizedBox(width: 8),
                        _chip(
                          isAr ? 'النتائج' : 'Results',
                          '${filtered.length}',
                          Icons.filter_list,
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  // بحث
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: isAr
                          ? 'بحث في الإعلانات...'
                          : 'Search announcements...',
                      hintStyle:
                          const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── القائمة ───
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kColor),
                    )
                  : _error != null
                      ? _buildError()
                      : filtered.isEmpty
                          ? _buildEmpty()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildCard(filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateAnnouncementScreen(),
              ),
            );
            if (result == true) _load();
          },
          backgroundColor: _kColor,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            isAr ? 'إعلان جديد' : 'New Announcement',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> ann) {
    final priority = (ann['priority'] ?? 'medium').toString();
    final type = (ann['type'] ?? 'general').toString();
    final color = _getPriorityColor(priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child:
                      Icon(_getTypeIcon(type), color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (ann['title'] ?? '').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (ann['publish_at'] ?? '').toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateAnnouncementScreen(
                            announcement: ann,
                          ),
                        ),
                      );
                      if (result == true) _load();
                    } else if (value == 'delete') {
                      await _delete(ann);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: _kColor),
                          const SizedBox(width: 8),
                          Text(isAr ? 'تعديل' : 'Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'حذف' : 'Delete',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if ((ann['message'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                (ann['message'] ?? '').toString(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (ann['priority_display'] ?? priority).toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFF382483).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (ann['target_type_display'] ??
                            ann['target_type'] ??
                            '')
                        .toString(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF382483),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          Text(_error ?? (isAr ? 'حدث خطأ' : 'An error occurred')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _load,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kColor,
              foregroundColor: Colors.white,
            ),
            child: Text(isAr ? 'إعادة المحاولة' : 'Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _search.isNotEmpty
                ? (isAr ? 'لا توجد نتائج' : 'No results found')
                : (isAr ? 'لا توجد إعلانات' : 'No announcements'),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (_search.isEmpty)
            Text(
              isAr
                  ? 'اضغط + لإنشاء إعلان جديد'
                  : 'Press + to create a new announcement',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
        ],
      ),
    );
  }
}