import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/product_image.dart';
import '../../core/user_session.dart';
import '../../services/local_order_service.dart';

class OrderStatusScreen extends StatelessWidget {
  final String status;
  final String title;

  const OrderStatusScreen({
    super.key,
    required this.status,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final uid = UserSession().uid;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: uid == null
          ? const Center(
              child: Text(
                'Vui lòng đăng nhập để xem đơn hàng.',
                style: TextStyle(color: AppColors.textLight),
              ),
            )
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: LocalOrderService.instance.getOrders(uid),
              builder: (context, snapshot) {
                final orders = (snapshot.data ?? [])
                    .where((o) => (o['status'] ?? '') == status)
                    .toList();
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  );
                }
                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Chưa có đơn hàng ở trạng thái này.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textLight),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Hãy đặt hàng để trải nghiệm dịch vụ tốt nhất từ DKPL Sports.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final items = (order['items'] as List?) ?? [];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đơn #${order['id']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...items.map((item) {
                            return Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: ProductImage(
                                        src: item['image'],
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'x${item['quantity']}  •  \$${(item['price'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          const SizedBox(height: 10),
                          Text(
                            'Địa chỉ: ${order['address']}',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Thanh toán: ${order['paymentMethod']}',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tổng: \$${(order['total'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
