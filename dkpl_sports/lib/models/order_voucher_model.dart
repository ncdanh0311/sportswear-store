class OrderVoucherModel {
  final String orderId;
  final String voucherId;

  OrderVoucherModel({
    required this.orderId,
    required this.voucherId,
  });

  factory OrderVoucherModel.fromMap(Map<String, dynamic> map) {
    return OrderVoucherModel(
      orderId: (map['orderId'] ?? '').toString(),
      voucherId: (map['voucherId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'voucherId': voucherId,
    };
  }
}
