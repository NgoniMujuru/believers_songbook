import 'package:flutter/material.dart';

class MainPageSettings extends ChangeNotifier {
  int _openPageIndex = 0;

  int get openPageIndex => _openPageIndex;

  void setOpenPageIndex(int openPageIndex) {
    _openPageIndex = openPageIndex;
    notifyListeners();
  }
}
