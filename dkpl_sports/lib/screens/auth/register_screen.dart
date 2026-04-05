import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../services/auth_service.dart'; // Import Service

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isObscure = true;
  bool _isLoading = false;

  void _handleRegister() async {
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    final confirmPass = _confirmPassController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    // Validate cơ bản
    if (email.isEmpty || pass.isEmpty || name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin!")),
      );
      return;
    }
    if (pass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu xác nhận không khớp!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // GỌI LOGIC TỪ AUTH SERVICE
    final result = await AuthService.instance.register(
      email: email,
      password: pass,
      name: name,
      phone: phone,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Quay về màn Login
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Tạo tài khoản",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 30),

              CustomTextField(
                label: "Họ và tên",
                icon: Icons.person_outline,
                controller: _nameController,
              ),
              CustomTextField(
                label: "Email",
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              CustomTextField(
                label: "Số điện thoại",
                icon: Icons.phone_android_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
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
              CustomTextField(
                label: "Xác nhận mật khẩu",
                icon: Icons.lock_clock_outlined,
                isPassword: true,
                obscureText: _isObscure,
                controller: _confirmPassController,
              ),

              const SizedBox(height: 30),

              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : CustomButton(text: "Đăng ký", onPressed: _handleRegister),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
