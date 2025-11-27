import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongBookSettings extends ChangeNotifier {
  late String _songBookFile;

  String get songBookFile => _songBookFile;

  Future<void> setSongBookFile(String songBookFile) async {
    _songBookFile = songBookFile;
    notifyListeners();
    final Future<SharedPreferences> prefsRef = SharedPreferences.getInstance();
    final SharedPreferences prefs = await prefsRef;
    prefs.setString('songBookFile', songBookFile);
  }
}
