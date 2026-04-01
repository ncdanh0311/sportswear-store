// File: lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/auth_widgets.dart'; 
import 'forgot_password_screen.dart';
import 'package:dkpl_sports_admin/screens/navigation/main_navigation_screen.dart'; 
import 'package:dkpl_sports_admin/screens/staff/add_staff_screen.dart'; // Import màn hình Add Staff để làm backdoor

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

    // TỰ ĐỘNG ĐIỀN SẴN TÀI KHOẢN ADMIN ĐỂ DEV TEST NHANH CỰC KỲ TIỆN LỢI
    _emailCtrl.text = "admin@dkpl.vn";
    _passwordCtrl.text = "dkpl123456";
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passwordCtrl.dispose(); _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    final result = await AuthService.instance.login(email: _emailCtrl.text, password: _passwordCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
    } else {
      setState(() => _errorMsg = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthHeader(
                    title: 'Đăng nhập', 
                    subtitle: 'Hệ thống Quản trị Nội bộ DKPL', 
                    icon: Icons.admin_panel_settings_outlined
                  ),
                  const SizedBox(height: 32),
                  
                  if (_errorMsg != null) ...[ AuthErrorBanner(message: _errorMsg!), const SizedBox(height: 20)],
                  
                  AuthInputField(controller: _emailCtrl, label: 'Email cấp phát', hint: 'nv.a@dkpl.vn', prefixIcon: Icons.email_outlined),
                  const SizedBox(height: 20),
                  AuthInputField(controller: _passwordCtrl, label: 'Mật khẩu', hint: '••••••••', prefixIcon: Icons.lock_outline, isPassword: true),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                      child: const Text('Quên mật khẩu?', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  AuthButton(label: 'ĐĂNG NHẬP', isLoading: _isLoading, onPressed: _onLogin),
                  
                  const SizedBox(height: 32),
                  
                  // ── CỬA HẬU DÀNH CHO DEVELOPER SETUP LẦN ĐẦU ──
                  const AuthDivider(text: 'Dành cho Developer Setup'),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStaffScreen())),
                      child: const Text(
                        '🚀 Khởi tạo tài khoản Owner gốc', 
                        style: TextStyle(
                          color: Colors.orangeAccent, 
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold
                        )
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
