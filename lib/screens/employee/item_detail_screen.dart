import 'package:flutter/material.dart';
import '../../widgets/attachments_widget.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class ItemDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final String itemType; // leave_request | request

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.itemType,
  });

  Color statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'approved':
        return context.l10n.approved;
      case 'rejected':
        return context.l10n.rejected;
      case 'pending':
        return context.l10n.pending;
      default:
        return status;
    }
  }

  String value(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    final status = value(item['status']).isEmpty ? 'pending' : value(item['status']);
    final id = item['id'] is int ? item['id'] as int : int.tryParse(value(item['id'])) ?? 0;

    final notes = value(item['notes']).isNotEmpty
        ? value(item['notes'])
        : value(item['reason']);

    final rejectReason = value(item['reject_reason']);
    final createdAt = value(item['created_at']);
    final startDate = value(item['start_date']);
    final endDate = value(item['end_date']);
    final days = value(item['days']).isNotEmpty
        ? value(item['days'])
        : value(item['duration_days']);
    final amount = value(item['amount']);

    final title = itemType == 'leave_request' ? 'تفاصيل الإجازة' : 'تفاصيل الطلب';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          backgroundColor: const Color(0xFF1976D2),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor(status)),
                        ),
                        child: Text(
                          statusLabel(context, status),
                          style: TextStyle(
                            color: statusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '#$id',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.requestDetails,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Divider(height: 20),

                      if (itemType == 'leave_request') ...[
                        infoRow(context.l10n.gender, value(item['leave_type_name'])),
                        if (startDate.isNotEmpty) infoRow('من', startDate),
                        if (endDate.isNotEmpty) infoRow('إلى', endDate),
                        if (days.isNotEmpty) infoRow('عدد الأيام', '$days يوم'),
                      ] else ...[
                        infoRow(context.l10n.gender, value(item['request_type_name'])),
                        if (amount.isNotEmpty) infoRow('المبلغ', '$amount جنيه'),
                        if (days.isNotEmpty) infoRow('المدة', days),
                      ],

                      if (createdAt.isNotEmpty)
                        infoRow('تاريخ الطلب', createdAt.split('T').first),

                      if (notes.isNotEmpty) ...[
                        SizedBox(height: 8),
                        const Text(
                          'السبب / الملاحظات',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notes,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],

                      if (rejectReason.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'سبب الرفض',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                rejectReason,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              if (id > 0)
                AttachmentsWidget(
                  model: itemType == 'leave_request'
                      ? 'leaves.LeaveRequest'
                      : 'requests_app.EmployeeRequest',
                  objectId: id,
                  canEdit: status == 'pending',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
