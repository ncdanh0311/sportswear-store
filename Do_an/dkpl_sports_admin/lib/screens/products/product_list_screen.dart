import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:dkpl_sports_admin/models/product_model.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';

import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'manage_variants_screen.dart';

// =========================================================================
// MÀN HÌNH DANH SÁCH SẢN PHẨM CHÍNH TỪ FIREBASE
// =========================================================================
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();

  String _formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: const Text('Quản Lý Sản Phẩm', style: AppStyles.h2),
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
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_add_product",
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductScreen()),
        ),
        backgroundColor: AppColors.accentCyan,
        child: const Icon(Icons.add, color: AppColors.primaryNavy, size: 28),
      ),
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
                  '${model.categoryId} • ${model.variantsCount} biến thể',
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
                onChanged: (val) => _productService.updateProduct(model.id, {'is_active': val}),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined, size: 20, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManageVariantsScreen(productId: model.id, productName: name),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProductScreen(productID: model.id)),
                    ),
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

