// File: lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staff_model.dart';
import '../models/auth_result_model.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StaffModel? _currentUser;
  StaffModel? get currentUser => _currentUser;

  // ── 1. ĐĂNG NHẬP (Chỉ tìm trong bảng 'staff') ──
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      if (email.trim().isEmpty || password.trim().isEmpty) {
        return const AuthResult(success: false, message: 'Vui lòng nhập đủ thông tin.');
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // TỐI ƯU THEO Ý BẠN: Tìm trong collection 'staff' thay vì 'users'
      DocumentSnapshot doc = await _firestore
          .collection('staff')
          .doc(userCredential.user!.uid)
          .get();

      if (doc.exists) {
        _currentUser = StaffModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        return AuthResult(success: true, message: 'Đăng nhập thành công!', user: _currentUser);
      } else {
        // Rất quan trọng: Đề phòng trường hợp Khách hàng lấy app Nhân viên để login
        await _auth.signOut();
        return const AuthResult(
          success: false,
          message: 'Tài khoản này không có quyền truy cập App Admin.',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return const AuthResult(success: false, message: 'Email hoặc mật khẩu không đúng.');
      }
      return AuthResult(success: false, message: e.message ?? 'Lỗi đăng nhập');
    } catch (e) {
      return AuthResult(success: false, message: 'Lỗi không xác định: $e');
    }
  }

  // ── 2. ĐĂNG KÝ (TẠO TÀI KHOẢN NHÂN VIÊN MỚI) ──
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dateOfBirth,
    required String joinDate, // <--- THÊM MỚI VÀO BIẾN ĐẦU VÀO
    required String password,
    required String role,
  }) async {
    try {
      String creatorId = _currentUser?.id ?? 'system';

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      String uid = userCredential.user!.uid;

      StaffModel newUser = StaffModel(
        id: uid,
        fullName: fullName.trim(),
        email: email.trim(),
        phone: phone.trim(),
        address: address.trim(),
        dateOfBirth: dateOfBirth.trim(),
        joinDate: joinDate.trim(), // <--- GÁN VÀO MODEL
        role: role,
        avatar: 'https://i.pravatar.cc/150?img=10',
        createdAt: DateTime.now().toIso8601String(),
        createdBy: creatorId,
      );

      await _firestore.collection('staff').doc(uid).set(newUser.toJson());

      _currentUser = newUser;
      return AuthResult(
        success: true,
        message: 'Tạo tài khoản nhân viên thành công!',
        user: newUser,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return const AuthResult(success: false, message: 'Email này đã được sử dụng.');
      }
      return AuthResult(success: false, message: e.message ?? 'Lỗi đăng ký');
    }
  }

  // ── 3. QUÊN MẬT KHẨU ──
  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult(
        success: true,
        message: 'Link đặt lại mật khẩu đã được gửi vào Email.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message ?? 'Lỗi gửi email reset.');
    }
  }

  // ── 4. ĐĂNG XUẤT ──
  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }
}
