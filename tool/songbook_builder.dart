import 'package:csv/csv.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

/// Shared logic for building and validating songbook data, used by both
/// `tool/build_songbooks.dart` (the generator) and `test/songbooks_test.dart`
/// (the guard) so there is a single source of truth.

/// Parse a songbook CSV, tolerant of CRLF endings and a leading UTF-8 BOM —
/// matches how the app reads songbooks at runtime.
List<List<dynamic>> parseCsv(String text) {
  var t = text;
  if (t.isNotEmpty && t.codeUnitAt(0) == 0xFEFF) t = t.substring(1);
  t = t.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return const CsvToListConverter(fieldDelimiter: ';', eol: '\n').convert(t);
}

/// Title sort used for the "All" aggregate: alphanumeric titles first, then the
/// rest, case-insensitive (mirrors the app's in-list comparator).
int titleCompare(String a, String b) {
  final alphaNum = RegExp(r'^[a-zA-Z0-9]');
  final fa = alphaNum.hasMatch(a), fb = alphaNum.hasMatch(b);
  if (fa && !fb) return -1;
  if (!fa && fb) return 1;
  return a.toLowerCase().compareTo(b.toLowerCase());
}

String _norm(dynamic t) =>
    t.toString().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

/// Two song titles are considered duplicates when their similarity score
/// (0-100) exceeds this value. 90 was chosen after testing several thresholds;
/// it catches near-identical titles across books while avoiding false positives
/// on songs that share a common opening phrase.
const _dedupSimilarityThreshold = 90;

/// Build the de-duplicated, renumbered rows for `All.csv` from each songbook's
/// parsed rows (passed in registry order). Deterministic: a stable sort keeps
/// equal-title rows in their original order so the output is reproducible.
List<List<dynamic>> buildAllRows(List<List<List<dynamic>>> books) {
  final rows = <List<dynamic>>[];
  for (final book in books) {
    for (final r in book) {
      if (r.length >= 4 && r[1].toString().trim().isNotEmpty) {
        rows.add(List<dynamic>.of(r));
      }
    }
  }
  final indexed = [for (var i = 0; i < rows.length; i++) MapEntry(i, rows[i])];
  indexed.sort((x, y) {
    final c = titleCompare(x.value[1].toString(), y.value[1].toString());
    return c != 0 ? c : x.key.compareTo(y.key);
  });
  final sorted = [for (final e in indexed) e.value];
  for (var i = 0; i + 1 < sorted.length; i++) {
    if (ratio(_norm(sorted[i][1]), _norm(sorted[i + 1][1])) > _dedupSimilarityThreshold) {
      sorted.removeAt(i);
      i--;
    }
  }
  for (var i = 0; i < sorted.length; i++) {
    sorted[i][0] = i + 1;
  }
  return sorted;
}

String rowsToCsv(List<List<dynamic>> rows) =>
    const ListToCsvConverter(fieldDelimiter: ';', eol: '\n').convert(rows);

/// File contents that should be written to `assets/All.csv`.
String buildAllCsv(List<List<List<dynamic>>> books) =>
    '${rowsToCsv(buildAllRows(books))}\n';

/// The songbook FileNames registered in song_book_assets.dart, in order,
/// excluding the aggregate "All" book itself.
List<String> registeredFileNames(String registryDart) =>
    RegExp(r"'FileName':\s*'([^']+)'")
        .allMatches(registryDart)
        .map((m) => m.group(1)!)
        .where((n) => n != 'All')
        .toList();
