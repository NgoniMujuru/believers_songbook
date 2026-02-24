import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:believers_songbook/services/sync_service.dart';

class MainPageSettings extends ChangeNotifier {
  int _openPageIndex = 0;

  int get openPageIndex => _openPageIndex;

  void setOpenPageIndex(int openPageIndex) {
    _openPageIndex = openPageIndex;
    notifyListeners();
  }

  String locale = 'en';

  Future<void> setLocale(String locale) async {
    this.locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('locale', locale);
    SyncService.pushSetting('locale', locale);
  }

  String get getLocale => locale;
}
