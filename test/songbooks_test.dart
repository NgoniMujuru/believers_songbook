import 'dart:io';

import 'package:believers_songbook/constants/song_book_assets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../tool/songbook_builder.dart';

/// Guards the songbook data so the hand-maintained registry and the generated
/// aggregate (assets/All.csv) can never silently drift out of sync.
void main() {
  test('every registered songbook has a valid, header-less CSV', () {
    for (final book in SongBookAssets.songList) {
      final name = book['FileName'] as String;
      final file = File('assets/$name.csv');
      expect(file.existsSync(), isTrue, reason: 'Missing assets/$name.csv');

      final rows = parseCsv(file.readAsStringSync());
      expect(rows, isNotEmpty, reason: 'assets/$name.csv is empty');
      expect(rows.first[0], isA<int>(),
          reason:
              'assets/$name.csv: first cell must be a song number (int) — it '
              'looks like the file has a header row, which breaks numeric sort.');
      for (final row in rows) {
        expect(row.length, greaterThanOrEqualTo(4),
            reason: 'assets/$name.csv has a row with fewer than 4 columns '
                '(SongNum;Title;Key;Lyrics): $row');
      }
    }
  });

  test('every assets/*.csv is registered in song_book_assets.dart', () {
    final registered =
        SongBookAssets.songList.map((b) => b['FileName'] as String).toSet();
    for (final entity in Directory('assets').listSync()) {
      if (entity is! File || !entity.path.endsWith('.csv')) continue;
      final name = entity.uri.pathSegments.last.replaceAll('.csv', '');
      expect(registered.contains(name), isTrue,
          reason: 'assets/$name.csv exists but is not registered in '
              'lib/constants/song_book_assets.dart');
    }
  });

  test('assets/songbook_manifest.json is up to date', () {
    expect(File('assets/songbook_manifest.json').existsSync(), isTrue,
        reason: 'assets/songbook_manifest.json is missing. Regenerate with:\n'
            '    dart run tool/build_songbooks.dart');
  });

  test('assets/All.csv is up to date', () {
    final registry =
        File('lib/constants/song_book_assets.dart').readAsStringSync();
    final books = [
      for (final name in registeredFileNames(registry))
        parseCsv(File('assets/$name.csv').readAsStringSync()),
    ];
    final expected = buildAllCsv(books);
    final actual = File('assets/All.csv').readAsStringSync();
    expect(actual, expected,
        reason: 'assets/All.csv is stale. Regenerate it with:\n'
            '    dart run tool/build_songbooks.dart');
  });
}
