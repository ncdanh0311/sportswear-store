import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:flutter/material.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final ProductService _productService = ProductService();
  final _nameEventCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  Future<void> _handleCreateEvent() async {
    if (_nameEventCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên sự kiện!")),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn thời gian diễn ra!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> eventData = {
        "name": _nameEventCtrl.text.trim(),
        "startDate": Timestamp.fromDate(_startDate!),
        "endDate": Timestamp.fromDate(_endDate!),
      };

      await _productService.createEvent(eventData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tạo sự kiện thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? (_startDate ?? DateTime.now())),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        String formattedDate =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";

        if (isStart) {
          _startDate = picked;
          _startDateCtrl.text = formattedDate;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            _endDateCtrl.clear();
          }
        } else {
          if (_startDate != null && picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Ngày kết thúc phải sau ngày bắt đầu!")),
            );
            return;
          }
          _endDate = picked;
          _endDateCtrl.text = formattedDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(title: const Text("Tạo sự kiện mới")),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SectionTitle(title: "1. Thông tin chung"),
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductTextField(label: "Tên event", controller: _nameEventCtrl),
                        Row(
                          children: [
                            Expanded(
                              child: ProductDatePickerField(
                                label: "Từ ngày:",
                                controller: _startDateCtrl,
                                hint: "Ngày bắt đầu",
                                onTap: () => _pickDate(true),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ProductDatePickerField(
                                label: "Đến ngày",
                                controller: _endDateCtrl,
                                hint: "Ngày kết thúc",
                                onTap: () => _pickDate(false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DKPLButton(text: "Tạo sự kiện", onPressed: _handleCreateEvent),
                ],
              ),
            ),
    );
  }
}
