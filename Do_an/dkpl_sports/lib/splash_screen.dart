// File: lib/screens/splash_screen.dart (hoặc đường dẫn tương ứng)
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/user_session.dart'; // Đổi đường dẫn import cho đúng
import 'HomePage.dart'; // Đổi đường dẫn import cho đúng

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
    // 1. Vừa tạo hiệu ứng chờ 2s, vừa chạy ngầm việc check Login
    await Future.wait([
      Future.delayed(const Duration(seconds: 2)), // Đợi 2s cho đẹp
      _restoreSessionIfLoggedIn(), // Hàm phục hồi dữ liệu ngầm
    ]);

    // 2. Chuyển sang giao diện Homepage
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()),
    );
  }

  // Hàm phục hồi UserSession từ Firebase
  Future<void> _restoreSessionIfLoggedIn() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      // Nếu Firebase báo là đã từng login trước đó
      if (user != null) {
        String uid = user.uid;

        // Đi tìm data của user này trong Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

          bool isActive = data["is_actived"] ?? true;
          if (isActive) {
            // NẠP LẠI DỮ LIỆU VÀO RAM (UserSession)
            UserSession().saveUser(data);
            print("✅ Đã phục hồi UserSession thành công!");
          } else {
            // Nếu tài khoản bị khóa trong lúc tắt App, thì ép đăng xuất
            await FirebaseAuth.instance.signOut();
            UserSession().clearUser();
          }
        } else {
          // Lỗi data mồ côi
          await FirebaseAuth.instance.signOut();
          UserSession().clearUser();
        }
      }
    } catch (e) {
      print("❌ Lỗi khi phục hồi session: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Nên set màu nền để tránh viền đen
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
