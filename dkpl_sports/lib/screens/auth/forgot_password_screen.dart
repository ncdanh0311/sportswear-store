import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../services/auth_service.dart'; // Import Service

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Email!")));
      return;
    }

    setState(() => _isLoading = true);

    // GỌI LOGIC TỪ SERVICE
    final result = await AuthService.instance.resetPassword(email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Đã gửi Email!"),
          content: Text(result.message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Đóng Dialog
                Navigator.pop(context); // Trở về Login
              },
              child: const Text(
                "Đồng ý",
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 20),
            const Text(
              "Quên mật khẩu?",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Đừng lo lắng! Hãy nhập email đăng ký của bạn, chúng tôi sẽ gửi hướng dẫn lấy lại mật khẩu.",
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
            ),
            const SizedBox(height: 40),

            CustomTextField(
              label: "Email",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            const SizedBox(height: 30),

            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : CustomButton(
                    text: "Gửi yêu cầu",
                    onPressed: _handleResetPassword,
                  ),
          ],
        ),
      ),
    );
  }
}
