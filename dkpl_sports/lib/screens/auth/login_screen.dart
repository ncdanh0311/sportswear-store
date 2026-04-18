import 'package:flutter/material.dart';
import '../../services/local_auth_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import 'package:dkpl_sports/HomePage.dart';

/// Màn hình đăng nhập, sử dụng StatefulWidget vì có các trạng thái cần thay đổi
/// (như trạng thái loading, trạng thái ẩn/hiện mật khẩu).
class LoginScreen extends StatefulWidget {
  // Cờ kiểm tra xem màn hình này có đang được nhúng (như một popup/bottom sheet)
  // hay là một màn hình độc lập toàn màn hình.
  final bool embedded;
  // Hàm callback được gọi khi đăng nhập thành công (dành cho trường hợp embedded)
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    super.key,
    this.embedded = false, // Mặc định là màn hình độc lập
    this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller dùng để lấy và quản lý dữ liệu nhập vào từ ô Email
  final _emailController = TextEditingController();
  // Controller dùng để lấy và quản lý dữ liệu nhập vào từ ô Mật khẩu
  final _passController = TextEditingController();
  
  // Biến trạng thái để xác định mật khẩu đang bị ẩn (true) hay hiện (false)
  bool _isObscure = true;
  // Biến trạng thái để hiển thị vòng xoay loading khi đang gọi API
  bool _isLoading = false;

  /// Hàm xử lý logic khi người dùng bấm nút "Đăng nhập"
  void _handleLogin() async {
    // 1. Kiểm tra tính hợp lệ của dữ liệu đầu vào (Validation)
    // Nếu email hoặc mật khẩu trống (chỉ có khoảng trắng)
    if (_emailController.text.trim().isEmpty ||
        _passController.text.trim().isEmpty) {
      // Hiển thị thông báo (SnackBar) yêu cầu nhập đủ thông tin
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin!")),
      );
      return; // Dừng hàm lại, không gọi API nữa
    }

    // 2. Cập nhật trạng thái loading để vô hiệu hóa nút bấm và hiện vòng xoay
    setState(() => _isLoading = true);

    // 3. GỌI LOGIC TỪ SERVICE ĐỂ ĐĂNG NHẬP
    // Chờ phản hồi từ LocalAuthService
    final result = await LocalAuthService.instance.login(
      email: _emailController.text.trim(),
      password: _passController.text.trim(),
    );

    // 4. Kiểm tra widget còn tồn tại trên màn hình không trước khi cập nhật UI
    // (Tránh lỗi gọi setState khi màn hình đã bị đóng)
    if (!mounted) return;
    
    // Tắt trạng thái loading sau khi có kết quả từ service
    setState(() => _isLoading = false);

    // 5. Xử lý kết quả trả về từ Service
    if (result.success) { // Nếu đăng nhập thành công
      if (widget.embedded) {
        // Trường hợp màn hình đang được nhúng: gọi callback và hiện thông báo
        widget.onLoginSuccess?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng nhập thành công"),
            backgroundColor: Colors.green, // Đổi màu xanh báo thành công
          ),
        );
      } else {
        // Trường hợp màn hình độc lập: Chuyển sang Homepage
        // pushAndRemoveUntil giúp xóa toàn bộ lịch sử màn hình trước đó,
        // người dùng bấm nút Back (Trở về) sẽ không quay lại màn hình Login được nữa.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const Homepage()),
          (route) => false,
        );
      }
    } else {
      // Nếu đăng nhập thất bại: Hiển thị lỗi do service trả về
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Đặt màu nền cho toàn bộ màn hình
      backgroundColor: AppColors.background,
      // SingleChildScrollView giúp nội dung có thể cuộn được
      // Tránh lỗi "Bottom overflowed" (tràn màn hình) khi bàn phím ảo bật lên
      body: SingleChildScrollView(
        // Padding cách lề hai bên 24.0 và cách trên dưới 60.0
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60.0),
        child: Column(
          children: [
            // Logo của ứng dụng
            Image.asset('assets/images/Logo2.png', height: 120),
            const SizedBox(height: 20), // Khoảng cách
            
            // Tiêu đề chính
            const Text(
              "Chào mừng trở lại!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            
            // Tiêu đề phụ
            const Text(
              "Đăng nhập để tiếp tục đam mê",
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
            ),
            const SizedBox(height: 40), // Khoảng cách

            // Ô nhập Email
            CustomTextField(
              label: "Email",
              icon: Icons.email_outlined,
              controller: _emailController,
              keyboardType: TextInputType.emailAddress, // Mở bàn phím có nút '@'
            ),
            
            // Ô nhập Mật khẩu
            CustomTextField(
              label: "Mật khẩu",
              icon: Icons.lock_outline,
              isPassword: true, // Cờ báo hiệu đây là ô mật khẩu
              controller: _passController,
              obscureText: _isObscure, // Biến quy định ẩn/hiện chữ
              // Nút hình con mắt ở cuối ô nhập liệu
              suffixIcon: IconButton(
                icon: Icon(
                  // Đổi icon dựa theo trạng thái _isObscure
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                ),
                // Khi bấm vào sẽ đảo ngược trạng thái _isObscure và build lại UI
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ),
            ),

            // Nút Quên mật khẩu
            Align(
              alignment: Alignment.centerRight, // Căn sang lề phải
              child: TextButton(
                // Điều hướng sang màn hình ForgotPasswordScreen khi bấm vào
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

            // Khu vực Nút Đăng nhập / Loading
            // Nếu _isLoading = true -> Hiện vòng xoay
            // Nếu _isLoading = false -> Hiện nút Đăng nhập
            _isLoading
                ? const CircularProgressIndicator(color: AppColors.primaryBlue)
                : CustomButton(text: "Đăng nhập", onPressed: _handleLogin),

            const SizedBox(height: 20),
            
            // Khu vực điều hướng sang trang Đăng ký
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // Căn giữa nội dung
              children: [
                const Text(
                  "Chưa có tài khoản? ",
                  style: TextStyle(color: AppColors.textDark),
                ),
                // GestureDetector giúp nhận diện thao tác chạm (tap)
                GestureDetector(
                  // Điều hướng sang màn hình RegisterScreen
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