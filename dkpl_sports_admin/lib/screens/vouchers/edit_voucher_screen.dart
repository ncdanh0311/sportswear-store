import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditVoucherScreen extends StatefulWidget {
  final String voucherID;
  const EditVoucherScreen({super.key, required this.voucherID});

  @override
  State<EditVoucherScreen> createState() => _EditVoucherScreenState();
}

class _EditVoucherScreenState extends State<EditVoucherScreen> {
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // Tải dữ liệu Voucher cũ lên Form
  Future<void> _initData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('vouchers')
          .doc(widget.voucherID)
          .get();
      if (mounted && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        setState(() {
          _codeCtrl.text = data['code'] ?? '';
          _nameCtrl.text = data['name'] ?? '';

          _discountType = data['discount_type'] == 'percent' ? '%' : 'VNĐ';

          double dValue = (data['discount_value'] ?? 0).toDouble();
          _discountValueCtrl.text = _discountType == '%'
              ? dValue.toString()
              : dValue.toInt().toString();

          _minOrderCtrl.text = (data['min_order'] ?? 0).toInt().toString();

          if (_discountType == '%') {
            _maxDiscountCtrl.text = (data['max_discount'] ?? 0).toInt().toString();
          }

          _usageLimitCtrl.text = (data['usage_limit'] ?? 0).toString();

          Timestamp? startTs = data['start_date'];
          Timestamp? endTs = data['end_date'];
          if (startTs != null) {
            _startDate = startTs.toDate();
            _startDateCtrl.text = DateFormat('dd/MM/yyyy').format(_startDate!);
          }
          if (endTs != null) {
            _endDate = endTs.toDate();
            _endDateCtrl.text = DateFormat('dd/MM/yyyy').format(_endDate!);
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải data edit voucher: $e");
      setState(() => _isLoading = false);
    }
  }

  // Hàm chọn ngày tháng
  Future<void> _pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? (_startDate ?? DateTime.now())),
      firstDate: DateTime(2020), // Cho phép chọn lùi về quá khứ vì có thể voucher tạo từ lâu
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
  Future<void> _handleUpdateVoucher() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Tên chương trình!")));
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

    setState(() => _isLoading = true);

    try {
      // Đóng gói dữ liệu cập nhật (Không gửi trường 'code' lên vì không cho phép sửa)
      Map<String, dynamic> updateData = {
        'name': _nameCtrl.text.trim(),
        'discount_type': _discountType == '%' ? 'percent' : 'fixed',
        'discount_value': double.tryParse(_discountValueCtrl.text.trim()) ?? 0,
        'min_order': double.tryParse(_minOrderCtrl.text.trim()) ?? 0,
        'max_discount': _discountType == '%'
            ? (double.tryParse(_maxDiscountCtrl.text.trim()) ?? 0)
            : 0,
        'usage_limit': int.tryParse(_usageLimitCtrl.text.trim()) ?? 0,
        'start_date': Timestamp.fromDate(_startDate!),
        'end_date': Timestamp.fromDate(_endDate!),
      };

      await _productService.updateVoucher(widget.voucherID, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cập nhật Voucher thành công!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("Lỗi cập nhật Voucher: $e");
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
      appBar: AppBar(title: const Text("Sửa Voucher")),
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
                        // Mã Voucher bị khóa mờ (AbsorbPointer)
                        AbsorbPointer(
                          child: Opacity(
                            opacity: 0.6,
                            child: ProductTextField(
                              label: "Mã Voucher (Code) - Không thể sửa",
                              controller: _codeCtrl,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ProductTextField(label: "Tên chương trình", controller: _nameCtrl),
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
                        if (_discountType == '%') ...[
                          const SizedBox(height: 12),
                          ProductTextField(
                            label: "Mức giảm tối đa (VNĐ)",
                            controller: _maxDiscountCtrl,
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
                          label: "Tổng lượt sử dụng (Có thể tăng thêm)",
                          controller: _usageLimitCtrl,
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
                  DKPLButton(text: "Lưu thay đổi", onPressed: _handleUpdateVoucher),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

