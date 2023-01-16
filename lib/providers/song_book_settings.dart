import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class SongBookSettings extends ChangeNotifier {
  String _songBookPath = 'assets/Songs.csv'; // Default song book

  String get songBookPath => _songBookPath;

  void setSongBookPath(String path) {
    _songBookPath = path;
    notifyListeners();
  }
}
