import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:dkpl_sports_admin/services/product_service.dart';

class EditEventScreen extends StatefulWidget {
  final String eventID;
  const EditEventScreen({super.key, required this.eventID});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final ProductService _productService = ProductService();

  final _nameEventCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final eventDoc =
        await FirebaseFirestore.instance.collection('events').doc(widget.eventID).get();

    if (mounted && eventDoc.exists) {
      final data = eventDoc.data() as Map<String, dynamic>;
      setState(() {
        _nameEventCtrl.text = data['name'] ?? '';
        final startTs = data['startDate'] as Timestamp?;
        final endTs = data['endDate'] as Timestamp?;
        if (startTs != null) {
          _startDate = startTs.toDate();
          _startDateCtrl.text = DateFormat('dd/MM/yyyy').format(_startDate!);
        }
        if (endTs != null) {
          _endDate = endTs.toDate();
          _endDateCtrl.text = DateFormat('dd/MM/yyyy').format(_endDate!);
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdateEvent() async {
    if (_nameEventCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tên sự kiện!")),
      );
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn thời gian!")),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updateData = {
        "name": _nameEventCtrl.text.trim(),
        "startDate": Timestamp.fromDate(_startDate!),
        "endDate": Timestamp.fromDate(_endDate!),
      };

      await _productService.updateEvent(widget.eventID, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thành công!"), backgroundColor: Colors.green),
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
      appBar: AppBar(title: const Text("Sửa Sự kiện")),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentCyan))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SectionTitle(title: "Thông tin chung"),
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
                  const SizedBox(height: 24),
                  DKPLButton(text: "Lưu thay đổi", onPressed: _handleUpdateEvent),
                ],
              ),
            ),
    );
  }
}
