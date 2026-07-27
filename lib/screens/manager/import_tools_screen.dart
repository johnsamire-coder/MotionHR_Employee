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
  bool _resultSuccess = false;

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

      setState(() {
        _resultSuccess = true;
        _resultMessage = result['details'] ?? result['message'] ?? (isAr ? 'تم الاستيراد بنجاح' : 'Import completed successfully');
        _selectedFilePath = null;
        _selectedFileName = null;
      });
    } catch (e) {
      setState(() {
        _resultSuccess = false;
        _resultMessage = e.toString();
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
    return Card(
      elevation: 2,
      color: _resultSuccess ? Colors.green[50] : Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(
              _resultSuccess ? Icons.check_circle : Icons.error_outline,
              color: _resultSuccess ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isAr
                  ? (_resultSuccess ? 'تم الاستيراد بنجاح' : 'فشل الاستيراد')
                  : (_resultSuccess ? 'Import Successful' : 'Import Failed'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _resultSuccess ? Colors.green : Colors.red,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            _resultMessage ?? '',
            style: TextStyle(
              color: _resultSuccess ? Colors.green[800] : Colors.red[800],
              fontSize: 13,
            ),
          ),
        ]),
      ),
    );
  }
}
