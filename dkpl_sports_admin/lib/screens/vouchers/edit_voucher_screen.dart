import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';

class EditVoucherScreen extends StatefulWidget {
  final String voucherID;
  const EditVoucherScreen({super.key, required this.voucherID});

  @override
  State<EditVoucherScreen> createState() => _EditVoucherScreenState();
}

class _EditVoucherScreenState extends State<EditVoucherScreen> {
  final _codeCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _maxDiscountCtrl = TextEditingController();
  final _usageLimitCtrl = TextEditingController();

  final ProductService _productService = ProductService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVoucher();
  }

  Future<void> _loadVoucher() async {
    final doc = await FirebaseFirestore.instance.collection('vouchers').doc(widget.voucherID).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _codeCtrl.text = (data['code'] ?? '').toString();
      _discountCtrl.text = (data['discount'] ?? 0).toString();
      _minOrderCtrl.text = (data['minOrder'] ?? 0).toString();
      _maxDiscountCtrl.text = (data['maxDiscount'] ?? 0).toString();
      _usageLimitCtrl.text = (data['usageLimit'] ?? 1).toString();
      _isLoading = false;
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    final data = {
      'code': _codeCtrl.text.trim(),
      'discount': double.tryParse(_discountCtrl.text) ?? 0,
      'minOrder': double.tryParse(_minOrderCtrl.text) ?? 0,
      'maxDiscount': double.tryParse(_maxDiscountCtrl.text) ?? 0,
      'usageLimit': int.tryParse(_usageLimitCtrl.text) ?? 1,
    };

    await _productService.updateVoucher(widget.voucherID, data);

    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: const Text("Sửa Voucher"),
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
                  DKPLButton(text: "Lưu thay đổi", onPressed: _handleSave),
                ],
              ),
            ),
    );
  }
}
