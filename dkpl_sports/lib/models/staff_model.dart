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

  StaffModel({
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

  factory StaffModel.fromMap(Map<String, dynamic> map) {
    return StaffModel(
      id: (map['id'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      dob: ModelUtils.readDate(map['dob']),
      email: (map['email'] ?? '').toString(),
      password: (map['password'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      cccd: (map['cccd'] ?? '').toString(),
      roleId: (map['roleId'] ?? '').toString(),
      createdAt: ModelUtils.readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
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
}
