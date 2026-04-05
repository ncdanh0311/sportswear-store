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
      id: ModelUtils.readString(map['id']),
      userId: ModelUtils.readString(map['userId']),
      fullName: ModelUtils.readString(map['fullName']),
      phone: ModelUtils.readString(map['phone']),
      detail: ModelUtils.readString(map['detail']),
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
