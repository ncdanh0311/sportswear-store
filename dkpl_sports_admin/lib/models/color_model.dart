import 'model_utils.dart';

class ColorModel {
  final String id;
  final String name;

  ColorModel({required this.id, required this.name});

  factory ColorModel.fromMap(Map<String, dynamic> map) {
    return ColorModel(
      id: ModelUtils.readString(map['id']),
      name: ModelUtils.readString(map['name']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
      };
}
