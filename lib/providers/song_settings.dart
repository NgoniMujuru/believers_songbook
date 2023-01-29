import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongSettings extends ChangeNotifier {
  double _fontSize = 22; // Default font size
  bool _displayKey = false;

  double get fontSize => _fontSize;
  bool get displayKey => _displayKey;

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    notifyListeners();
    final Future<SharedPreferences> prefsRef = SharedPreferences.getInstance();
    final SharedPreferences prefs = await prefsRef;
    prefs.setDouble('fontSize', size);
  }

  Future<void> setDisplayKey(bool display) async {
    _displayKey = display;
    notifyListeners();
    final Future<SharedPreferences> prefsRef = SharedPreferences.getInstance();
    final SharedPreferences prefs = await prefsRef;
    prefs.setBool('displayKey', display);
  }
}
