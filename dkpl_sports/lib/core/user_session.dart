import '../models/model_utils.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? uid;
  String? fullName;
  String? gender;
  DateTime? dob;
  String? email;
  String? phone;
  String? avatar;
  bool isActive = true;
  int? rewardPoints;
  String? membershipTier;
  DateTime? createdAt;

  void saveUser(Map<String, dynamic> data) {
    try {
      uid = (data['id'] ?? data['uid'] ?? '').toString();
      fullName = (data['fullName'] ?? '').toString();
      email = (data['email'] ?? '').toString();
      phone = (data['phone'] ?? '').toString();
      avatar = (data['avatar'] ?? '').toString();
      gender = (data['gender'] ?? '').toString();
      membershipTier = (data['membershipTier'] ?? '').toString();

      isActive = ModelUtils.readBool(data['isActive'], fallback: true);
      rewardPoints = ModelUtils.readInt(data['rewardPoints']);

      final dobValue = ModelUtils.readDate(data['dob']);
      if (dobValue != null && dobValue.isNotEmpty) {
        dob = DateTime.tryParse(dobValue);
      }

      final created =
          ModelUtils.readDate(data['createdAt']);
      if (created != null && created.isNotEmpty) {
        createdAt = DateTime.tryParse(created);
      }
    } catch (e) {
      print("Lỗi khi lưu UserSession: $e");
    }
  }

  void clearUser() {
    uid = null;
    fullName = null;
    gender = null;
    dob = null;
    email = null;
    phone = null;
    avatar = null;
    isActive = true;
    rewardPoints = null;
    membershipTier = null;
    createdAt = null;
  }

  void updateUser(Map<String, dynamic> newData) {
    try {
      if (newData.containsKey('fullName')) fullName = newData['fullName'];
      if (newData.containsKey('phone')) phone = newData['phone'];
      if (newData.containsKey('gender')) gender = newData['gender'];
      if (newData.containsKey('avatar')) avatar = newData['avatar'];
      if (newData.containsKey('email')) email = newData['email'];
      if (newData.containsKey('membershipTier'))
        membershipTier = newData['membershipTier'];
      if (newData.containsKey('isActive'))
        isActive = ModelUtils.readBool(newData['isActive'], fallback: true);
      if (newData.containsKey('rewardPoints'))
        rewardPoints = ModelUtils.readInt(newData['rewardPoints']);

      if (newData.containsKey('dob')) {
        final newDob = ModelUtils.readDate(newData['dob']);
        if (newDob != null) {
          dob = DateTime.tryParse(newDob);
        }
      }
    } catch (e) {
      print("Lỗi khi update UserSession: $e");
    }
  }
}
