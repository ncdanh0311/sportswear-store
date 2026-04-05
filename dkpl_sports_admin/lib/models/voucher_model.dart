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

  const VoucherModel({
    required this.id,
    required this.code,
    required this.discount,
    required this.minOrder,
    required this.maxDiscount,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json, String documentId) {
    return VoucherModel(
      id: documentId,
      code: ModelUtils.readString(json['code']),
      discount: ModelUtils.readDouble(json['discount']),
      minOrder: ModelUtils.readDouble(json['minOrder']),
      maxDiscount: ModelUtils.readDouble(json['maxDiscount']),
      usageLimit: ModelUtils.readInt(json['usageLimit']),
      usedCount: ModelUtils.readInt(json['usedCount']),
      isActive: ModelUtils.readBool(json['isActive'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'discount': discount,
        'minOrder': minOrder,
        'maxDiscount': maxDiscount,
        'usageLimit': usageLimit,
        'usedCount': usedCount,
        'isActive': isActive,
      };
}
