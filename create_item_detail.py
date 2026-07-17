# -*- coding: utf-8 -*-
"""
سكريبت ينشئ item_detail_screen.dart
شاشة تفاصيل الطلب/الإجازة مع المرفقات (Phase 4.1)
"""
import os

CONTENT = '''// lib/screens/item_detail_screen.dart
// Item Detail Screen - Shows request/leave details with attachments

import 'package:flutter/material.dart';
import '../widgets/attachments_widget.dart';

const kPrimaryColor = Color(0xFF6C63FF);

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final String itemType; // "leave" or "request"

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.itemType,
  });

  bool get isLeave => itemType == 'leave';

  String get modelName => isLeave 
    ? 'leaves.LeaveRequest' 
    : 'requests_app.EmployeeRequest';

  String get title => isLeave ? 'تفاصيل الإجازة' : 'تفاصيل الطلب';

  Color _statusColor(String s) {
    final lower = s.toLowerCase();
    if (s.contains('موافق') || lower.contains('approved')) return Colors.green;
    if (s.contains('رفض') || lower.contains('reject')) return Colors.red;
    return Colors.orange;
  }

  IconData _statusIcon(String s) {
    final lower = s.toLowerCase();
    if (s.contains('موافق') || lower.contains('approved')) return Icons.check_circle;
    if (s.contains('رفض') || lower.contains('reject')) return Icons.cancel;
    return Icons.access_time;
  }

  @override
  Widget build(BuildContext context) {
    final itemId = item['id'] is int 
      ? item['id'] 
      : int.tryParse('\${item['id']}') ?? 0;
    
    final status = (item['status_display'] ?? item['status'] ?? '').toString();
    final isPending = status.contains('معلق') || 
                      status.toLowerCase().contains('pending') || 
                      status.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusCard(status),

            const SizedBox(height: 16),

            // Details Card
            _buildDetailsCard(),

            const SizedBox(height: 16),

            // Attachments Section
            _buildAttachmentsSection(itemId, isPending),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _statusIcon(status),
              size: 42,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            status.isEmpty ? 'معلق' : status,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'التفاصيل',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            _buildRow(
              'النوع',
              '\${item['leave_type'] ?? item['type'] ?? item['title'] ?? '-'}',
              Icons.category,
            ),

            if (item['subject'] != null && '\${item['subject']}'.isNotEmpty)
              _buildRow('الموضوع', '\${item['subject']}', Icons.subject),

            if (item['start_date'] != null)
              _buildRow('تاريخ البداية', '\${item['start_date']}', Icons.event),

            if (item['end_date'] != null)
              _buildRow('تاريخ النهاية', '\${item['end_date']}', Icons.event_available),

            if (item['days_count'] != null)
              _buildRow('عدد الأيام', '\${item['days_count']} يوم', Icons.calendar_today),

            if (item['duration_hours'] != null)
              _buildRow('عدد الساعات', '\${item['duration_hours']} ساعة', Icons.access_time),

            if (item['amount'] != null && item['amount'] != 0)
              _buildRow('المبلغ', '\${item['amount']} جنيه', Icons.attach_money),

            if (item['reason'] != null && '\${item['reason']}'.isNotEmpty)
              _buildRow('السبب', '\${item['reason']}', Icons.comment),

            if (item['details'] != null && '\${item['details']}'.isNotEmpty)
              _buildRow('التفاصيل', '\${item['details']}', Icons.description),

            if (item['review_notes'] != null && '\${item['review_notes']}'.isNotEmpty)
              _buildRow(
                'ملاحظات المراجع',
                '\${item['review_notes']}',
                Icons.rate_review,
              ),

            _buildRow(
              'تاريخ التقديم',
              '\${item['created_at'] ?? '-'}'.split('T').first,
              Icons.schedule,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(int itemId, bool canEdit) {
    if (itemId <= 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'لا يمكن عرض المرفقات - معرف الطلب غير متاح',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canEdit)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'يمكنك إضافة مرفقات (تقارير، صور، وثائق) قبل موافقة المدير',
                    style: TextStyle(
                      color: Colors.blue.shade900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

        AttachmentsWidget(
          model: modelName,
          objectId: itemId,
          canEdit: canEdit,
        ),

        if (!canEdit)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 10),
                Text(
                  'لا يمكن تعديل المرفقات بعد المراجعة',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
'''

os.makedirs("lib/screens", exist_ok=True)

with open("lib/screens/item_detail_screen.dart", "w", encoding="utf-8") as f:
    f.write(CONTENT)

print("OK - item_detail_screen.dart created:", len(CONTENT), "bytes")