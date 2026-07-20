// lib/services/report_pdf_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'branding_service.dart';

class ReportPdfService {
  static Future<void> printReport({
    required String title,
    required List<List<String>> rows,
    List<String>? headers,
    String? subtitle,
  }) async {
    await BrandingService.ensureFontsLoaded();
    final company = await BrandingService.getCompany();
    final logo = await BrandingService.getLogo();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
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

          // ─── Title ───────────────────────────────
          widgets.add(
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                child: pw.Text(
                  title,
                  style: BrandingService.arabicStyle(
                    fontSize: 16,
                    bold: true,
                  ),
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl,
                ),
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 8));

          // ─── Table ───────────────────────────────
          if (headers != null && rows.isNotEmpty) {
            widgets.add(
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Table(
                  border: pw.TableBorder.all(
                    color: PdfColors.grey300,
                    width: 0.5,
                  ),
                  columnWidths: _buildColumnWidths(headers.length),
                  children: [
                    // Header Row
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF4A148C),
                      ),
                      children: headers.map((h) => _headerCell(h)).toList(),
                    ),
                    // Data Rows
                    ...rows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final row = entry.value;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: idx % 2 == 0
                              ? PdfColors.white
                              : PdfColor.fromInt(0xFFF3E5F5),
                        ),
                        children: row.map((cell) => _dataCell(cell)).toList(),
                      );
                    }),
                  ],
                ),
              ),
            );
          } else if (rows.isNotEmpty) {
            // No headers — simple list
            for (final row in rows) {
              widgets.add(
                pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: PdfColors.grey300,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Text(
                      row.join(' | '),
                      style: BrandingService.arabicStyle(fontSize: 10),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ),
              );
            }
          } else {
            // Empty state
            widgets.add(
              pw.Directionality(
                textDirection: pw.TextDirection.rtl,
                child: pw.Center(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(24),
                    child: pw.Text(
                      'لا توجد بيانات لهذه الفترة',
                      style: BrandingService.arabicStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ),
              ),
            );
          }

          widgets.add(pw.SizedBox(height: 16));

          // ─── Footer Date ─────────────────────────
          widgets.add(
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Text(
                'تاريخ التقرير: ${DateTime.now().toString().split('.')[0]}',
                style: BrandingService.arabicStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          );

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: title,
    );
  }

  // ─── Helper: Header Cell ─────────────────────────
  static pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: BrandingService.boldFont,
          fontSize: 9,
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
        ),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // ─── Helper: Data Cell ───────────────────────────
  static pw.Widget _dataCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: BrandingService.regularFont,
          fontSize: 8,
        ),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  // ─── Helper: Column Widths ───────────────────────
  static Map<int, pw.TableColumnWidth> _buildColumnWidths(int count) {
    final widths = <int, pw.TableColumnWidth>{};
    for (int i = 0; i < count; i++) {
      widths[i] = const pw.FlexColumnWidth(1);
    }
    return widths;
  }
}