import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/employee_management_service.dart';

const Color kImportColor = Color(0xFF37474F);

class ImportToolsScreen extends StatefulWidget {
  const ImportToolsScreen({super.key});
  @override
  State<ImportToolsScreen> createState() => _ImportToolsScreenState();
}

class _ImportToolsScreenState extends State<ImportToolsScreen> {
  bool get isAr => Localizations.localeOf(context).languageCode == 'ar';

  bool _downloading = false;
  bool _uploading = false;
  bool _sendEmails = false;

  String? _selectedFilePath;
  String? _selectedFileName;
  String? _resultMessage;
  int? _created;
  int? _updated;
  int? _errors;
  bool _zeroWarning = false; // ignore: prefer_final_fields
  bool _resultSuccess = false;

  List<Map<String, dynamic>> _importLogs = [];
  bool _loadingLogs = false;

  Future<void> _downloadTemplate() async {
    setState(() => _downloading = true);
    try {
      final bytes = await EmployeeManagementService.downloadEmployeeTemplate();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/employee_import_template.xlsx');
      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: isAr ? 'نموذج استيراد الموظفين' : 'Employee import template',
        subject: isAr ? 'نموذج استيراد الموظفين' : 'Employee import template',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr
              ? 'تم تجهيز النموذج. اختر حفظه من نافذة المشاركة'
              : 'Template is ready. Save it from the share sheet'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      setState(() => _downloading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadImportLogs();
  }

  Future<void> _loadImportLogs() async {
    setState(() => _loadingLogs = true);
    try {
      final logs = await EmployeeManagementService.getImportLogs();
      if (mounted) setState(() => _importLogs = logs);
    } catch (_) {}
    if (mounted) setState(() => _loadingLogs = false);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
        _resultMessage = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isAr ? 'اختر ملف الإكسيل أولاً' : 'Please select an Excel file first'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() {
      _uploading = true;
      _resultMessage = null;
    });

    try {
      final result = await EmployeeManagementService.importEmployeesExcel(
        filePath: _selectedFilePath!,
        sendEmails: _sendEmails,
      );

      final created = result['created'] ?? 0;
      final updated = result['updated'] ?? 0;
      final errors = result['errors'] ?? 0;
      final hasZeroResults = result['has_zero_results'] ?? false;
      final isFailedImport = errors > 0 && created == 0 && updated == 0;

      setState(() {
        _created = created;
        _updated = updated;
        _errors = errors;
        _zeroWarning = hasZeroResults;
        _resultSuccess = !isFailedImport;
        _resultMessage = result['raw'] ?? result['message'] ?? '';
        _selectedFilePath = null;
        _selectedFileName = null;
      });

      _loadImportLogs();
    } catch (e) {
      setState(() {
        _resultSuccess = false;
        _resultMessage = e.toString().replaceFirst("Exception: ", "");
      });
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            isAr ? 'أدوات الاستيراد' : 'Import Tools',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: kImportColor,
          foregroundColor: Colors.white,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _infoCard(),
            const SizedBox(height: 16),
            _downloadCard(),
            const SizedBox(height: 16),
            _uploadCard(),
            if (_resultMessage != null) ...[
              const SizedBox(height: 16),
              _resultCard(),
            ],
            const SizedBox(height: 24),
            _logsSection(),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Card(
      color: kImportColor.withAlpha(15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Icon(Icons.info_outline, color: kImportColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isAr
                  ? 'نزّل النموذج، عبّيه ببيانات الموظفين، وارفعه للسيستم'
                  : 'Download the template, fill in employee data, then upload it',
              style: const TextStyle(color: kImportColor),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _downloadCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isAr ? 'الخطوة 1: تحميل نموذج الإكسيل' : 'Step 1: Download Excel Template',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'حمّل الشيت الفارغ الجاهز مع كل الأعمدة والقوائم المنسدلة'
                : 'Download the ready template with all columns and dropdown lists',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloading ? null : _downloadTemplate,
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download),
              label: Text(isAr ? 'تحميل النموذج' : 'Download Template'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kImportColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _uploadCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isAr ? 'الخطوة 2: رفع الشيت بعد التعبئة' : 'Step 2: Upload Filled Sheet',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedFileName != null ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(10),
                color: _selectedFileName != null
                    ? Colors.green.withAlpha(10)
                    : Colors.grey[100],
              ),
              child: Row(children: [
                Icon(
                  _selectedFileName != null ? Icons.check_circle : Icons.upload_file,
                  color: _selectedFileName != null ? Colors.green : Colors.grey,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedFileName ??
                        (isAr ? 'اضغط لاختيار ملف الإكسيل' : 'Tap to select Excel file'),
                    style: TextStyle(
                      color: _selectedFileName != null ? Colors.green : Colors.grey[600],
                      fontWeight: _selectedFileName != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(isAr ? 'إرسال إيميل للموظفين الجدد' : 'Send emails to new employees'),
            subtitle: Text(
              isAr
                  ? 'يرسل بيانات الدخول لكل موظف عنده إيميل'
                  : 'Sends login credentials to employees with email',
              style: const TextStyle(fontSize: 12),
            ),
            value: _sendEmails,
            activeThumbColor: kImportColor,
            onChanged: (v) => setState(() => _sendEmails = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploading ? null : _uploadFile,
              icon: _uploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(isAr ? 'رفع وتنفيذ الاستيراد' : 'Upload & Import'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _resultCard() {
    final bool isWarning = _zeroWarning && _resultSuccess;
    final Color mainColor = isWarning ? Colors.orange : (_resultSuccess ? Colors.green : Colors.red);
    final Color? bgColor = isWarning ? Colors.orange[50] : (_resultSuccess ? Colors.green[50] : Colors.red[50]);

    return Card(
      elevation: 3,
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: mainColor.withAlpha(100), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(isWarning ? Icons.warning_amber_rounded : (_resultSuccess ? Icons.check_circle : Icons.error_outline), color: mainColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isWarning
                    ? (isAr ? 'تنبيه: لا توجد بيانات صالحة' : 'Warning: No valid data')
                    : (isAr ? (_resultSuccess ? 'نتيجة الاستيراد' : 'فشل الاستيراد') : (_resultSuccess ? 'Import Result' : 'Import Failed')),
                style: TextStyle(fontWeight: FontWeight.bold, color: mainColor, fontSize: 16),
              ),
            ),
          ]),
          const Divider(height: 24),
          if (_resultSuccess) ...[
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statItem(isAr ? 'جديد' : 'New', _created ?? 0, Colors.green),
              _statItem(isAr ? 'تحديث' : 'Updated', _updated ?? 0, Colors.blue),
              _statItem(isAr ? 'أخطاء' : 'Errors', _errors ?? 0, Colors.red),
            ]),
            const SizedBox(height: 16),
          ],
          if (isWarning) ...[
            const SizedBox(height: 8),
            Text(
              isAr
                  ? 'لم يتم العثور على أي موظفين في الملف. تأكد من:'
                  : 'No employees found in the file. Make sure:',
              style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(isAr ? '• البيانات تبدأ من الصف الرابع' : '• Data starts from row 4', style: TextStyle(color: Colors.orange[800])),
            Text(isAr ? '• عمود نوع العملية فيه new أو update' : '• operation_type column has new or update', style: TextStyle(color: Colors.orange[800])),
          ],
          if (_resultMessage != null && _resultMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(isAr ? 'التفاصيل:' : 'Details:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(6),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Text(
                  _resultMessage!,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _statItem(String label, int value, Color color) {
    return Column(children: [
      Text(
        value.toString(),
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 12, color: color.withAlpha(180))),
    ]);
  }

  Widget _logsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.history, color: kImportColor),
        const SizedBox(width: 8),
        Text(
          isAr ? 'سجل العمليات (آخر 3 أيام)' : 'Import History (last 3 days)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kImportColor),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.refresh, color: kImportColor),
          onPressed: _loadImportLogs,
        ),
      ]),
      if (_loadingLogs)
        const Center(child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ))
      else if (_importLogs.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                isAr ? 'لا توجد عمليات استيراد في آخر 3 أيام' : 'No import operations in the last 3 days',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        )
      else
        ..._importLogs.map((log) => _logItem(log)),
    ]);
  }

  Widget _logItem(Map<String, dynamic> log) {
    final int created = log['created_count'] ?? 0;
    final int updated = log['updated_count'] ?? 0;
    final int errors  = log['error_count'] ?? 0;
    final String filename = log['original_filename'] ?? (isAr ? 'ملف غير معروف' : 'Unknown file');
    final String date = log['created_at'] ?? '';
    final String uploadedBy = log['uploaded_by'] ?? '';
    final String? fileUrl = log['file_url'];

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.insert_drive_file, color: kImportColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(filename,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (fileUrl != null)
              IconButton(
                icon: const Icon(Icons.download, color: kImportColor, size: 20),
                tooltip: isAr ? 'تحميل الملف' : 'Download file',
                onPressed: () async {
                  try {
                    final bytes = await EmployeeManagementService.downloadFromUrl(fileUrl);
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/$filename');
                    await file.writeAsBytes(bytes, flush: true);
                    await Share.shareXFiles([XFile(file.path)], text: filename);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
          ]),
          const SizedBox(height: 6),
          Text('$date  •  $uploadedBy',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
          const SizedBox(height: 8),
          Row(children: [
            _miniStat(isAr ? 'جديد' : 'New', created, Colors.green),
            const SizedBox(width: 12),
            _miniStat(isAr ? 'تحديث' : 'Updated', updated, Colors.blue),
            const SizedBox(width: 12),
            _miniStat(isAr ? 'أخطاء' : 'Errors', errors, Colors.red),
          ]),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Row(children: [
      Text(value.toString(),
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: color.withAlpha(180), fontSize: 11)),
    ]);
  }
}