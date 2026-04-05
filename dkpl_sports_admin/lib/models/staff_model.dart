import 'model_utils.dart';

class StaffModel {
  final String id;
  final String fullName;
  final String? dob;
  final String email;
  final String password;
  final String phone;
  final String address;
  final String cccd;
  final String roleId;
  final String? createdAt;

  const StaffModel({
    required this.id,
    required this.fullName,
    required this.dob,
    required this.email,
    required this.password,
    required this.phone,
    required this.address,
    required this.cccd,
    required this.roleId,
    required this.createdAt,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json, String documentId) {
    final roleId = ModelUtils.readString(
      json['roleId'],
      fallback: ModelUtils.readString(json['role']),
    );
    return StaffModel(
      id: documentId,
      fullName: ModelUtils.readString(json['fullName']),
      dob: ModelUtils.readDate(json['dob']),
      email: ModelUtils.readString(json['email']),
      password: ModelUtils.readString(json['password']),
      phone: ModelUtils.readString(json['phone']),
      address: ModelUtils.readString(json['address']),
      cccd: ModelUtils.readString(json['cccd']),
      roleId: roleId,
      createdAt: ModelUtils.readDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'dob': dob,
        'email': email,
        'password': password,
        'phone': phone,
        'address': address,
        'cccd': cccd,
        'roleId': roleId,
        'createdAt': createdAt,
      };
}
