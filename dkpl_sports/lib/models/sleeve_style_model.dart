class SleeveStyleModel {
  final String id;
  final String name;

  SleeveStyleModel({
    required this.id,
    required this.name,
  });

  factory SleeveStyleModel.fromMap(Map<String, dynamic> map) {
    return SleeveStyleModel(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}
