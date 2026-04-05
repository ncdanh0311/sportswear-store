// File: lib/screens/duyetdon.dart (Hoặc đường dẫn bạn đang lưu)
import 'package:flutter/material.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';

class DuyetDonScreen extends StatefulWidget {
  const DuyetDonScreen({
    super.key,
    this.canUpdateStatus = true,
    this.paidOnlyMode = false,
  });

  final bool canUpdateStatus;
  final bool paidOnlyMode;

  @override
  State<DuyetDonScreen> createState() => _DuyetDonScreenState();
}

class _DuyetDonScreenState extends State<DuyetDonScreen> {
  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: Text(
          widget.paidOnlyMode ? 'Đơn đã thanh toán' : 'Duyệt Đơn Hàng',
          style: AppStyles.h2,
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.white), 
            onPressed: (){}
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // Dữ liệu giả lập (Demo)
        itemBuilder: (context, index) {
          return _buildOrderCard(index);
        },
      ),
    );
  }

  Widget _buildOrderCard(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DKPLCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Mã đơn + Trạng thái ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Mã đơn: #DH00${index + 1}",
                  style: const TextStyle(
                    color: AppColors.accentCyan, 
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.paidOnlyMode
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.paidOnlyMode
                          ? Colors.green.withOpacity(0.5)
                          : Colors.orange.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    widget.paidOnlyMode ? "Đã thanh toán" : "Chờ duyệt",
                    style: TextStyle(
                      color: widget.paidOnlyMode ? Colors.greenAccent : Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white24, height: 1),
            ),
            
            // ── Khối Thông tin Khách hàng ──
            _buildInfoRow(Icons.person_outline, "Khách hàng:", "Nguyễn Văn Khách ${index + 1}"),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone_outlined, "Điện thoại:", "0909 123 45${index}"),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on_outlined, "Địa chỉ:", "123 Đường Tôn Đức Thắng, Quận 1, TP.HCM"),
            const SizedBox(height: 16),

            // ── Khối Thông tin Sản phẩm ──
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26, // Nền làm tối đi một chút để tách biệt
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.shopping_bag_outlined, "Sản phẩm:", "Áo Polo Nam Slim Fit (Đen - Size L)"),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.numbers_outlined, "Số lượng:", "2 sản phẩm"),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.attach_money_outlined, "Tổng tiền:", "590.000 đ", isHighlight: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Khối Nút Thao tác (Hủy / Duyệt) ──
            if (widget.canUpdateStatus)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withOpacity(0.1),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        // Xử lý từ chối
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text("Từ chối", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent.withOpacity(0.1),
                        foregroundColor: Colors.greenAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.greenAccent, width: 1.2),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        // Xử lý duyệt đơn
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Duyệt đơn", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  widget.paidOnlyMode
                      ? 'Vai trò kế toán: theo dõi các đơn đã thanh toán.'
                      : 'Vai trò này chỉ có quyền theo dõi đơn hàng.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Widget dùng chung để vẽ từng dòng thông tin ──
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value, 
            style: TextStyle(
              color: isHighlight ? AppColors.accentCyan : Colors.white, 
              fontSize: 13, 
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal
            )
          ),
        ),
      ],
    );
  }
}
