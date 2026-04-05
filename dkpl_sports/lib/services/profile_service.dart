import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/user_session.dart';
import '../core/constants/firebase_collections.dart';

class ProfileService {
  ProfileService._();
  static final ProfileService instance = ProfileService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: "gs://dkpl-sports-storage",
  );

  // 1. Cập nhật thông tin text
  Future<String?> updateProfile(Map<String, dynamic> dataToUpdate) async {
    try {
      String uid = UserSession().uid!;
      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .update(dataToUpdate);
      UserSession().updateUser(dataToUpdate);
      return null; // Trả về null nghĩa là không có lỗi
    } catch (e) {
      return "Lỗi cập nhật: $e";
    }
  }

  // 2. Upload Avatar
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      String uid = UserSession().uid!;
      final storageRef = _storage.ref().child('avatars').child('$uid.jpg');

      await storageRef.putFile(imageFile);
      String downUrl = await storageRef.getDownloadURL();

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .update({'avatar': downUrl});
      UserSession().updateUser({'avatar': downUrl});

      return null; // Không có lỗi
    } catch (e) {
      return "Lỗi upload ảnh: $e";
    }
  }
}
