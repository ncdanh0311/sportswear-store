import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/auth_result_model.dart';
import '../models/staff_model.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StaffModel? _currentUser;
  StaffModel? get currentUser => _currentUser;

  Future<AuthResult> login({required String email, required String password}) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final normalizedPassword = password.trim();

      if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
        return const AuthResult(success: false, message: 'Vui long nhap day du thong tin.');
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: normalizedPassword,
      );

      final doc = await _firestore.collection('staff').doc(userCredential.user!.uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return const AuthResult(
          success: false,
          message: 'Tai khoan nay khong co quyen truy cap app admin.',
        );
      }

      final map = doc.data() as Map<String, dynamic>;
      if (map['isDeleted'] == true) {
        await _auth.signOut();
        return const AuthResult(success: false, message: 'Tai khoan nhan su da bi vo hieu hoa.');
      }

      _currentUser = StaffModel.fromJson(map, doc.id);
      return AuthResult(success: true, message: 'Dang nhap thanh cong!', user: _currentUser);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return const AuthResult(success: false, message: 'Email hoac mat khau khong dung.');
      }
      return AuthResult(success: false, message: e.message ?? 'Loi dang nhap');
    } catch (e) {
      return AuthResult(success: false, message: 'Loi khong xac dinh: $e');
    }
  }

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    required String dateOfBirth,
    required String joinDate,
    required String password,
    required String role,
  }) async {
    try {
      final creatorId = _currentUser?.id ?? 'system';
      final normalizedEmail = email.trim().toLowerCase();

      final existingByEmail = await _firestore
          .collection('staff')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (existingByEmail.docs.isNotEmpty) {
        final existingDoc = existingByEmail.docs.first;
        final existingData = existingDoc.data();
        final isDeleted = existingData['isDeleted'] == true;

        if (!isDeleted) {
          return const AuthResult(
            success: false,
            message: 'Email nay dang duoc gan cho mot nhan su dang hoat dong.',
          );
        }

        final restoredUser = StaffModel(
          id: existingDoc.id,
          fullName: fullName.trim(),
          email: normalizedEmail,
          phone: phone.trim(),
          address: address.trim(),
          dateOfBirth: dateOfBirth.trim(),
          joinDate: joinDate.trim(),
          role: role,
          avatar: (existingData['avatar'] as String?)?.trim().isNotEmpty == true
              ? (existingData['avatar'] as String)
              : 'https://i.pravatar.cc/150?img=10',
          createdAt: existingData['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
          createdBy: existingData['createdBy']?.toString() ?? creatorId,
        );

        await _firestore.collection('staff').doc(existingDoc.id).update({
          ...restoredUser.toJson(),
          'isDeleted': false,
          'deletedAt': null,
          'deletedBy': null,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        return const AuthResult(
          success: true,
          message:
              'Da kich hoat lai tai khoan cu theo email nay. Neu can, dung Quen mat khau de dat lai mat khau moi.',
        );
      }

      final userCredential = await _createStaffAuthUser(
        email: normalizedEmail,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final newUser = StaffModel(
        id: uid,
        fullName: fullName.trim(),
        email: normalizedEmail,
        phone: phone.trim(),
        address: address.trim(),
        dateOfBirth: dateOfBirth.trim(),
        joinDate: joinDate.trim(),
        role: role,
        avatar: 'https://i.pravatar.cc/150?img=10',
        createdAt: DateTime.now().toIso8601String(),
        createdBy: creatorId,
      );

      await _firestore.collection('staff').doc(uid).set({
        ...newUser.toJson(),
        'isDeleted': false,
      });

      return AuthResult(
        success: true,
        message: 'Tao tai khoan nhan vien thanh cong!',
        user: newUser,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return const AuthResult(success: false, message: 'Email nay da duoc su dung.');
      }
      return AuthResult(success: false, message: e.message ?? 'Loi dang ky');
    } catch (e) {
      return AuthResult(success: false, message: 'Loi khong xac dinh: $e');
    }
  }

  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult(
        success: true,
        message: 'Link dat lai mat khau da duoc gui vao email.',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, message: e.message ?? 'Loi gui email reset.');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  Future<UserCredential> _createStaffAuthUser({
    required String email,
    required String password,
  }) async {
    final defaultApp = Firebase.app();
    final tempAppName = 'staff_creator_${DateTime.now().microsecondsSinceEpoch}';
    final tempApp = await Firebase.initializeApp(name: tempAppName, options: defaultApp.options);

    try {
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await tempAuth.signOut();
      return credential;
    } finally {
      await tempApp.delete();
    }
  }
}
