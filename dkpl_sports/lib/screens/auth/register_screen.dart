import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_textfield.dart';
import '../../services/local_auth_service.dart'; 


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Khai báo các Controller để quản lý dữ liệu nhập vào từ các ô TextField
  final _nameController = TextEditingController();       // Ô Họ và tên
  final _emailController = TextEditingController();      // Ô Email
  final _phoneController = TextEditingController();      // Ô Số điện thoại
  final _passController = TextEditingController();       // Ô Mật khẩu
  final _confirmPassController = TextEditingController();// Ô Xác nhận mật khẩu

  // Biến trạng thái để xác định mật khẩu đang bị ẩn (true) hay hiện (false)
  bool _isObscure = true;
  // Biến trạng thái để hiển thị vòng xoay loading khi đang gọi API đăng ký
  bool _isLoading = false;

  /// Hàm xử lý logic khi người dùng bấm nút "Đăng ký"
  void _handleRegister() async {
    // Lấy dữ liệu từ các controller và dùng trim() để xóa khoảng trắng thừa ở 2 đầu
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    final confirmPass = _confirmPassController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    // 1. Validate cơ bản: Kiểm tra xem có ô nào bị bỏ trống không
    if (email.isEmpty || pass.isEmpty || name.isEmpty || phone.isEmpty) {
      // Hiển thị thông báo (SnackBar) yêu cầu điền đủ thông tin
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin!")),
      );
      return; // Dừng hàm lại, không thực hiện bước tiếp theo
    }
    
    // 2. Validate: Kiểm tra mật khẩu và xác nhận mật khẩu có khớp nhau không
    if (pass != confirmPass) {
      // Hiển thị thông báo lỗi nếu 2 ô mật khẩu khác nhau
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mật khẩu xác nhận không khớp!")),
      );
      return; // Dừng hàm lại
    }

    // 3. Cập nhật trạng thái loading để vô hiệu hóa nút bấm và hiện vòng xoay
    setState(() => _isLoading = true);

    // 4. GỌI LOGIC TỪ AUTH SERVICE ĐỂ ĐĂNG KÝ
    // Chờ kết quả trả về từ LocalAuthService
    final result = await LocalAuthService.instance.register(
      email: email,
      password: pass,
      name: name,
      phone: phone,
    );

    // 5. Kiểm tra xem widget còn tồn tại không trước khi cập nhật UI
    if (!mounted) return;
    
    // Tắt vòng xoay loading sau khi có kết quả
    setState(() => _isLoading = false);

    // 6. Xử lý kết quả trả về
    if (result.success) {
      // Nếu đăng ký thành công: Hiển thị thông báo màu xanh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.green),
      );
      // Đóng màn hình đăng ký và tự động quay về màn hình Đăng nhập (Login)
      Navigator.pop(context); 
    } else {
      // Nếu đăng ký thất bại (ví dụ: email đã tồn tại): Hiển thị thông báo màu đỏ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Đặt màu nền tổng thể
      backgroundColor: AppColors.background,
      
      // Thanh tiêu đề trên cùng (AppBar)
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Nền trong suốt
        elevation: 0, // Xóa hiệu ứng đổ bóng
        leading: IconButton(
          // Nút quay lại (mũi tên hướng trái)
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          // Khi bấm vào sẽ đóng màn hình hiện tại để về màn hình trước
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      // Sử dụng SingleChildScrollView để nội dung có thể cuộn được, 
      // tránh lỗi tràn màn hình khi bàn phím ảo bật lên
      body: SingleChildScrollView(
        child: Padding(
          // Căn lề trái/phải 24 pixel
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            // Căn các thành phần con về phía bên trái
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề màn hình
              const Text(
                "Tạo tài khoản",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 30), // Khoảng cách

              // Ô nhập Họ và tên
              CustomTextField(
                label: "Họ và tên",
                icon: Icons.person_outline,
                controller: _nameController,
              ),
              
              // Ô nhập Email
              CustomTextField(
                label: "Email",
                icon: Icons.email_outlined,
                controller: _emailController,
              ),
              
              // Ô nhập Số điện thoại
              CustomTextField(
                label: "Số điện thoại",
                icon: Icons.phone_android_outlined,
                controller: _phoneController,
                keyboardType: TextInputType.phone, // Mở bàn phím số
              ),
              
              // Ô nhập Mật khẩu
              CustomTextField(
                label: "Mật khẩu",
                icon: Icons.lock_outline,
                isPassword: true, // Kích hoạt chế độ ẩn chữ
                controller: _passController,
                obscureText: _isObscure, // Dựa vào trạng thái để ẩn/hiện
                // Nút hình con mắt ở cuối ô
                suffixIcon: IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  // Đảo ngược trạng thái _isObscure khi bấm
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                ),
              ),
              
              // Ô nhập Xác nhận mật khẩu
              CustomTextField(
                label: "Xác nhận mật khẩu",
                icon: Icons.lock_clock_outlined,
                isPassword: true,
                obscureText: _isObscure, // Dùng chung biến _isObscure với ô trên
                controller: _confirmPassController,
              ),

              const SizedBox(height: 30), // Khoảng trống trước nút bấm

              // Khu vực Nút Đăng ký / Vòng xoay Loading
              // Nếu đang tải (_isLoading = true) thì hiện vòng xoay ở giữa
              // Nếu không thì hiện Nút bấm
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : CustomButton(
                      text: "Đăng ký", 
                      onPressed: _handleRegister // Gọi hàm xử lý khi bấm
                    ),

              const SizedBox(height: 20), // Khoảng trống ở cuối cùng
            ],
          ),
        ),
      ),
    );
  }
}