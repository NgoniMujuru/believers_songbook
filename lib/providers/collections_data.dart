import 'package:believers_songbook/models/collection.dart';
import 'package:flutter/material.dart';

import '../models/local_database.dart';

class CollectionsData extends ChangeNotifier {
  List<Collection> _collections = [];

  List<Collection> get collections => _collections;

  Future<void> setCollections(List<Collection> collections) async {
    _collections = collections;
    notifyListeners();
    print(collections);
  }

  Future<void> addCollection(Collection collection) async {
    _collections.add(collection);
    notifyListeners();
    LocalDatabase localDatabase = LocalDatabase();
    await localDatabase.insertCollection(collection);
  }
}
