import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'announcement_detail_screen.dart';

const kPrimaryColor = Color(0xFF6C63FF);
const kBaseUrl = 'https://jssolutions-eg.com';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  List<dynamic> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final res = await http.get(
        Uri.parse('$kBaseUrl/attendance/api/mobile/announcements/list/'),
        headers: {'Authorization': 'Token $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _announcements = data['announcements'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading announcements: $e');
    }
    setState(() => _loading = false);
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

  String _getTypeLabel(String type, bool isAr) {
    final t = type.toLowerCase();

    if (t.contains('holiday')) {
      return isAr ? 'إجازة' : 'Holiday';
    }
    if (t.contains('meeting')) {
      return isAr ? 'اجتماع' : 'Meeting';
    }
    if (t.contains('event')) {
      return isAr ? 'فعالية' : 'Event';
    }
    if (t.contains('celebration')) {
      return isAr ? 'احتفال' : 'Celebration';
    }
    if (t.contains('urgent')) {
      return isAr ? 'عاجل' : 'Urgent';
    }
    return isAr ? 'إعلان' : 'Announcement';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isAr ? 'إعلانات الشركة' : 'Company Announcements'),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _announcements.isEmpty
                ? Center(
                    child: Text(
                      isAr
                          ? 'لا توجد إعلانات حالياً'
                          : 'No announcements available currently',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAnnouncements,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _announcements.length,
                      itemBuilder: (context, index) {
                        final item = _announcements[index];
                        final isRead = item['is_read'] == true;
                        final color = _getPriorityColor(item['priority'] ?? '');

                        return Card(
                          elevation: isRead ? 1 : 3,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isRead
                                  ? Colors.transparent
                                  : kPrimaryColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(
                                _getTypeIcon(item['type'] ?? ''),
                                color: color,
                              ),
                            ),
                            title: Text(
                              item['title'] ?? '',
                              style: TextStyle(
                                fontWeight:
                                    isRead ? FontWeight.normal : FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  _getTypeLabel(item['type'] ?? '', isAr),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['publish_at'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            trailing: isRead
                                ? null
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: kPrimaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnnouncementDetailScreen(
                                    announcement: item,
                                  ),
                                ),
                              );
                              _loadAnnouncements();
                            },
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}