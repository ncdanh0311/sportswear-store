class NeckStyleModel {
  final String id;
  final String name;

  NeckStyleModel({
    required this.id,
    required this.name,
  });

  factory NeckStyleModel.fromMap(Map<String, dynamic> map) {
    return NeckStyleModel(
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
