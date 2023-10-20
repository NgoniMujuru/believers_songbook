import 'package:flutter/material.dart';

class MainPageSettings extends ChangeNotifier {
  int _openPageIndex = 0;

  int get openPageIndex => _openPageIndex;

  void setOpenPageIndex(int openPageIndex) {
    _openPageIndex = openPageIndex;
    notifyListeners();
  }

  String locale = 'en';

  void setLocale(String locale) {
    this.locale = locale;
    notifyListeners();
  }

  String get getLocale => locale;
}
