import 'model_utils.dart';

class MaterialModel {
  final String id;
  final String name;

  MaterialModel({required this.id, required this.name});

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      id: ModelUtils.readString(map['id']),
      name: ModelUtils.readString(map['name']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}
