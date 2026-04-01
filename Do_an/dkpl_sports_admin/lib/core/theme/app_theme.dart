import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.primaryNavy, // Màu nền dự phòng
      
      // Cấu hình AppBar mặc định
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Để lộ nền gradient bên dưới
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.bold, 
          color: AppColors.white
        ),
        iconTheme: IconThemeData(color: AppColors.white),
      ),

      // Cấu hình Input mặc định (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white.withOpacity(0.1), // Nền mờ trên background xanh
        hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentCyan, width: 2),
        ),
      ),
    );
  }
}