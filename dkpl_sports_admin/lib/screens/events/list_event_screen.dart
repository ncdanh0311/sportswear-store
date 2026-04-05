import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/event_model.dart';
import 'package:dkpl_sports_admin/screens/events/create_event_screen.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'detail_event_screen.dart';
import 'edit_event_screen.dart';

class ListEventScreen extends StatefulWidget {
  const ListEventScreen({super.key});

  @override
  State<ListEventScreen> createState() => _ListEventScreenState();
}

class _ListEventScreenState extends State<ListEventScreen> {
  final ProductService _productService = ProductService();

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: const Text("Sự kiện khuyến mãi", style: AppStyles.h2),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "btn_add_event",
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen()));
        }, // gọi create_event_screen
        child: const Icon(Icons.add),
      ),
      child: StreamBuilder(
        stream: _productService.getEventsStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Chưa có sản phẩm", style: TextStyle(color: Colors.white54)),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final model = EventModel.fromJson(data, docs[index].id);
              return _buildEventItem(model);
            },
          );
        },
      ),
    );
  }

  Widget _buildEventItem(EventModel model) {
    String name = model.name;
    bool isActive = model.isActive;
    Timestamp? startTs = model.startDate;
    Timestamp? endTs = model.endDate;
    String dateStart = startTs != null ? DateFormat('dd/MM/yyyy').format(startTs.toDate()) : '...';
    String dateEnd = endTs != null ? DateFormat('dd/MM/yyyy').format(endTs.toDate()) : '...';
    String bannerUrl = model.bannerUrl;
    String eventType = model.eventType;

    return DKPLCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (bannerUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(bannerUrl, width: 50, height: 50, fit: BoxFit.cover),
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.event_available, color: Colors.white54),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Switch(
                value: isActive,
                activeThumbColor: Colors.cyan,
                onChanged: (bool newValue) async {
                  await _productService.toggleEventStatus(model.id, model, newValue);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Thời gian: $dateStart - $dateEnd",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Loại event: $eventType",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Cụm 2 nút bấm
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DetailEventScreen(event: model)),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, color: Colors.cyan, size: 20),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditEventScreen(eventID: model.id)),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined, color: Colors.cyan, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

