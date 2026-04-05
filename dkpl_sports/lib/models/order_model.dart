import 'model_utils.dart';

class OrderModel {
  final String id;
  final String userId;
  final String addressId;
  final double total;
  final String status;
  final String paymentMethod;
  final String? expectedDelivery;
  final String? createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.addressId,
    required this.total,
    required this.status,
    required this.paymentMethod,
    required this.expectedDelivery,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      addressId: (map['addressId'] ?? '').toString(),
      total: ModelUtils.readDouble(map['total']),
      status: (map['status'] ?? 'pending').toString(),
      paymentMethod: (map['paymentMethod'] ?? '').toString(),
      expectedDelivery: ModelUtils.readDate(map['expectedDelivery']),
      createdAt: ModelUtils.readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'addressId': addressId,
      'total': total,
      'status': status,
      'paymentMethod': paymentMethod,
      'expectedDelivery': expectedDelivery,
      'createdAt': createdAt,
    };
  }
}
