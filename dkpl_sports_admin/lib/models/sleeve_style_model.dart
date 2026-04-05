import 'model_utils.dart';

class SleeveStyleModel {
  final String id;
  final String name;

  SleeveStyleModel({required this.id, required this.name});

  factory SleeveStyleModel.fromMap(Map<String, dynamic> map) {
    return SleeveStyleModel(
      id: ModelUtils.readString(map['id']),
      name: ModelUtils.readString(map['name']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}
