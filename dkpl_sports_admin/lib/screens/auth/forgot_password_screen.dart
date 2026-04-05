import 'package:flutter/material.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  String? _successMsg;

  Future<void> _onSendEmail() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() { _isLoading = true; _errorMsg = null; _successMsg = null; });

    final result = await AuthService.instance.forgotPassword(email: _emailCtrl.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      setState(() => _successMsg = result.message);
    } else {
      setState(() => _errorMsg = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthHeader(title: 'Quên mật khẩu', subtitle: 'Nhập email để nhận link tạo mật khẩu mới', icon: Icons.lock_reset_outlined),
            const SizedBox(height: 32),
            
            if (_errorMsg != null) ...[AuthErrorBanner(message: _errorMsg!), const SizedBox(height: 18)],
            if (_successMsg != null) ...[AuthSuccessBanner(message: _successMsg!), const SizedBox(height: 18)],
            
            AuthInputField(controller: _emailCtrl, label: 'Email đã đăng ký', hint: 'admin@dkpl.vn', prefixIcon: Icons.email_outlined),
            const SizedBox(height: 32),
            AuthButton(label: 'GỬI YÊU CẦU', isLoading: _isLoading, onPressed: _onSendEmail),
          ],
        ),
      ),
    );
  }
}
