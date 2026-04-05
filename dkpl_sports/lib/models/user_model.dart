import 'model_utils.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String password;
  final String phone;
  final String avatar;
  final String gender;
  final String? dob;
  final bool isActive;
  final int rewardPoints;
  final String membershipTier;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    required this.avatar,
    required this.gender,
    required this.dob,
    required this.isActive,
    required this.rewardPoints,
    required this.membershipTier,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: (map['id'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      password: (map['password'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      avatar: (map['avatar'] ?? '').toString(),
      gender: (map['gender'] ?? '').toString(),
      dob: ModelUtils.readDate(map['dob']),
      isActive: ModelUtils.readBool(map['isActive'], fallback: true),
      rewardPoints: ModelUtils.readInt(map['rewardPoints']),
      membershipTier: (map['membershipTier'] ?? '').toString(),
      createdAt: ModelUtils.readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'password': password,
      'phone': phone,
      'avatar': avatar,
      'gender': gender,
      'dob': dob,
      'isActive': isActive,
      'rewardPoints': rewardPoints,
      'membershipTier': membershipTier,
      'createdAt': createdAt,
    };
  }
}
