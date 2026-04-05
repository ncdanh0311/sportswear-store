import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:dkpl_sports_admin/models/event_model.dart';

class DetailEventScreen extends StatelessWidget {
  final EventModel event;

  const DetailEventScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Bóc tách data
    String name = event.name;
    String type = event.eventType;
    double discountValue = event.discountValue;
    String discountType = event.discountType;
    String bannerUrl = event.bannerUrl;

    final startTs = event.startDate;
    final endTs = event.endDate;
    String dateStart = startTs != null ? DateFormat('dd/MM/yyyy').format(startTs.toDate()) : '...';
    String dateEnd = endTs != null ? DateFormat('dd/MM/yyyy').format(endTs.toDate()) : '...';

    final conditions = event.conditions;
    bool applyAll = conditions.applyAll;
    List categories = conditions.categories;
    List sports = conditions.sports;
    List brands = conditions.brands;

    String discountStr = discountType == 'percent'
        ? '${discountValue.toInt()}%'
        : '${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(discountValue)}';

    return BaseBackground(
      appBar: AppBar(
        title: const Text("Chi tiết Sự kiện", style: AppStyles.h2),
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            if (bannerUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  bannerUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),

            // Info
            const SectionTitle(title: "1. Thông tin chung"),
            DKPLCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.accentCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  _buildDetailRow("Loại sự kiện:", type),
                  _buildDetailRow("Thời gian:", "$dateStart - $dateEnd"),
                  _buildDetailRow("Mức giảm giá:", discountStr, valueColor: Colors.orange),
                  _buildDetailRow(
                    "Trạng thái:",
                    event.isActive ? "Đang chạy" : "Đã tắt",
                    valueColor: event.isActive ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Scope
            const SectionTitle(title: "2. Đối tượng áp dụng"),
            DKPLCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (applyAll)
                    const Text(
                      "✔️ Áp dụng cho TOÀN BỘ sản phẩm",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    )
                  else ...[
                    if (categories.isNotEmpty) _buildListChips("Danh mục:", categories),
                    if (sports.isNotEmpty) _buildListChips("Môn thể thao:", sports),
                    if (brands.isNotEmpty) _buildListChips("Thương hiệu:", brands),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color valueColor = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.white54)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: valueColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListChips(String title, List items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items
                .map(
                  (e) => Chip(
                    label: Text(e.toString(), style: const TextStyle(fontSize: 12)),
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.5),
                    side: BorderSide.none,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

