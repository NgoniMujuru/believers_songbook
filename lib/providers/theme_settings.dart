import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:believers_songbook/services/sync_service.dart';

class ThemeSettings extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  Future<void> setIsDarkMode(bool isDarkMode) async {
    _isDarkMode = isDarkMode;
    notifyListeners();
    final Future<SharedPreferences> prefsRef = SharedPreferences.getInstance();
    final SharedPreferences prefs = await prefsRef;
    prefs.setBool('isDarkMode', isDarkMode);
    SyncService.pushSetting('isDarkMode', isDarkMode);
  }
}
