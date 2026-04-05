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

  String _formatPrice(num price) {
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
  }

  @override
  Widget build(BuildContext context) {
    final discountTitle = "Giảm ${_formatPrice(voucher.discount)}";

    return BaseBackground(
      appBar: AppBar(
        title: const Text('Chi tiết Voucher', style: AppStyles.h2),
        backgroundColor: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DKPLCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(voucher.code, style: AppStyles.h2),
              const SizedBox(height: 8),
              Text(discountTitle, style: const TextStyle(color: AppColors.accentCyan)),
              const Divider(color: Colors.white12, height: 24),
              _row("Đơn tối thiểu", _formatPrice(voucher.minOrder)),
              _row("Giảm tối đa", _formatPrice(voucher.maxDiscount)),
              _row("Số lượt", "${voucher.usedCount}/${voucher.usageLimit}"),
              _row("Trạng thái", voucher.isActive ? "Đang hoạt động" : "Tạm tắt"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
