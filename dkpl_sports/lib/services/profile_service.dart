import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/user_session.dart';
import '../core/constants/firebase_collections.dart';

/// Service quản lý việc cập nhật hồ sơ người dùng (Text và Avatar).
class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Trỏ cụ thể tới bucket lưu trữ của dự án
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: "gs://dkpl-sports-storage",
  );

  /// Cập nhật các trường thông tin cơ bản (tên, số điện thoại, ngày sinh...)
  /// Đồng bộ dữ liệu lên Firestore và cập nhật lại phiên bộ nhớ (UserSession) local.
  Future<String?> updateProfile(Map<String, dynamic> dataToUpdate) async {
    try {
      String uid = UserSession().uid!;
      
      // Update lên database
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .update(dataToUpdate);
          
      // Update lại biến global giữ thông tin user đang chạy trong app
      UserSession().updateUser(dataToUpdate);
      return null; // Trả về null nghĩa là thực thi thành công (không có lỗi)
    } catch (e) {
      return "Lỗi cập nhật: $e"; // Trả về text nếu có lỗi để UI hiển thị thông báo
    }
  }

  /// Upload ảnh đại diện (Avatar) lên Firebase Storage.
  /// Ghi đè file cũ bằng cách dùng chung 1 tên file '$uid.jpg'.
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      String uid = UserSession().uid!;
      
      // Khai báo đường dẫn lưu file trên Storage: /avatars/{uid}.jpg
      final storageRef = _storage.ref().child('avatars').child('$uid.jpg');

      // Thực hiện đẩy file lên
      await storageRef.putFile(imageFile);
      
      // Lấy link ảnh công khai sau khi up thành công
      String downUrl = await storageRef.getDownloadURL();

      // Cập nhật link ảnh mới vào document của user trên Firestore
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .update({'avatar': downUrl});
          
      // Đồng bộ ảnh mới xuống bộ nhớ app
      UserSession().updateUser({'avatar': downUrl});

      return null; // Thành công
    } catch (e) {
      return "Lỗi upload ảnh: $e";
    }
  }
}