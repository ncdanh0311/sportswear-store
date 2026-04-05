// File: lib/screens/login_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/auth_widgets.dart'; 
import 'forgot_password_screen.dart';
import 'package:dkpl_sports_admin/screens/navigation/main_navigation_screen.dart'; 
import 'package:dkpl_sports_admin/screens/staff/add_staff_screen.dart';

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
  bool _isCheckingBootstrap = true;
  bool _allowBootstrap = false;
  String? _errorMsg;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

    // Chỉ autofill trong chế độ debug để test nhanh.
    if (kDebugMode) {
      _emailCtrl.text = "admin1@gmail.com";
      _passwordCtrl.text = "dkpl123";
    }
    _checkBootstrapMode();
  }

  Future<void> _checkBootstrapMode() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('staff').limit(1).get();
      if (!mounted) return;
      setState(() {
        _allowBootstrap = snapshot.docs.isEmpty;
        _isCheckingBootstrap = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _allowBootstrap = false;
        _isCheckingBootstrap = false;
      });
    }
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
                  
                  if (_isCheckingBootstrap)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),

                  if (!_isCheckingBootstrap && _allowBootstrap) ...[
                    const SizedBox(height: 24),
                    const AuthDivider(text: 'Khởi tạo hệ thống'),
                    const SizedBox(height: 8),
                    const Text(
                      'Chưa có tài khoản nhân sự. Hãy tạo Admin đầu tiên.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddStaffScreen(bootstrapMode: true),
                        ),
                      ),
                      child: const Text(
                        'Tạo tài khoản Admin đầu tiên',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],

                  if (kDebugMode) ...[
                    const SizedBox(height: 24),
                    const AuthDivider(text: 'Debug Mode'),
                    const SizedBox(height: 8),
                    const Text(
                      'Đang bật autofill tài khoản test.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
