import 'package:flutter/material.dart';

class AppColors {
  // Màu chính lấy từ Logo
  static const Color primaryNavy = Color(0xFF001B48); // Màu khiên tối
  static const Color primaryBlue = Color(0xFF02457A); // Màu xanh chủ đạo
  static const Color accentCyan = Color(0xFF00D4FF);  // Màu sáng (highlight)
  
  // Màu nền (Gradient)
  static const Color backgroundDark = Color(0xFF001233);
  static const Color backgroundLight = Color(0xFF003060);

  // Màu trạng thái & Text
  static const Color white = Colors.white;
  static const Color textPrimary = Colors.white; // Vì nền tối nên chữ trắng
  static const Color textSecondary = Color(0xFF97AABD);
  static const Color error = Color(0xFFFF4C4C);
  
  // Gradient dùng chung cho toàn app
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      backgroundLight, // Xanh sáng hơn ở trên
      backgroundDark,  // Xanh đen ở dưới
    ],
  );
}