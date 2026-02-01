import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:believers_songbook/models/local_database.dart';
import 'package:believers_songbook/models/collection.dart';


void main() {
  // Initialize FFI for testing
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create in-memory database for testing
    db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: LocalDatabase.createDatabase,
      ),
    );
    // Replace the database instance with our test database
    LocalDatabase.database = Future.value(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('getCollectionSongs sets and persists positions for legacy songs', () async {
    // 1. Insert test collections
    final collection1 = Collection(id: 1, name: 'Collection 1', dateCreated: DateTime.now().toString());
    final collection2 = Collection(id: 2, name: 'Collection 2', dateCreated: DateTime.now().toString());
    
    await db.insert('collections', collection1.toMap());
    await db.insert('collections', collection2.toMap());

    // 2. Insert legacy songs (without songPosition)
    final legacySongs = [
      {
        'id': 1,
        'collectionId': 1,
        'title': 'Song 1',
        'key': 'C',
        'lyrics': 'lyrics 1',
      },
      {
        'id': 2,
        'collectionId': 1,
        'title': 'Song 2',
        'key': 'D',
        'lyrics': 'lyrics 2',
      },
      {
        'id': 3,
        'collectionId': 2,
        'title': 'Song 3',
        'key': 'E',
        'lyrics': 'lyrics 3',
      },
    ];

    for (var song in legacySongs) {
      await db.insert('collectionSongs', song);
    }

    // 3. Add one song with existing position to verify it's not changed
    await db.insert('collectionSongs', {
      'id': 4,
      'collectionId': 1,
      'title': 'Song 4',
      'key': 'F',
      'lyrics': 'lyrics 4',
      'songPosition': 99,
    });

    // 4. Load songs using getCollectionSongs
    final loadedSongs = await LocalDatabase.getCollectionSongs();

    // 5. Verify results
    expect(loadedSongs.length, equals(4));

    // Verify songs in collection 1
    final collection1Songs = loadedSongs.where((s) => s.collectionId == 1).toList();
    expect(collection1Songs.length, equals(3));
    
    // Check legacy songs got sequential positions
    expect(collection1Songs.any((s) => s.title == 'Song 1' && s.songPosition == 0), isTrue);
    expect(collection1Songs.any((s) => s.title == 'Song 2' && s.songPosition == 1), isTrue);
    // Verify the existing position was preserved
    expect(collection1Songs.any((s) => s.title == 'Song 4' && s.songPosition == 99), isTrue);

    // Verify song in collection 2
    final collection2Songs = loadedSongs.where((s) => s.collectionId == 2).toList();
    expect(collection2Songs.length, equals(1));
    expect(collection2Songs[0].songPosition, equals(0));

    // 6. Verify positions were persisted to database
    final rawSongs = await db.query('collectionSongs');
    for (var song in rawSongs) {
      expect(song['songPosition'], isNotNull);
    }
  });
}