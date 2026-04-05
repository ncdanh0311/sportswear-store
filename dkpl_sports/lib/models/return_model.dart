import 'model_utils.dart';

class ReturnModel {
  final String id;
  final String orderId;
  final String reason;
  final String status;
  final String? createdAt;

  ReturnModel({
    required this.id,
    required this.orderId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory ReturnModel.fromMap(Map<String, dynamic> map) {
    return ReturnModel(
      id: (map['id'] ?? '').toString(),
      orderId: (map['orderId'] ?? '').toString(),
      reason: (map['reason'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      createdAt: ModelUtils.readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'reason': reason,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
