import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/firebase_collections.dart';
import '../core/user_session.dart';

class AuthResult {
  final bool success;
  final String message;
  AuthResult({required this.success, required this.message});
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool get isLoggedIn => _auth.currentUser != null;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      DocumentSnapshot userDoc = await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        bool isActive = (data["isActive"]) ?? true;

        if (!isActive) {
          await _auth.signOut();
          return AuthResult(
            success: false,
            message:
                "Tài khoản của bạn đã bị khóa! Vui lòng liên hệ CSKH",
          );
        }

        UserSession().saveUser(data);
        return AuthResult(success: true, message: "Đăng nhập thành công");
      } else {
        await _auth.signOut();
        return AuthResult(
          success: false,
          message: "Không tìm thấy dữ liệu tài khoản.",
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Email hoặc Mật khẩu không chính xác";
      if (e.code == 'invalid-email') msg = "Định dạng Email không hợp lệ";
      return AuthResult(success: false, message: msg);
    } catch (e) {
      return AuthResult(success: false, message: "Lỗi không xác định: $e");
    }
  }

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      Map<String, dynamic> userData = {
        'id': uid,
        'fullName': name,
        'email': email,
        'password': '',
        'phone': phone,
        'avatar':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRD0Y5uEmFetc0Xb25SAiiO4ZwYE8g7r8HBug&s',
        'gender': '',
        'dob': null,
        'isActive': true,
        'rewardPoints': 0,
        'membershipTier': 'bronze',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await _firestore
          .collection(FirebaseCollections.users)
          .doc(uid)
          .set(userData);
      return AuthResult(success: true, message: "Đăng ký thành công!");
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Đăng ký thất bại";
      if (e.code == 'email-already-in-use')
        errorMsg = "Email này đã được sử dụng!";
      if (e.code == 'weak-password') errorMsg = "Mật khẩu quá yếu!";
      return AuthResult(success: false, message: errorMsg);
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        message: "Đã gửi Email đặt lại mật khẩu!",
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Lỗi xảy ra, vui lòng thử lại";
      if (e.code == 'user-not-found') errorMsg = "Email này chưa được đăng ký";
      if (e.code == 'invalid-email') errorMsg = "Định dạng Email không hợp lệ";
      return AuthResult(success: false, message: errorMsg);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    UserSession().clearUser();
  }
}
