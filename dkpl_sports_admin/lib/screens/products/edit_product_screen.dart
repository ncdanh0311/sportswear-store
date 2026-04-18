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
  // Nhận vào productID để biết đang sửa sản phẩm nào
  final String productID;
  const EditProductScreen({Key? key, required this.productID}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ProductService _productService = ProductService();

  // Controllers cho các trường văn bản
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // Biến lưu trữ giá trị đang được chọn của các Dropdown
  String? _selectedCategory, _selectedSport, _selectedBrand;
  String? _selectedMaterial, _selectedNeckStyle, _selectedSleeveStyle;
  
  // Danh sách các tùy chọn cho Dropdown
  List<String> _categories = [], _sports = [], _brands = [];
  List<String> _materials = [], _neckStyles = [], _sleeveStyles = [];

  // 💡 QUAN TRỌNG: Tách biệt danh sách ảnh cũ và ảnh mới
  // Ảnh cũ là URL lấy từ Firebase (Network)
  List<String> _oldImageUrls = [];
  // Ảnh mới là File lấy từ bộ nhớ điện thoại (Local File)
  final List<File> _newImageFiles = [];
  
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initData(); // Gọi hàm khởi tạo dữ liệu khi mở màn hình
  }

  /// Tải dữ liệu cấu hình và dữ liệu hiện tại của sản phẩm để đổ lên UI
  Future<void> _initData() async {
    // Lấy song song/tuần tự cấu hình, thông tin sản phẩm và danh sách ảnh cũ
    final config = await _productService.fetchAppConfig();
    final doc = await _productService.getProduct(widget.productID);
    // Lấy danh sách URL ảnh từ stream (chỉ lấy event đầu tiên - first)
    final images = await _productService.getProductImagesStream(widget.productID).first;

    // Nếu widget vẫn còn trên cây UI và document tồn tại
    if (mounted && doc.exists) {
      final data = doc.data() as Map<String, dynamic>;

      setState(() {
        // Đổ dữ liệu vào các danh sách Dropdown
        _categories = List<String>.from(config['categories'] ?? []);
        _sports = List<String>.from(config['sports'] ?? []);
        _brands = List<String>.from(config['brands'] ?? []);
        _materials = List<String>.from(config['materials'] ?? []);
        _neckStyles = List<String>.from(config['neck_styles'] ?? []);
        _sleeveStyles = List<String>.from(config['sleeve_styles'] ?? []);

        // Điền dữ liệu cũ vào các ô Text và Dropdown
        _nameController.text = data['name'] ?? '';
        _descController.text = data['description'] ?? '';
        _selectedCategory = data['categoryId'];
        _selectedSport = data['sportId'];
        _selectedBrand = data['brandId'];
        _selectedMaterial = data['materialId'];
        _selectedNeckStyle = data['neckStyleId'];
        _selectedSleeveStyle = data['sleeveStyleId'];

        _oldImageUrls = images; // Lưu mảng link ảnh cũ
        _isLoading = false;     // Tắt loading
        _syncDescription();     // Chạy đồng bộ mô tả một lần cho chắc chắn
      });
    }
  }

  /// Hàm thêm thuộc tính mới (giống bên AddProduct)
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

  /// Tự động tạo chuỗi mô tả
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

  /// Xử lý khi người dùng bấm "Lưu thay đổi"
  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    try {
      // 1. CHỈ upload những ảnh MỚI được chọn (tiết kiệm băng thông và thời gian)
      List<String> newUrls = await _productService.uploadImages(
        _newImageFiles,
        productId: widget.productID,
      );

      // 2. Gộp ảnh cũ (những ảnh không bị người dùng bấm xóa) và ảnh mới upload thành 1 mảng final
      List<String> finalImages = [..._oldImageUrls, ...newUrls];
      _syncDescription();

      // 3. Tạo Map chứa data mới cập nhật
      final data = {
        "name": _nameController.text.trim(),
        "description": _descController.text,
        "categoryId": _selectedCategory,
        "sportId": _selectedSport,
        "brandId": _selectedBrand,
        "materialId": _selectedMaterial,
        "neckStyleId": _selectedNeckStyle,
        "sleeveStyleId": _selectedSleeveStyle,
        "thumbnail": finalImages.isNotEmpty ? finalImages[0] : "", // Lấy ảnh đầu làm thumbnail
      };

      // 4. Gọi Service update product chính
      await _productService.updateProduct(widget.productID, data);
      
      // 5. Thay thế toàn bộ Collection ảnh bằng mảng finalImages mới
      await _productService.replaceProductImages(widget.productID, finalImages);

      // Thành công thì thông báo và thoát màn hình
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật!")));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// Hàm chọn ảnh mới từ thư viện điện thoại
  Future<void> _pickImage() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    // Thêm vào mảng ảnh mới (chưa phải URL mạng)
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
                  const SectionTitle(title: "Hình ảnh"),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Nút thêm ảnh mới
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 90,
                            color: Colors.white10,
                            child: const Icon(Icons.add_a_photo, color: Colors.white),
                          ),
                        ),
                        
                        // --- HIỂN THỊ ẢNH CŨ (TỪ FIREBASE) ---
                        ..._oldImageUrls.asMap().entries.map(
                          (e) => Stack(
                            children: [
                              // Dùng Image.network vì đây là URL mạng
                              Image.network(e.value, width: 90, height: 110, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                child: GestureDetector(
                                  // Khi bấm nút xóa, chỉ cần bỏ URL ra khỏi mảng _oldImageUrls
                                  onTap: () => setState(() => _oldImageUrls.removeAt(e.key)),
                                  child: const Icon(Icons.cancel, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // --- HIỂN THỊ ẢNH MỚI (TỪ ĐIỆN THOẠI) ---
                        ..._newImageFiles.asMap().entries.map(
                          (e) => Stack(
                            children: [
                              // Dùng Image.file vì đây là đường dẫn nội bộ
                              Image.file(e.value, width: 90, height: 110, fit: BoxFit.cover),
                              Positioned(
                                right: 0,
                                child: GestureDetector(
                                  // Khi xóa, gỡ File ra khỏi mảng
                                  onTap: () => setState(() => _newImageFiles.removeAt(e.key)),
                                  child: const Icon(Icons.cancel, color: Colors.red),
                                ),
                              ),
                              // 💡 Đánh dấu "NEW" để người dùng dễ phân biệt đâu là ảnh vừa thêm
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

                  // Các phần form thông tin bên dưới tương tự màn hình AddProductScreen
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
                        ProductDropdown(
                          label: "Brand",
                          value: _selectedBrand,
                          items: _brands,
                          onChanged: (v) => setState(() => _selectedBrand = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionTitle(title: "Chi tiết"),
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
                  DKPLButton(text: "Lưu thay đổi", onPressed: _handleUpdate),
                ],
              ),
            ),
    );
  }
}