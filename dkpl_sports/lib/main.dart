import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBFTMGszKfMlxLlMm9p33z4ydWhY2vYn5o", 
      appId: "1:423644867047:android:12188b8a1f7dd8aeeff542", 
      messagingSenderId: "423644867047", 
      projectId: "dkpl-sports",
      // storageBucket: "...", // Có thể bỏ qua nếu chưa dùng Storage
    ),
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Tắt cái banner "Debug" ở góc phải
      title: 'DKPL Sports',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SplashScreen(), // Trang đầu tiên ứng dụng sẽ mở
    );
  }
}
