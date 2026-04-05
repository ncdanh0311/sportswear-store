import 'model_utils.dart';

class SportModel {
  final String id;
  final String name;

  SportModel({required this.id, required this.name});

  factory SportModel.fromMap(Map<String, dynamic> map) {
    return SportModel(
      id: ModelUtils.readString(map['id']),
      name: ModelUtils.readString(map['name']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}
