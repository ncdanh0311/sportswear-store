import 'model_utils.dart';

class RoleModel {
  final String id;
  final String name;

  RoleModel({required this.id, required this.name});

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      id: ModelUtils.readString(map['id']),
      name: ModelUtils.readString(map['name']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}
