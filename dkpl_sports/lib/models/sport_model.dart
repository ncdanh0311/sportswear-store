class SportModel {
  final String id;
  final String name;

  SportModel({
    required this.id,
    required this.name,
  });

  factory SportModel.fromMap(Map<String, dynamic> map) {
    return SportModel(
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
