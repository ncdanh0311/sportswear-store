import 'package:flutter/material.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';

class AddVoucherScreen extends StatefulWidget {
  const AddVoucherScreen({super.key});

  @override
  State<AddVoucherScreen> createState() => _AddVoucherScreenState();
}

class _AddVoucherScreenState extends State<AddVoucherScreen> {
  final _codeCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _maxDiscountCtrl = TextEditingController();
  final _usageLimitCtrl = TextEditingController(text: '1');

  final ProductService _productService = ProductService();
  bool _isLoading = false;

  Future<void> _handleSave() async {
    if (_codeCtrl.text.isEmpty || _discountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'code': _codeCtrl.text.trim(),
      'discount': double.tryParse(_discountCtrl.text) ?? 0,
      'minOrder': double.tryParse(_minOrderCtrl.text) ?? 0,
      'maxDiscount': double.tryParse(_maxDiscountCtrl.text) ?? 0,
      'usageLimit': int.tryParse(_usageLimitCtrl.text) ?? 1,
      'usedCount': 0,
      'isActive': true,
    };

    await _productService.addVoucher(data);

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: const Text("Thêm Voucher"),
        backgroundColor: Colors.transparent,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductTextField(label: "Mã Voucher", controller: _codeCtrl),
                        const SizedBox(height: 12),
                        ProductTextField(
                          label: "Giảm giá",
                          controller: _discountCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        ProductTextField(
                          label: "Đơn tối thiểu",
                          controller: _minOrderCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        ProductTextField(
                          label: "Giảm tối đa",
                          controller: _maxDiscountCtrl,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        ProductTextField(
                          label: "Số lượt sử dụng",
                          controller: _usageLimitCtrl,
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  DKPLButton(text: "Lưu Voucher", onPressed: _handleSave),
                ],
              ),
            ),
    );
  }
}
