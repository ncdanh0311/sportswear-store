// File: lib/screens/add_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/screens/auth/login_screen.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _dobCtrl = TextEditingController();
  DateTime? _selectedDOB;

  final _joinDateCtrl = TextEditingController(); // <--- Controller Ngày vào làm
  DateTime? _selectedJoinDate;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: "dkpl123456");

  bool _isLoading = false;

  final Map<String, String> _rolesMap = {
    'Chăm sóc khách hàng (CSKH)': 'cskh',
    'Quản lý kho (Storage)': 'storage',
    'Content / Marketing': 'content',
    'Quản trị viên (Admin)': 'admin',
  };

  String _selectedRoleLabel = 'Chăm sóc khách hàng (CSKH)';

  // Hàm chọn ngày sinh
  Future<void> _pickDateOfBirth() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1960),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)), // Yêu cầu >= 16 tuổi
    );

    if (picked != null) {
      setState(() {
        _selectedDOB = picked;
        _dobCtrl.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  // Hàm chọn ngày vào làm
  Future<void> _pickJoinDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Mặc định mở ra là ngày hôm nay
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _selectedJoinDate = picked;
        _joinDateCtrl.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<void> _handleCreateStaff() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _addressCtrl.text.isEmpty ||
        _dobCtrl.text.isEmpty ||
        _joinDateCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin nhân sự!')));
      return;
    }

    setState(() => _isLoading = true);
    String roleValue = _rolesMap[_selectedRoleLabel] ?? 'cskh';

    final result = await AuthService.instance.register(
      fullName: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      address: _addressCtrl.text,
      dateOfBirth: _dobCtrl.text,
      joinDate: _joinDateCtrl.text, // <--- Truyền dữ liệu xuống
      password: _passwordCtrl.text,
      role: roleValue,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo nhân sự thành công!', style: TextStyle(color: Colors.greenAccent)),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hệ thống đã chuyển phiên bản, vui lòng đăng nhập lại.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message, style: const TextStyle(color: Colors.redAccent)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(title: const Text('Thêm Nhân Sự Mới')),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: "1. Thông tin cá nhân"),
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductTextField(
                          label: "Họ và Tên",
                          controller: _nameCtrl,
                          hint: "VD: Nguyễn Văn A",
                        ),
                        const SizedBox(height: 16),
                        ProductTextField(
                          label: "Số điện thoại",
                          controller: _phoneCtrl,
                          hint: "VD: 0909...",
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ProductDatePickerField(
                                label: "Ngày sinh",
                                controller: _dobCtrl,
                                hint: "Chọn ngày",
                                onTap: _pickDateOfBirth,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ProductDatePickerField(
                                label: "Ngày vào làm",
                                controller: _joinDateCtrl,
                                hint: "Chọn ngày",
                                onTap: _pickJoinDate,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ProductTextField(
                          label: "Địa chỉ thường trú",
                          controller: _addressCtrl,
                          hint: "VD: 123 Lê Lợi, Q.1, HCM",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SectionTitle(title: "2. Tài khoản & Phân quyền"),
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductTextField(
                          label: "Email cấp phát",
                          controller: _emailCtrl,
                          hint: "VD: nva@dkpl.vn",
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        ProductTextField(
                          label: "Mật khẩu tạm thời",
                          controller: _passwordCtrl,
                          hint: "Sẽ cấp cho nhân viên để login",
                        ),
                        const SizedBox(height: 16),
                        ProductDropdown(
                          label: "Chức vụ (Role)",
                          value: _selectedRoleLabel,
                          items: _rolesMap.keys.toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedRoleLabel = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  DKPLButton(text: "TẠO TÀI KHOẢN NHÂN VIÊN", onPressed: _handleCreateStaff),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

