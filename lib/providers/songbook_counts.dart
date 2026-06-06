import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SongbookCounts extends ChangeNotifier {
  int _total = 0;
  final Map<String, int> _books = {};

  int get total => _total;
  int countFor(String fileName) => _books[fileName] ?? 0;

  Future<void> load() async {
    try {
      final raw =
          await rootBundle.loadString('assets/songbook_manifest.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _total = (data['total'] as num).toInt();
      final books = data['books'] as Map<String, dynamic>;
      _books
        ..clear()
        ..addAll(books.map((k, v) => MapEntry(k, (v as num).toInt())));
      notifyListeners();
    } catch (_) {}
  }
}
