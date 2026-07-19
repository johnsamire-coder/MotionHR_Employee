// lib/services/report_pdf_service.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'branding_service.dart';

class ReportPdfService {
  /// طباعة / مشاركة تقرير عام مع Branding كامل
  static Future<void> printReport({
    required String title,
    required List<List<String>> rows,
    List<String>? headers,
    String? subtitle,
  }) async {
    final company = await BrandingService.getCompany();
    final logo = await BrandingService.getLogo();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => pw.Column(
          children: [
            BrandingService.buildPdfHeader(
              company: company,
              logo: logo,
              subtitle: subtitle ?? title,
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (ctx) => BrandingService.buildPdfFooter(company: company),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          // عنوان التقرير
          widgets.add(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));

          // الجدول
          if (headers != null && rows.isNotEmpty) {
            widgets.add(
              pw.TableHelper.fromTextArray(
                context: ctx,
                headerDirection: pw.TextDirection.rtl,
                cellAlignment: pw.Alignment.centerRight,
                headerAlignment: pw.Alignment.centerRight,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF4A148C),
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                oddCellStyle: const pw.TextStyle(fontSize: 9),
                cellDecoration: (index, data, rowNum) => pw.BoxDecoration(
                  color: rowNum % 2 == 0
                      ? PdfColors.white
                      : PdfColor.fromInt(0xFFF3E5F5),
                ),
                headers: headers,
                data: rows,
              ),
            );
          } else if (rows.isNotEmpty) {
            // بدون headers - كل صف كـ text
            for (final row in rows) {
              widgets.add(
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 4, horizontal: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                    ),
                  ),
                  child: pw.Text(
                    row.join(' | '),
                    style: const pw.TextStyle(fontSize: 10),
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),
              );
            }
          } else {
            widgets.add(
              pw.Center(
                child: pw.Text(
                  'لا توجد بيانات',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            );
          }

          // التاريخ والوقت
          widgets.add(pw.SizedBox(height: 16));
          widgets.add(
            pw.Text(
              'تاريخ التقرير: ${DateTime.now().toString().split('.')[0]}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          );

          return widgets;
        },
      ),
    );

    // عرض نافذة الطباعة / المشاركة
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: title,
    );
  }
}