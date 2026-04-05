import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/voucher_model.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Import các màn hình liên quan
import 'add_voucher_screen.dart';
import 'detail_voucher_screen.dart';
import 'edit_voucher_screen.dart';

class VoucherListScreen extends StatefulWidget {
  const VoucherListScreen({super.key});

  @override
  State<VoucherListScreen> createState() => _VoucherListScreenState();
}

class _VoucherListScreenState extends State<VoucherListScreen> {
  final ProductService _productService = ProductService();
  bool get _canManageVouchers =>
      RolePermissions.canManageVouchers(AuthService.instance.currentUser?.role);

  // Hàm fomat tiền cho đẹp
  String _formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManageVouchers) {
      return BaseBackground(
        appBar: AppBar(
          title: const Text("Quản lý Voucher", style: AppStyles.h2),
          backgroundColor: Colors.transparent,
        ),
        child: const Center(
          child: Text(
            'Bạn không có quyền quản lý voucher.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return BaseBackground(
      appBar: AppBar(
        title: const Text("Quản lý Voucher", style: AppStyles.h2),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_add_voucher",
        backgroundColor: AppColors.accentCyan,
        onPressed: () {
          // Chuyển sang màn hình Thêm Voucher
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVoucherScreen()));
        },
        child: const Icon(Icons.add, color: AppColors.primaryNavy, size: 28),
      ),
      // Dùng StreamBuilder để lấy dữ liệu realtime
      child: StreamBuilder<QuerySnapshot>(
        stream: _productService.getVouchersStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Chưa có Voucher nào", style: TextStyle(color: Colors.white54)),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final model = VoucherModel.fromJson(data, docs[index].id);
              return _buildVoucherItem(model);
            },
          );
        },
      ),
    );
  }

  Widget _buildVoucherItem(VoucherModel model) {
    // 1. Bóc tách dữ liệu từ Model
    String code = model.code;
    String type = model.discountType; // 'percent' hoặc 'fixed'
    double discountValue = model.discountValue;
    double minOrder = model.minOrder;
    double maxDiscount = model.maxDiscount;

    int usageLimit = model.usageLimit;
    int usedCount = model.usedCount;
    bool isActive = model.isActive;

    // 2. Format Ngày tháng
    Timestamp? startTs = model.startDate;
    Timestamp? endTs = model.endDate;
    String dateStart = startTs != null ? DateFormat('dd/MM').format(startTs.toDate()) : '...';
    String dateEnd = endTs != null ? DateFormat('dd/MM').format(endTs.toDate()) : '...';

    // 3. Tính toán chuỗi hiển thị mức giảm
    String discountTitle = "";
    if (type == 'percent') {
      discountTitle = "Giảm ${discountValue.toInt()}%";
      if (maxDiscount > 0) {
        discountTitle += " (Tối đa ${_formatPrice(maxDiscount)})";
      }
    } else {
      discountTitle = "Giảm ${_formatPrice(discountValue)}";
    }

    // 4. Tính % thanh Progress
    double progress = usageLimit > 0 ? (usedCount / usageLimit) : 0;
    if (progress > 1.0) progress = 1.0;

    return DKPLCard(
      padding: const EdgeInsets.all(0),
      child: Row(
        children: [
          // Phần cuống vé bên trái (Hiển thị Mã)
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            decoration: BoxDecoration(
              // Nếu hết hạn hoặc hết lượt -> Đổi màu xám xịt cho dễ nhận biết
              color: isActive ? AppColors.primaryBlue.withOpacity(0.3) : Colors.white10,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              border: Border(
                right: BorderSide(
                  color: isActive ? AppColors.accentCyan.withOpacity(0.5) : Colors.white24,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
            ),
            child: Center(
              child: Text(
                code,
                style: TextStyle(
                  color: isActive ? AppColors.accentCyan : Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Phần nội dung bên phải
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discountTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Đơn tối thiểu: ${_formatPrice(minOrder)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // Thanh tiến độ sử dụng
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white10,
                          // Gần hết lượt thì thanh tiến độ đổi màu đỏ/cam
                          color: progress > 0.8 ? Colors.redAccent : AppColors.accentCyan,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "$usedCount/$usageLimit",
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Hành động & Trạng thái
                  Row(
                    children: [
                      // 1. Bọc Expanded để text ngày tháng tự lùi nhường chỗ
                      Expanded(
                        child: Text(
                          "HSD: $dateStart - $dateEnd",
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis, // Nếu chật quá nó sẽ hiện dấu "..."
                        ),
                      ),

                      // 2. Thu nhỏ Switch lại 20% cho gọn
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: isActive,
                          activeColor: AppColors.accentCyan,
                          onChanged: (val) {
                            _productService.updateVoucherStatus(model.id, val);
                          },
                        ),
                      ),

                      // 3. Ép khoảng cách 2 nút Icon lại sát nhau
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailVoucherScreen(voucher: model),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, color: Colors.cyan, size: 20),
                        padding: const EdgeInsets.only(left: 0, right: 8),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditVoucherScreen(voucherID: model.id),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, color: Colors.cyan, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

