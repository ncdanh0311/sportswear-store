import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';
import 'package:dkpl_sports_admin/models/product_model.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';

import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'manage_variants_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  String get _role => AuthService.instance.currentUser?.roleId ?? '';
  bool get _canManageProducts => RolePermissions.canManageProducts(_role);
  bool get _canManageVariants => RolePermissions.canManageVariants(_role);

  String _formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  Future<void> _confirmDeleteProduct(ProductModel model) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "${model.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _productService.deleteProduct(model.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa sản phẩm thành công.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Xóa thất bại: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: Text(
          _canManageProducts ? 'Quản Lý Sản Phẩm' : 'Sản phẩm & Biến thể',
          style: AppStyles.h2,
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _productService.getProductsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Chưa có sản phẩm", style: TextStyle(color: Colors.white54)),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final model = ProductModel.fromJson(data, docs[index].id);
              return _buildProductItem(model);
            },
          );
        },
      ),
      floatingActionButton: _canManageProducts
          ? FloatingActionButton(
              heroTag: "btn_add_product",
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddProductScreen()),
              ),
              backgroundColor: AppColors.accentCyan,
              child: const Icon(Icons.add, color: AppColors.primaryNavy, size: 28),
            )
          : null,
    );
  }

  Widget _buildProductItem(ProductModel model) {
    String name = model.name;
    String thumbnail = model.thumbnail;
    double min = model.minPrice;
    double max = model.maxPrice;
    bool isActive = model.isActive;
    String priceStr = (min == max)
        ? _formatPrice(min)
        : "${_formatPrice(min)} - ${_formatPrice(max)}";

    return DKPLCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white10,
              image: thumbnail.isNotEmpty
                  ? DecorationImage(image: NetworkImage(thumbnail), fit: BoxFit.cover)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppStyles.h2.copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  priceStr,
                  style: AppStyles.body.copyWith(
                    color: AppColors.accentCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: ${model.categoryId}',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Switch(
                value: isActive,
                activeColor: AppColors.accentCyan,
                onChanged: _canManageProducts
                    ? (val) => _productService.updateProduct(model.id, {'isActive': val})
                    : null,
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 20,
                      color: _canManageVariants ? Colors.white : Colors.white24,
                    ),
                    onPressed: _canManageVariants
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ManageVariantsScreen(productId: model.id, productName: name),
                            ),
                          )
                        : null,
                  ),
                  if (_canManageProducts)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditProductScreen(productID: model.id)),
                      ),
                    ),
                  if (_canManageProducts)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      onPressed: () => _confirmDeleteProduct(model),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
