import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/voucher_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailVoucherScreen extends StatelessWidget {
  final VoucherModel voucher;

  const DetailVoucherScreen({super.key, required this.voucher});

  // Hàm format tiền tệ
  String _formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Bóc tách dữ liệu
    String code = voucher.code;
    String name = voucher.name;
    String type = voucher.discountType;

    double discountValue = voucher.discountValue;
    double minOrder = voucher.minOrder;
    double maxDiscount = voucher.maxDiscount;

    int usageLimit = voucher.usageLimit;
    int usedCount = voucher.usedCount;
    bool isActive = voucher.isActive;

    // 2. Format Ngày tháng
    final startTs = voucher.startDate;
    final endTs = voucher.endDate;
    String dateStart = startTs != null ? DateFormat('dd/MM/yyyy').format(startTs.toDate()) : '...';
    String dateEnd = endTs != null ? DateFormat('dd/MM/yyyy').format(endTs.toDate()) : '...';

    // 3. Xử lý chuỗi hiển thị mức giảm
    String discountStr = type == 'percent'
        ? '${discountValue.toInt()}%'
        : _formatPrice(discountValue);

    // 4. Tính % thanh Progress
    double progress = usageLimit > 0 ? (usedCount / usageLimit) : 0;
    if (progress > 1.0) progress = 1.0;

    return BaseBackground(
      appBar: AppBar(
        title: const Text("Chi tiết Voucher", style: AppStyles.h2),
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ Hiển thị Nổi bật (Banner Voucher)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                // Nếu Voucher bị tắt, đổi màu nền sang xám cho trực quan
                gradient: isActive
                    ? const LinearGradient(colors: [AppColors.accentCyan, AppColors.primaryBlue])
                    : const LinearGradient(colors: [Colors.white24, Colors.white10]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "MÃ VOUCHER",
                    style: TextStyle(
                      color: isActive ? AppColors.primaryNavy : Colors.white54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    code,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white70,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Thông số chi tiết",
              style: TextStyle(
                color: AppColors.accentCyan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DKPLCard(
              child: Column(
                children: [
                  _buildDetailRow("Mức giảm:", discountStr, Colors.white),
                  _buildDetailRow("Đơn tối thiểu:", _formatPrice(minOrder), Colors.white),

                  // Nếu là giảm % thì mới hiện dòng Giảm tối đa
                  if (type == 'percent' && maxDiscount > 0)
                    _buildDetailRow("Giảm tối đa:", _formatPrice(maxDiscount), Colors.white),

                  const Divider(color: Colors.white12, height: 24),
                  _buildDetailRow("Thời gian:", "$dateStart - $dateEnd", Colors.orangeAccent),
                  _buildDetailRow(
                    "Trạng thái:",
                    isActive ? "Đang hoạt động" : "Đã tắt / Hết hạn",
                    isActive ? Colors.green : Colors.redAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "Thống kê sử dụng",
              style: TextStyle(
                color: AppColors.accentCyan,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DKPLCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Đã sử dụng", style: TextStyle(color: Colors.white54)),
                      Text(
                        "$usedCount / $usageLimit lượt",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    // Sắp hết lượt thì đổi màu cảnh báo
                    color: progress > 0.8 ? Colors.redAccent : AppColors.accentCyan,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 8),
                  // Thông báo nhỏ nếu đã hết lượt
                  if (usedCount >= usageLimit)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "Đã đạt giới hạn sử dụng!",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget vẽ từng dòng chi tiết
  Widget _buildDetailRow(String label, String value, Color valColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(
            value,
            style: TextStyle(color: valColor, fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

