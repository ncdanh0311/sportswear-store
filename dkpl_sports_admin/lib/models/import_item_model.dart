import 'model_utils.dart';

class ImportItemModel {
  final String id;
  final String importId;
  final String variantId;
  final int quantity;

  ImportItemModel({
    required this.id,
    required this.importId,
    required this.variantId,
    required this.quantity,
  });

  factory ImportItemModel.fromMap(Map<String, dynamic> map) {
    return ImportItemModel(
      id: ModelUtils.readString(map['id']),
      importId: ModelUtils.readString(map['importId']),
      variantId: ModelUtils.readString(map['variantId']),
      quantity: ModelUtils.readInt(map['quantity']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'importId': importId,
      'variantId': variantId,
      'quantity': quantity,
    };
  }
}
