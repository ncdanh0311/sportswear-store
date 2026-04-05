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

      final uid = userCredential.user!.uid;
      final staffRef = _firestore.collection('staff').doc(uid);
      var doc = await staffRef.get();

      if (!doc.exists) {
        final lookup = await _firestore
            .collection('staff')
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
        if (lookup.docs.isNotEmpty) {
          final fallbackData = lookup.docs.first.data();
          final merged = {
            'id': uid,
            ...fallbackData,
          };
          if ((merged['roleId'] ?? '').toString().isEmpty &&
              (merged['role'] ?? '').toString().isNotEmpty) {
            merged['roleId'] = merged['role'];
          }
          await staffRef.set(merged, SetOptions(merge: true));
          doc = await staffRef.get();
        }
      }

      if (!doc.exists) {
        await _auth.signOut();
        return const AuthResult(
          success: false,
          message: 'Tai khoan nay khong co quyen truy cap app admin.',
        );
      }

      final map = doc.data() as Map<String, dynamic>;
      if ((map['roleId'] ?? '').toString().isEmpty &&
          (map['role'] ?? '').toString().isNotEmpty) {
        await staffRef.set({
          'roleId': map['role'],
        }, SetOptions(merge: true));
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
    required String dob,
    required String cccd,
    required String password,
    required String roleId,
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
        return const AuthResult(
          success: false,
          message: 'Email nay dang duoc gan cho mot nhan su dang hoat dong.',
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
        dob: dob.trim(),
        email: normalizedEmail,
        password: password,
        phone: phone.trim(),
        address: address.trim(),
        cccd: cccd.trim(),
        roleId: roleId,
        createdAt: DateTime.now().toIso8601String(),
      );

      await _firestore.collection('staff').doc(uid).set(newUser.toJson());

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
