class CollectionSong {
  final int id;
  final int collectionId;
  final String title;
  final String key;
  final String lyrics;

  CollectionSong({
    required this.collectionId,
    required this.title,
    required this.key,
    required this.lyrics,
    required this.id,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collectionId': collectionId,
      'title': title,
      'key': key,
      'lyrics': lyrics,
    };
  }

  @override
  String toString() {
    return 'CollectionSong{id: $id, collectionId: $collectionId, title: $title';
  }
}
