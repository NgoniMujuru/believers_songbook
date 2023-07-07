import 'package:believers_songbook/models/collection.dart';
import 'package:believers_songbook/models/collection_song.dart';
import 'package:flutter/material.dart';

import '../models/local_database.dart';

class CollectionsData extends ChangeNotifier {
  List<Collection> _collections = [];
  List<CollectionSong> _collectionSongs = [];
  Map<int, List<CollectionSong>> _songsByCollection = {};

  List<Collection> get collections => _collections;
  List<CollectionSong> get collectionSongs => _collectionSongs;
  Map<int, List<CollectionSong>> get songsByCollection => _songsByCollection;

  Future<void> setCollections(List<Collection> collections) async {
    // sort collections alphabetically by name
    collections.sort((a, b) => a.name.compareTo(b.name));
    _collections = collections;
    notifyListeners();
    print(collections);
  }

  Future<void> setCollectionSongs(List<CollectionSong> collectionSongs) async {
    _collectionSongs = collectionSongs;
    _songsByCollection = createSongsByCollection(_collections, _collectionSongs);

    print(collectionSongs);
  }

  Future<void> addCollection(Collection collection) async {
    _collections.add(collection);
    _collections.sort((a, b) => a.name.compareTo(b.name));
    _songsByCollection[collection.id] = [];
    notifyListeners();
    await LocalDatabase.insertCollection(collection);
  }

  Future<void> deleteCollection(int collectionId) async {
    _collections.removeWhere((collection) => collection.id == collectionId);
    _collectionSongs
        .removeWhere((collectionSong) => collectionSong.collectionId == collectionId);
    _songsByCollection.remove(collectionId);
    notifyListeners();
    await LocalDatabase.deleteCollection(collectionId);
  }

  // add collection song
  Future<void> addCollectionSong(CollectionSong collectionSong) async {
    _collectionSongs.add(collectionSong);
    _songsByCollection[collectionSong.collectionId]?.add(collectionSong);
    notifyListeners();
    await LocalDatabase.insertCollectionSong(collectionSong);
  }

  // delete collection song
  Future<void> deleteCollectionSong(int collectionSongId) async {
    _collectionSongs
        .removeWhere((collectionSong) => collectionSong.id == collectionSongId);
    _songsByCollection.forEach((key, value) {
      value.removeWhere((collectionSong) => collectionSong.id == collectionSongId);
    });
    notifyListeners();
    await LocalDatabase.deleteCollectionSong(collectionSongId);
  }
}

Map<int, List<CollectionSong>> createSongsByCollection(collections, collectionSongs) {
  Map<int, List<CollectionSong>> songsByCollection = <int, List<CollectionSong>>{};

  for (var collection in collections) {
    if (!songsByCollection.containsKey(collection.id)) {
      songsByCollection[collection.id] = [];
    }
    for (var collectionSong in collectionSongs) {
      if (collectionSong.collectionId == collection.id) {
        songsByCollection[collection.id]?.add(collectionSong);
      }
    }
  }
  return songsByCollection;
}
