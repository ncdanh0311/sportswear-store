import 'model_utils.dart';

class AddressModel {
  final String id;
  final String userId;
  final String fullName;
  final String phone;
  final String detail;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.detail,
    required this.isDefault,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      detail: (map['detail'] ?? '').toString(),
      isDefault: ModelUtils.readBool(map['isDefault']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'fullName': fullName,
      'phone': phone,
      'detail': detail,
      'isDefault': isDefault,
    };
  }
}
