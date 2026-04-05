import 'model_utils.dart';

class BrandModel {
  final String id;
  final String name;

  BrandModel({required this.id, required this.name});

  factory BrandModel.fromMap(Map<String, dynamic> map) {
    return BrandModel(
      id: ModelUtils.readString(map['id']),
      name: ModelUtils.readString(map['name']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}
