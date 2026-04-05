import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final CollectionReference _inventoryRef =
      FirebaseFirestore.instance.collection('inventory');

  bool get _canManageInventory =>
      RolePermissions.canManageInventory(AuthService.instance.currentUser?.roleId);

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
      child: StreamBuilder<QuerySnapshot>(
        stream: _inventoryRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accentCyan));
          }

          final docs = snapshot.data!.docs;
          int totalVariants = docs.length;
          int totalStock = 0;
          int lowStock = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            int qty = (data['quantity'] ?? 0) as int;
            totalStock += qty;
            if (qty <= 5) lowStock++;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _buildKpiCard('Biến thể', totalVariants.toString(), Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard('Tổng tồn', totalStock.toString(), AppColors.accentCyan),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      'Sắp hết',
                      lowStock.toString(),
                      lowStock > 0 ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Danh sách tồn kho',
                style: TextStyle(
                  color: AppColors.accentCyan,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final variantId = (data['variantId'] ?? doc.id).toString();
                final qty = (data['quantity'] ?? 0) as int;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InventoryItem(variantId: variantId, quantity: qty),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

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
}

class _InventoryItem extends StatelessWidget {
  final String variantId;
  final int quantity;

  const _InventoryItem({required this.variantId, required this.quantity});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('product_variants').doc(variantId).get(),
      builder: (context, snapshot) {
        final variant = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final productId = (variant['productId'] ?? '').toString();
        final size = (variant['size'] ?? '').toString();
        final colorId = (variant['colorId'] ?? '').toString();

        if (productId.isEmpty) {
          return DKPLCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: Colors.white54),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Biến thể không hợp lệ',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                Text(
                  quantity.toString(),
                  style: TextStyle(
                    color: quantity <= 5 ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('products').doc(productId).get(),
          builder: (context, productSnapshot) {
            final product = productSnapshot.data?.data() as Map<String, dynamic>? ?? {};
            final name = (product['name'] ?? 'Không tên').toString();
            final thumb = (product['thumbnail'] ?? '').toString();

            return DKPLCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      image: thumb.isNotEmpty
                          ? DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover)
                          : null,
                    ),
                    child: thumb.isEmpty
                        ? const Icon(Icons.inventory_2_outlined, color: Colors.white54)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Size: $size · Color: $colorId',
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
                        quantity.toString(),
                        style: TextStyle(
                          color: quantity <= 5 ? Colors.redAccent : Colors.greenAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
