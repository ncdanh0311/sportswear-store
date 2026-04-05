import 'package:flutter/material.dart';
import '../../services/local_auth_service.dart';
import '../../core/constants/app_colors.dart'; // Đổi đường dẫn nếu cần
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'package:dkpl_sports/HomePage.dart';

class LoginScreen extends StatefulWidget {
  final bool embedded;
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.embedded = false,
    this.onLoginSuccess,
  });
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // GỌI LOGIC TỪ SERVICE (Sạch sẽ chưa?)
    final result = await LocalAuthService.instance.login(
      email: _emailController.text.trim(),
      password: _passController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      if (widget.embedded) {
        widget.onLoginSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng nhập thành công"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
          (route) => false,
        );
      }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
        child: Column(
          children: [
            Image.asset('assets/images/Logo2.png', height: 120),
            const SizedBox(height: 20),
            const Text(
              "Chào mừng trở lại!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const Text(
              "Đăng nhập để tiếp tục đam mê",
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
            ),
            const SizedBox(height: 40),

            CustomTextField(
              label: "Email",
              icon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            CustomTextField(
              label: "Mật khẩu",
              icon: Icons.lock_outline,
              isPassword: true,
              controller: _passController,
              obscureText: _isObscure,
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: const Text(
                  "Quên mật khẩu?",
                  style: TextStyle(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _isLoading
                ? const CircularProgressIndicator(color: AppColors.primaryBlue)
                : CustomButton(text: "Đăng nhập", onPressed: _handleLogin),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Chưa có tài khoản? ",
                  style: TextStyle(color: AppColors.textDark),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text(
                    "Đăng ký ngay",
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
