import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart'; // Dùng TextField & Dropdown chuẩn
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'edit_product_screen.dart';

class ManageVariantsScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ManageVariantsScreen({Key? key, required this.productId, required this.productName})
    : super(key: key);

  @override
  State<ManageVariantsScreen> createState() => _ManageVariantsScreenState();
}

class _ManageVariantsScreenState extends State<ManageVariantsScreen> {
  final ProductService _productService = ProductService();

  List<String> _materials = [];
  int _currentImageIndex = 0;

  String _formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    final data = await _productService.fetchAppConfig();
    if (mounted) {
      setState(() {
        _materials = List<String>.from(data['materials'] ?? []);
      });
    }
  }

  // --- LOGIC DIALOG (Add & Edit gộp chung logic hiển thị) ---
  void _showVariantDialog({String? variantId, Map<String, dynamic>? currentData}) {
    // 1. KHỞI TẠO CONTROLLER
    final sizeCtrl = TextEditingController(text: currentData?['size']);
    final materialCtrl = TextEditingController(
      text: currentData?['material'],
    ); // Nếu dùng text field

    // Giá gốc (Original Price)
    final originalPriceCtrl = TextEditingController(
      text: currentData != null ? currentData['original_price'].toString() : '',
    );

    // Tồn kho
    final stockCtrl = TextEditingController(
      text: currentData != null ? currentData['stock'].toString() : '0',
    );

    // --- MỚI: Controller cho Giảm giá ---
    // Mặc định là 0 nếu chưa có
    final saleCtrl = TextEditingController(
      text: currentData != null ? currentData['sale_price'].toString() : '0',
    );

    String? selectedMaterial = currentData?['material'];
    bool isEdit = variantId != null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.primaryNavy,
              title: Text(
                isEdit ? "Cập nhật biến thể" : "Thêm biến thể",
                style: const TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Size
                    ProductTextField(label: "Size", controller: sizeCtrl, hint: "S, M, L..."),
                    const SizedBox(height: 12),

                    // 2. Chất liệu
                    ProductDropdown(
                      label: "Chất liệu",
                      value: selectedMaterial,
                      items: _materials,
                      onChanged: (v) => setStateDialog(() => selectedMaterial = v),
                    ),
                    const SizedBox(height: 12),

                    // 3. Giá Gốc (Original Price)
                    ProductTextField(
                      label: "Giá Gốc (Chưa giảm)",
                      controller: originalPriceCtrl,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // --- 4. MỚI: Ô NHẬP GIẢM GIÁ ---
                    ProductTextField(
                      label: "Giảm giá (VD: 0.2 là 20%)",
                      controller: saleCtrl,
                      keyboardType: TextInputType.number,
                      hint: "Nhập 0.1, 0.2...",
                    ),

                    // 5. Tồn kho (Chỉ hiện khi Edit)
                    if (isEdit) ...[
                      const SizedBox(height: 12),
                      ProductTextField(
                        label: "Tồn kho",
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validate cơ bản
                    if (sizeCtrl.text.isEmpty || originalPriceCtrl.text.isEmpty) return;

                    final data = {
                      "size": sizeCtrl.text.toUpperCase(),
                      "material": selectedMaterial ?? "Khác",
                      "stock": int.tryParse(stockCtrl.text) ?? 0,

                      // Gửi Giá gốc & Tỉ lệ giảm cho Service tính toán
                      "original_price": double.tryParse(originalPriceCtrl.text) ?? 0,
                      "sale_price": double.tryParse(saleCtrl.text) ?? 0,
                    };

                    // Gọi Service
                    if (isEdit) {
                      await _productService.updateVariant(widget.productId, variantId!, data);
                    } else {
                      await _productService.addVariant(widget.productId, data);
                    }

                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(isEdit ? "Đã cập nhật!" : "Đã thêm!")));
                    }
                  },
                  child: const Text(
                    "Lưu",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: const Text('Chi tiết & Biến thể', style: AppStyles.h2),
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditProductScreen(productID: widget.productId)),
            ),
            icon: const Icon(Icons.edit_document, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showVariantDialog(),
        backgroundColor: AppColors.accentCyan,
        label: const Text(
          "Thêm Biến Thể",
          style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: AppColors.primaryNavy),
      ),

      // 1. Stream lấy Product (Để hiển thị ảnh)
      child: StreamBuilder<DocumentSnapshot>(
        stream: _productService.getProductStream(widget.productId),
        builder: (context, productSnapshot) {
          if (!productSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!productSnapshot.data!.exists)
            return const Center(child: Text("Sản phẩm không tồn tại"));

          final productData = productSnapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> images = productData['images'] ?? [];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CAROUSEL ẢNH ---
                if (images.isNotEmpty) ...[
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) => setState(() => _currentImageIndex = index),
                      itemBuilder: (ctx, index) => Image.network(images[index], fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == index
                              ? AppColors.accentCyan
                              : Colors.white24,
                        ),
                      ),
                    ),
                  ),
                ],

                // --- INFO ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.productName, style: AppStyles.h2.copyWith(fontSize: 22)),
                      const SizedBox(height: 8),
                      Text(
                        productData['description'] ?? "Chưa có mô tả",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(label: Text(productData['category_id'] ?? '')),
                          Chip(label: Text(productData['brand'] ?? '')),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 30),
                      const SectionTitle(title: "Danh sách biến thể"),
                    ],
                  ),
                ),

                // --- VARIANTS LIST ---
                StreamBuilder<QuerySnapshot>(
                  stream: _productService.getVariantsStream(widget.productId),
                  builder: (context, variantSnapshot) {
                    if (!variantSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final variants = variantSnapshot.data!.docs;

                    if (variants.isEmpty)
                      return const Center(
                        child: Text("Chưa có biến thể", style: TextStyle(color: Colors.white54)),
                      );

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: variants.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final vData = variants[index].data() as Map<String, dynamic>;
                        final vId = variants[index].id;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.white.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  vData['size'] ?? '?',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentCyan,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      vData['material'] ?? '?',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      "Kho: ${vData['stock'] ?? 0}",
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _formatPrice(vData['price'] ?? 0),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accentCyan,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                                onPressed: () =>
                                    _showVariantDialog(variantId: vId, currentData: vData),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                                onPressed: () =>
                                    _productService.deleteVariant(widget.productId, vId),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

