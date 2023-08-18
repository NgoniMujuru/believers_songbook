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
      // When the database is first created, create a table to store collections.
      onCreate: createDatabase,
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
    if (kDebugMode) {
      print('Database initialized');
    }
  }

  static Future<void> createDatabase(Database db, int version) async {
    await db.execute(
      'CREATE TABLE collections(id INTEGER PRIMARY KEY, name TEXT UNIQUE, description TEXT, dateCreated TEXT)',
    );
    await db.execute(
      'CREATE TABLE collectionSongs(id INTEGER PRIMARY KEY, collectionId INTEGER, title TEXT, key TEXT, lyrics TEXT, FOREIGN KEY(collectionId) REFERENCES collections(id))',
    );
    // Additional SQL statements or table creations can be executed here
  }

  static Future<void> insertCollection(Collection collection) async {
    // Get a reference to the database.
    final db = await database;

    // Insert the Collection into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same collection is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'collections',
      collection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // delete collection and remove all songs in the collection from the collectionSongs table
  static Future<void> deleteCollection(int collectionId) async {
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

  static Future<void> deleteCollectionSong(int collectionSongId) async {
    final db = await database;
    await db.delete(
      'collectionSongs',
      where: 'id = ?',
      whereArgs: [collectionSongId],
    );
  }

  // update collectionSongs from array
  static Future<void> updateCollectionSongs(List<CollectionSong> collectionSongs) async {
    final db = await database;
    collectionSongs.forEach((collectionSong) async {
      await db.update(
        'collectionSongs',
        collectionSong.toMap(),
        where: 'id = ?',
        whereArgs: [collectionSong.id],
      );
    });
  }

  static Future<List<Collection>> getCollections() async {
    // Get a reference to the database.
    final db = await database;

    // Query the table for all The Collections.
    final List<Map<String, dynamic>> collectionMaps = await db.query('collections');

    // Convert the List<Map<String, dynamic> into a List<Collection>.
    return List.generate(collectionMaps.length, (i) {
      return Collection(
        id: collectionMaps[i]['id'],
        name: collectionMaps[i]['name'],
        dateCreated: collectionMaps[i]['dateCreated'],
      );
    });
  }

  static Future<List<CollectionSong>> getCollectionSongs() async {
    final db = await database;
    final List<Map<String, dynamic>> collectionSongMaps =
        await db.query('collectionSongs');
    return List.generate(collectionSongMaps.length, (i) {
      return CollectionSong(
        id: collectionSongMaps[i]['id'],
        collectionId: collectionSongMaps[i]['collectionId'],
        title: collectionSongMaps[i]['title'],
        key: collectionSongMaps[i]['key'],
        lyrics: collectionSongMaps[i]['lyrics'],
      );
    });
  }

  static Future<void> deleteDatabaseFile() async {
    final databasePath = await getDatabasesPath();
    final databasePathToDelete = join(databasePath, 'local_database.db');
    await deleteDatabase(databasePathToDelete);
  }
}
