// lib/screens/manager/reports/report_common.dart
// أدوات مشتركة لشاشات التقارير اللي بتجيب بياناتها وملفات التصدير من السيرفر (زي الويب)
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/api_client.dart';

const String kReportsApi = 'https://jssolutions-eg.com/attendance/api/mobile/manager/reports';
const String kServerRoot = 'https://jssolutions-eg.com';
const Color kReportColor = Color(0xFF382483);

bool reportIsAr(BuildContext context) => Localizations.localeOf(context).languageCode == 'ar';

Map<String, dynamic> decodeJson(List<int> bytes) {
  try {
    final d = jsonDecode(utf8.decode(bytes));
    return d is Map<String, dynamic> ? d : {'results': d};
  } catch (_) {
    return {};
  }
}

List<Map<String, dynamic>> mapList(dynamic v) =>
    v is List ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList() : <Map<String, dynamic>>[];

num asNum(dynamic v) => v is num ? v : (num.tryParse('${v ?? ''}') ?? 0);

String fmtNum(dynamic v, {int digits = 2}) {
  final n = asNum(v);
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(digits);
}

String fmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// GET بيانات JSON من السيرفر، وبيرمي رسالة الخطأ اللي السيرفر بعتها لو فيه
Future<Map<String, dynamic>> getJson(Uri uri, {String? fallbackError}) async {
  final res = await ApiClient.get(uri);
  final d = decodeJson(res.bodyBytes);
  if (res.statusCode >= 400 || d['success'] == false || (d['error'] != null && d['error'] is String)) {
    throw Exception(d['error'] ?? d['message'] ?? fallbackError ?? 'Error ${res.statusCode}');
  }
  return d;
}

/// تنزيل ملف (Excel/PDF) من السيرفر ومشاركته من الموبايل
Future<void> downloadAndShare(BuildContext context, Uri uri, String fileName) async {
  final isAr = reportIsAr(context);
  try {
    final res = await ApiClient.get(uri);
    final type = res.headers['content-type'] ?? '';
    if (res.statusCode != 200 || type.contains('json')) throw Exception();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(res.bodyBytes, flush: true);
    await Share.shareXFiles([XFile(file.path)], text: fileName);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAr ? 'فشل التصدير' : 'Export failed'), backgroundColor: Colors.red));
    }
  }
}

Widget statTile(String label, String value, Color c) => Expanded(
      child: Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c)),
          const SizedBox(height: 2),
          Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        ]),
      ),
    );

PopupMenuButton<String> exportMenu(BuildContext context, void Function(String kind) onSelected,
    {bool pdf = true}) {
  final isAr = reportIsAr(context);
  return PopupMenuButton<String>(
    icon: const Icon(Icons.download),
    onSelected: onSelected,
    itemBuilder: (_) => [
      PopupMenuItem(value: 'excel', child: Text(isAr ? 'تصدير Excel' : 'Export Excel')),
      if (pdf) PopupMenuItem(value: 'pdf', child: Text(isAr ? 'تصدير PDF' : 'Export PDF')),
    ],
  );
}
