import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';
import 'manage_variants_screen.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductService _productService = ProductService();

  // Controllers
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _colorsController = TextEditingController();

  // Data
  String? _selectedCategory, _selectedSport, _selectedBrands;
  String? _selectedNeckStyle, _selectedSleeveStyle;
  List<String> _categories = [], _sports = [], _brands = [], _neckStyles = [], _sleeveStyles = [];

  // Image
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
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
          // Cách ép kiểu này là "bất tử": Nó an toàn chuyển mọi thứ thành List<String>
          _categories =
              (data['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _sports = (data['sports'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _brands = (data['brands'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _neckStyles =
              (data['neck_styles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _sleeveStyles =
              (data['sleeve_styles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          _isLoading = false; // Tắt xoay loading
        });
      }
    } catch (e) {
      print("Lỗi tải config AddProduct: $e");
      // Nếu có lỗi, cũng PHẢI tắt xoay loading đi
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải danh mục từ Firebase: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Wrapper gọi Dialog và Service
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

  Future<void> _handleSave() async {
    if (_nameController.text.isEmpty || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thiếu tên hoặc ảnh!"), backgroundColor: Colors.red),
      );
      return;
    } 

    setState(() => _isLoading = true);
    try {
      List<String> images = await _productService.uploadImages(_selectedImages);

      final data = {
        "name": _nameController.text.trim(),
        "search_keywords": _nameController.text.toLowerCase().split(" "),
        "category_id": _selectedCategory,
        "sport_id": _selectedSport,
        "brand": _selectedBrands,
        "color_name": _colorsController.text,
        "description": _descController.text,
        "common_specs": {"neck_style": _selectedNeckStyle, "sleeve_style": _selectedSleeveStyle},
        "images": images,
        "thumbnail": images.isNotEmpty ? images[0] : "",
        "is_active": true,
        "min_price": 0,
        "max_price": 0,
        "variants_count": 0,
      };

      String newId = await _productService.addProduct(data);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ManageVariantsScreen(productId: newId, productName: _nameController.text),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      setState(() => _isLoading = false);
    }
  }

  // Hàm chọn ảnh
  Future<void> _pickImage() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) setState(() => _selectedImages.addAll(images.map((e) => File(e.path))));
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: const Text('Thêm Sản Phẩm', style: AppStyles.h2),
        backgroundColor: Colors.transparent,
        leading: const BackButton(color: Colors.white),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: "1. Hình ảnh"),
                  const SizedBox(height: 10),
                  // Widget hiển thị ảnh (Bạn có thể tách ra file widget nếu thích)
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 90,
                            color: Colors.white10,
                            child: const Icon(Icons.add_a_photo, color: Colors.white),
                          ),
                        ),
                        ..._selectedImages.asMap().entries.map(
                          (e) => Stack(
                            children: [
                              Image.file(e.value, width: 90, height: 110, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedImages.removeAt(e.key)),
                                  child: const Icon(Icons.cancel, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle(title: "2. Thông tin chung"),
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductTextField(
                          label: "Tên sản phẩm",
                          controller: _nameController,
                          hint: "VD: Áo đấu...",
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ProductDropdown(
                                label: "Loại SP",
                                value: _selectedCategory,
                                items: _categories,
                                onChanged: (v) => setState(() => _selectedCategory = v),
                                onAddPressed: () => _onAddAttr(
                                  "Loại",
                                  _categories,
                                  "categories",
                                  (v) => _selectedCategory = v,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ProductDropdown(
                                label: "Môn TT",
                                value: _selectedSport,
                                items: _sports,
                                onChanged: (v) => setState(() => _selectedSport = v),
                                onAddPressed: () =>
                                    _onAddAttr("Môn", _sports, "sports", (v) => _selectedSport = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ProductTextField(
                                label: "Màu sắc",
                                controller: _colorsController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ProductDropdown(
                                label: "Thương hiệu",
                                value: _selectedBrands,
                                items: _brands,
                                onChanged: (v) => setState(() => _selectedBrands = v),
                                onAddPressed: () => _onAddAttr(
                                  "Brand",
                                  _brands,
                                  "brands",
                                  (v) => _selectedBrands = v,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle(title: "3. Chi tiết"),
                  DKPLCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ProductDropdown(
                                label: "Kiểu cổ",
                                value: _selectedNeckStyle,
                                items: _neckStyles,
                                onChanged: (v) => setState(() => _selectedNeckStyle = v),
                                onAddPressed: () => _onAddAttr(
                                  "Cổ",
                                  _neckStyles,
                                  "neck_styles",
                                  (v) => _selectedNeckStyle = v,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ProductDropdown(
                                label: "Kiểu tay",
                                value: _selectedSleeveStyle,
                                items: _sleeveStyles,
                                onChanged: (v) => setState(() => _selectedSleeveStyle = v),
                                onAddPressed: () => _onAddAttr(
                                  "Tay",
                                  _sleeveStyles,
                                  "sleeve_styles",
                                  (v) => _selectedSleeveStyle = v,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ProductTextField(label: "Mô tả", controller: _descController, maxLines: 3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  DKPLButton(text: "Tiếp tục (Nhập biến thể)", onPressed: _handleSave),
                ],
              ),
            ),
    );
  }
}

