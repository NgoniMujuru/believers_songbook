import 'dart:convert';
import 'dart:io';

import 'songbook_builder.dart';

/// Regenerates assets/All.csv and assets/songbook_manifest.json from the
/// registered songbooks.
///
/// Run from the project root after adding or editing any songbook:
///   dart run tool/build_songbooks.dart
void main() {
  final registry =
      File('lib/constants/song_book_assets.dart').readAsStringSync();
  final names = registeredFileNames(registry);

  final books = <List<List<dynamic>>>[];
  final counts = <String, int>{};
  for (final name in names) {
    final file = File('assets/$name.csv');
    if (!file.existsSync()) {
      stderr.writeln('ERROR: registered songbook assets/$name.csv is missing.');
      exit(1);
    }
    final rows = parseCsv(file.readAsStringSync());
    books.add(rows);
    counts[name] = rows.length;
  }

  final allRows = buildAllRows(books);
  File('assets/All.csv').writeAsStringSync('${rowsToCsv(allRows)}\n');

  final manifest = {
    'total': allRows.length,
    'books': counts,
  };
  File('assets/songbook_manifest.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));

  stdout.writeln(
      'Regenerated assets/All.csv from ${names.length} songbooks (${allRows.length} songs).');
  stdout.writeln('Wrote assets/songbook_manifest.json');
}
