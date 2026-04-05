import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // 1. Kiểm tra trạng thái đăng nhập
  bool get isLoggedIn => _auth.currentUser != null;

  // 2. Đăng nhập
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

      // Đọc data từ bảng users
      DocumentSnapshot userDoc = await _firestore
          .collection("users")
          .doc(uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        bool isActive = data["is_actived"] ?? true;

        if (!isActive) {
          await _auth.signOut();
          return AuthResult(
            success: false,
            message: "Tài khoản của bạn đã bị khóa! Vui lòng liên hệ CSKH",
          );
        }

        UserSession().saveUser(data); // Lưu vào Session
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

  // 3. Đăng ký
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
        'uid': uid,
        'full_name': name,
        'email': email,
        'phone': phone,
        'role': 'user',
        'avatar':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRD0Y5uEmFetc0Xb25SAiiO4ZwYE8g7r8HBug&s',
        'is_actived': true,
        'reward_points': 0,
        'membership_tier': 'bronze',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('users').doc(uid).set(userData);
      return AuthResult(success: true, message: "Đăng ký thành công!");
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Đăng ký thất bại";
      if (e.code == 'email-already-in-use')
        errorMsg = "Email này đã được sử dụng!";
      if (e.code == 'weak-password') errorMsg = "Mật khẩu quá yếu!";
      return AuthResult(success: false, message: errorMsg);
    }
  }

  // 4. Quên mật khẩu
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

  // 5. Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
    UserSession().clearUser();
  }
}
