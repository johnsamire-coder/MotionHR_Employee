// lib/widgets/attachments_widget.dart
// Attachments Widget - Reusable widget for file attachments (Phase 4) - FIXED

import 'package:flutter/material.dart';
import '../services/attachment_service.dart';
import 'package:motionhr_employee/l10n/l10n.dart';

class AttachmentsWidget extends StatefulWidget {
  final String model;
  final int? objectId;
  final bool canEdit;
  final int maxFiles;
  final Function(List<AttachmentModel>)? onChanged;

  const AttachmentsWidget({
    super.key,
    required this.model,
    this.objectId,
    this.canEdit = true,
    this.maxFiles = 10,
    this.onChanged,
  });

  @override
  State<AttachmentsWidget> createState() => _AttachmentsWidgetState();
}

class _AttachmentsWidgetState extends State<AttachmentsWidget> {
  List<AttachmentModel> _attachments = [];
  bool _loading = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.objectId != null) {
      _loadAttachments();
    }
  }

  Future<void> _loadAttachments() async {
    setState(() => _loading = true);
    try {
      final list = await AttachmentService.list(
        model: widget.model,
        objectId: widget.objectId!,
      );
      setState(() {
        _attachments = list;
        _loading = false;
      });
      widget.onChanged?.call(_attachments);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المرفقات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddOptions() {
    if (_attachments.length >= widget.maxFiles) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('الحد الأقصى ${widget.maxFiles} ملفات'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'اختر مصدر الملف',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildOption(
              icon: Icons.camera_alt,
              color: Colors.blue,
              title: 'التقاط صورة',
              onTap: () => _pickAndUpload('camera'),
            ),
            _buildOption(
              icon: Icons.photo_library,
              color: Colors.green,
              title: 'من المعرض',
              onTap: () => _pickAndUpload('gallery'),
            ),
            _buildOption(
              icon: Icons.attach_file,
              color: Colors.orange,
              title: 'اختيار ملف (PDF/Word/Excel)',
              onTap: () => _pickAndUpload('file'),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Future<void> _pickAndUpload(String source) async {
    try {
      PickedFile? picked;

      if (source == 'camera') {
        picked = await AttachmentService.pickImageFromCamera();
      } else if (source == 'gallery') {
        picked = await AttachmentService.pickImageFromGallery();
      } else {
        picked = await AttachmentService.pickFile();
      }

      if (picked == null) return;

      if (picked.error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(picked.error!),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (widget.objectId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('احفظ الطلب أولاً قبل رفع المرفقات'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      setState(() => _uploading = true);

      final result = await AttachmentService.upload(
        filePath: picked.path,
        model: widget.model,
        objectId: widget.objectId!,
      );

      setState(() => _uploading = false);

      if (result.success && result.attachment != null) {
        setState(() {
          _attachments.add(result.attachment!);
        });
        widget.onChanged?.call(_attachments);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم رفع الملف بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'خطأ في الرفع'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _uploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAttachment(AttachmentModel attachment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المرفق'),
        content: Text('هل تريد حذف "${attachment.originalName}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await AttachmentService.delete(attachment.id);

    if (success) {
      setState(() {
        _attachments.removeWhere((a) => a.id == attachment.id);
      });
      widget.onChanged?.call(_attachments);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف المرفق'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حذف المرفق'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openAttachment(AttachmentModel attachment) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جاري فتح الملف...'),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await AttachmentService.downloadAndOpen(attachment);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لا يمكن فتح الملف'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getFileIcon(AttachmentModel a) {
    if (a.isImage) return Icons.image;
    if (a.isPdf) return Icons.picture_as_pdf;
    if (a.isWord) return Icons.description;
    if (a.isExcel) return Icons.table_chart;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(AttachmentModel a) {
    if (a.isImage) return Colors.purple;
    if (a.isPdf) return Colors.red;
    if (a.isWord) return Colors.blue;
    if (a.isExcel) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header - FIXED with Wrap to prevent overflow
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_file, size: 20, color: Colors.blue),
                  SizedBox(width: 6),
                  const Text(
                    'المرفقات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_attachments.length}/${widget.maxFiles}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.canEdit)
                TextButton.icon(
                  onPressed: _uploading ? null : _showAddOptions,
                  icon: Icon(
                    _uploading ? Icons.hourglass_empty : Icons.add_circle,
                    size: 20,
                  ),
                  label: Text(_uploading ? 'جاري الرفع...' : context.l10n.add),
                ),
            ],
          ),

          SizedBox(height: 8),

          // List
          if (_loading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 40, color: Colors.grey.shade400),
                    SizedBox(height: 8),
                    Text(
                      'لا توجد مرفقات',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (widget.canEdit) ...[
                      SizedBox(height: 4),
                      Text(
                        'اضغط "إضافة" لرفع ملف',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            ..._attachments.map((a) => _buildAttachmentTile(a)),
        ],
      ),
    );
  }

  Widget _buildAttachmentTile(AttachmentModel a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getFileColor(a).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getFileIcon(a), color: _getFileColor(a), size: 20),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.originalName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  a.sizeFormatted,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.download, size: 20, color: Colors.blue),
            onPressed: () => _openAttachment(a),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          if (widget.canEdit)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: () => _deleteAttachment(a),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}