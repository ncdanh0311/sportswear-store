import 'model_utils.dart';

class InventoryModel {
  final String id;
  final String variantId;
  final int quantity;

  const InventoryModel({
    required this.id,
    required this.variantId,
    required this.quantity,
  });

  factory InventoryModel.fromMap(Map<String, dynamic> map) {
    return InventoryModel(
      id: ModelUtils.readString(map['id']),
      variantId: ModelUtils.readString(map['variantId']),
      quantity: ModelUtils.readInt(map['quantity']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'variantId': variantId,
      'quantity': quantity,
    };
  }
}
