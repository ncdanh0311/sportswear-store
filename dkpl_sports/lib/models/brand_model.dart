class BrandModel {
  final String id;
  final String name;

  BrandModel({
    required this.id,
    required this.name,
  });

  factory BrandModel.fromMap(Map<String, dynamic> map) {
    return BrandModel(
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
