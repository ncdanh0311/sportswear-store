import 'model_utils.dart';

class VoucherModel {
  final String id;
  final String code;
  final double discount;
  final double minOrder;
  final double maxDiscount;
  final int usageLimit;
  final int usedCount;
  final bool isActive;

  VoucherModel({
    required this.id,
    required this.code,
    required this.discount,
    required this.minOrder,
    required this.maxDiscount,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
  });

  factory VoucherModel.fromMap(Map<String, dynamic> map) {
    return VoucherModel(
      id: (map['id'] ?? '').toString(),
      code: (map['code'] ?? '').toString(),
      discount: ModelUtils.readDouble(map['discount']),
      minOrder: ModelUtils.readDouble(map['minOrder']),
      maxDiscount: ModelUtils.readDouble(map['maxDiscount']),
      usageLimit: ModelUtils.readInt(map['usageLimit']),
      usedCount: ModelUtils.readInt(map['usedCount']),
      isActive: ModelUtils.readBool(map['isActive'], fallback: true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'discount': discount,
      'minOrder': minOrder,
      'maxDiscount': maxDiscount,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isActive': isActive,
    };
  }
}
