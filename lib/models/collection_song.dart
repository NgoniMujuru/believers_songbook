class CollectionSong {
  final int id;
  final int collectionId;
  final String title;
  final String key;
  final String lyrics;
  int songPosition;

  CollectionSong({
    required this.collectionId,
    required this.title,
    required this.key,
    required this.lyrics,
    required this.id,
    required this.songPosition,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collectionId': collectionId,
      'title': title,
      'key': key,
      'lyrics': lyrics,
      'songPosition': songPosition,
    };
  }

  @override
  String toString() {
    return 'CollectionSong{id: $id, collectionId: $collectionId, title: $title';
  }
}
