// lib/services/branding_service.dart
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'employee_management_service.dart';

class BrandingService {
  static Map<String, dynamic>? cachedCompany;
  static pw.MemoryImage? cachedLogo;
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  /// Load Arabic fonts
  static Future<void> ensureFontsLoaded() async {
    if (_regularFont != null && _boldFont != null) return;
    try {
      final regularData =
          await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      _regularFont = pw.Font.ttf(regularData);
      _boldFont = pw.Font.ttf(boldData);
    } catch (e) {
      _regularFont = null;
      _boldFont = null;
    }
  }

  static pw.Font? get regularFont => _regularFont;
  static pw.Font? get boldFont => _boldFont;

  static pw.TextStyle arabicStyle({
    double fontSize = 12,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: bold ? _boldFont : _regularFont,
      fontFallback: bold ? [_regularFont!] : [],
      fontSize: fontSize,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color,
    );
  }

  /// Get company data (with cache)
  static Future<Map<String, dynamic>> getCompany() async {
    if (cachedCompany != null) return cachedCompany!;
    try {
      cachedCompany = await EmployeeManagementService.getCompanyInfo();
    } catch (_) {
      cachedCompany = {};
    }
    return cachedCompany!;
  }

  /// Get company logo (with cache)
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

  /// Clear cache
  static void clearCache() {
    cachedCompany = null;
    cachedLogo = null;
    _regularFont = null;
    _boldFont = null;
  }

  /// Unified PDF Header
  static pw.Widget buildPdfHeader({
    required Map<String, dynamic> company,
    pw.MemoryImage? logo,
    String? subtitle,
  }) {
    final companyName = company['name_ar']?.toString() ??
        company['name_en']?.toString() ??
        'Company';
    final companyNameEn = company['name_en']?.toString() ?? '';
    final phone = company['phone']?.toString() ?? '';

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
                  companyName,
                  style: arabicStyle(
                    fontSize: 18,
                    bold: true,
                    color: PdfColors.white,
                  ),
                ),
                if (companyNameEn.isNotEmpty)
                  pw.Text(
                    companyNameEn,
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFFE1BEE7),
                    ),
                  ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  pw.SizedBox(height: 3),
                  pw.Text(
                    subtitle,
                    style: arabicStyle(
                      fontSize: 11,
                      color: PdfColor.fromInt(0xFFCE93D8),
                    ),
                  ),
                ],
                if (phone.isNotEmpty)
                  pw.Text(
                    'Tel: $phone',
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

  /// Unified PDF Footer
  static pw.Widget buildPdfFooter({Map<String, dynamic>? company}) {
    final address = company?['address']?.toString() ?? '';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        if (address.isNotEmpty)
          pw.Text(
            address,
            style: arabicStyle(fontSize: 8, color: PdfColors.grey700),
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

  /// Excel footer text
  static String excelFooterText() {
    return 'Powered by MotionHR - JS Solutions';
  }

  /// Company display name
  static String companyDisplayName(Map<String, dynamic> company) {
    return company['name_ar']?.toString() ??
        company['name_en']?.toString() ??
        'MotionHR';
  }

  /// Single page branded PDF
  static Future<pw.Document> buildBrandedSinglePage({
    String? subtitle,
    required pw.Widget Function(
      Map<String, dynamic> company,
      pw.MemoryImage? logo,
    ) contentBuilder,
  }) async {
    await ensureFontsLoaded();
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
              buildPdfHeader(
                  company: company, logo: logo, subtitle: subtitle),
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

  /// Multi page branded PDF
  static Future<pw.Document> buildBrandedMultiPage({
    String? subtitle,
    required List<pw.Widget> Function(
      Map<String, dynamic> company,
      pw.MemoryImage? logo,
    ) contentBuilder,
  }) async {
    await ensureFontsLoaded();
    final company = await getCompany();
    final logo = await getLogo();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => buildPdfHeader(
            company: company, logo: logo, subtitle: subtitle),
        footer: (ctx) => buildPdfFooter(company: company),
        build: (ctx) => contentBuilder(company, logo),
      ),
    );
    return pdf;
  }
}