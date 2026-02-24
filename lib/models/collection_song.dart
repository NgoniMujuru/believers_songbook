class CollectionSong {
  final String id;
  final String collectionId;
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

  factory CollectionSong.fromMap(Map<String, dynamic> map) {
    return CollectionSong(
      id: map['id'].toString(),
      collectionId: map['collectionId'].toString(),
      title: map['title'],
      key: map['key'],
      lyrics: map['lyrics'],
      songPosition: map['songPosition'] ?? 0,
    );
  }

  @override
  String toString() {
    return 'CollectionSong{id: $id, collectionId: $collectionId, title: $title, songPosition: $songPosition} ';
  }
}
