import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class SongSettings extends ChangeNotifier {
  double _fontSize = 22; // Default font size

  double get fontSize => _fontSize;

  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }
}
