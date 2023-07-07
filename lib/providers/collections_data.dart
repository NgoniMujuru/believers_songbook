import 'package:believers_songbook/models/collection.dart';
import 'package:believers_songbook/models/collection_song.dart';
import 'package:flutter/material.dart';

import '../models/local_database.dart';

class CollectionsData extends ChangeNotifier {
  List<Collection> _collections = [];
  List<CollectionSong> _collectionSongs = [];

  List<Collection> get collections => _collections;
  List<CollectionSong> get collectionSongs => _collectionSongs;

  Future<void> setCollections(List<Collection> collections) async {
    _collections = collections;
    notifyListeners();
    print(collections);
  }

  Future<void> setCollectionSongs(List<CollectionSong> collectionSongs) async {
    _collectionSongs = collectionSongs;
    print(collectionSongs);
  }

  Future<void> addCollection(Collection collection) async {
    _collections.add(collection);
    notifyListeners();
    await LocalDatabase.insertCollection(collection);
  }

  Future<void> deleteCollection(int collectionId) async {
    _collections.removeWhere((collection) => collection.id == collectionId);
    _collectionSongs
        .removeWhere((collectionSong) => collectionSong.collectionId == collectionId);
    notifyListeners();
    await LocalDatabase.deleteCollection(collectionId);
  }

  // add collection song
  Future<void> addCollectionSong(CollectionSong collectionSong) async {
    _collectionSongs.add(collectionSong);
    notifyListeners();
    await LocalDatabase.insertCollectionSong(collectionSong);
  }

  // delete collection song
  Future<void> deleteCollectionSong(int collectionSongId) async {
    _collectionSongs
        .removeWhere((collectionSong) => collectionSong.id == collectionSongId);
    notifyListeners();
    await LocalDatabase.deleteCollectionSong(collectionSongId);
  }
}
