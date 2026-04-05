import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class OrderModel {
  final String id;
  final String userId;
  final String addressId;
  final double total;
  final String status;
  final String paymentMethod;
  final DateTime? expectedDelivery;
  final DateTime? createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.addressId,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.expectedDelivery,
    required this.createdAt,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrderModel.fromJson(data, doc.id);
  }

  factory OrderModel.fromJson(Map<String, dynamic> data, String id) {
    return OrderModel(
      id: id,
      userId: ModelUtils.readString(data['userId']),
      addressId: ModelUtils.readString(data['addressId']),
      total: ModelUtils.readDouble(data['total']),
      status: ModelUtils.readString(data['status'], fallback: 'pending'),
      paymentMethod: ModelUtils.readString(data['paymentMethod']),
      expectedDelivery: ModelUtils.readDateTime(data['expectedDelivery']),
      createdAt: ModelUtils.readDateTime(data['createdAt']),
    );
  }
}
