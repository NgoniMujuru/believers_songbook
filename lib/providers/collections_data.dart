import 'package:believers_songbook/models/collection.dart';
import 'package:believers_songbook/models/collection_song.dart';
import 'package:flutter/material.dart';

import '../models/local_database.dart';
import '../services/sync_service.dart';

class CollectionsData extends ChangeNotifier {
  List<Collection> _collections = [];
  List<CollectionSong> _collectionSongs = [];
  Map<String, List<CollectionSong>> _songsByCollection = {};

  List<Collection> get collections => _collections;
  List<CollectionSong> get collectionSongs => _collectionSongs;
  Map<String, List<CollectionSong>> get songsByCollection => _songsByCollection;

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
    SyncService.pushCollection(collection);
  }

  Future<void> deleteCollection(String collectionId) async {
    _collections.removeWhere((collection) => collection.id == collectionId);
    _collectionSongs
        .removeWhere((collectionSong) => collectionSong.collectionId == collectionId);
    _songsByCollection.remove(collectionId);
    notifyListeners();
    await LocalDatabase.deleteCollection(collectionId);
    SyncService.deleteCloudCollection(collectionId);
  }

  Future<void> addCollectionSong(CollectionSong collectionSong) async {
    _collectionSongs.add(collectionSong);
    _songsByCollection[collectionSong.collectionId]?.add(collectionSong);
    notifyListeners();
    await LocalDatabase.insertCollectionSong(collectionSong);
    SyncService.pushCollectionSong(collectionSong);
  }

  Future<void> deleteCollectionSong(String collectionSongId) async {
    // Find the song first to get collectionId for cloud deletion
    final song = _collectionSongs.firstWhere(
      (s) => s.id == collectionSongId,
      orElse: () => CollectionSong(id: '', collectionId: '', title: '', key: '', lyrics: '', songPosition: 0),
    );
    _collectionSongs
        .removeWhere((collectionSong) => collectionSong.id == collectionSongId);
    _songsByCollection.forEach((key, value) {
      value.removeWhere((collectionSong) => collectionSong.id == collectionSongId);
    });
    notifyListeners();
    await LocalDatabase.deleteCollectionSong(collectionSongId);
    if (song.collectionId.isNotEmpty) {
      SyncService.deleteCloudCollectionSong(song.collectionId, collectionSongId);
    }
  }

  Future<void> updateCollectionSongs(
      List<String> collectionSongIds, String lyrics, String key) async {
    List<CollectionSong> updatedCollectionSongs = [];

    for (String id in collectionSongIds) {
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
    SyncService.updateCloudCollectionSongs(updatedCollectionSongs);
  }
}

Map<String, List<CollectionSong>> createSongsByCollection(collections, collectionSongs) {
  Map<String, List<CollectionSong>> songsByCollection = <String, List<CollectionSong>>{};

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

void updateSongPositions(List<CollectionSong> collectionSongs) {
    for (int i = 0; i < collectionSongs.length; i++) {
      collectionSongs[i].songPosition = i + 1;
    }
  }
