import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_textfield.dart';
import '../../../services/local_auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Controller dùng để lấy và quản lý dữ liệu chữ mà người dùng nhập vào ô Email
  final _emailController = TextEditingController();
  
  // Biến trạng thái để hiển thị vòng xoay loading khi đang gọi API gửi email
  bool _isLoading = false;

  /// Hàm dispose được gọi khi màn hình này bị đóng/hủy hoàn toàn
  @override
  void dispose() {
    // Luôn phải dispose (hủy) các controller để giải phóng bộ nhớ, tránh memory leak
    _emailController.dispose();
    super.dispose();
  }

  /// Hàm xử lý logic khi người dùng bấm nút "Gửi yêu cầu"
  Future<void> _handleResetPassword() async {
    // Lấy nội dung email người dùng nhập, dùng trim() để xóa khoảng trắng thừa ở 2 đầu
    final email = _emailController.text.trim();

    // 1. Kiểm tra tính hợp lệ (Validation)
    if (email.isEmpty) {
      // Nếu ô email trống, hiển thị thanh thông báo (SnackBar) màu mặc định
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Email!")));
      return; // Kết thúc hàm tại đây, không làm các bước tiếp theo
    }

    // 2. Cập nhật trạng thái thành "đang tải" để vô hiệu hóa nút bấm và hiện vòng xoay
    setState(() => _isLoading = true);

    // 3. GỌI LOGIC TỪ SERVICE ĐỂ XỬ LÝ
    // Chờ service thực hiện việc gửi email báo quên mật khẩu
    final result = await LocalAuthService.instance.resetPassword(email);

    // 4. Kiểm tra xem widget (màn hình) này có còn tồn tại không
    // (Lỡ người dùng bấm nút Back đóng màn hình trong lúc API đang chạy)
    if (!mounted) return;
    
    // Tắt trạng thái loading sau khi service đã trả về kết quả
    setState(() => _isLoading = false);

    // 5. Xử lý kết quả trả về từ Service
    if (result.success) {
      // Nếu gửi email thành công, hiện một hộp thoại (Dialog) thông báo
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Đã gửi Email!"), // Tiêu đề hộp thoại
          content: Text(result.message),      // Nội dung thông báo lấy từ service
          actions: [
            // Nút "Đồng ý" trong hộp thoại
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Lệnh 1: Đóng hộp thoại (Dialog) hiện tại
                Navigator.pop(context); // Lệnh 2: Đóng màn hình Quên mật khẩu, trở về màn hình Đăng nhập (Login)
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
      // Nếu thất bại (ví dụ: email không tồn tại), hiện lỗi bằng SnackBar màu đỏ
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Màu nền của toàn bộ màn hình
      backgroundColor: AppColors.background,
      
      // Thanh tiêu đề trên cùng (AppBar)
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Làm trong suốt AppBar
        elevation: 0, // Xóa bóng mờ (đổ bóng) dưới AppBar
        leading: IconButton(
          // Nút quay lại (Back)
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          // Bấm vào sẽ đóng màn hình này để quay lại màn hình trước đó
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      // Phần thân của màn hình
      body: Padding(
        // Căn lề hai bên trái/phải 24 pixel
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          // Căn các widget con theo lề trái
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20), // Khoảng trống
            
            // Icon lớn biểu tượng cho việc reset mật khẩu
            const Icon(
              Icons.lock_reset,
              size: 80,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 20), // Khoảng trống
            
            // Tiêu đề chính của màn hình
            const Text(
              "Quên mật khẩu?",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10), // Khoảng trống
            
            // Dòng text hướng dẫn người dùng
            const Text(
              "Đừng lo lắng! Hãy nhập email đăng ký của bạn, chúng tôi sẽ gửi hướng dẫn lấy lại mật khẩu.",
              style: TextStyle(fontSize: 16, color: AppColors.textLight),
            ),
            const SizedBox(height: 40), // Khoảng trống lớn trước khi nhập liệu

            // Ô nhập liệu Email (Sử dụng widget CustomTextField tự build)
            CustomTextField(
              label: "Email",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress, // Mở bàn phím tối ưu cho gõ email
              controller: _emailController, // Gắn controller để lấy dữ liệu
            ),
            const SizedBox(height: 30), // Khoảng trống trước nút bấm

            // Khu vực Nút Gửi yêu cầu / Vòng xoay Loading
            // Nếu biến _isLoading là true -> Hiển thị vòng xoay ở giữa màn hình
            // Nếu biến _isLoading là false -> Hiển thị nút CustomButton
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : CustomButton(
                    text: "Gửi yêu cầu",
                    // Khi bấm vào nút, sẽ gọi hàm xử lý logic ở trên
                    onPressed: _handleResetPassword,
                  ),
          ],
        ),
      ),
    );
  }
}
