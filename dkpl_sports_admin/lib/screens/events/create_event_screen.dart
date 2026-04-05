// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:dkpl_sports_admin/services/product_service.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final ProductService _productService = ProductService();
  String? _selectedEventType, _selectedSaleType;
  List<String> _eventType = [], _saleType = [];
  final _nameEventCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final _salePercentCtrl = TextEditingController();
  File? _bannerImage;
  final ImagePicker _picker = ImagePicker();
  bool _applyToAll = true; // Mặc định là áp dụng toàn shop

  bool _applyToCategory = false;
  List<String> _selectedCategories = [];

  bool _applyToSport = false;
  List<String> _selectedSports = [];

  bool _applyToBrand = false;
  List<String> _selectedBrands = [];

  List<String> _allCategories = [];

  List<String> _allSports = [];

  List<String> _allBrands = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConfig();
  }

  Future<void> _fetchConfig() async {
    try {
      final data = await _productService.fetchAppConfig();
      if (mounted) {
        setState(() {
          _allCategories = List<String>.from(data['categories'] ?? []);
          _allSports = List<String>.from(data['sports'] ?? []);
          _allBrands = List<String>.from(data['brands'] ?? []);
          _eventType = List<String>.from(data['event_types'] ?? []);
          _saleType = ['%', 'VNĐ'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Lỗi tải config: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCreateEvent() async {
    // 1. Kiểm tra Validate cơ bản
    if (_nameEventCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập tên sự kiện!")));
      return;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng chọn thời gian diễn ra!")));
      return;
    }
    if (_salePercentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập mức giảm giá!")));
      return;
    }

    // 2. Bật Loading
    setState(() => _isLoading = true);

    try {
      // 3. Upload ảnh Banner (Nếu có)
      String bannerUrl = "";
      if (_bannerImage != null) {
        // Gọi hàm uploadImages (dùng tạm hàm của product cũng được, hoặc viết hàm riêng uploadEventBanner)
        List<String> urls = await _productService.uploadImages([
          _bannerImage!,
        ], productId: "event_${DateTime.now().millisecondsSinceEpoch}");
        if (urls.isNotEmpty) bannerUrl = urls.first;
      }

      // 4. Đóng gói dữ liệu JSON
      Map<String, dynamic> eventData = {
        "name": _nameEventCtrl.text.trim(),
        "event_type": _selectedEventType ?? "Khác",
        "start_date": Timestamp.fromDate(_startDate!),
        "end_date": Timestamp.fromDate(_endDate!),
        "is_active": true, // Tự động kích hoạt khi tạo
        "banner_url": bannerUrl,

        "discount_type": _selectedSaleType == "%" ? "percent" : "fixed",
        "discount_value": double.tryParse(_salePercentCtrl.text.trim()) ?? 0,

        // Điều kiện áp dụng
        "conditions": {
          "apply_all": _applyToAll,
          "categories": _applyToAll ? [] : _selectedCategories,
          "sports": _applyToAll ? [] : _selectedSports,
          "brands": _applyToAll ? [] : _selectedBrands,
        },

        "created_at": FieldValue.serverTimestamp(),
      };

      // 5. Lưu vào Firestore (Bạn cần thêm hàm createEvent trong ProductService nhé)
      await _productService.createEventAndApply(eventData);

      // 6. Thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tạo sự kiện thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Quay về danh sách Event
      }
    } catch (e) {
      print("Lỗi tạo event: $e");
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? (_startDate ?? DateTime.now())),
      firstDate: DateTime.now(), // Không cho chọn ngày đã qua
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        // Format ngày: DD/MM/YYYY
        String formattedDate =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";

        if (isStart) {
          _startDate = picked;
          _startDateCtrl.text = formattedDate;

          // Logic phụ: Nếu ngày kết thúc đang nhỏ hơn ngày bắt đầu -> Xóa ngày kết thúc
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            _endDateCtrl.clear();
          }
        } else {
          // Kiểm tra không cho phép ngày kết thúc nhỏ hơn ngày bắt đầu
          if (_startDate != null && picked.isBefore(_startDate!)) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Ngày kết thúc phải sau ngày bắt đầu!")));
            return;
          }
          _endDate = picked;
          _endDateCtrl.text = formattedDate;
        }
      });
    }
  }

  // 2. Hàm xử lý logic loại trừ (Khi click vào Checkbox)
  void _onApplyAllChanged(bool? value) {
    if (value == true) {
      setState(() {
        _applyToAll = true;
        // Tắt hết các cái khác và xóa dữ liệu đã chọn
        _applyToCategory = false;
        _applyToSport = false;
        _applyToBrand = false;
        _selectedCategories.clear();
        _selectedSports.clear();
        _selectedBrands.clear();
      });
    }
  }

  void _onSpecificConditionChanged(String type, bool? value) {
    setState(() {
      bool isChecked = value ?? false;

      if (type == 'category') {
        _applyToCategory = isChecked;
        if (!isChecked) _selectedCategories.clear();
      } else if (type == 'sport') {
        _applyToSport = isChecked;
        if (!isChecked) _selectedSports.clear();
      } else if (type == 'brand') {
        _applyToBrand = isChecked;
        if (!isChecked) _selectedBrands.clear();
      }

      // Nếu có bất kỳ điều kiện nào được bật -> Tắt nút "Toàn bộ" đi
      if (_applyToCategory || _applyToSport || _applyToBrand) {
        _applyToAll = false;
      } else {
        // Nếu tắt hết sạch điều kiện -> Tự động bật lại nút "Toàn bộ"
        _applyToAll = true;
      }
    });
  }

  Future<void> _pickBanner() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _bannerImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Lỗi chọn ảnh: $e");
    }
  }

  void _removeBanner() {
    setState(() {
      _bannerImage = null;
    });
  }

  void _onAddAttr(String title, List<String> list, String field, Function(String) onSet) {
    showAddAttributeDialog(
      context,
      title: title,
      onSave: (val) async {
        setState(() {
          list.add(val);
          onSet(val);
        });
        await _productService.addAttributeToConfig(field, val);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm!")));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(title: Text("Tạo sự kiện mới")),
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
                        ProductDropdown(
                          label: "Loại event",
                          value: _selectedEventType,
                          items: _eventType,
                          onChanged: (v) => setState(() => _selectedEventType = v),
                          onAddPressed: () => _onAddAttr(
                            "Loại",
                            _eventType,
                            "categories",
                            (v) => _selectedEventType = v,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SectionTitle(title: "2. Hình thức giảm giá"),
                  DKPLCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: ProductTextField(
                            label: "Nhập số lượng giảm:",
                            controller: _salePercentCtrl,
                          ),
                        ),
                        Expanded(
                          child: ProductDropdown(
                            label: "Hình thức giảm: ",
                            value: _selectedSaleType,
                            items: _saleType,
                            onChanged: (v) => setState(() => _selectedSaleType = v),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SectionTitle(title: "3. Banner sự kiện"),
                  GestureDetector(
                    onTap: _bannerImage == null ? _pickBanner : null,
                    child: _bannerImage == null
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryBlue.withOpacity(0.3),
                                  ),
                                  child: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: AppColors.accentCyan,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Bấm để tải ảnh Banner lên",
                                  style: TextStyle(
                                    color: AppColors.accentCyan,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Kích thước khuyến nghị: 16:9",
                                  style: TextStyle(color: Colors.white54, fontSize: 11),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _bannerImage!,
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

                  SectionTitle(title: "4. Đối tượng áp dụng"),
                  DKPLCard(
                    child: Theme(
                      data: Theme.of(context).copyWith(unselectedWidgetColor: Colors.white54),
                      child: Column(
                        children: [
                          //Toàn bộ SP
                          CheckboxListTile(
                            title: const Text(
                              "Áp dụng toàn bộ sản phẩm",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            value: _applyToAll,
                            onChanged: _onApplyAllChanged,
                            activeColor: AppColors.accentCyan,
                            checkColor: Colors.black,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          // 2. THEO DANH MỤC
                          CheckboxListTile(
                            title: const Text(
                              "Theo Danh mục",
                              style: TextStyle(color: Colors.white),
                            ),
                            value: _applyToCategory,
                            onChanged: (val) => _onSpecificConditionChanged('category', val),
                            activeColor: AppColors.accentCyan,
                            checkColor: Colors.black,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          // Hiện vùng chọn nếu được tick
                          if (_applyToCategory)
                            _buildSelectedArea(
                              "Danh mục",
                              _allCategories, // _categories là mảng bạn lấy từ _fetchConfig()
                              _selectedCategories,
                              (newList) => setState(() => _selectedCategories = newList),
                            ),

                          // 3. THEO MÔN THỂ THAO
                          CheckboxListTile(
                            title: const Text(
                              "Theo Môn thể thao",
                              style: TextStyle(color: Colors.white),
                            ),
                            value: _applyToSport,
                            onChanged: (val) => _onSpecificConditionChanged('sport', val),
                            activeColor: AppColors.accentCyan,
                            checkColor: Colors.black,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_applyToSport)
                            _buildSelectedArea(
                              "Môn thể thao",
                              _allSports,
                              _selectedSports,
                              (newList) => setState(() => _selectedSports = newList),
                            ),

                          // 4. THEO THƯƠNG HIỆU
                          CheckboxListTile(
                            title: const Text(
                              "Theo Thương hiệu",
                              style: TextStyle(color: Colors.white),
                            ),
                            value: _applyToBrand,
                            onChanged: (val) => _onSpecificConditionChanged('brand', val),
                            activeColor: AppColors.accentCyan,
                            checkColor: Colors.black,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_applyToBrand)
                            _buildSelectedArea(
                              "Thương hiệu",
                              _allBrands,
                              _selectedBrands,
                              (newList) => setState(() => _selectedBrands = newList),
                            ),
                        ],
                      ),
                    ),
                  ),
                  DKPLButton(text: "Tạo sự kiện", onPressed: _handleCreateEvent),
                ],
              ),
            ),
    );
  }

  Widget _buildSelectedArea(
    String title,
    List<String> allItems,
    List<String> selectedItems,
    Function(List<String>) onUpdate,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 48.0, bottom: 12.0), // Thụt lề vào trong so với Checkbox
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selectedItems.isEmpty
                  ? [
                      const Text(
                        "Chưa chọn mục nào",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ]
                  : selectedItems
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
          IconButton(
            icon: const Icon(Icons.edit_square, color: AppColors.accentCyan, size: 20),
            onPressed: () {
              // Gọi hàm hiển thị Dialog ở Bước 2
              _openMultiSelectDialog(title, allItems, selectedItems, onUpdate);
            },
          ),
        ],
      ),
    );
  }

  void _openMultiSelectDialog(
    String title,
    List<String> allItems,
    List<String> currentSelected,
    Function(List<String>) onSaved,
  ) {
    // Tạo 1 list tạm để thao tác trong Dialog (tránh ảnh hưởng list thật bên ngoài khi chưa bấm Lưu)
    List<String> tempSelected = List.from(currentSelected);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.primaryNavy,
              title: Text("Chọn $title", style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                // Giới hạn chiều cao để không bị tràn màn hình nếu list quá dài
                height: 300,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    final item = allItems[index];
                    final isChecked = tempSelected.contains(item);
                    return CheckboxListTile(
                      title: Text(item, style: const TextStyle(color: Colors.white)),
                      value: isChecked,
                      activeColor: AppColors.accentCyan,
                      checkColor: Colors.black,
                      onChanged: (bool? val) {
                        setStateDialog(() {
                          // Update UI bên trong Dialog
                          if (val == true) {
                            tempSelected.add(item);
                          } else {
                            tempSelected.remove(item);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Hủy", style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    onSaved(tempSelected); // Bắn list tạm ra ngoài
                    Navigator.pop(context); // Đóng hộp thoại
                  },
                  child: const Text(
                    "Xác nhận",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

