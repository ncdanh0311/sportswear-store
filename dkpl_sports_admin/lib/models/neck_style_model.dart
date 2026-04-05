import 'model_utils.dart';

class NeckStyleModel {
  final String id;
  final String name;

  NeckStyleModel({required this.id, required this.name});

  factory NeckStyleModel.fromMap(Map<String, dynamic> map) {
    return NeckStyleModel(
      id: ModelUtils.readString(map['id']),
      name: ModelUtils.readString(map['name']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}
