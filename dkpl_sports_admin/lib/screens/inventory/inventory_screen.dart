import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart'; // Để dùng ProductTextField
import 'package:dkpl_sports_admin/services/auth_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Collection Products thực tế trên Firebase của bạn
  final CollectionReference _productsRef = FirebaseFirestore.instance.collection('products');
  bool get _canManageInventory =>
      RolePermissions.canManageInventory(AuthService.instance.currentUser?.role);

  @override
  Widget build(BuildContext context) {
    if (!_canManageInventory) {
      return BaseBackground(
        appBar: AppBar(
          title: const Text('Quản Lý Kho Hàng', style: AppStyles.h2),
          backgroundColor: Colors.transparent,
        ),
        child: const Center(
          child: Text(
            'Bạn không có quyền quản lý tồn kho.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return BaseBackground(
      appBar: AppBar(
        title: const Text('Quản Lý Kho Hàng', style: AppStyles.h2),
        backgroundColor: Colors.transparent,
      ),
      // Dùng StreamBuilder để lấy dữ liệu kho Real-time từ Firebase
      child: StreamBuilder<QuerySnapshot>(
        stream: _productsRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }

          final docs = snapshot.data!.docs;

          // Tính toán các chỉ số KPI
          int totalProducts = docs.length;
          int totalStock = 0;
          List<DocumentSnapshot> lowStockDocs = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            int stock = data['stock'] ?? 0; // Đọc trường stock, nếu chưa có mặc định là 0
            totalStock += stock;
            if (stock <= 5) lowStockDocs.add(doc);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── 1. KPI THỐNG KÊ KHO ──
              Row(
                children: [
                  Expanded(child: _buildKpiCard('Tổng SP', totalProducts.toString(), Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard('Tổng tồn', totalStock.toString(), AppColors.accentCyan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      'Sắp hết',
                      lowStockDocs.length.toString(),
                      lowStockDocs.isNotEmpty ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 2. HÀNH ĐỘNG NHANH (Thay vì tạo page mới, ta dùng Modal Bottom Sheet) ──
              DKPLButton(
                text: '📥 Tạo phiếu Nhập kho',
                onPressed: () => _showActionModal(context, isReceipt: true, products: docs),
              ),
              const SizedBox(height: 12),
              DKPLButton(
                text: '📤 Tạo phiếu Xuất kho',
                isSecondary: true,
                onPressed: () => _showActionModal(context, isReceipt: false, products: docs),
              ),
              const SizedBox(height: 12),
              DKPLButton(
                text: '✅ Duyệt phiếu chờ (Demo)',
                onPressed: () => _showApprovalModal(context),
              ),
              const SizedBox(height: 24),

              // ── 3. CẢNH BÁO TỒN KHO ──
              const Text(
                '⚠️ Cảnh báo tồn kho',
                style: TextStyle(
                  color: AppColors.accentCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DKPLCard(
                child: lowStockDocs.isEmpty
                    ? const Text(
                        'Kho đang ổn định, không có sản phẩm nào sắp hết.',
                        style: TextStyle(color: Colors.white70),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: lowStockDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '• ${data['name'] ?? 'Không tên'}',
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  'Tồn: ${data['stock'] ?? 0}',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),

              // ── 4. DANH SÁCH SẢN PHẨM HIỆN TẠI TRONG KHO ──
              const Text(
                '📦 Danh sách hàng hóa',
                style: TextStyle(
                  color: AppColors.accentCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                int currentStock = data['stock'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DKPLCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            image: data['thumbnail'] != null && data['thumbnail'] != ''
                                ? DecorationImage(
                                    image: NetworkImage(data['thumbnail']),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: data['thumbnail'] == null || data['thumbnail'] == ''
                              ? const Icon(Icons.inventory_2_outlined, color: Colors.white54)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? 'Không tên',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'SKU: ${data['sku'] ?? '-'}',
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Tồn kho',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            Text(
                              currentStock.toString(),
                              style: TextStyle(
                                color: currentStock <= 5 ? Colors.redAccent : Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  // Widget Thẻ KPI
  Widget _buildKpiCard(String title, String value, Color valColor) {
    return DKPLCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: valColor, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // POPUP NHẬP / XUẤT KHO (Dùng ModalBottom thay vì tạo Page mới)
  // =========================================================================
  void _showActionModal(
    BuildContext context, {
    required bool isReceipt,
    required List<DocumentSnapshot> products,
  }) {
    if (products.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Chưa có sản phẩm nào trong Firebase!')));
      return;
    }

    String selectedProductId = products.first.id;
    final qtyCtrl = TextEditingController(text: '1');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // Tìm data của sản phẩm đang chọn
          final selectedDoc = products.firstWhere((doc) => doc.id == selectedProductId);
          final selectedData = selectedDoc.data() as Map<String, dynamic>;
          int currentStock = selectedData['stock'] ?? 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isReceipt ? 'TẠO PHIẾU NHẬP KHO' : 'TẠO PHIẾU XUẤT KHO',
                  style: const TextStyle(
                    color: AppColors.accentCyan,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Chọn sản phẩm',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedProductId,
                      isExpanded: true,
                      dropdownColor: AppColors.primaryBlue,
                      style: const TextStyle(color: Colors.white),
                      items: products.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(
                            d['name'] ?? 'Không tên',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setModalState(() => selectedProductId = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tồn hiện tại: $currentStock',
                  style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                ),
                const SizedBox(height: 16),

                ProductTextField(
                  label: isReceipt ? 'Số lượng nhập' : 'Số lượng xuất',
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),

                DKPLButton(
                  text: 'Xác nhận (Lưu thẳng Firebase)',
                  onPressed: () {
                    int qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                    if (qty <= 0) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Vui lòng nhập số lượng > 0')));
                      return;
                    }
                    if (!isReceipt && qty > currentStock) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Không đủ hàng tồn để xuất!')));
                      return;
                    }

                    // CẬP NHẬT TRỰC TIẾP LÊN FIREBASE
                    int newStock = isReceipt ? (currentStock + qty) : (currentStock - qty);
                    FirebaseFirestore.instance.collection('products').doc(selectedProductId).update(
                      {'stock': newStock},
                    );

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Đã cập nhật tồn kho thành công!',
                          style: TextStyle(color: Colors.greenAccent),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // POPUP DUYỆT PHIẾU (DEMO GIAO DIỆN)
  // =========================================================================
  void _showApprovalModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'DANH SÁCH PHIẾU CHỜ DUYỆT',
              style: TextStyle(
                color: AppColors.accentCyan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Tính năng Duyệt Phiếu quy mô lớn sẽ được cập nhật trong phiên bản sau. Hiện tại bạn có thể cập nhật Tồn Kho trực tiếp ở nút Nhập/Xuất kho phía ngoài.",
              style: TextStyle(color: Colors.white54, height: 1.5),
            ),
            const SizedBox(height: 20),
            DKPLButton(text: 'Đóng', onPressed: () => Navigator.pop(ctx)),
          ],
        );
      },
    );
  }
}

