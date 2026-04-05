import 'model_utils.dart';

class CartItemModel {
  final String id;
  final String cartId;
  final String variantId;
  final int quantity;

  CartItemModel({
    required this.id,
    required this.cartId,
    required this.variantId,
    required this.quantity,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      id: ModelUtils.readString(map['id']),
      cartId: ModelUtils.readString(map['cartId']),
      variantId: ModelUtils.readString(map['variantId']),
      quantity: ModelUtils.readInt(map['quantity'], fallback: 1),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cartId': cartId,
      'variantId': variantId,
      'quantity': quantity,
    };
  }
}
