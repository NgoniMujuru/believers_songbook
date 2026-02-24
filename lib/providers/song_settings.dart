import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:believers_songbook/services/sync_service.dart';

class SongSettings extends ChangeNotifier {
  double _fontSize = 22; // Default font size
  bool _displayKey = true;
  bool _displaySongNumber = false;

  double get fontSize => _fontSize;
  bool get displayKey => _displayKey;
  bool get displaySongNumber => _displaySongNumber;

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    final Future<SharedPreferences> prefsRef = SharedPreferences.getInstance();
    final SharedPreferences prefs = await prefsRef;
    prefs.setDouble('fontSize', size);
    SyncService.pushSetting('fontSize', size);
  }

  Future<void> setDisplayKey(bool display) async {
    _displayKey = display;
    notifyListeners();
    final Future<SharedPreferences> prefsRef = SharedPreferences.getInstance();
    final SharedPreferences prefs = await prefsRef;
    prefs.setBool('displayKey', display);
    SyncService.pushSetting('displayKey', display);
  }

    Future<void> setDisplaySongNumber(bool display) async {
    _displaySongNumber = display;
    notifyListeners();
    final Future<SharedPreferences> prefsRef = SharedPreferences.getInstance();
    final SharedPreferences prefs = await prefsRef;
    prefs.setBool('displaySongNumber', display);
    SyncService.pushSetting('displaySongNumber', display);
  }
}
