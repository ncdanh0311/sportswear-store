// File: lib/screens/splash_screen.dart (hoặc đường dẫn tương ứng)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../core/user_session.dart';
import 'HomePage.dart';
import 'services/local_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      _restoreSessionIfLoggedIn(),
    ]);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()),
    );
  }

  Future<void> _restoreSessionIfLoggedIn() async {
    try {
      final localRestored = await LocalAuthService.instance.restoreSession();
      if (localRestored) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String uid = user.uid;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection(FirebaseCollections.users)
            .doc(uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

          bool isActive = data["isActive"] ?? true;
          if (isActive) {
            UserSession().saveUser(data);
          } else {
            await FirebaseAuth.instance.signOut();
            UserSession().clearUser();
          }
        } else {
          await FirebaseAuth.instance.signOut();
          UserSession().clearUser();
        }
      }
    } catch (e) {
      print("Lỗi khi phục hồi session: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/splash_screen.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
