import 'package:cloud_firestore/cloud_firestore.dart';

class VoucherModel {
  final String id;
  final String code;
  final String name;
  final String discountType;
  final double discountValue;
  final double minOrder;
  final double maxDiscount;
  final int usageLimit;
  final int usedCount;
  final bool isActive;
  final Timestamp? startDate;
  final Timestamp? endDate;

  const VoucherModel({
    required this.id,
    required this.code,
    required this.name,
    required this.discountType,
    required this.discountValue,
    required this.minOrder,
    required this.maxDiscount,
    required this.usageLimit,
    required this.usedCount,
    required this.isActive,
    required this.startDate,
    required this.endDate,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> json, String documentId) {
    return VoucherModel(
      id: documentId,
      code: json['code'] ?? 'NO_CODE',
      name: json['name'] ?? 'Chuong trinh khuyen mai',
      discountType: json['discount_type'] ?? 'percent',
      discountValue: (json['discount_value'] ?? 0).toDouble(),
      minOrder: (json['min_order'] ?? 0).toDouble(),
      maxDiscount: (json['max_discount'] ?? 0).toDouble(),
      usageLimit: json['usage_limit'] ?? 1,
      usedCount: json['used_count'] ?? 0,
      isActive: json['is_active'] ?? false,
      startDate: json['start_date'],
      endDate: json['end_date'],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_order': minOrder,
        'max_discount': maxDiscount,
        'usage_limit': usageLimit,
        'used_count': usedCount,
        'is_active': isActive,
        'start_date': startDate,
        'end_date': endDate,
      };
}
