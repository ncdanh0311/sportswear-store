import 'model_utils.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String variantId;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.id,
    required this.orderId,
    required this.variantId,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: (map['id'] ?? '').toString(),
      orderId: (map['orderId'] ?? '').toString(),
      variantId: (map['variantId'] ?? '').toString(),
      quantity: ModelUtils.readInt(map['quantity'], fallback: 1),
      price: ModelUtils.readDouble(map['price']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'variantId': variantId,
      'quantity': quantity,
      'price': price,
    };
  }
}
