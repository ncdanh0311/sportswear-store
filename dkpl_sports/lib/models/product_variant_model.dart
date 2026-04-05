import 'model_utils.dart';

class ProductVariantModel {
  final String id;
  final String productId;
  final String size;
  final String colorId;
  final double price;
  final int quantity;

  const ProductVariantModel({
    required this.id,
    required this.productId,
    required this.size,
    required this.colorId,
    required this.price,
    required this.quantity,
  });

  static const empty = ProductVariantModel(
    id: '',
    productId: '',
    size: '',
    colorId: '',
    price: 0,
    quantity: 0,
  );

  factory ProductVariantModel.fromMap(Map<String, dynamic> map) {
    return ProductVariantModel(
      id: (map['id'] ?? '').toString(),
      productId: (map['productId'] ?? '').toString(),
      size: (map['size'] ?? '').toString(),
      colorId: (map['colorId'] ?? '').toString(),
      price: ModelUtils.readDouble(map['price']),
      quantity: ModelUtils.readInt(map['quantity']),
    );
  }

  ProductVariantModel copyWith({int? quantity}) {
    return ProductVariantModel(
      id: id,
      productId: productId,
      size: size,
      colorId: colorId,
      price: price,
      quantity: quantity ?? this.quantity,
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
