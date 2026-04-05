import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/firebase_collections.dart';
import '../core/user_session.dart';

class LocalAuthResult {
  final bool success;
  final String message;
  LocalAuthResult({required this.success, required this.message});
}

class LocalAuthService {
  LocalAuthService._();
  static final LocalAuthService instance = LocalAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<LocalAuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final emailLower = email.trim().toLowerCase();
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailLower,
        password: password,
      );
      final uid = userCredential.user!.uid;
      final userRef = _firestore.collection(FirebaseCollections.users).doc(uid);
      final userDoc = await userRef.get();
      if (!userDoc.exists) {
        final fallbackName =
            emailLower.contains('@') ? emailLower.split('@').first : emailLower;
        final userData = {
          'id': uid,
          'fullName': fallbackName,
          'email': emailLower,
          'password': '',
          'phone': '',
          'avatar':
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRD0Y5uEmFetc0Xb25SAiiO4ZwYE8g7r8HBug&s',
          'gender': '',
          'dob': null,
          'isActive': true,
          'rewardPoints': 0,
          'membershipTier': 'bronze',
          'createdAt': DateTime.now().toIso8601String(),
        };
        await userRef.set(userData);
      }
      final data = (await userRef.get()).data() as Map<String, dynamic>;
      final isActive = (data['isActive']) ?? true;
      if (!isActive) {
        await _auth.signOut();
        return LocalAuthResult(
          success: false,
          message: 'Tài khoản của bạn đã bị khóa.',
        );
      }
      UserSession().saveUser(data);
      return LocalAuthResult(
        success: true,
        message: 'Đăng nhập thành công',
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Email hoặc mật khẩu không chính xác';
      if (e.code == 'invalid-email') {
        msg = 'Định dạng Email không hợp lệ';
      } else if (e.code == 'user-not-found') {
        final exists = await _firestore
            .collection(FirebaseCollections.users)
            .where('email', isEqualTo: email.trim().toLowerCase())
            .limit(1)
            .get();
        if (exists.docs.isNotEmpty) {
          msg =
              'Tài khoản chưa có trong Firebase Authentication. Hãy đăng ký lại bằng email này hoặc liên hệ admin để đồng bộ.';
        } else {
          msg = 'Tài khoản không tồn tại';
        }
      } else if (e.code == 'wrong-password') {
        msg =
            'Mật khẩu không đúng. Nếu vừa đổi mật khẩu, hãy dùng mật khẩu mới hoặc đặt lại.';
      } else if (e.code == 'user-disabled') {
        msg = 'Tài khoản đã bị khóa';
      } else if (e.code == 'too-many-requests') {
        msg = 'Thử lại sau, bạn đã nhập sai quá nhiều lần';
      } else if (e.code == 'invalid-credential') {
        msg = 'Thông tin đăng nhập không hợp lệ';
      }
      return LocalAuthResult(success: false, message: msg);
    } catch (e) {
      return LocalAuthResult(success: false, message: 'Lỗi: $e');
    }
  }

  Future<LocalAuthResult> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final emailLower = email.trim().toLowerCase();
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailLower,
        password: password,
      );
      final uid = userCredential.user!.uid;
      final userData = {
        'id': uid,
        'fullName': name,
        'email': emailLower,
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
      UserSession().saveUser(userData);
      return LocalAuthResult(success: true, message: 'Đăng ký thành công!');
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Đăng ký thất bại';
      if (e.code == 'email-already-in-use')
        errorMsg = 'Email này đã được sử dụng!';
      if (e.code == 'weak-password') errorMsg = 'Mật khẩu quá yếu!';
      return LocalAuthResult(success: false, message: errorMsg);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    UserSession().clearUser();
  }

  Future<void> updateUserFields({
    required String uid,
    required Map<String, dynamic> fields,
  }) async {
    await _firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .update(fields);
    UserSession().updateUser(fields);
  }

  Future<bool> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final userDoc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .get();
    if (!userDoc.exists) return false;
    final data = userDoc.data() as Map<String, dynamic>;
    final isActive = (data['isActive']) ?? true;
    if (!isActive) {
      await _auth.signOut();
      UserSession().clearUser();
      return false;
    }
    UserSession().saveUser(data);
    return true;
  }
}
