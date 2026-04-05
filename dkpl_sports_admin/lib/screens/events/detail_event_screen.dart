import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/event_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailEventScreen extends StatelessWidget {
  final EventModel event;
  const DetailEventScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final start = event.startDate?.toDate();
    final end = event.endDate?.toDate();
    final dateStart = start != null ? DateFormat('dd/MM/yyyy').format(start) : '...';
    final dateEnd = end != null ? DateFormat('dd/MM/yyyy').format(end) : '...';

    return BaseBackground(
      appBar: AppBar(
        title: const Text('Chi tiết sự kiện', style: AppStyles.h2),
        backgroundColor: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DKPLCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(event.name, style: AppStyles.h2),
              const SizedBox(height: 8),
              _row("Bắt đầu", dateStart),
              _row("Kết thúc", dateEnd),
              const Divider(color: Colors.white12, height: 24),
              const Text(
                "Sự kiện theo lịch",
                style: TextStyle(color: AppColors.accentCyan),
              ),
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
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}
