import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddVoucherScreen extends StatefulWidget {
  const AddVoucherScreen({super.key});

  @override
  State<AddVoucherScreen> createState() => _AddVoucherScreenState();
}

class _AddVoucherScreenState extends State<AddVoucherScreen> {
  final ProductService _productService = ProductService();

  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _discountValueCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _maxDiscountCtrl = TextEditingController();
  final _usageLimitCtrl = TextEditingController();

  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  String _discountType = '%';
  bool _isLoading = false;

  // Hàm chọn ngày tháng
  Future<void> _pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? (_startDate ?? DateTime.now())),
      firstDate: DateTime.now(), // Không cho chọn ngày đã qua
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        String formattedDate =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";

        if (isStart) {
          _startDate = picked;
          _startDateCtrl.text = formattedDate;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            _endDateCtrl.clear();
          }
        } else {
          if (_startDate != null && picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Ngày kết thúc phải sau ngày bắt đầu!")));
            return;
          }
          _endDate = picked;
          _endDateCtrl.text = formattedDate;
        }
      });
    }
  }

  // Hàm xử lý lưu Voucher
  Future<void> _handleCreateVoucher() async {
    // 1. Tiền xử lý Mã Code (Viết hoa, xóa khoảng trắng thừa)
    String code = _codeCtrl.text.trim().replaceAll(" ", "").toUpperCase();

    // 2. Kiểm tra điều kiện đầu vào
    if (code.isEmpty || _nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Mã và Tên chương trình!")));
      return;
    }
    if (_discountValueCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập mức giảm giá!")));
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn thời gian áp dụng!")));
      return;
    }

    // 3. Bật Loading
    setState(() => _isLoading = true);

    try {
      // 4. Gom dữ liệu
      Map<String, dynamic> voucherData = {
        'code': code,
        'name': _nameCtrl.text.trim(),
        'discount_type': _discountType == '%' ? 'percent' : 'fixed',
        'discount_value': double.tryParse(_discountValueCtrl.text.trim()) ?? 0,
        'min_order': double.tryParse(_minOrderCtrl.text.trim()) ?? 0,
        // Nếu là giảm % thì lấy maxDiscount, nếu là VNĐ thì gán bằng 0
        'max_discount': _discountType == '%'
            ? (double.tryParse(_maxDiscountCtrl.text.trim()) ?? 0)
            : 0,
        'usage_limit': int.tryParse(_usageLimitCtrl.text.trim()) ?? 0,
        'used_count': 0, // Voucher mới tạo chưa ai dùng
        'start_date': Timestamp.fromDate(_startDate!),
        'end_date': Timestamp.fromDate(_endDate!),
        'is_active': true, // Mặc định tạo xong là BẬT luôn
      };

      // 5. Lưu lên Firebase
      await _productService.addVoucher(voucherData);

      // 6. Thông báo và thoát
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tạo Voucher thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Lỗi tạo Voucher: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(title: const Text("Thêm Voucher Mới")),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SectionTitle(title: "1. Thông tin cơ bản"),
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductTextField(
                          label: "Mã Voucher (Code)",
                          controller: _codeCtrl,
                          hint: "VD: TET2026 (Viết liền, không dấu)",
                        ),
                        const SizedBox(height: 12),
                        ProductTextField(
                          label: "Tên chương trình",
                          controller: _nameCtrl,
                          hint: "VD: Khuyến mãi Tết Nguyên Đán",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle(title: "2. Thiết lập giảm giá"),
                  DKPLCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ProductTextField(
                                label: "Mức giảm",
                                controller: _discountValueCtrl,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ProductDropdown(
                                label: "Loại giảm",
                                value: _discountType,
                                items: const ['%', 'VNĐ'],
                                onChanged: (v) {
                                  setState(() {
                                    _discountType = v!;
                                    // Xóa dữ liệu Giảm tối đa nếu đổi sang loại VNĐ
                                    if (_discountType == 'VNĐ') _maxDiscountCtrl.clear();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ProductTextField(
                          label: "Đơn hàng tối thiểu (VNĐ)",
                          controller: _minOrderCtrl,
                          keyboardType: TextInputType.number,
                        ),

                        // Khối Ẩn/Hiện: Chỉ hiện "Giảm tối đa" nếu chọn loại %
                        if (_discountType == '%') ...[
                          const SizedBox(height: 12),
                          ProductTextField(
                            label: "Mức giảm tối đa (VNĐ)",
                            controller: _maxDiscountCtrl,
                            hint: "VD: 50000",
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle(title: "3. Giới hạn & Thời gian"),
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductTextField(
                          label: "Tổng lượt sử dụng",
                          controller: _usageLimitCtrl,
                          hint: "VD: 100",
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ProductDatePickerField(
                                label: "Từ ngày:",
                                controller: _startDateCtrl,
                                hint: "Bắt đầu",
                                onTap: () => _pickDate(true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ProductDatePickerField(
                                label: "Đến ngày",
                                controller: _endDateCtrl,
                                hint: "Kết thúc",
                                onTap: () => _pickDate(false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  DKPLButton(text: "Tạo Voucher", onPressed: _handleCreateVoucher),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

