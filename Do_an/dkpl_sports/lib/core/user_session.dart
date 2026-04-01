class UserSession {
  // 1. Singleton (Giữ nguyên như cũ)
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  // 2. Các biến lưu trữ
  String? uid;
  String? fullName;
  String? gender;
  DateTime? dob; // Ngày sinh
  String? email;
  String? phone;
  String? role;
  String? avatar;
  String? address;
  bool is_actived = true;
  int? reward_points;
  String? membership_tier;
  DateTime? created_at; 

  // 3. Hàm lưu dữ liệu từ Firebase vào Session (Gọi khi Login)
  void saveUser(Map<String, dynamic> data) {
    try {
      uid = data['uid'];
      fullName = data['full_name'];
      email = data['email'];
      phone = data['phone'];
      role = data['role'];
      avatar = data['avatar'];
      gender = data['gender'];
      address = data['address'];
      membership_tier = data['membership_tier'];
      
      is_actived = data['is_actived'] ?? true;

      // Xử lý Số nguyên (Điểm thưởng)
      reward_points = data['reward_points'];

      // Xử lý Ngày tháng (Quan trọng: Convert từ String sang DateTime)
      if (data['dob'] != null) {
        // Nếu lưu dạng String ISO8601
        dob = DateTime.tryParse(data['dob']); 
      }

      if (data['created_at'] != null) {
        created_at = DateTime.tryParse(data['created_at']);
      }
      
    } catch (e) {
      print("Lỗi khi lưu UserSession: $e");
    }
  }

  // 4. Hàm xóa dữ liệu (Gọi khi Logout)
  void clearUser() {
    uid = null;
    fullName = null;
    gender = null;
    dob = null;
    email = null;
    phone = null;
    role = null;
    avatar = null;
    address = null;
    is_actived = true;
    reward_points = null;
    membership_tier = null;
    created_at = null;
  }

  void updateUser(Map<String, dynamic> newData) {
    try {
      // Chỉ cập nhật nếu dữ liệu mới có tồn tại (Khác null)
      if (newData.containsKey('full_name')) fullName = newData['full_name'];
      if (newData.containsKey('phone')) phone = newData['phone'];
      if (newData.containsKey('address')) address = newData['address'];
      if (newData.containsKey('gender')) gender = newData['gender'];
      if (newData.containsKey('avatar')) avatar = newData['avatar'];
      if (newData.containsKey('email')) email = newData['email']; // Ít khi cho đổi email nhưng cứ để
      
      if (newData.containsKey('dob')) {
        var newDob = newData['dob'];
        if (newDob is String) {
          dob = DateTime.tryParse(newDob);
        } else if (newDob is DateTime) {
          dob = newDob;
        }
      }

      print("✅ Đã cập nhật UserSession thành công!");
    } catch (e) {
      print("❌ Lỗi khi update UserSession: $e");
    }
  }
}