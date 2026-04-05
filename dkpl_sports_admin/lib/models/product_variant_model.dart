import 'model_utils.dart';

class ProductVariantModel {
  final String id;
  final String productId;
  final String size;
  final String colorId;
  final double price;

  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.size,
    required this.colorId,
    required this.price,
  });

  static const empty = ProductVariantModel(
    id: '',
    productId: '',
    size: '',
    colorId: '',
    price: 0,
  );

  factory ProductVariantModel.fromMap(Map<String, dynamic> map) {
    return ProductVariantModel(
      id: ModelUtils.readString(map['id']),
      productId: ModelUtils.readString(map['productId']),
      size: ModelUtils.readString(map['size']),
      colorId: ModelUtils.readString(map['colorId']),
      price: ModelUtils.readDouble(map['price']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'size': size,
      'colorId': colorId,
      'price': price,
    };
  }
}
