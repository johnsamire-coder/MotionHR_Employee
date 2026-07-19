// lib/services/branding_service.dart
// خدمة موحدة لإضافة Branding الشركة على جميع ملفات PDF/Excel

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'employee_management_service.dart';

class BrandingService {
  static Map<String, dynamic>? cachedCompany;
  static pw.MemoryImage? cachedLogo;

  /// جلب بيانات الشركة (مع cache)
  static Future<Map<String, dynamic>> getCompany() async {
    if (cachedCompany != null) return cachedCompany!;
    try {
      cachedCompany = await EmployeeManagementService.getCompanyInfo();
    } catch (_) {
      cachedCompany = {};
    }
    return cachedCompany!;
  }

  /// جلب لوجو الشركة (مع cache)
  static Future<pw.MemoryImage?> getLogo() async {
    if (cachedLogo != null) return cachedLogo;
    try {
      final company = await getCompany();
      final logoUrl = company['logo_url']?.toString() ?? '';
      if (logoUrl.isEmpty) return null;

      final res = await http
          .get(Uri.parse(logoUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        cachedLogo = pw.MemoryImage(res.bodyBytes);
      }
    } catch (_) {}
    return cachedLogo;
  }

  /// مسح الـ cache (لو الشركة عدلت اللوجو)
  static void clearCache() {
    cachedCompany = null;
    cachedLogo = null;
  }

  /// PDF Header موحد
  static pw.Widget buildPdfHeader({
    required Map<String, dynamic> company,
    pw.MemoryImage? logo,
    String? subtitle,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF6A1B9A),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 65,
            height: 65,
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: const pw.EdgeInsets.all(4),
            child: logo != null
                ? pw.Image(logo, fit: pw.BoxFit.contain)
                : pw.Center(
                    child: pw.Text(
                      'HR',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF6A1B9A),
                      ),
                    ),
                  ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  company['name_ar']?.toString() ??
                      company['name_en']?.toString() ??
                      'Company',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                if ((company['name_en'] ?? '').toString().isNotEmpty)
                  pw.Text(
                    company['name_en'].toString(),
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFFE1BEE7),
                    ),
                  ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: PdfColor.fromInt(0xFFCE93D8),
                    ),
                  ),
                ],
                if ((company['phone'] ?? '').toString().isNotEmpty)
                  pw.Text(
                    'Tel: ${company['phone']}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFFE1BEE7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// PDF Footer موحد ✅ Powered by MotionHR - JS Solutions
  static pw.Widget buildPdfFooter({Map<String, dynamic>? company}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        if (company != null &&
            (company['address'] ?? '').toString().isNotEmpty)
          pw.Text(
            company['address'].toString(),
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            textAlign: pw.TextAlign.center,
          ),
        pw.SizedBox(height: 3),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated: ${DateTime.now().toString().split('.')[0]}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
            pw.Text(
              'Powered by MotionHR - JS Solutions',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColor.fromInt(0xFF6A1B9A),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// نص Excel Footer الموحد
  static String excelFooterText() {
    return 'Powered by MotionHR - JS Solutions';
  }

  /// اسم الشركة للاستخدام في Excel/PDF headers
  static String companyDisplayName(Map<String, dynamic> company) {
    return company['name_ar']?.toString() ??
        company['name_en']?.toString() ??
        'MotionHR';
  }

  // ═══════════════════════════════════════════════════════════
  // قوالب جاهزة لأي شاشة طباعة جديدة في المستقبل
  // أي تقرير PDF جديد = سطرين بس، والـ branding يتحط تلقائي
  // ═══════════════════════════════════════════════════════════

  /// PDF صفحة واحدة مع branding كامل (header + footer)
  static Future<pw.Document> buildBrandedSinglePage({
    String? subtitle,
    required pw.Widget Function(
      Map<String, dynamic> company,
      pw.MemoryImage? logo,
    ) contentBuilder,
  }) async {
    final company = await getCompany();
    final logo = await getLogo();
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildPdfHeader(company: company, logo: logo, subtitle: subtitle),
              pw.SizedBox(height: 16),
              pw.Expanded(child: contentBuilder(company, logo)),
              pw.SizedBox(height: 12),
              buildPdfFooter(company: company),
            ],
          ),
        ),
      ),
    );
    return pdf;
  }

  /// PDF متعدد الصفحات مع branding يتكرر في كل صفحة تلقائي
  static Future<pw.Document> buildBrandedMultiPage({
    String? subtitle,
    required List<pw.Widget> Function(
      Map<String, dynamic> company,
      pw.MemoryImage? logo,
    ) contentBuilder,
  }) async {
    final company = await getCompany();
    final logo = await getLogo();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) =>
            buildPdfHeader(company: company, logo: logo, subtitle: subtitle),
        footer: (ctx) => buildPdfFooter(company: company),
        build: (ctx) => contentBuilder(company, logo),
      ),
    );
    return pdf;
  }
}
