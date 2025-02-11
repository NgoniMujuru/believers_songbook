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
    collections.sort((a, b) => a.name.compareTo(b.name));
    _collections = collections;
    notifyListeners();
  }

  Future<void> setCollectionSongs(List<CollectionSong> collectionSongs) async {
    _collectionSongs = collectionSongs;
    _songsByCollection = createSongsByCollection(_collections, _collectionSongs);
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

  // update collection song
  Future<void> updateCollectionSongs(
      List<int> collectionSongIds, String lyrics, String key) async {
    List<CollectionSong> updatedCollectionSongs = [];

    for (int id in collectionSongIds) {
      CollectionSong collectionSong =
          _collectionSongs.firstWhere((collectionSong) => collectionSong.id == id);
      _collectionSongs.removeWhere((song) => song.id == collectionSong.id);
      CollectionSong updatedCollectionSong = CollectionSong(
        id: collectionSong.id,
        collectionId: collectionSong.collectionId,
        lyrics: lyrics,
        key: key,
        title: collectionSong.title,
        songPosition: collectionSong.songPosition,
      );
      _collectionSongs.add(updatedCollectionSong);
      _songsByCollection[collectionSong.collectionId]
          ?.removeWhere((song) => song.id == collectionSong.id);
      _songsByCollection[collectionSong.collectionId]?.add(updatedCollectionSong);
      updatedCollectionSongs.add(updatedCollectionSong);
    }
    notifyListeners();

    await LocalDatabase.updateCollectionSongs(updatedCollectionSongs);
  }
}

Map<int, List<CollectionSong>> createSongsByCollection(collections, collectionSongs) {
  Map<int, List<CollectionSong>> songsByCollection = <int, List<CollectionSong>>{};

  for (var collection in collections) {
    if (!songsByCollection.containsKey(collection.id)) { //if collection does not exist create an empty list
      songsByCollection[collection.id] = [];
    }
    for (var collectionSong in collectionSongs) {
      if (collectionSong.collectionId == collection.id) {
        songsByCollection[collection.id]?.add(collectionSong); // if collection exists add the song to the collection
      }
    }
  }
  return songsByCollection;
}

void updateSongPositions(List<CollectionSong> collectionSongs) {
    for (int i = 0; i < collectionSongs.length; i++) {
      collectionSongs[i].songPosition = i + 1;
    }
  }
