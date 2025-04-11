// tool/build_date_generator.dart

import 'dart:io';

void main() {
  final now = DateTime.now().toUtc();
  final fileContent = '''
// GENERATED FILE - DO NOT MODIFY
// Generated on $now

const String buildDate = '${now.toIso8601String()}';
''';

  final outputFile = File('lib/generated/build_date.dart');
  outputFile.createSync(recursive: true);
  outputFile.writeAsStringSync(fileContent);

  print('✅ Build date file generated at: ${outputFile.path}');
}