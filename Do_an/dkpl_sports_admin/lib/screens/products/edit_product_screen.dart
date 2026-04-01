import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:dkpl_sports_admin/core/widgets/product_widgets.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_button.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/app_styles.dart';

class EditProductScreen extends StatefulWidget {
  final String productID;
  const EditProductScreen({Key? key, required this.productID}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ProductService _productService = ProductService();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _colorsController = TextEditingController();

  String? _selectedCategory, _selectedSport, _selectedBrands;
  String? _selectedNeckStyle, _selectedSleeveStyle;
  List<String> _categories = [], _sports = [], _brands = [], _neckStyles = [], _sleeveStyles = [];

  // Image Logic
  List<String> _oldImageUrls = [];
  final List<File> _newImageFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final config = await _productService.fetchAppConfig();
    final doc = await _productService.getProduct(widget.productID);

    if (mounted && doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final specs = data['common_specs'] as Map<String, dynamic>?;

      setState(() {
        // Config Data
        _categories = List<String>.from(config['categories'] ?? []);
        _sports = List<String>.from(config['sports'] ?? []);
        _brands = List<String>.from(config['brands'] ?? []);
        _neckStyles = List<String>.from(config['neck_styles'] ?? []);
        _sleeveStyles = List<String>.from(config['sleeve_styles'] ?? []);

        // Product Data
        _nameController.text = data['name'] ?? '';
        _descController.text = data['description'] ?? '';
        _colorsController.text = data['color_name'] ?? '';
        _selectedCategory = data['category_id'];
        _selectedSport = data['sport_id'];
        _selectedBrands = data['brand'];

        // Nested Data
        _selectedNeckStyle = specs?['neck_style'];
        _selectedSleeveStyle = specs?['sleeve_style'];

        _oldImageUrls = List<String>.from(data['images'] ?? []);
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    try {
      // 1. Upload ảnh mới
      List<String> newUrls = await _productService.uploadImages(
        _newImageFiles,
        productId: widget.productID,
      );

      // 2. Gộp ảnh cũ + mới
      List<String> finalImages = [..._oldImageUrls, ...newUrls];

      final data = {
        "name": _nameController.text.trim(),
        "search_keywords": _nameController.text.toLowerCase().split(" "),
        "category_id": _selectedCategory,
        "sport_id": _selectedSport,
        "brand": _selectedBrands,
        "color_name": _colorsController.text,
        "description": _descController.text,
        "common_specs": {"neck_style": _selectedNeckStyle, "sleeve_style": _selectedSleeveStyle},
        "images": finalImages,
        "thumbnail": finalImages.isNotEmpty ? finalImages[0] : "",
      };

      await _productService.updateProduct(widget.productID, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật!")));
        Navigator.pop(context);
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) setState(() => _newImageFiles.addAll(images.map((e) => File(e.path))));
  }

  @override
  Widget build(BuildContext context) {
    return BaseBackground(
      appBar: AppBar(
        title: const Text('Sửa Sản Phẩm', style: AppStyles.h2),
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
                  // --- IMAGE LIST (HYBRID) ---
                  const SectionTitle(title: "Hình ảnh"),
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

                        // Old Images
                        ..._oldImageUrls.asMap().entries.map(
                          (e) => Stack(
                            children: [
                              Image.network(e.value, width: 90, height: 110, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _oldImageUrls.removeAt(e.key)),
                                  child: const Icon(Icons.cancel, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // New Images
                        ..._newImageFiles.asMap().entries.map(
                          (e) => Stack(
                            children: [
                              Image.file(e.value, width: 90, height: 110, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _newImageFiles.removeAt(e.key)),
                                  child: const Icon(Icons.cancel, color: Colors.red),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: Container(
                                  color: Colors.green,
                                  child: const Text("NEW", style: TextStyle(fontSize: 10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- INFO ---
                  const SectionTitle(title: "Thông tin"),
                  DKPLCard(
                    child: Column(
                      children: [
                        ProductTextField(label: "Tên", controller: _nameController),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ProductDropdown(
                                label: "Loại",
                                value: _selectedCategory,
                                items: _categories,
                                onChanged: (v) => setState(() => _selectedCategory = v),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ProductDropdown(
                                label: "Môn",
                                value: _selectedSport,
                                items: _sports,
                                onChanged: (v) => setState(() => _selectedSport = v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ProductTextField(label: "Màu", controller: _colorsController),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ProductDropdown(
                                label: "Brand",
                                value: _selectedBrands,
                                items: _brands,
                                onChanged: (v) => setState(() => _selectedBrands = v),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- SPECS ---
                  const SectionTitle(title: "Chi tiết"),
                  DKPLCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ProductDropdown(
                                label: "Cổ",
                                value: _selectedNeckStyle,
                                items: _neckStyles,
                                onChanged: (v) => setState(() => _selectedNeckStyle = v),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ProductDropdown(
                                label: "Tay",
                                value: _selectedSleeveStyle,
                                items: _sleeveStyles,
                                onChanged: (v) => setState(() => _selectedSleeveStyle = v),
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
                  DKPLButton(text: "Lưu thay đổi", onPressed: _handleUpdate),
                ],
              ),
            ),
    );
  }
}

