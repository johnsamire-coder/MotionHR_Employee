// lib/services/employee_pdf_service.dart
// PDF generation for new employee credentials + WhatsApp sharing

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;

class EmployeePdfService {
  /// Generate PDF file with employee credentials
  /// Returns File path
  static Future<String> generateEmployeePdf({
    required Map<String, dynamic> employee,
    required Map<String, dynamic> credentials,
    required Map<String, dynamic> whatsapp,
    String? companyName,
    String? companyLogoUrl,
    String? companyPhone,
    String? companyAddress,
  }) async {
    final pdf = pw.Document();
    // تحميل لوجو الشركة
    pw.MemoryImage? logoImage;
    if (companyLogoUrl != null && companyLogoUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(companyLogoUrl))
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    // Use built-in font that supports Latin - for Arabic we'll use simple approach
    // For proper Arabic, we would need to embed Arabic TTF font
    // Here we use Helvetica with English labels + Arabic values may not render perfect,
    // so we provide both Arabic labels as transliterated and English.
    
    // Try to load a font that supports Arabic if available, otherwise fallback
    pw.Font? arabicFont;
    try {
      // Attempt to use a standard font - pdf package may not support Arabic fully
      // We'll create PDF with English headers to ensure readability
      arabicFont = pw.Font.helvetica();
    } catch (_) {
      arabicFont = pw.Font.helvetica();
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [                // Header بلوجو الشركة
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1976D2),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Row(
                    children: [
                      // اللوجو
                      pw.Container(
                        width: 80,
                        height: 80,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        padding: const pw.EdgeInsets.all(6),
                        child: logoImage != null
                            ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                            : pw.Center(
                                child: pw.Text(
                                  'HR',
                                  style: pw.TextStyle(
                                    fontSize: 30,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromInt(0xFF1976D2),
                                  ),
                                ),
                              ),
                      ),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              companyName ?? employee['company'] ?? 'Company',
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                font: arabicFont,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'MotionHR System',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColor.fromInt(0xFFE3F2FD),
                                font: arabicFont,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Employee Account Details',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColor.fromInt(0xFFBBDEFB),
                                font: arabicFont,
                              ),
                            ),
                            if (companyPhone != null && companyPhone.isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'Tel: $companyPhone',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  color: PdfColor.fromInt(0xFFE3F2FD),
                                  font: arabicFont,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'بيانات الموظف',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    font: arabicFont,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildInfoRow('الاسم الكامل:', employee['full_name_ar'] ?? '', arabicFont),
                _buildInfoRow('الرقم الوظيفي:', employee['employee_code'] ?? '', arabicFont),
                _buildInfoRow('رقم الموبايل:', employee['phone'] ?? '', arabicFont),
                _buildInfoRow('الرقم القومي:', employee['national_id'] ?? '', arabicFont),
                _buildInfoRow('الفرع:', employee['branch'] ?? '', arabicFont),
                _buildInfoRow('القسم:', employee['department'] ?? '', arabicFont),
                _buildInfoRow('المسمى الوظيفي:', employee['job_title'] ?? '', arabicFont),
                _buildInfoRow('تاريخ التعيين:', employee['hire_date'] ?? '', arabicFont),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 12),
                pw.Text(
                  'بيانات الدخول',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    font: arabicFont,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF5F5F5),
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xFF1976D2),
                      width: 1.5,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCredentialRow('اسم المستخدم / Username:', credentials['username'] ?? '', arabicFont, isBold: true),
                      pw.SizedBox(height: 12),
                      _buildCredentialRow('كلمة المرور / Password:', credentials['password'] ?? '', arabicFont, isBold: true, isPassword: true),
                      pw.SizedBox(height: 12),
                      _buildCredentialRow('رابط الدخول:', credentials['login_url'] ?? 'https://jssolutions-eg.com', arabicFont),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFFF3E0),
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFFF9800)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'تعليمات هامة:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          font: arabicFont,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        '1. قم بتسجيل الدخول باستخدام اسم المستخدم وكلمة المرور اعلاه',
                        style: pw.TextStyle(fontSize: 10, font: arabicFont),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '2. سيطلب منك تغيير كلمة المرور عند أول دخول',
                        style: pw.TextStyle(fontSize: 10, font: arabicFont),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '3. حمل تطبيق MotionHR من المتجر وسجل دخولك',
                        style: pw.TextStyle(fontSize: 10, font: arabicFont),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '4. لا تشارك بيانات الدخول مع أي شخص آخر',
                        style: pw.TextStyle(fontSize: 10, font: arabicFont),
                      ),
                    ],
                  ),
                ),                pw.Spacer(),
                pw.Divider(thickness: 0.5),
                pw.SizedBox(height: 6),
                if (companyAddress != null && companyAddress.isNotEmpty)
                  pw.Text(
                    companyAddress,
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700, font: arabicFont),
                    textAlign: pw.TextAlign.center,
                  ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated: ${DateTime.now().toString().split('.')[0]}',
                      style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, font: arabicFont),
                    ),
                    pw.Text(
                      'MotionHR System',
                      style: pw.TextStyle(fontSize: 8, color: PdfColor.fromInt(0xFF1976D2), fontWeight: pw.FontWeight.bold, font: arabicFont),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save to temp directory
    final dir = await getTemporaryDirectory();
    final fileName = 'MotionHR_${employee['employee_code'] ?? 'employee'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font? font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: font, color: PdfColor.fromInt(0xFF616161)),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, font: font),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCredentialRow(String label, String value, pw.Font? font, {bool isBold = false, bool isPassword = false}) {
    return pw.Row(
      children: [
        pw.Container(
          width: 160,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, font: font),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: isPassword ? PdfColor.fromInt(0xFFFFEBEE) : PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: isPassword ? PdfColor.fromInt(0xFFE53935) : PdfColor.fromInt(0xFFBDBDBD),
              ),
            ),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: isBold ? 14 : 11,
                fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
                font: font,
                color: isPassword ? PdfColor.fromInt(0xFFC62828) : PdfColors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Share PDF via system share sheet (user can choose WhatsApp)
  static Future<void> sharePdf(String filePath, {String? phone, String? employeeName}) async {
    final file = XFile(filePath);
    final text = employeeName != null
        ? 'مرحبا $employeeName 👋\n\nتم إنشاء حسابك في نظام MotionHR\n\nستجد في الملف المرفق بيانات الدخول الخاصة بك\n\nيرجى تغيير كلمة المرور عند أول دخول\n\nشكرا لك!'
        : 'بيانات حسابك في MotionHR';

    await Share.shareXFiles([file], text: text, subject: 'MotionHR - بيانات الحساب');
  }

  /// Open WhatsApp directly with phone number (text only, PDF must be shared via share sheet)
  static Future<void> openWhatsApp(String phone, {String? message}) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    // Ensure Egyptian number handling: if starts with 0, replace with 2
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '2$cleanPhone';
    }
    // If not starting with 2, assume it's Egyptian and add 20?
    // Better keep as is but wa.me expects full international number without +
    
    final text = message ?? 'مرحبا! تم إنشاء حسابك في MotionHR، سأرسل لك ملف PDF ببيانات الدخول';
    final encodedText = Uri.encodeComponent(text);
    
    // Try whatsapp:// first
    final whatsappUrl = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encodedText');
    final webUrl = Uri.parse('https://wa.me/$cleanPhone?text=$encodedText');
    
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('لا يمكن فتح واتساب');
      }
    } catch (e) {
      // Fallback to web
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        rethrow;
      }
    }
  }

  /// Share both: open WhatsApp + share PDF
  static Future<void> shareViaWhatsAppWithPdf({
    required String filePath,
    required String phone,
    required String employeeName,
    required String username,
    required String password,
  }) async {
    // First share the PDF file
    await sharePdf(filePath, phone: phone, employeeName: employeeName);
    
    // Small delay then open WhatsApp (optional - user might want both)
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
