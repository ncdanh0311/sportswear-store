// File: lib/screens/orders/order_confirmation_screen.dart (hoặc đường dẫn tương ứng)
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../core/constants/app_colors.dart'; // Đổi đường dẫn nếu cần
import '../../core/user_session.dart'; // Import để lấy thông tin Khách hàng thật

class VoucherModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final double discount;
  final double minOrder;
  final String type;
  VoucherModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discount,
    required this.minOrder,
    required this.type,
  });
}

class OrderConfirmationScreen extends StatefulWidget {
  final ProductModel product;
  final int quantity;
  const OrderConfirmationScreen({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String selectedShipping = 'standard';
  VoucherModel? selectedVoucher;

  final List<Map<String, dynamic>> shippingOptions = [
    {
      'id': 'standard',
      'name': 'Giao hàng tiêu chuẩn',
      'time': '3-5 ngày',
      'price': 2.99,
      'icon': Icons.local_shipping,
    },
    {
      'id': 'express',
      'name': 'Giao hàng nhanh',
      'time': '1-2 ngày',
      'price': 5.99,
      'icon': Icons.electric_bolt,
    },
    {
      'id': 'instant',
      'name': 'Giao hàng hỏa tốc',
      'time': 'Trong ngày',
      'price': 9.99,
      'icon': Icons.rocket_launch,
    },
  ];

  final List<VoucherModel> availableVouchers = [
    VoucherModel(
      id: '1',
      code: 'NEWUSER10',
      title: 'Giảm 10% cho đơn hàng đầu',
      description: 'Áp dụng cho đơn hàng từ \$50',
      discount: 10,
      minOrder: 50,
      type: 'percent',
    ),
    VoucherModel(
      id: '2',
      code: 'FREESHIP',
      title: 'Miễn phí vận chuyển',
      description: 'Áp dụng cho đơn hàng từ \$30',
      discount: 0,
      minOrder: 30,
      type: 'shipping',
    ),
    VoucherModel(
      id: '3',
      code: 'SAVE5',
      title: 'Giảm \$5',
      description: 'Áp dụng cho đơn hàng từ \$25',
      discount: 5,
      minOrder: 25,
      type: 'fixed',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // LẤY DỮ LIỆU THẬT TỪ USER SESSION ĐỂ TỰ ĐỘNG ĐIỀN
    final session = UserSession();
    nameController.text = session.fullName ?? "Khách hàng mới";
    phoneController.text = session.phone ?? "";
    addressController.text = session.address ?? "";
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    noteController.dispose();
    super.dispose();
  }

  double get subtotal => widget.product.price * widget.quantity;
  double get shippingFee {
    if (selectedVoucher?.type == 'shipping') return 0;
    return shippingOptions.firstWhere(
      (s) => s['id'] == selectedShipping,
    )['price'];
  }

  double get voucherDiscount {
    if (selectedVoucher == null) return 0;
    if (selectedVoucher!.type == 'percent')
      return subtotal * selectedVoucher!.discount / 100;
    if (selectedVoucher!.type == 'fixed') return selectedVoucher!.discount;
    return 0;
  }

  double get total => subtotal + shippingFee - voucherDiscount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue, // Đã sửa
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Xác nhận đặt hàng',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProductSummary(),
            const SizedBox(height: 12),
            _buildShippingAddress(),
            const SizedBox(height: 12),
            _buildShippingOptions(),
            const SizedBox(height: 12),
            _buildVoucherSection(),
            const SizedBox(height: 12),
            _buildNoteSection(),
            const SizedBox(height: 12),
            _buildPriceSummary(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.product.images.first,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.product.weight,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${widget.product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ), // Đã sửa
                    Text(
                      'x${widget.quantity}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: AppColors.primaryBlue,
                size: 22,
              ), // Đã sửa
              const SizedBox(width: 8),
              const Text(
                'Địa chỉ nhận hàng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Số điện thoại',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: addressController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Địa chỉ chi tiết',
              prefixIcon: const Icon(Icons.home_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping,
                color: AppColors.primaryBlue,
                size: 22,
              ), // Đã sửa
              const SizedBox(width: 8),
              const Text(
                'Phương thức vận chuyển',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...shippingOptions.map((option) {
            final isSelected = selectedShipping == option['id'];
            return GestureDetector(
              onTap: () => setState(() => selectedShipping = option['id']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ), // Đã sửa
                  color: isSelected
                      ? AppColors.primaryBlue.withOpacity(.05)
                      : Colors.transparent, // Đã sửa
                ),
                child: Row(
                  children: [
                    Icon(
                      option['icon'],
                      color: isSelected
                          ? AppColors.primaryBlue
                          : Colors.grey.shade600,
                      size: 28,
                    ), // Đã sửa
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : Colors.black87,
                            ),
                          ), // Đã sửa
                          const SizedBox(height: 2),
                          Text(
                            option['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${option['price'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? AppColors.primaryBlue
                            : Colors.black87,
                        fontSize: 15,
                      ),
                    ), // Đã sửa
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVoucherSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.discount,
                color: AppColors.primaryBlue,
                size: 22,
              ), // Đã sửa
              const SizedBox(width: 8),
              const Text(
                'Mã giảm giá',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              if (selectedVoucher != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() => selectedVoucher = null),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (selectedVoucher != null)
            _buildSelectedVoucher()
          else
            _buildVoucherSelector(),
        ],
      ),
    );
  }

  Widget _buildSelectedVoucher() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(.1),
            AppColors.primaryBlue.withOpacity(.05),
          ],
        ), // Đã sửa
        border: Border.all(color: AppColors.primaryBlue, width: 1), // Đã sửa
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(6),
            ), // Đã sửa
            child: Text(
              selectedVoucher!.code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedVoucher!.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Giảm ${selectedVoucher!.type == 'percent' ? '${selectedVoucher!.discount}%' : '\$${selectedVoucher!.discount}'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: AppColors.primaryBlue,
          ), // Đã sửa
        ],
      ),
    );
  }

  Widget _buildVoucherSelector() {
    return GestureDetector(
      onTap: _showVoucherBottomSheet,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              'Chọn hoặc nhập mã giảm giá',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note_alt_outlined,
                color: AppColors.primaryBlue,
                size: 22,
              ), // Đã sửa
              const SizedBox(width: 8),
              const Text(
                'Ghi chú đơn hàng',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú cho đơn hàng (không bắt buộc)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _buildPriceRow('Tạm tính', '\$${subtotal.toStringAsFixed(2)}', false),
          const SizedBox(height: 12),
          _buildPriceRow(
            'Phí vận chuyển',
            selectedVoucher?.type == 'shipping'
                ? 'Miễn phí'
                : '\$${shippingFee.toStringAsFixed(2)}',
            false,
            strikethrough: selectedVoucher?.type == 'shipping',
          ),
          const SizedBox(height: 12),
          if (voucherDiscount > 0)
            _buildPriceRow(
              'Giảm giá',
              '-\$${voucherDiscount.toStringAsFixed(2)}',
              false,
              isDiscount: true,
            ),
          if (voucherDiscount > 0) const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _buildPriceRow('Tổng cộng', '\$${total.toStringAsFixed(2)}', true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    bool isBold, {
    bool isDiscount = false,
    bool strikethrough = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isDiscount
                ? Colors.red
                : isBold
                ? AppColors.primaryBlue
                : Colors.black87,
            decoration: strikethrough ? TextDecoration.lineThrough : null,
          ),
        ), // Đã sửa
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng thanh toán:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ), // Đã sửa
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _handlePlaceOrder,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryBlue],
                  ), // Đã sửa
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ], // Đã sửa
                ),
                child: const Center(
                  child: Text(
                    'Đặt hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoucherBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Chọn mã giảm giá',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availableVouchers.length,
                  itemBuilder: (context, index) {
                    final voucher = availableVouchers[index];
                    final canUse = subtotal >= voucher.minOrder;
                    return GestureDetector(
                      onTap: canUse
                          ? () {
                              setState(() => selectedVoucher = voucher);
                              Navigator.pop(context);
                            }
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: canUse
                                ? AppColors.primaryBlue.withOpacity(.3)
                                : Colors.grey.shade300,
                          ),
                          color: canUse ? Colors.white : Colors.grey.shade50,
                        ), // Đã sửa
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: canUse
                                    ? AppColors.primaryBlue.withOpacity(.1)
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ), // Đã sửa
                              child: Icon(
                                Icons.confirmation_number,
                                color: canUse
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade400,
                              ), // Đã sửa
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    voucher.code,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: canUse
                                          ? AppColors.primaryBlue
                                          : Colors.grey.shade500,
                                    ),
                                  ), // Đã sửa
                                  const SizedBox(height: 4),
                                  Text(
                                    voucher.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: canUse
                                          ? Colors.black87
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    voucher.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!canUse)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Không đủ ĐK',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handlePlaceOrder() {
    if (nameController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập họ tên');
      return;
    }
    if (phoneController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập số điện thoại');
      return;
    }
    if (addressController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập địa chỉ');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ), // Đã sửa
              const SizedBox(height: 16),
              const Text(
                'Đặt hàng thành công!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Đơn hàng của bạn đang được xử lý',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ), // Đã sửa
                  child: const Text(
                    'Về trang chủ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
