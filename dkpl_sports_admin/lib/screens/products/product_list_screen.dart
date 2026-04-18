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
  
  // --- PHÂN QUYỀN (RBAC) ---
  // Lấy role hiện tại của user
  String get _role => AuthService.instance.currentUser?.roleId ?? '';
  // Kiểm tra quyền Quản lý Sản phẩm (Thêm, Sửa, Xóa SP gốc)
  bool get _canManageProducts => RolePermissions.canManageProducts(_role);
  // Kiểm tra quyền Quản lý Biến thể (Xem, thêm, sửa biến thể)
  bool get _canManageVariants => RolePermissions.canManageVariants(_role);

  // Hàm format tiền tệ VNĐ
  String _formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  /// Hiển thị hộp thoại xác nhận trước khi xóa sản phẩm
  Future<void> _confirmDeleteProduct(ProductModel model) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa sản phẩm'),
        content: Text('Bạn có chắc muốn xóa "${model.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Trả về false nếu bấm Hủy
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),  // Trả về true nếu bấm Xóa
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    // Nếu user đóng dialog hoặc bấm Hủy thì dừng hàm
    if (shouldDelete != true) return;

    try {
      // Gọi service xóa sản phẩm (đã bao gồm cascade delete: xóa cả biến thể và kho)
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
        // Tiêu đề thay đổi tùy theo quyền của user
        title: Text(
          _canManageProducts ? 'Quản Lý Sản Phẩm' : 'Sản phẩm & Biến thể',
          style: AppStyles.h2,
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {}, // TODO: Tính năng tìm kiếm sẽ phát triển sau
          ),
        ],
      ),
      
      // STREAM BUILDER: Lắng nghe danh sách sản phẩm realtime từ Firestore
      child: StreamBuilder<QuerySnapshot>(
        stream: _productService.getProductsStream(),
        builder: (context, snapshot) {
          // Trạng thái đang tải
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }
          // Trạng thái trống (không có sản phẩm nào)
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Chưa có sản phẩm", style: TextStyle(color: Colors.white54)),
            );
          }

          final docs = snapshot.data!.docs;

          // Render danh sách sản phẩm
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // Parse JSON thành ProductModel để dễ truy xuất thuộc tính
              final model = ProductModel.fromJson(data, docs[index].id);
              return _buildProductItem(model);
            },
          );
        },
      ),
      
      // Nút Thêm sản phẩm (Dấu +) góc dưới màn hình. 
      // Chỉ hiển thị nếu user có quyền _canManageProducts
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
          : null, // Trả về null sẽ ẩn hoàn toàn nút FAB
    );
  }

  /// Hàm build ra UI của 1 thẻ sản phẩm trong danh sách
  Widget _buildProductItem(ProductModel model) {
    String name = model.name;
    String thumbnail = model.thumbnail;
    double min = model.minPrice;
    double max = model.maxPrice;
    bool isActive = model.isActive;
    
    // Xử lý chuỗi hiển thị giá. 
    // Nếu min == max (chỉ có 1 giá hoặc chưa có biến thể) thì hiện 1 số.
    // Ngược lại hiện khoảng giá (VD: 100k - 200k)
    String priceStr = (min == max)
        ? _formatPrice(min)
        : "${_formatPrice(min)} - ${_formatPrice(max)}";

    return DKPLCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // --- CỘT 1: ẢNH THUMBNAIL ---
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white10, // Màu nền dự phòng nếu không có ảnh
              image: thumbnail.isNotEmpty
                  ? DecorationImage(image: NetworkImage(thumbnail), fit: BoxFit.cover)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          
          // --- CỘT 2: THÔNG TIN CƠ BẢN ---
          Expanded( // Expanded để đẩy khối Actions sang mép phải
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppStyles.h2.copyWith(fontSize: 16),
                  maxLines: 2, // Tối đa 2 dòng, dài quá thì hiển thị dấu ...
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
          
          // --- CỘT 3: CÁC NÚT TƯƠNG TÁC (ACTIONS) ---
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Nút Tắt/Mở trạng thái bán của sản phẩm
              Switch(
                value: isActive,
                activeColor: AppColors.accentCyan,
                // Nếu ko có quyền quản lý, disable switch (truyền null vào onChanged)
                onChanged: _canManageProducts
                    ? (val) async {
                        // LOGIC NGHIỆP VỤ: Không cho phép ngừng bán (val == false) nếu vẫn còn hàng trong kho
                        if (!val) {
                          // Gọi API kiểm tra tổng tồn kho của toàn bộ biến thể
                          final totalStock = await _productService.getTotalStockForProduct(model.id);
                          if (!mounted) return;
                          
                          if (totalStock > 0) {
                            // Chặn lại và báo lỗi
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Không thể ngừng bán khi sản phẩm còn tồn kho.'),
                              ),
                            );
                            return; // Thoát hàm, không update DB
                          }
                        }
                        // Nếu qua được đoạn check trên thì update DB
                        await _productService.updateProduct(model.id, {'isActive': val});
                      }
                    : null,
              ),
              
              // Dãy nút Icon (Xem, Sửa, Xóa)
              Row(
                children: [
                  // Nút Xem/Quản lý Biến thể (Con mắt)
                  IconButton(
                    icon: Icon(
                      Icons.visibility_outlined,
                      size: 20,
                      color: _canManageVariants ? Colors.white : Colors.white24, // Làm mờ nếu ko có quyền
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
                  
                  // Nút Sửa Sản Phẩm (Chỉ hiện nếu có quyền _canManageProducts)
                  if (_canManageProducts)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditProductScreen(productID: model.id)),
                      ),
                    ),
                    
                  // Nút Xóa Sản Phẩm (Chỉ hiện nếu có quyền _canManageProducts)
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