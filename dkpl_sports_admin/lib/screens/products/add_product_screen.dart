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
  // Khởi tạo service xử lý logic database
  final ProductService _productService = ProductService();

  // Controllers để quản lý text nhập vào cho Tên và Mô tả
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  // Các biến lưu giá trị được chọn (selected values) từ Dropdown
  String? _selectedCategory, _selectedSport, _selectedBrand;
  String? _selectedMaterial, _selectedNeckStyle, _selectedSleeveStyle;
  
  // Các mảng lưu trữ dữ liệu cấu hình (danh sách lựa chọn) lấy từ Firestore
  List<String> _categories = [], _sports = [], _brands = [];
  List<String> _materials = [], _neckStyles = [], _sleeveStyles = [];

  // Danh sách các file ảnh đã chọn từ thiết bị
  final List<File> _selectedImages = [];
  
  // Instance của ImagePicker dùng để mở thư viện ảnh của thiết bị
  final ImagePicker _picker = ImagePicker();
  
  // Biến trạng thái hiển thị vòng xoay loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Vừa vào màn hình là gọi hàm tải dữ liệu cấu hình (cho các dropdown) ngay
    _fetchConfig();
  }

  /// Hàm tải cấu hình từ Firebase (các danh mục, thương hiệu, chất liệu...)
  Future<void> _fetchConfig() async {
    try {
      final data = await _productService.fetchAppConfig();
      if (mounted) {
        setState(() {
          // Parse và gán dữ liệu từ Map trả về vào các List tương ứng
          _categories = (data['categories'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _sports = (data['sports'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _brands = (data['brands'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _materials = (data['materials'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _neckStyles = (data['neck_styles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          _sleeveStyles = (data['sleeve_styles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
          
          _isLoading = false; // Tắt loading sau khi lấy data xong
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Báo lỗi nếu việc lấy dữ liệu cấu hình thất bại
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải danh mục: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Hàm xử lý khi người dùng muốn Thêm nhanh một thuộc tính mới (VD: Thêm 1 brand mới chưa có trong list)
  void _onAddAttr(String title, List<String> list, String collection, Function(String) onSet) {
    // Gọi một dialog (giả sử được định nghĩa ở widget khác) để nhập tên thuộc tính mới
    showAddAttributeDialog(
      context,
      title: title,
      onSave: (val) async {
        setState(() {
          list.add(val);  // Thêm vào danh sách ở local để hiển thị ngay lập tức
          onSet(val);     // Tự động set giá trị dropdown bằng giá trị vừa thêm
          _syncDescription(); // Cập nhật lại chuỗi mô tả tự động
        });
        // Gọi service lưu thuộc tính mới này lên Firestore để lần sau load lại vẫn còn
        await _productService.addAttributeToConfig(collection, val);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã thêm!")));
      },
    );
  }

  /// Tự động sinh ra đoạn text mô tả dựa trên các thông số chi tiết đã chọn
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
    // Ghép các dòng lại với nhau bằng dấu xuống dòng
    return lines.join("\n");
  }

  /// Đồng bộ (cập nhật) text trong Text Box Mô tả
  void _syncDescription() {
    _descController.text = _buildAutoDescription();
  }

  /// Hàm xử lý khi bấm nút "Tiếp tục"
  Future<void> _handleSave() async {
    // Validate cơ bản: Bắt buộc phải có tên sản phẩm và ít nhất 1 hình ảnh
    if (_nameController.text.isEmpty || _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thiếu tên hoặc ảnh!"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true); // Bật loading che toàn màn hình
    try {
      // 1. Upload mảng hình ảnh lên Firebase Storage và lấy về mảng URL
      List<String> images = await _productService.uploadImages(_selectedImages);
      _syncDescription(); // Đảm bảo description được update lần cuối

      // 2. Chuẩn bị Map dữ liệu sản phẩm để lưu
      final data = {
        "name": _nameController.text.trim(),
        "description": _descController.text.trim(),
        "categoryId": _selectedCategory,
        "brandId": _selectedBrand,
        "sportId": _selectedSport,
        "materialId": _selectedMaterial,
        "neckStyleId": _selectedNeckStyle,
        "sleeveStyleId": _selectedSleeveStyle,
        "thumbnail": images.isNotEmpty ? images[0] : "", // Lấy ảnh đầu tiên làm thumbnail
        "isActive": true,     // Mặc định sản phẩm mới tạo là hoạt động
        "minPrice": 0,        // Sẽ được update tự động sau khi thêm biến thể (variant)
        "maxPrice": 0,
        "rating": 0,
        "ratingCount": 0,
        "sold": 0,
      };

      // 3. Gọi service thêm sản phẩm vào Firestore, truyền kèm danh sách ảnh URL để lưu vào Batch
      String newId = await _productService.addProduct(data, images: images);

      if (mounted) {
        // 4. Nếu thành công, điều hướng (thay thế) màn hình hiện tại bằng màn hình Quản lý Biến thể
        // Để người dùng tiếp tục nhập size, màu sắc và số lượng tồn kho cho sản phẩm vừa tạo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ManageVariantsScreen(productId: newId, productName: _nameController.text),
          ),
        );
      }
    } catch (e) {
      // Nếu có lỗi trong quá trình upload ảnh hoặc lưu DB
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      setState(() => _isLoading = false);
    }
  }

  /// Mở thư viện ảnh (gallery) cho phép chọn nhiều ảnh cùng lúc
  Future<void> _pickImage() async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null) {
      // Chuyển đổi từ XFile sang File và thêm vào mảng _selectedImages
      setState(() => _selectedImages.addAll(images.map((e) => File(e.path))));
    }
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
          ? const Center(child: CircularProgressIndicator()) // Hiện loading nếu đang chờ DB hoặc đang upload
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECTION 1: HÌNH ẢNH ---
                  const SectionTitle(title: "1. Hình ảnh"),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    // Dùng ListView horizontal để cuộn ngang danh sách hình ảnh
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // Nút bấm (+) để mở thư viện ảnh
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 90,
                            color: Colors.white10,
                            child: const Icon(Icons.add_a_photo, color: Colors.white),
                          ),
                        ),
                        // Duyệt qua mảng ảnh đã chọn để hiển thị
                        ..._selectedImages.asMap().entries.map(
                          (e) => Stack(
                            children: [
                              // Hiển thị ảnh từ local File
                              Image.file(e.value, width: 90, height: 110, fit: BoxFit.cover),
                              // Nút (x) màu đỏ ở góc trên bên phải để xóa ảnh khỏi mảng
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

                  // --- SECTION 2: THÔNG TIN CHUNG ---
                  const SectionTitle(title: "2. Thông tin chung"),
                  DKPLCard(
                    child: Column(
                      children: [
                        // Ô nhập Text cho Tên Sản phẩm
                        ProductTextField(
                          label: "Tên sản phẩm",
                          controller: _nameController,
                          hint: "VD: Áo đấu...",
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Dropdown Loại SP
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
                            // Dropdown Môn thể thao
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
                        // Dropdown Thương hiệu
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

                  // --- SECTION 3: CHI TIẾT SẢN PHẨM ---
                  const SectionTitle(title: "3. Chi tiết"),
                  DKPLCard(
                    child: Column(
                      children: [
                        // Dropdown Chất liệu (Có kèm theo việc update text Mô tả tự động khi chọn)
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
                        // Box hiển thị mô tả tự động (có thể sửa tay do dùng TextField)
                        ProductTextField(label: "Mô tả", controller: _descController, maxLines: 3),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Nút chuyển bước, gọi hàm lưu sản phẩm và nhảy sang màn hình thêm Biến thể
                  DKPLButton(text: "Tiếp tục (Nhập biến thể)", onPressed: _handleSave),
                ],
              ),
            ),
    );
  }
}