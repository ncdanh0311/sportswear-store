import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/order_model.dart';
import 'package:dkpl_sports_admin/services/order_service.dart';
import 'customer_profile_screen.dart';

class DuyetDonScreen extends StatefulWidget {
  const DuyetDonScreen({super.key});

  @override
  State<DuyetDonScreen> createState() => _DuyetDonScreenState();
}

class _DuyetDonScreenState extends State<DuyetDonScreen> {
  final OrderService _orderService = OrderService.instance;

  String formatMoney(num value) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(value);
  }

  String formatDate(DateTime? time) {
    if (time == null) return 'Chưa có';
    return DateFormat('dd/MM/yyyy HH:mm').format(time);
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'shipping':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'shipping':
        return 'Đang giao';
      case 'completed':
        return 'Hoàn tất';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return 'Chờ xử lý';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: const Text('Duyệt Đơn Hàng', style: AppStyles.h2),
        backgroundColor: Colors.transparent,
      ),
      child: StreamBuilder<List<OrderModel>>(
        stream: _orderService.watchOrders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Text('Chưa có đơn hàng', style: TextStyle(color: Colors.white)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(context, order);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final status = order.status;
    final total = order.total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        child: DKPLCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mã đơn: #${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accentCyan,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      getStatusText(status),
                      style: TextStyle(
                        color: getStatusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Colors.white24),
              ),

              _buildCustomerSection(order),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, 'Thời gian:', formatDate(order.createdAt)),
              _buildInfoRow(Icons.payment, 'Thanh toán:', order.paymentMethod.isEmpty ? '---' : order.paymentMethod),
              const SizedBox(height: 12),
              _buildItemsSection(order),
              const SizedBox(height: 12),
              _buildInfoRow(Icons.attach_money, 'Tổng:', formatMoney(total), isHighlight: true),
              const SizedBox(height: 16),
              _buildActionRow(order.id, status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection(OrderModel order) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _orderService.fetchUser(order.userId),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        return FutureBuilder<Map<String, dynamic>?>(
          future: _orderService.fetchAddress(order.addressId),
          builder: (context, addressSnapshot) {
            final address = addressSnapshot.data;
            final name = (user?['fullName'] ?? '').toString();
            final phone = (user?['phone'] ?? '').toString();
            final email = (user?['email'] ?? '').toString();
            final addressText = (address?['detail'] ?? '').toString();

            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerProfileScreen(
                            name: name,
                            phone: phone,
                            email: email,
                            address: addressText,
                            userId: order.userId.isEmpty ? null : order.userId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildInfoRow(
                        Icons.person_outline,
                        'Khách:',
                        name.isEmpty ? '---' : name,
                      ),
                    ),
                  ),
                ),
                _buildInfoRow(Icons.phone_outlined, 'SĐT:', phone.isEmpty ? '---' : phone),
                _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ:', addressText.isEmpty ? '---' : addressText),
                _buildInfoRow(Icons.email_outlined, 'Email:', email.isEmpty ? '---' : email),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildItemsSection(OrderModel order) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _orderService.fetchOrderItems(order.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Text('Chưa có sản phẩm', style: TextStyle(color: Colors.white54));
        }

        return Column(
          children: items.map((item) {
            final variantId = (item['variantId'] ?? '').toString();
            final quantity = (item['quantity'] ?? 0) as int;
            final price = (item['price'] ?? 0) as num;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildItemRow(variantId, quantity, price.toDouble()),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildItemRow(String variantId, int quantity, double price) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _orderService.fetchVariant(variantId),
      builder: (context, variantSnapshot) {
        final variant = variantSnapshot.data;
        final size = (variant?['size'] ?? '').toString();
        final colorId = (variant?['colorId'] ?? '').toString();

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_bag, color: Colors.white54, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variant: $variantId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Size: $size · Color: $colorId',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SL: $quantity · ${formatMoney(price)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                formatMoney(price * quantity),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accentCyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionRow(String orderId, String status) {
    return Row(
      children: [
        if (status == 'pending') ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _orderService.updateStatus(orderId, 'cancelled'),
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Hủy'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _orderService.updateStatus(orderId, 'shipping'),
              icon: const Icon(Icons.local_shipping, size: 16),
              label: const Text('Giao'),
            ),
          ),
        ],
        if (status == 'shipping')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _orderService.updateStatus(orderId, 'completed'),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Đã xong'),
            ),
          ),
        if (status == 'completed' || status == 'cancelled')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.done_all, size: 16),
              label: Text(
                status == 'completed' ? 'Hoàn tất' : 'Đã hủy',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: Text(label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isHighlight ? AppColors.accentCyan : Colors.white,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
