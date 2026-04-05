import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Các trường ĐƯỢC PHÉP sửa
  final _nameEventCtrl = TextEditingController();
  String? _selectedEventType;
  List<String> _eventType = [];
  String _oldBannerUrl = "";
  File? _newBannerImage;
  final ImagePicker _picker = ImagePicker();

  // Các trường CHỈ HIỂN THỊ (Không cho sửa)
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _salePercentCtrl = TextEditingController();
  String? _selectedSaleType;
  List<String> _saleType = ['%', 'VNĐ'];

  bool _applyToAll = true;
  bool _applyToCategory = false;
  List<String> _selectedCategories = [];
  bool _applyToSport = false;
  List<String> _selectedSports = [];
  bool _applyToBrand = false;
  List<String> _selectedBrands = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      final configFuture = _productService.fetchAppConfig();
      final eventFuture = FirebaseFirestore.instance.collection('events').doc(widget.eventID).get();

      final results = await Future.wait([configFuture, eventFuture]);
      final configData = results[0] as Map<String, dynamic>;
      final eventDoc = results[1] as DocumentSnapshot;

      if (mounted && eventDoc.exists) {
        final data = eventDoc.data() as Map<String, dynamic>;

        setState(() {
          // Chỉ cần load event_type để sửa, bỏ qua category/sport/brand vì không cho sửa
          _eventType =
              (configData['event_types'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [];

          // Đổ dữ liệu
          _nameEventCtrl.text = data['name'] ?? '';
          if (_eventType.contains(data['event_type'])) {
            _selectedEventType = data['event_type'];
          }

          _oldBannerUrl = data['banner_url'] ?? '';

          // Đổ dữ liệu Read-only (Chỉ xem)
          double discountValue = (data['discount_value'] ?? 0).toDouble();
          _salePercentCtrl.text = data['discount_type'] == 'percent'
              ? discountValue.toString()
              : discountValue.toInt().toString();
          _selectedSaleType = data['discount_type'] == 'percent' ? '%' : 'VNĐ';

          Timestamp? startTs = data['start_date'];
          Timestamp? endTs = data['end_date'];
          if (startTs != null)
            _startDateCtrl.text = DateFormat('dd/MM/yyyy').format(startTs.toDate());
          if (endTs != null) _endDateCtrl.text = DateFormat('dd/MM/yyyy').format(endTs.toDate());

          Map<String, dynamic> conditions = data['conditions'] ?? {};
          _applyToAll = conditions['apply_all'] ?? false;
          _selectedCategories = List<String>.from(conditions['categories'] ?? []);
          _applyToCategory = _selectedCategories.isNotEmpty;
          _selectedSports = List<String>.from(conditions['sports'] ?? []);
          _applyToSport = _selectedSports.isNotEmpty;
          _selectedBrands = List<String>.from(conditions['brands'] ?? []);
          _applyToBrand = _selectedBrands.isNotEmpty;

          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpdateEvent() async {
    if (_nameEventCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên sự kiện!")));
      return;
    }
    setState(() => _isLoading = true);

    try {
      String finalBannerUrl = _oldBannerUrl;
      if (_newBannerImage != null) {
        List<String> urls = await _productService.uploadImages([
          _newBannerImage!,
        ], productId: "event_${DateTime.now().millisecondsSinceEpoch}");
        if (urls.isNotEmpty) finalBannerUrl = urls.first;
      }

      // TỐI ƯU: Chỉ gửi 3 trường được phép thay đổi lên Firebase
      Map<String, dynamic> updateData = {
        "name": _nameEventCtrl.text.trim(),
        "event_type": _selectedEventType ?? "Khác",
        "banner_url": finalBannerUrl,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickBanner() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _newBannerImage = File(image.path));
  }

  void _removeBanner() {
    setState(() {
      _newBannerImage = null;
      _oldBannerUrl = "";
    });
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
                  SectionTitle(title: "1. Thông tin chung"),
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductTextField(label: "Tên event", controller: _nameEventCtrl),
                        const SizedBox(height: 12),

                        // Khối thời gian bị BÓC AbsorbPointer (Không cho click)
                        AbsorbPointer(
                          child: Opacity(
                            opacity: 0.6, // Làm mờ đi để Admin biết là không bấm được
                            child: Row(
                              children: [
                                Expanded(
                                  child: ProductDatePickerField(
                                    label: "Từ ngày (Cố định):",
                                    controller: _startDateCtrl,
                                    hint: "",
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ProductDatePickerField(
                                    label: "Đến ngày (Cố định):",
                                    controller: _endDateCtrl,
                                    hint: "",
                                    onTap: () {},
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Loại Event vẫn cho sửa
                        ProductDropdown(
                          label: "Loại event",
                          value: _selectedEventType,
                          items: _eventType,
                          onChanged: (v) => setState(() => _selectedEventType = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  SectionTitle(title: "2. Hình thức giảm (Không thể sửa)"),
                  DKPLCard(
                    // Khóa toàn bộ khối Giảm giá
                    child: AbsorbPointer(
                      child: Opacity(
                        opacity: 0.6,
                        child: Row(
                          children: [
                            Expanded(
                              child: ProductTextField(
                                label: "Mức giảm:",
                                controller: _salePercentCtrl,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ProductDropdown(
                                label: "Hình thức: ",
                                value: _selectedSaleType,
                                items: _saleType,
                                onChanged: (v) {},
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  SectionTitle(title: "3. Banner sự kiện"),
                  GestureDetector(
                    onTap: (_newBannerImage == null && _oldBannerUrl.isEmpty) ? _pickBanner : null,
                    child: (_newBannerImage == null && _oldBannerUrl.isEmpty)
                        ? Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accentCyan.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_rounded,
                              color: AppColors.accentCyan,
                              size: 32,
                            ),
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _newBannerImage != null
                                    ? Image.file(
                                        _newBannerImage!,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        _oldBannerUrl,
                                        height: 160,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _removeBanner,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 20),
                  SectionTitle(title: "4. Đối tượng (Không thể sửa)"),
                  DKPLCard(
                    // Khóa toàn bộ khối Đối tượng
                    child: AbsorbPointer(
                      child: Opacity(
                        opacity: 0.6,
                        child: Column(
                          children: [
                            CheckboxListTile(
                              title: const Text(
                                "Áp dụng toàn bộ",
                                style: TextStyle(color: Colors.white),
                              ),
                              value: _applyToAll,
                              onChanged: null,
                              contentPadding: EdgeInsets.zero,
                            ),
                            CheckboxListTile(
                              title: const Text(
                                "Theo Danh mục",
                                style: TextStyle(color: Colors.white),
                              ),
                              value: _applyToCategory,
                              onChanged: null,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_applyToCategory) _buildReadOnlyChips(_selectedCategories),

                            CheckboxListTile(
                              title: const Text(
                                "Theo Môn thể thao",
                                style: TextStyle(color: Colors.white),
                              ),
                              value: _applyToSport,
                              onChanged: null,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_applyToSport) _buildReadOnlyChips(_selectedSports),

                            CheckboxListTile(
                              title: const Text(
                                "Theo Thương hiệu",
                                style: TextStyle(color: Colors.white),
                              ),
                              value: _applyToBrand,
                              onChanged: null,
                              contentPadding: EdgeInsets.zero,
                            ),
                            if (_applyToBrand) _buildReadOnlyChips(_selectedBrands),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  DKPLButton(text: "Lưu thay đổi", onPressed: _handleUpdateEvent),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  // Hàm hiển thị Chip Rút gọn (Đã bỏ nút Edit)
  Widget _buildReadOnlyChips(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 48.0, bottom: 12.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => Chip(
                  label: Text(item, style: const TextStyle(fontSize: 11)),
                  backgroundColor: AppColors.white.withOpacity(0.1),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

