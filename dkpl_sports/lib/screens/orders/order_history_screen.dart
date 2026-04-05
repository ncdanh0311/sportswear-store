import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/product_image.dart';
import '../../core/user_session.dart';
import '../../services/local_order_service.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _session = UserSession();

  @override
  Widget build(BuildContext context) {
    final uid = _session.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Vui lòng đăng nhập để xem lịch sử mua hàng.',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Lịch sử mua hàng',
          style: TextStyle(color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: LocalOrderService.instance.getOrders(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có đơn hàng nào',
                style: TextStyle(color: AppColors.textLight),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final items = (order['items'] as List?) ?? [];
              final first = items.isNotEmpty ? items.first : null;
              final status = (order['status'] ?? 'pending').toString();
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: first == null
                          ? const Icon(Icons.inventory_2_outlined)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ProductImage(
                                src: first['image'],
                                fit: BoxFit.contain,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đơn #${order['id'] ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${items.length} sản phẩm',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${(order['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusChip(status),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusChip(String status) {
    String label = 'Chờ xác nhận';
    Color color = Colors.orange;
    if (status == 'shipping') {
      label = 'Đang giao';
      color = Colors.blue;
    } else if (status == 'delivered') {
      label = 'Đã giao';
      color = Colors.green;
    } else if (status == 'review') {
      label = 'Đánh giá';
      color = Colors.purple;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
