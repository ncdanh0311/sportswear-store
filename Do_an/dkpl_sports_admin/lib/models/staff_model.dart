class StaffModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String dateOfBirth;
  final String joinDate; // <--- THÊM MỚI: Ngày vào làm
  final String role;
  final String avatar;
  final String createdAt;
  final String createdBy;

  const StaffModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.dateOfBirth,
    required this.joinDate, // <--- THÊM VÀO CONSTRUCTOR
    required this.role,
    required this.avatar,
    required this.createdAt,
    required this.createdBy,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json, String documentId) {
    return StaffModel(
      id: documentId,
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      joinDate: json['joinDate'] ?? '', // <--- ĐỌC TỪ FIREBASE
      role: json['role'] ?? 'cskh',
      avatar: json['avatar'] ?? '',
      createdAt: json['createdAt'] ?? '',
      createdBy: json['createdBy'] ?? 'system',
    );
  }

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'address': address,
    'dateOfBirth': dateOfBirth,
    'joinDate': joinDate, // <--- GHI LÊN FIREBASE
    'role': role,
    'avatar': avatar,
    'createdAt': createdAt,
    'createdBy': createdBy,
  };
}
