import 'model_utils.dart';

class OrderVoucherModel {
  final String orderId;
  final String voucherId;

  OrderVoucherModel({
    required this.orderId,
    required this.voucherId,
  });

  factory OrderVoucherModel.fromMap(Map<String, dynamic> map) {
    return OrderVoucherModel(
      orderId: ModelUtils.readString(map['orderId']),
      voucherId: ModelUtils.readString(map['voucherId']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'voucherId': voucherId,
    };
  }
}
