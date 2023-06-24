class Collection {
  final int id;
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

  @override
  String toString() {
    return 'Collection{id: $id, name: $name, dateCreated: $dateCreated}';
  }
}
