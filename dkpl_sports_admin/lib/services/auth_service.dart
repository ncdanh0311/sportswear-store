import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/auth_result_model.dart';
import '../models/staff_model.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Khởi tạo các instance của Firebase Auth và Firestore
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Biến lưu trữ thông tin nhân viên hiện tại đang đăng nhập
  StaffModel? _currentUser;
  StaffModel? get currentUser => _currentUser;

  /// Hàm đăng nhập
  Future<AuthResult> login({required String email, required String password}) async {
    try {
      // Chuẩn hóa chuỗi đầu vào (xóa khoảng trắng thừa, đưa email về in thường)
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPassword = password.trim();

      // Kiểm tra rỗng
      if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
        return const AuthResult(success: false, message: 'Vui lòng nhập đầy đủ thông tin.');
      }

      // Thực hiện đăng nhập qua Firebase Authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );

      // Lấy UID của user vừa đăng nhập thành công
      final uid = userCredential.user!.uid;
      final staffRef = _firestore.collection('staff').doc(uid);
      var doc = await staffRef.get(); // Lấy document tương ứng trong collection 'staff'

      // Nếu không tìm thấy document theo UID (có thể do lỗi đồng bộ data cũ)
      if (!doc.exists) {
        // Thử tìm kiếm document dựa trên email thay vì UID
        final lookup = await _firestore
            .collection('staff')
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
        
        // Nếu tìm thấy theo email
        if (lookup.docs.isNotEmpty) {
          final fallbackData = lookup.docs.first.data();
          // Cập nhật lại id của document bằng UID thật của Firebase Auth
          final merged = {
            'id': uid,
            ...fallbackData,
          };
          
          // Đồng bộ/chuyển đổi trường 'role' cũ sang trường 'roleId' mới nếu cần
          if ((merged['roleId'] ?? '').toString().isEmpty &&
              (merged['role'] ?? '').toString().isNotEmpty) {
            merged['roleId'] = merged['role'];
          }
          // Lưu đè lại vào Firestore với Document ID là UID chuẩn
          await staffRef.set(merged, SetOptions(merge: true));
          doc = await staffRef.get(); // Cập nhật lại biến doc
        }
      }

      // Nếu vẫn không tồn tại dữ liệu nhân viên trong Firestore
      if (!doc.exists) {
        await _auth.signOut(); // Đăng xuất vì user không phải là nhân viên (staff)
        return const AuthResult(
          success: false,
          message: 'Tài khoản này không có quyền truy cập app admin.',
        );
      }

      final map = doc.data() as Map<String, dynamic>;
      
      // Xử lý migrate (chuyển đổi) data cũ: Nếu chưa có roleId mà chỉ có role thì tự động gán role cho roleId
      if ((map['roleId'] ?? '').toString().isEmpty &&
          (map['role'] ?? '').toString().isNotEmpty) {
        await staffRef.set({
          'roleId': map['role'],
        }, SetOptions(merge: true));
      }
      
      // Khởi tạo model User hiện tại và trả về kết quả thành công
      _currentUser = StaffModel.fromJson(map, doc.id);
      return AuthResult(success: true, message: 'Đăng nhập thành công!', user: _currentUser);
      
    } on FirebaseAuthException catch (e) {
      // Bắt các lỗi cụ thể từ Firebase Auth
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return const AuthResult(success: false, message: 'Email hoặc mật khẩu không đúng.');
      }
      return AuthResult(success: false, message: e.message ?? 'Lỗi đăng nhập');
    } catch (e) {
      // Bắt các lỗi khác (ví dụ: lỗi mạng, lỗi parse JSON...)
      return AuthResult(success: false, message: 'Lỗi không xác định: $e');
    }
  }

  /// Hàm đăng ký tài khoản nhân viên mới (Chỉ dành cho Admin/Quản lý tạo)
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dob,
    required String cccd,
    required String password,
    required String roleId,
  }) async {
    try {
      final creatorId = _currentUser?.id ?? 'system'; // Lưu lại ID người tạo (có thể dùng để track sau này)
      final normalizedEmail = email.trim().toLowerCase();

      // Kiểm tra xem email này đã tồn tại trong collection 'staff' chưa
      final existingByEmail = await _firestore
          .collection('staff')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (existingByEmail.docs.isNotEmpty) {
        return const AuthResult(
          success: false,
          message: 'Email này đang được gắn cho một nhân sự đang hoạt động.',
        );
      }

      // Gọi hàm helper tạo user qua Firebase Auth mà KHÔNG làm văng phiên đăng nhập của Admin hiện tại
      final userCredential = await _createStaffAuthUser(
        email: normalizedEmail,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // Khởi tạo model nhân viên mới
      final newUser = StaffModel(
        id: uid,
        fullName: fullName.trim(),
        dob: dob.trim(),
        email: normalizedEmail,
        password: password, // Lưu ý: Trong thực tế việc lưu password rõ (clear text) vào database không được khuyến khích vì lý do bảo mật.
        phone: phone.trim(),
        address: address.trim(),
        cccd: cccd.trim(),
        roleId: roleId,
        createdAt: DateTime.now().toIso8601String(),
      );

      // Lưu thông tin nhân viên mới vào Firestore
      await _firestore.collection('staff').doc(uid).set(newUser.toJson());

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
    } catch (e) {
      return AuthResult(success: false, message: 'Lỗi không xác định: $e');
    }
  }

  /// Hàm gửi email khôi phục mật khẩu
  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      // Yêu cầu Firebase gửi email chứa link reset password
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult(
        success: true,
        message: 'Link đặt lại mật khẩu đã được gửi vào email.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message ?? 'Lỗi gửi email reset.');
    }
  }

  /// Hàm đăng xuất
  Future<void> logout() async {
    await _auth.signOut(); // Xóa phiên đăng nhập trên Firebase
    _currentUser = null;   // Xóa cache user trên app
  }

  /// Hàm phụ trợ (Helper function) dùng để tạo tài khoản nhân viên mới
  /// Firebase Auth có một đặc điểm: Khi bạn gọi `createUserWithEmailAndPassword`, 
  /// tài khoản vừa tạo sẽ TỰ ĐỘNG ĐĂNG NHẬP, làm mất phiên đăng nhập của Admin hiện tại.
  /// Để giải quyết việc này, hàm này khởi tạo một Firebase App tạm thời (tempApp).
  Future<UserCredential> _createStaffAuthUser({
    required String email,
    required String password,
  }) async {
    final defaultApp = Firebase.app(); // Lấy cấu hình của Firebase app chính
    // Tạo tên ngẫu nhiên cho app phụ để tránh trùng lặp
    final tempAppName = 'staff_creator_${DateTime.now().microsecondsSinceEpoch}';
    
    // Khởi tạo Firebase app thứ hai
    final tempApp = await Firebase.initializeApp(name: tempAppName, options: defaultApp.options);

    try {
      // Lấy instance Auth của app phụ này
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      // Thực hiện tạo tài khoản (app phụ sẽ đăng nhập, app chính của admin không bị ảnh hưởng)
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Đăng xuất app phụ ngay sau khi tạo xong
      await tempAuth.signOut();
      return credential;
    } finally {
      // Cuối cùng, dù thành công hay thất bại, bắt buộc phải xóa app phụ đi để giải phóng tài nguyên
      await tempApp.delete();
    }
  }
}