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

  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String? _selectedCategory, _selectedSport, _selectedBrand;
  String? _selectedMaterial, _selectedNeckStyle, _selectedSleeveStyle;
  List<String> _categories = [], _sports = [], _brands = [];
  List<String> _materials = [], _neckStyles = [], _sleeveStyles = [];

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
          _categories = (data['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _sports = (data['sports'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _brands = (data['brands'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _materials = (data['materials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _neckStyles = (data['neck_styles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _sleeveStyles = (data['sleeve_styles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải danh mục: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onAddAttr(String title, List<String> list, String collection, Function(String) onSet) {
    showAddAttributeDialog(
      context,
      title: title,
      onSave: (val) async {
        setState(() {
          list.add(val);
          onSet(val);
          _syncDescription();
        });
        await _productService.addAttributeToConfig(collection, val);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm!")));
      },
    );
  }

  String _buildAutoDescription() {
    final lines = <String>[];
    if ((_selectedMaterial ?? '').isNotEmpty) {
      lines.add("Chất liệu: $_selectedMaterial");
    }
    if ((_selectedNeckStyle ?? '').isNotEmpty) {
      lines.add("Kiểu cổ: $_selectedNeckStyle");
    }
    if ((_selectedSleeveStyle ?? '').isNotEmpty) {
      lines.add("Kiểu tay áo: $_selectedSleeveStyle");
    }
    return lines.join("\n");
  }

  void _syncDescription() {
    _descController.text = _buildAutoDescription();
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
      _syncDescription();

      final data = {
        "name": _nameController.text.trim(),
        "description": _descController.text.trim(),
        "categoryId": _selectedCategory,
        "brandId": _selectedBrand,
        "sportId": _selectedSport,
        "materialId": _selectedMaterial,
        "neckStyleId": _selectedNeckStyle,
        "sleeveStyleId": _selectedSleeveStyle,
        "thumbnail": images.isNotEmpty ? images[0] : "",
        "isActive": true,
        "minPrice": 0,
        "maxPrice": 0,
        "rating": 0,
        "ratingCount": 0,
        "sold": 0,
      };

      String newId = await _productService.addProduct(data, images: images);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ManageVariantsScreen(productId: newId, productName: _nameController.text),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      setState(() => _isLoading = false);
    }
  }

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
                        ProductDropdown(
                          label: "Thương hiệu",
                          value: _selectedBrand,
                          items: _brands,
                          onChanged: (v) => setState(() => _selectedBrand = v),
                          onAddPressed: () => _onAddAttr(
                            "Brand",
                            _brands,
                            "brands",
                            (v) => _selectedBrand = v,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle(title: "3. Chi tiết"),
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductDropdown(
                          label: "Chất liệu",
                          value: _selectedMaterial,
                          items: _materials,
                          onChanged: (v) => setState(() {
                            _selectedMaterial = v;
                            _syncDescription();
                          }),
                          onAddPressed: () => _onAddAttr(
                            "Chất liệu",
                            _materials,
                            "materials",
                            (v) => _selectedMaterial = v,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ProductDropdown(
                                label: "Kiểu cổ",
                                value: _selectedNeckStyle,
                                items: _neckStyles,
                                onChanged: (v) => setState(() {
                                  _selectedNeckStyle = v;
                                  _syncDescription();
                                }),
                                onAddPressed: () => _onAddAttr(
                                  "Kiểu cổ",
                                  _neckStyles,
                                  "neck_styles",
                                  (v) => _selectedNeckStyle = v,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ProductDropdown(
                                label: "Kiểu tay áo",
                                value: _selectedSleeveStyle,
                                items: _sleeveStyles,
                                onChanged: (v) => setState(() {
                                  _selectedSleeveStyle = v;
                                  _syncDescription();
                                }),
                                onAddPressed: () => _onAddAttr(
                                  "Kiểu tay áo",
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
