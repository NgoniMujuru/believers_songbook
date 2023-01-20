import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongBookSettings extends ChangeNotifier {
  late String _songBookFile; // Default song book

  String get songBookFile => _songBookFile;

  Future<void> setSongBookFile(String songBookFile) async {
    _songBookFile = songBookFile;
    notifyListeners();
    final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    final SharedPreferences prefs = await _prefs;
    prefs.setString('songBookFile', songBookFile);
  }
}
