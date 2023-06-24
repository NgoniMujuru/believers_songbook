class Collection {
  final int id;
  final String name;
  final String description;
  final String dateCreated;

  Collection({
    required this.id,
    required this.name,
    required this.description,
    required this.dateCreated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dateCreated': dateCreated,
    };
  }

  @override
  String toString() {
    return 'Collection{id: $id, name: $name, description: $description, dateCreated: $dateCreated}';
  }
}
