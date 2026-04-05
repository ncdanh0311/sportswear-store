import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class VariantModel {
  final String id;
  final String productId;
  final String size;
  final String colorId;
  final double price;

  const VariantModel({
    required this.id,
    required this.productId,
    required this.size,
    required this.colorId,
    required this.price,
  });

  factory VariantModel.fromFirestore(DocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return VariantModel(
      id: doc.id,
      productId: ModelUtils.readString(data['productId']),
      size: ModelUtils.readString(data['size']),
      colorId: ModelUtils.readString(data['colorId']),
      price: ModelUtils.readDouble(data['price']),
    );
  }
}
