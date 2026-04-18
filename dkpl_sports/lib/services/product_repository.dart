import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/inventory_model.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';

/// Repository đóng vai trò tải và ánh xạ (mapping) toàn bộ dữ liệu sản phẩm.
/// Tối ưu hiệu năng bằng cách sử dụng bộ nhớ đệm (Cache).
class ProductRepository {
  // Bộ nhớ đệm giữ danh sách sản phẩm sau lần tải đầu tiên.
  // Tránh việc gọi API liên tục mỗi khi chuyển màn hình gây tốn lượt read Firebase.
  static List<ProductModel>? _cache;

  static List<ProductModel> get cache => _cache ?? const [];

  /// Tải toàn bộ danh mục sản phẩm từ Firestore và ráp nối các bảng liên quan.
  static Future<List<ProductModel>> loadProducts() async {
    // Nếu đã có cache thì trả về luôn, không gọi network nữa
    if (_cache != null) return _cache!;

    final firestore = FirebaseFirestore.instance;
    
    // Gửi 4 truy vấn song song (có thể tối ưu bằng Future.wait để nhanh hơn)
    final productsSnap = await firestore.collection(FirebaseCollections.products).get();
    final variantSnap = await firestore.collection(FirebaseCollections.productVariants).get();
    final inventorySnap = await firestore.collection(FirebaseCollections.inventory).get();
    final imagesSnap = await firestore.collection(FirebaseCollections.productImages).get();

    // 1. Gom nhóm Tồn kho theo variantId
    final inventoryByVariantId = <String, int>{};
    for (final doc in inventorySnap.docs) {
      final model = InventoryModel.fromMap({
        'id': doc.id,
        ...doc.data(),
      });
      if (model.variantId.isNotEmpty) {
        inventoryByVariantId[model.variantId] = model.quantity;
      }
    }

    // 2. Gom nhóm Các biến thể (Size/Color) theo productId và gán số lượng tồn kho vào
    final variantsByProductId = <String, List<ProductVariantModel>>{};
    for (final doc in variantSnap.docs) {
      final data = doc.data();
      final variant = ProductVariantModel.fromMap({
        'id': doc.id,
        'productId': (data['productId'] ?? '').toString(),
        'size': (data['size'] ?? '').toString(),
        'colorId': (data['colorId'] ?? '').toString(),
        'price': data['price'],
        'quantity': inventoryByVariantId[doc.id] ?? 0, // Nhặt tồn kho tương ứng
      });
      if (variant.productId.isEmpty) continue;
      variantsByProductId.putIfAbsent(variant.productId, () => []).add(variant);
    }

    // 3. Gom nhóm Ảnh theo productId
    final imagesByProductId = <String, List<String>>{};
    for (final doc in imagesSnap.docs) {
      final data = doc.data();
      final productId = (data['productId'] ?? '').toString();
      final url = (data['imageUrl'] ?? '').toString();
      if (productId.isEmpty || url.isEmpty) continue;
      imagesByProductId.putIfAbsent(productId, () => []).add(url);
    }

    // 4. Lắp ráp dữ liệu cuối cùng cho đối tượng ProductModel
    final products = <ProductModel>[];
    for (final doc in productsSnap.docs) {
      final data = doc.data();
      final images = imagesByProductId[doc.id] ?? const <String>[];

      products.add(
        ProductModel.fromMap(
          {
            'id': doc.id,
            ...data,
          },
          images: images,
          variants: variantsByProductId[doc.id] ?? const <ProductVariantModel>[],
        ),
      );
    }

    // Lưu vào bộ nhớ đệm
    _cache = products;
    return products;
  }
}