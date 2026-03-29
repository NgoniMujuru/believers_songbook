import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:believers_songbook/models/collection.dart';
import 'package:believers_songbook/models/collection_song.dart';

/// Service that syncs user settings and collections to/from Firestore.
///
/// Firestore structure:
/// ```
/// users/{uid}/
///   settings: { fontSize, displayKey, displaySongNumber, isDarkMode, songBookFile, locale, sortOrder, searchBy }
///   collections/{collectionId}: { name, dateCreated }
///   collections/{collectionId}/songs/{songId}: { title, key, lyrics, songPosition }
/// ```
class SyncService {
  /// Whether Firebase has been initialized. Prevents crashes when providers
  /// call pushSetting() before Firebase.initializeApp() completes.
  static bool get _isFirebaseReady {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static String? get _uid {
    if (!_isFirebaseReady) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Returns the user document reference, or null if not signed in.
  static DocumentReference? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid);
  }

  // ─── Settings Sync ───────────────────────────────────────────────

  /// Push all user settings to Firestore.
  static Future<void> pushSettings({
    required double fontSize,
    required bool displayKey,
    required bool displaySongNumber,
    required bool isDarkMode,
    required String songBookFile,
    required String locale,
    String? sortOrder,
    String? searchBy,
  }) async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      await doc.set({
        'settings': {
          'fontSize': fontSize,
          'displayKey': displayKey,
          'displaySongNumber': displaySongNumber,
          'isDarkMode': isDarkMode,
          'songBookFile': songBookFile,
          'locale': locale,
          if (sortOrder != null) 'sortOrder': sortOrder,
          if (searchBy != null) 'searchBy': searchBy,
        },
        'lastSyncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('SyncService.pushSettings error: $e');
    }
  }

  /// Push a single setting key-value pair.
  static Future<void> pushSetting(String key, dynamic value) async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      await doc.set({
        'settings': {key: value},
        'lastSyncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('SyncService.pushSetting error: $e');
    }
  }

