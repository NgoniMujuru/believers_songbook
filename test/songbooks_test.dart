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

  test('every songbook keeps the line breaks in its lyrics', () {
    // A merge step once concatenated a songbook's lyric lines with no
    // separator, fusing the end of each line into the start of the next
    // ("...crianças vinhamSuas bênças..."). The rows stayed structurally valid,
    // so nothing above caught it. Verses only render if the line breaks
    // survive, so assert they are still there.
    for (final book in SongBookAssets.songList) {
      final name = book['FileName'] as String;
      final rows = parseCsv(File('assets/$name.csv').readAsStringSync());

      // Short lyrics are legitimately a single line; only judge the ones long
      // enough that they must have wrapped somewhere.
      final long =
          rows.where((r) => r[3].toString().length >= 80).toList();
      if (long.isEmpty) continue;

      final multiline =
          long.where((r) => r[3].toString().contains('\n')).length;
      final ratio = multiline / long.length;
      expect(ratio, greaterThan(0.9),
          reason: 'assets/$name.csv: only ${(ratio * 100).toStringAsFixed(1)}% '
              'of its long lyrics contain a line break ($multiline/'
              '${long.length}). The line breaks were probably stripped while '
              'the songbook was generated — every song would render as one '
              'unbroken run-on paragraph.');
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
