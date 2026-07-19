import 'dart:io';

final arabicRegex = RegExp(r"'[^']*[ء-ي][^']*'");
final englishRegex = RegExp(r"'[A-Za-z][^']*'");

void main() async {
  final libDir = Directory('lib');

  final results = <String>{};

  await for (var file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      final content = await file.readAsString();

      for (final match in arabicRegex.allMatches(content)) {
        results.add(match.group(0)!);
      }

      for (final match in englishRegex.allMatches(content)) {
        final text = match.group(0)!;

        // Ignore obvious code strings
        if (!text.contains('package:') &&
            !text.contains('http') &&
            !text.contains('.dart') &&
            text.length > 4) {
          results.add(text);
        }
      }
    }
  }

  final out = File('hardcoded_report.txt');
  await out.writeAsString(results.join('\n\n'));

  print('✅ Done. Check hardcoded_report.txt');
}