  /// Pull all user settings from Firestore.
  /// Returns null if not signed in or no data exists.
  static Future<Map<String, dynamic>?> pullSettings() async {
    final doc = _userDoc;
    if (doc == null) return null;

    try {
      final snapshot = await doc.get();
      if (!snapshot.exists) return null;
      final data = snapshot.data() as Map<String, dynamic>?;
      return data?['settings'] as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) print('SyncService.pullSettings error: $e');
      return null;
    }
  }

  // ─── Collections Sync ────────────────────────────────────────────

  /// Push a single collection (without songs) to Firestore.
  static Future<void> pushCollection(Collection collection) async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      await doc
          .collection('collections')
          .doc(collection.id)
          .set({
        'name': collection.name,
        'dateCreated': collection.dateCreated,
      });
    } catch (e) {
      if (kDebugMode) print('SyncService.pushCollection error: $e');
    }
  }

  /// Delete a collection and all its songs from Firestore.
  static Future<void> deleteCloudCollection(String collectionId) async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      // Delete all songs in the collection first
      final songsSnapshot = await doc
          .collection('collections')
          .doc(collectionId)
          .collection('songs')
          .get();

      // Chunk deletes to stay under Firestore's 500-operation batch limit
      final allDocs = songsSnapshot.docs;
      for (var i = 0; i < allDocs.length; i += 498) {
        final batch = _firestore.batch();
        final chunk = allDocs.skip(i).take(498);
        for (var songDoc in chunk) {
          batch.delete(songDoc.reference);
        }
        if (i + 498 >= allDocs.length) {
          // Last chunk: also delete the collection doc itself
          batch.delete(doc.collection('collections').doc(collectionId));
        }
        await batch.commit();
      }
      if (allDocs.isEmpty) {
        // No songs — just delete the collection document
        await doc.collection('collections').doc(collectionId).delete();
      }
    } catch (e) {
      if (kDebugMode) print('SyncService.deleteCloudCollection error: $e');
    }
  }

  /// Push a single collection song to Firestore.
  static Future<void> pushCollectionSong(CollectionSong song) async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      await doc
          .collection('collections')
          .doc(song.collectionId)
          .collection('songs')
          .doc(song.id)
          .set({
        'title': song.title,
        'key': song.key,
        'lyrics': song.lyrics,
        'songPosition': song.songPosition,
      });
    } catch (e) {
      if (kDebugMode) print('SyncService.pushCollectionSong error: $e');
    }
  }

  /// Delete a collection song from Firestore.
  static Future<void> deleteCloudCollectionSong(
      String collectionId, String songId) async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      await doc
          .collection('collections')
          .doc(collectionId)
          .collection('songs')
          .doc(songId)
          .delete();
    } catch (e) {
      if (kDebugMode) print('SyncService.deleteCloudCollectionSong error: $e');
    }
  }

  /// Update collection songs in Firestore (e.g. after reorder or edit).
  static Future<void> updateCloudCollectionSongs(
      List<CollectionSong> songs) async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      // Chunk to stay under Firestore's 500-operation batch limit
      for (var i = 0; i < songs.length; i += 498) {
        final batch = _firestore.batch();
        final chunk = songs.skip(i).take(498);
        for (var song in chunk) {
          final ref = doc
              .collection('collections')
              .doc(song.collectionId)
              .collection('songs')
              .doc(song.id);
          batch.set(ref, {
            'title': song.title,
            'key': song.key,
            'lyrics': song.lyrics,
            'songPosition': song.songPosition,
          });
        }
        await batch.commit();
      }
    } catch (e) {
      if (kDebugMode) print('SyncService.updateCloudCollectionSongs error: $e');
    }
  }

  // ─── Full Pull (restore from cloud) ─────────────────────────────

  /// Pull all collections and their songs from Firestore.
  /// Returns a map with 'collections' and 'collectionSongs' lists.
  static Future<Map<String, dynamic>?> pullCollections() async {
    final doc = _userDoc;
    if (doc == null) return null;

    try {
      final collectionsSnapshot = await doc.collection('collections').get();

      List<Collection> collections = [];
      List<CollectionSong> collectionSongs = [];

      for (var collectionDoc in collectionsSnapshot.docs) {
        final collectionData = collectionDoc.data();
        collections.add(Collection(
          id: collectionDoc.id,
          name: collectionData['name'] ?? '',
          dateCreated: collectionData['dateCreated'] ?? '',
        ));

        // Pull songs for this collection
        final songsSnapshot =
            await collectionDoc.reference.collection('songs').get();
        for (var songDoc in songsSnapshot.docs) {
          final songData = songDoc.data();
          collectionSongs.add(CollectionSong(
            id: songDoc.id,
            collectionId: collectionDoc.id,
            title: songData['title'] ?? '',
            key: songData['key'] ?? '',
            lyrics: songData['lyrics'] ?? '',
            songPosition: songData['songPosition'] ?? 0,
          ));
        }
      }

      return {
        'collections': collections,
        'collectionSongs': collectionSongs,
      };
    } catch (e) {
      if (kDebugMode) print('SyncService.pullCollections error: $e');
      return null;
    }
  }

  // ─── Full Push (backup to cloud) ────────────────────────────────

  /// Push all local collections and songs to Firestore (merge).
  static Future<void> pushAllCollections(
      List<Collection> collections, List<CollectionSong> collectionSongs) async {
    final doc = _userDoc;
    if (doc == null) return;

    try {
      // Combine all operations and chunk to stay under Firestore's
      // 500-operation batch limit.
      var opCount = 0;
      var batch = _firestore.batch();

      for (var collection in collections) {
        final collectionRef =
            doc.collection('collections').doc(collection.id);
        batch.set(collectionRef, {
          'name': collection.name,
          'dateCreated': collection.dateCreated,
        });
        opCount++;
        if (opCount >= 498) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      for (var song in collectionSongs) {
        final songRef = doc
            .collection('collections')
            .doc(song.collectionId)
            .collection('songs')
            .doc(song.id);
        batch.set(songRef, {
          'title': song.title,
          'key': song.key,
          'lyrics': song.lyrics,
          'songPosition': song.songPosition,
        });
        opCount++;
        if (opCount >= 498) {
          await batch.commit();
          batch = _firestore.batch();
          opCount = 0;
        }
      }

      // Commit any remaining operations
      if (opCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      if (kDebugMode) print('SyncService.pushAllCollections error: $e');
    }
  }

  // ─── Full Sync (merge cloud + local) ────────────────────────────

  /// Perform a full sync: push local data to cloud, then pull cloud data.
  /// Returns pulled data that should be merged into local state.
  static Future<Map<String, dynamic>?> fullSync({
    required double fontSize,
    required bool displayKey,
    required bool displaySongNumber,
    required bool isDarkMode,
    required String songBookFile,
    required String locale,
    String? sortOrder,
    String? searchBy,
    required List<Collection> collections,
    required List<CollectionSong> collectionSongs,
  }) async {
    if (_uid == null) return null;

    try {
      // Push settings
      await pushSettings(
        fontSize: fontSize,
        displayKey: displayKey,
        displaySongNumber: displaySongNumber,
        isDarkMode: isDarkMode,
        songBookFile: songBookFile,
        locale: locale,
        sortOrder: sortOrder,
        searchBy: searchBy,
      );

      // Push collections
      await pushAllCollections(collections, collectionSongs);

      // Pull everything from cloud (will include what we just pushed + any data from other devices)
      final pulledSettings = await pullSettings();
      final pulledCollections = await pullCollections();

      return {
        if (pulledSettings != null) 'settings': pulledSettings,
        if (pulledCollections != null) ...pulledCollections,
      };
    } catch (e) {
      if (kDebugMode) print('SyncService.fullSync error: $e');
      return null;
    }
  }
}
