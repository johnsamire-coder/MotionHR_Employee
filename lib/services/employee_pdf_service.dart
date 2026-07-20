// lib/services/employee_pdf_service.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cross_file/cross_file.dart';
import 'branding_service.dart';

class EmployeePdfService {
  static Future<String> generateEmployeePdf({
    required Map<String, dynamic> employee,
    required Map<String, dynamic> credentials,
    required Map<String, dynamic> whatsapp,
    String? companyName,
    String? companyLogoUrl,
    String? companyPhone,
    String? companyAddress,
  }) async {
    await BrandingService.ensureFontsLoaded();
    final company = await BrandingService.getCompany();
    final logo = await BrandingService.getLogo();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                BrandingService.buildPdfHeader(
                  company: company,
                  logo: logo,
                  subtitle: 'Employee Account Details',
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'بيانات الموظف',
                  style: BrandingService.arabicStyle(fontSize: 18, bold: true),
                ),
                pw.SizedBox(height: 12),
                _buildInfoRow('الاسم الكامل:', employee['full_name_ar'] ?? ''),
                _buildInfoRow('الرقم الوظيفي:', employee['employee_code'] ?? ''),
                _buildInfoRow('رقم الموبايل:', employee['phone'] ?? ''),
                _buildInfoRow('الفرع:', employee['branch'] ?? ''),
                _buildInfoRow('القسم:', employee['department'] ?? ''),
                _buildInfoRow('المسمى الوظيفي:', employee['job_title'] ?? ''),
                pw.SizedBox(height: 20),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.SizedBox(height: 12),
                pw.Text(
                  'بيانات الدخول',
                  style: BrandingService.arabicStyle(fontSize: 18, bold: true),
                ),
                pw.SizedBox(height: 12),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF5F5F5),
                    borderRadius: pw.BorderRadius.circular(10),
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0xFF6A1B9A),
                      width: 1.5,
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCredentialRow('Username:', credentials['username'] ?? '', isBold: true),
                      pw.SizedBox(height: 12),
                      _buildCredentialRow('Password:', credentials['password'] ?? '', isBold: true, isPassword: true),
                      pw.SizedBox(height: 12),
                      _buildCredentialRow('Login URL:', credentials['login_url'] ?? 'https://jssolutions-eg.com'),
                    ],
                  ),
                ),
                pw.Spacer(),
                BrandingService.buildPdfFooter(company: company),
              ],
            ),
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = 'MotionHR_${employee['employee_code'] ?? 'emp'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Container(
            width: 130,
            child: pw.Text(
              label,
              style: BrandingService.arabicStyle(
                fontSize: 11,
                bold: true,
                color: PdfColor.fromInt(0xFF616161),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: BrandingService.arabicStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCredentialRow(
    String label,
    String value, {
    bool isBold = false,
    bool isPassword = false,
  }) {
    return pw.Row(
      children: [
        pw.Container(
          width: 120,
          child: pw.Text(
            label,
            style: BrandingService.arabicStyle(fontSize: 12, bold: true),
          ),
        ),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: isPassword ? PdfColor.fromInt(0xFFFFEBEE) : PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(
                color: isPassword
                    ? PdfColor.fromInt(0xFFE53935)
                    : PdfColor.fromInt(0xFFBDBDBD),
              ),
            ),
            child: pw.Text(
              value,
              style: BrandingService.arabicStyle(
                fontSize: isBold ? 13 : 11,
                bold: isBold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> sharePdf(String filePath, {String? phone, String? employeeName}) async {
    final file = XFile(filePath);
    const text = 'بيانات حسابك في MotionHR';
    await Share.shareXFiles([file], text: text);
  }

  static Future<void> openWhatsApp(String phone, {String? message}) async {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) cleanPhone = '2$cleanPhone';
    final text = message ?? 'مرحبا! تم إنشاء حسابك في MotionHR';
    final url = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
