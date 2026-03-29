class Collection {
  final String id;
  final String name;
  final String dateCreated;

  Collection({
    required this.id,
    required this.name,
    required this.dateCreated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dateCreated': dateCreated,
    };
  }

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'].toString(),
      name: map['name'],
      dateCreated: map['dateCreated'],
    );
  }

  @override
  String toString() {
    return 'Collection{id: $id, name: $name, dateCreated: $dateCreated}';
  }
}
