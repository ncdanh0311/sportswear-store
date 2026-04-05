import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class VoucherScreen extends StatelessWidget {
  const VoucherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vouchers = _fakeVouchers();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kho Voucher',
          style: TextStyle(color: AppColors.textDark),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vouchers.length,
        itemBuilder: (context, index) {
          final v = vouchers[index];
          return _VoucherCard(voucher: v);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _fakeVouchers() {
    return [
      {
        'title': 'Giảm 10% cho đơn đầu',
        'subtitle': 'Áp dụng đơn từ \$50',
        'code': 'NEW10',
        'active': true,
      },
      {
        'title': 'Freeship nội thành',
        'subtitle': 'Đơn từ \$30',
        'code': 'SHIP30',
        'active': true,
      },
      {
        'title': 'Giảm 15% cuối tuần',
        'subtitle': 'Khả dụng từ 06/04/2026',
        'code': 'WEEKEND15',
        'active': false,
      },
      {
        'title': 'Ưu đãi thành viên bạc',
        'subtitle': 'Khả dụng khi đạt 3 đơn thành công',
        'code': 'MEMBER',
        'active': false,
      },
    ];
  }
}

class _VoucherCard extends StatelessWidget {
  final Map<String, dynamic> voucher;
  const _VoucherCard({required this.voucher});

  @override
  Widget build(BuildContext context) {
    final active = voucher['active'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? AppColors.primaryBlue : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryBlue.withOpacity(.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.confirmation_number_outlined,
              color: active ? AppColors.primaryBlue : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: active ? AppColors.textDark : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  voucher['subtitle'],
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? AppColors.textLight : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryBlue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              voucher['code'],
              style: TextStyle(
                color: active ? Colors.white : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
