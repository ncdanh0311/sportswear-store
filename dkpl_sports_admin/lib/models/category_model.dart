import 'model_utils.dart';

class CategoryModel {
  final String id;
  final String name;
  final String image;

  CategoryModel({
    required this.id,
    required this.name,
    this.image = '',
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: ModelUtils.readString(map['id']),
      name: ModelUtils.readString(map['name']),
      image: ModelUtils.readString(map['image']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }
}
