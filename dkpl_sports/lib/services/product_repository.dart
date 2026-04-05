import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/inventory_model.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';

class ProductRepository {
  static List<ProductModel>? _cache;

  static List<ProductModel> get cache => _cache ?? const [];

  static Future<List<ProductModel>> loadProducts() async {
    if (_cache != null) return _cache!;

    final firestore = FirebaseFirestore.instance;
    final productsSnap = await firestore.collection(FirebaseCollections.products).get();
    final variantSnap =
        await firestore.collection(FirebaseCollections.productVariants).get();
    final inventorySnap =
        await firestore.collection(FirebaseCollections.inventory).get();
    final imagesSnap =
        await firestore.collection(FirebaseCollections.productImages).get();

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

    final variantsByProductId = <String, List<ProductVariantModel>>{};
    for (final doc in variantSnap.docs) {
      final data = doc.data();
      final variant = ProductVariantModel.fromMap({
        'id': doc.id,
        'productId': (data['productId'] ?? '').toString(),
        'size': (data['size'] ?? '').toString(),
        'colorId': (data['colorId'] ?? '').toString(),
        'price': data['price'],
        'quantity': inventoryByVariantId[doc.id] ?? 0,
      });
      if (variant.productId.isEmpty) continue;
      variantsByProductId.putIfAbsent(variant.productId, () => []).add(variant);
    }

    final imagesByProductId = <String, List<String>>{};
    for (final doc in imagesSnap.docs) {
      final data = doc.data();
      final productId = (data['productId'] ?? '').toString();
      final url = (data['imageUrl'] ?? '').toString();
      if (productId.isEmpty || url.isEmpty) continue;
      imagesByProductId.putIfAbsent(productId, () => []).add(url);
    }

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

    _cache = products;
    return products;
  }
}
