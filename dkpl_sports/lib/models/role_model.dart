class RoleModel {
  final String id;
  final String name;

  RoleModel({
    required this.id,
    required this.name,
  });

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
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
