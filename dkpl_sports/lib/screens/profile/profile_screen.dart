import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/user_session.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final session = UserSession();
  bool _isLoading = false;

  Future<void> _updateAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => _isLoading = true);

      // GỌI SERVICE XỬ LÝ UP ẢNH
      final error = await ProfileService.instance.uploadAvatar(
        File(pickedFile.path),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cập nhật ảnh thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          "Hồ sơ cá nhân",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderSection(),
                const SizedBox(height: 20),
                _buildOrderStatusSection(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildMenuTile(
                        icon: Icons.confirmation_number_outlined,
                        title: "Kho Voucher",
                        onTap: () {},
                      ),
                      _buildMenuTile(
                        icon: Icons.location_on_outlined,
                        title: "Địa chỉ nhận hàng",
                        onTap: () {},
                      ),
                      const SizedBox(height: 20),
                      _buildMenuTile(
                        icon: Icons.logout,
                        title: "Đăng xuất",
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () async {
                          await AuthService.instance.logout();
                          if (mounted) Navigator.pop(context); // Về trang chủ
                        },
                      ),
                      const SizedBox(
                        height: 40,
                      ), // Đệm dưới cùng cho đỡ sát mép
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. PHẦN HEADER (AVATAR & THÔNG TIN CƠ BẢN)
  // ==========================================
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(
                  session.avatar ??
                      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRD0Y5uEmFetc0Xb25SAiiO4ZwYE8g7r8HBug&s",
                ),
              ),
              GestureDetector(
                onTap: _updateAvatar,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.accentBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            session.fullName ?? "Khách hàng mới",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            session.email ?? "Chưa liên kết email",
            style: const TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
              setState(() {}); // Refresh sau khi sửa xong
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text("Chỉnh sửa hồ sơ"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. KHỐI TÌNH TRẠNG ĐƠN HÀNG ĐÃ ĐƯỢC PHỤC HỒI
  // ==========================================
  Widget _buildOrderStatusSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Đơn hàng của tôi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                "Xem tất cả",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusIcon(Icons.inventory_2_outlined, "Chờ xác nhận"),
              _buildStatusIcon(Icons.local_shipping_outlined, "Đang giao"),
              _buildStatusIcon(Icons.check_circle_outline, "Đã giao"),
              _buildStatusIcon(Icons.star_outline, "Đánh giá"),
            ],
          ),
        ],
      ),
    );
  }

  // Tiện ích vẽ icon cho phần Tình trạng đơn hàng
  Widget _buildStatusIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. WIDGET TẠO MENU TILE ĐÃ ĐƯỢC PHỤC HỒI ĐẸP MẮT
  // ==========================================
  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = AppColors.primaryBlue,
    Color textColor = AppColors.textDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
      ),
    );
  }
}
