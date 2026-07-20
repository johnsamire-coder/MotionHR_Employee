import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const kPrimaryColor = Color(0xFF6C63FF);
const kBaseUrl = 'https://jssolutions-eg.com';

class AnnouncementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  bool _isRead = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _isRead = widget.announcement['is_read'] == true;
    _confirmed = widget.announcement['is_read'] == true;
    if (!_isRead) _markAsRead();
  }

  Future<void> _markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      await http.post(
        Uri.parse('$kBaseUrl/attendance/api/mobile/announcements/mark-read/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'announcement_id': widget.announcement['id']}),
      );
      setState(() => _isRead = true);
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _getTypeIcon(String type) {
    if (type.contains('holiday')) return Icons.beach_access;
    if (type.contains('meeting')) return Icons.people;
    if (type.contains('event') || type.contains('celebration'))
      return Icons.celebration;
    if (type.contains('urgent')) return Icons.warning;
    if (type.contains('policy')) return Icons.policy;
    if (type.contains('reminder')) return Icons.alarm;
    return Icons.campaign;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final ann = widget.announcement;
    final priority = ann['priority'] ?? 'medium';
    final priorityColor = _getPriorityColor(priority);
    final requiresConfirmation = ann['requires_confirmation'] == true;

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isAr ? 'تفاصيل الإعلان' : 'Announcement Details',
          ),
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: kPrimaryColor.withOpacity(0.15),
                      child: Icon(
                        _getTypeIcon(ann['type'] ?? ''),
                        color: kPrimaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ann['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: priorityColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        ann['priority_display'] ?? '',
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Details Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAr ? 'تفاصيل الإعلان' : 'Announcement Details',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(height: 20),
                      _buildRow(
                        Icons.category,
                        isAr ? 'النوع' : 'Type',
                        ann['type_display'] ?? '',
                      ),
                      _buildRow(
                        Icons.schedule,
                        isAr ? 'تاريخ النشر' : 'Published At',
                        ann['publish_at'] ?? '',
                      ),
                      if (ann['expires_at'] != null)
                        _buildRow(
                          Icons.event_busy,
                          isAr ? 'ينتهي في' : 'Expires At',
                          ann['expires_at'],
                        ),
                      if ((ann['created_by'] ?? '').toString().isNotEmpty)
                        _buildRow(
                          Icons.person,
                          isAr ? 'من' : 'By',
                          ann['created_by'],
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Message Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.message,
                              color: kPrimaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'محتوى الإعلان' : 'Announcement Content',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        ann['message'] ?? '',
                        style:
                            const TextStyle(fontSize: 15, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Confirmation Card
              if (requiresConfirmation)
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  color: _confirmed
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(
                          _confirmed ? Icons.check_circle : Icons.info,
                          color:
                              _confirmed ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _confirmed
                              ? (isAr
                                  ? 'تم تأكيد القراءة'
                                  : 'Reading Confirmed')
                              : (isAr
                                  ? 'يتطلب هذا الإعلان تأكيد القراءة'
                                  : 'This announcement requires reading confirmation'),
                          style: TextStyle(
                            color: _confirmed
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (!_confirmed) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() => _confirmed = true);
                            },
                            icon: const Icon(Icons.check),
                            label: Text(
                              isAr ? 'تأكيد القراءة' : 'Confirm Reading',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}