import 'model_utils.dart';

class ProductImageModel {
  final String id;
  final String productId;
  final String imageUrl;

  ProductImageModel({
    required this.id,
    required this.productId,
    required this.imageUrl,
  });

  factory ProductImageModel.fromMap(Map<String, dynamic> map) {
    return ProductImageModel(
      id: ModelUtils.readString(map['id']),
      productId: ModelUtils.readString(map['productId']),
      imageUrl: ModelUtils.readString(map['imageUrl']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'productId': productId,
        'imageUrl': imageUrl,
      };
}
