import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'collection.dart';
import 'collection_song.dart';

class LocalDatabase {
  // ignore: prefer_typing_uninitialized_variables
  static var database;

  static initDatabase() async {
    database = openDatabase(
      join(await getDatabasesPath(), 'local_database.db'),
      onCreate: createDatabase,
      onUpgrade: onUpgrade,
      version: 3,
    );
    if (kDebugMode) {
      print('Database initialized');
    }
  }

  static Future<void> createDatabase(Database db, int version) async {
    await db.execute(
      'CREATE TABLE collections(id TEXT PRIMARY KEY, name TEXT UNIQUE, description TEXT, dateCreated TEXT)',
    );
    await db.execute(
      'CREATE TABLE collectionSongs(id TEXT PRIMARY KEY, collectionId TEXT, title TEXT, key TEXT, lyrics TEXT, songPosition INTEGER, FOREIGN KEY(collectionId) REFERENCES collections(id))',
    );
  }

  static Future<void> insertCollection(Collection collection) async {
    final db = await database;
    await db.insert(
      'collections',
      collection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteCollection(String collectionId) async {
    final db = await database;
    await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: [collectionId],
    );
    await db.delete(
      'collectionSongs',
      where: 'collectionId = ?',
      whereArgs: [collectionId],
    );
  }

  static Future<void> insertCollectionSong(CollectionSong collectionSong) async {
    final db = await database;
    await db.insert(
      'collectionSongs',
      collectionSong.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> deleteCollectionSong(String collectionSongId) async {
    final db = await database;
    await db.delete(
      'collectionSongs',
      where: 'id = ?',
      whereArgs: [collectionSongId],
    );
  }

  static Future<void> updateCollectionSongs(List<CollectionSong> collectionSongs) async {
    final db = await database;
    for (var collectionSong in collectionSongs) {
      await db.update(
        'collectionSongs',
        collectionSong.toMap(),
        where: 'id = ?',
        whereArgs: [collectionSong.id],
      );
    }
  }

  static Future<List<Collection>> getCollections() async {
    final db = await database;
    final List<Map<String, dynamic>> collectionMaps = await db.query('collections');
    return collectionMaps.map((map) => Collection.fromMap(map)).toList();
  }

  static Future<List<CollectionSong>> getCollectionSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> collectionSongMaps =
        await db.query('collectionSongs');

    // Group songs by collection ID to handle positions within each collection
    Map<String, List<Map<String, dynamic>>> songsByCollection = {};
    for (var song in collectionSongMaps) {
      String collectionId = song['collectionId'].toString();
      songsByCollection.putIfAbsent(collectionId, () => []).add(song);
    }

    List<CollectionSong> allSongs = [];

    for (var collectionSongs in songsByCollection.values) {
      for (int i = 0; i < collectionSongs.length; i++) {
        var songMap = collectionSongs[i];
        int position = songMap['songPosition'] ?? i;

        if (songMap['songPosition'] == null) {
          await db.update(
            'collectionSongs',
            {'songPosition': position},
            where: 'id = ?',
            whereArgs: [songMap['id']],
          );
        }

        allSongs.add(CollectionSong(
          id: songMap['id'].toString(),
          collectionId: songMap['collectionId'].toString(),
          title: songMap['title'],
          key: songMap['key'],
          lyrics: songMap['lyrics'],
          songPosition: position,
        ));
      }
    }

    return allSongs;
  }

  static Future<void> deleteDatabaseFile() async {
    final databasePath = await getDatabasesPath();
    final databasePathToDelete = join(databasePath, 'local_database.db');
    await deleteDatabase(databasePathToDelete);
  }

  static Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE collectionSongs ADD COLUMN songPosition INTEGER');
    }
    if (oldVersion < 3) {
      // Migrate from INTEGER IDs to TEXT IDs
      await db.execute(
        'CREATE TABLE collections_new(id TEXT PRIMARY KEY, name TEXT UNIQUE, description TEXT, dateCreated TEXT)',
      );
      await db.execute(
        'INSERT INTO collections_new(id, name, description, dateCreated) '
        'SELECT CAST(id AS TEXT), name, description, dateCreated FROM collections',
      );
      await db.execute('DROP TABLE collections');
      await db.execute('ALTER TABLE collections_new RENAME TO collections');

      await db.execute(
        'CREATE TABLE collectionSongs_new(id TEXT PRIMARY KEY, collectionId TEXT, title TEXT, key TEXT, lyrics TEXT, songPosition INTEGER, FOREIGN KEY(collectionId) REFERENCES collections(id))',
      );
      await db.execute(
        'INSERT INTO collectionSongs_new(id, collectionId, title, key, lyrics, songPosition) '
        'SELECT CAST(id AS TEXT), CAST(collectionId AS TEXT), title, key, lyrics, songPosition FROM collectionSongs',
      );
      await db.execute('DROP TABLE collectionSongs');
      await db.execute('ALTER TABLE collectionSongs_new RENAME TO collectionSongs');
    }
  }
}
