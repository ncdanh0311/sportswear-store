import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/firebase_collections.dart';
import '../core/user_session.dart';

/// Lớp hỗ trợ trả về kết quả của các thao tác xác thực (đăng nhập, đăng ký).
/// Chứa trạng thái [success] và thông báo [message] đi kèm để hiển thị cho người dùng.
class LocalAuthResult {
  final bool success;
  final String message;
  LocalAuthResult({required this.success, required this.message});
}

/// Service xử lý các nghiệp vụ liên quan đến xác thực người dùng (Authentication)
/// và đồng bộ dữ liệu hồ sơ người dùng với Firestore.
class LocalAuthService {
  // Áp dụng Singleton pattern
  LocalAuthService._();
  static final LocalAuthService instance = LocalAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Xử lý đăng nhập bằng [email] và [password].
  /// - Xác thực qua Firebase Auth.
  /// - Tự động tạo doc trên Firestore nếu user chưa có (trường hợp tạo tay trên Firebase Console).
  /// - Kiểm tra cờ `isActive` để chặn tài khoản bị khóa.
  /// - Lưu thông tin vào [UserSession] nếu thành công.
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

      // Fallback: Tự động tạo dữ liệu trên Firestore nếu user đăng nhập được 
      // nhưng chưa có document (ví dụ: Admin vừa thêm user này trực tiếp trên Firebase Console)
      if (!userDoc.exists) {
        final fallbackName =
            emailLower.contains('@') ? emailLower.split('@').first : emailLower;
        final userData = {
          'id': uid,
          'fullName': fallbackName,
          'email': emailLower,
          'password': '', // Lưu ý: Thường không nên lưu trường password trên Firestore
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

      // Lấy dữ liệu user mới nhất và kiểm tra trạng thái hoạt động
      final data = (await userRef.get()).data() as Map<String, dynamic>;
      final isActive = (data['isActive']) ?? true;
      
      if (!isActive) {
        await _auth.signOut();
        return LocalAuthResult(
          success: false,
          message: 'Tài khoản của bạn đã bị khóa.',
        );
      }

      // Lưu phiên đăng nhập vào bộ nhớ tạm
      UserSession().saveUser(data);
      return LocalAuthResult(
        success: true,
        message: 'Đăng nhập thành công',
      );
      
    } on FirebaseAuthException catch (e) {
      // Xử lý và việt hóa các mã lỗi phổ biến từ Firebase Auth
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

  /// Xử lý đăng ký tài khoản mới.
  /// - Tạo tài khoản định danh trên Firebase Auth.
  /// - Khởi tạo doc hồ sơ tương ứng trên Firestore với các chỉ số mặc định (điểm thưởng, hạng thành viên).
  /// - Lưu phiên đăng nhập tự động ngay sau khi đăng ký thành công.
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

      // Khởi tạo dữ liệu mặc định cho user mới
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
      if (e.code == 'email-already-in-use') {
        errorMsg = 'Email này đã được sử dụng!';
      } else if (e.code == 'weak-password') {
        errorMsg = 'Mật khẩu quá yếu!';
      }
      return LocalAuthResult(success: false, message: errorMsg);
    }
  }

  /// Đăng xuất khỏi hệ thống.
  /// Xóa phiên làm việc của Firebase Auth và dọn dẹp dữ liệu cache trong [UserSession].
  Future<void> logout() async {
    await _auth.signOut();
    UserSession().clearUser();
  }

  /// Gửi email đặt lại mật khẩu.
  Future<LocalAuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return LocalAuthResult(
        success: true,
        message: "Đã gửi Email đặt lại mật khẩu!",
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Lỗi xảy ra, vui lòng thử lại";
      if (e.code == 'user-not-found') {
        errorMsg = "Email này chưa được đăng ký";
      } else if (e.code == 'invalid-email') {
        errorMsg = "Định dạng Email không hợp lệ";
      }
      return LocalAuthResult(success: false, message: errorMsg);
    }
  }

  /// Cập nhật một hoặc nhiều trường dữ liệu của người dùng trên Firestore.
  /// Đồng thời tự động cập nhật lại dữ liệu tương ứng đang lưu trong [UserSession].
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

  /// Khôi phục phiên đăng nhập (thường gọi ở màn hình Splash khi mới mở app).
  /// - Kiểm tra xem Firebase Auth còn giữ token đăng nhập không.
  /// - Tải lại dữ liệu từ Firestore và kiểm tra cờ `isActive`.
  /// - Trả về [true] nếu khôi phục thành công, [false] nếu thất bại hoặc tài khoản bị khóa.
  Future<bool> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return false; // Chưa đăng nhập hoặc token đã hết hạn

    final userDoc = await _firestore
        .collection(FirebaseCollections.users)
        .doc(user.uid)
        .get();

    if (!userDoc.exists) return false;

    final data = userDoc.data() as Map<String, dynamic>;
    final isActive = (data['isActive']) ?? true;

    if (!isActive) {
      // Bắt buộc đăng xuất và dọn cache nếu tài khoản bị vô hiệu hóa
      await _auth.signOut();
      UserSession().clearUser();
      return false;
    }

    // Khôi phục thành công
    UserSession().saveUser(data);
    return true;
  }
}
