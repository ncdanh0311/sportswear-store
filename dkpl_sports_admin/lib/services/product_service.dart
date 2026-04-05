import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<Map<String, dynamic>> fetchAppConfig() async {
    final categories = await _fetchNames('categories');
    final sports = await _fetchNames('sports');
    final brands = await _fetchNames('brands');
    final materials = await _fetchNames('materials');
    final neckStyles = await _fetchNames('neck_styles');
    final sleeveStyles = await _fetchNames('sleeve_styles');
    final colors = await _fetchNames('colors');

    return {
      'categories': categories,
      'sports': sports,
      'brands': brands,
      'materials': materials,
      'neck_styles': neckStyles,
      'sleeve_styles': sleeveStyles,
      'colors': colors,
    };
  }

  Future<List<String>> _fetchNames(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs
        .map((e) => (e.data()['name'] ?? e.id).toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> addAttributeToConfig(String collection, String newValue) async {
    final id = newValue.trim();
    if (id.isEmpty) return;
    await _firestore.collection(collection).doc(id).set({
      'id': id,
      'name': newValue.trim(),
    });
  }

  Future<List<String>> uploadImages(List<File> images, {String? productId}) async {
    List<String> imageUrls = [];
    String id = productId ?? DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < images.length; i++) {
      File imageFile = images[i];
      if (!imageFile.existsSync()) continue;

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = "product_${id}_${timestamp}_$i.jpg";

      final storageRef = FirebaseStorage.instanceFor(
        bucket: "gs://dkpl-sports-storage",
      ).ref().child('uploads/products/$fileName');

      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      TaskSnapshot snapshot = await storageRef.putFile(imageFile, metadata);

      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    }
    return imageUrls;
  }

  Future<String> addProduct(Map<String, dynamic> data, {List<String> images = const []}) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    final docRef = _firestore.collection('products').doc();
    await docRef.set({
      'id': docRef.id,
      ...data,
    });

    if (images.isNotEmpty) {
      final batch = _firestore.batch();
      for (final url in images) {
        final imgRef = _firestore.collection('product_images').doc();
        batch.set(imgRef, {
          'id': imgRef.id,
          'productId': docRef.id,
          'imageUrl': url,
        });
      }
      await batch.commit();
    }

    return docRef.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _firestore.collection('products').doc(productId).update(data);
  }

  Future<void> replaceProductImages(String productId, List<String> images) async {
    final existing = await _firestore
        .collection('product_images')
        .where('productId', isEqualTo: productId)
        .get();

    final batch = _firestore.batch();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    for (final url in images) {
      final imgRef = _firestore.collection('product_images').doc();
      batch.set(imgRef, {
        'id': imgRef.id,
        'productId': productId,
        'imageUrl': url,
      });
    }
    await batch.commit();
  }

  Future<void> deleteProduct(String productId) async {
    final productRef = _firestore.collection('products').doc(productId);

    final variants = await _firestore
        .collection('product_variants')
        .where('productId', isEqualTo: productId)
        .get();
    final images = await _firestore
        .collection('product_images')
        .where('productId', isEqualTo: productId)
        .get();

    final batch = _firestore.batch();

    for (final doc in variants.docs) {
      batch.delete(doc.reference);
      batch.delete(_firestore.collection('inventory').doc(doc.id));
    }
    for (final doc in images.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(productRef);

    await batch.commit();
  }

  Future<DocumentSnapshot> getProduct(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  Stream<QuerySnapshot> getProductsStream() {
    return _firestore.collection('products').orderBy('createdAt', descending: true).snapshots();
  }

  Stream<DocumentSnapshot> getProductStream(String productId) {
    return _firestore.collection('products').doc(productId).snapshots();
  }

  Stream<List<String>> getProductImagesStream(String productId) {
    return _firestore
        .collection('product_images')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => (e.data()['imageUrl'] ?? '').toString()).toList());
  }

  Stream<List<Map<String, dynamic>>> getVariantsStream(String productId) {
    return _firestore
        .collection('product_variants')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .asyncMap((snapshot) async {
          final variantDocs = snapshot.docs;
          if (variantDocs.isEmpty) return <Map<String, dynamic>>[];

          final variantIds = variantDocs.map((doc) => doc.id).toList();
          final inventoryMap = await _fetchInventoryMap(variantIds);

          return variantDocs.map((doc) {
            final data = doc.data();
            final stock = inventoryMap[doc.id] ?? 0;
            return {
              'id': doc.id,
              ...data,
              'stock': stock,
            };
          }).toList();
        });
  }

  Future<void> addVariant(String productId, Map<String, dynamic> data) async {
    final stock = (data['stock'] ?? 0) as int;

    final variantRef = _firestore.collection('product_variants').doc();
    await variantRef.set({
      'id': variantRef.id,
      'productId': productId,
      'size': data['size'],
      'colorId': data['colorId'],
      'price': data['price'],
    });

    await _firestore.collection('inventory').doc(variantRef.id).set({
      'id': variantRef.id,
      'variantId': variantRef.id,
      'quantity': stock,
    });

    await _updateProductPriceRange(productId);
  }

  Future<void> updateVariant(String productId, String variantId, Map<String, dynamic> data) async {
    await _firestore.collection('product_variants').doc(variantId).update({
      'productId': productId,
      'size': data['size'],
      'colorId': data['colorId'],
      'price': data['price'],
    });

    if (data.containsKey('stock')) {
      await _firestore.collection('inventory').doc(variantId).set({
        'id': variantId,
        'variantId': variantId,
        'quantity': data['stock'],
      }, SetOptions(merge: true));
    }

    await _updateProductPriceRange(productId);
  }

  Future<void> deleteVariant(String productId, String variantId) async {
    await _firestore.collection('product_variants').doc(variantId).delete();
    await _firestore.collection('inventory').doc(variantId).delete();
    await _updateProductPriceRange(productId);
  }

  Future<void> _updateProductPriceRange(String productId) async {
    final snapshot = await _firestore
        .collection('product_variants')
        .where('productId', isEqualTo: productId)
        .get();

    if (snapshot.docs.isEmpty) {
      await _firestore.collection('products').doc(productId).update({
        'minPrice': 0,
        'maxPrice': 0,
      });
      return;
    }

    final prices = snapshot.docs
        .map((doc) => (doc.data()['price'] as num?)?.toDouble() ?? 0)
        .toList();
    double minPrice = prices.reduce((curr, next) => curr < next ? curr : next);
    double maxPrice = prices.reduce((curr, next) => curr > next ? curr : next);

    await _firestore.collection('products').doc(productId).update({
      'minPrice': minPrice,
      'maxPrice': maxPrice,
    });
  }

  Future<Map<String, int>> _fetchInventoryMap(List<String> variantIds) async {
    if (variantIds.isEmpty) return {};
    final Map<String, int> result = {};

    final chunks = <List<String>>[];
    for (var i = 0; i < variantIds.length; i += 10) {
      chunks.add(variantIds.sublist(i, i + 10 > variantIds.length ? variantIds.length : i + 10));
    }

    for (final chunk in chunks) {
      final snap = await _firestore
          .collection('inventory')
          .where('variantId', whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final variantId = (data['variantId'] ?? doc.id).toString();
        final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
        result[variantId] = quantity;
      }
    }
    return result;
  }

  Stream<QuerySnapshot> getEventsStream() {
    return _firestore.collection('events').orderBy('startDate', descending: true).snapshots();
  }

  Future<void> createEvent(Map<String, dynamic> data) async {
    final docRef = _firestore.collection('events').doc();
    await docRef.set({
      'id': docRef.id,
      ...data,
    });
  }

  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    await _firestore.collection('events').doc(eventId).update(data);
  }

  Stream<QuerySnapshot> getVouchersStream() {
    return _firestore.collection('vouchers').orderBy('code', descending: false).snapshots();
  }

  Future<void> addVoucher(Map<String, dynamic> data) async {
    final docRef = _firestore.collection('vouchers').doc();
    await docRef.set({
      'id': docRef.id,
      ...data,
    });
  }

  Future<void> updateVoucherStatus(String voucherId, bool isActive) async {
    await _firestore.collection('vouchers').doc(voucherId).update({
      'isActive': isActive,
    });
  }

  Future<void> updateVoucher(String voucherId, Map<String, dynamic> data) async {
    await _firestore.collection('vouchers').doc(voucherId).update(data);
  }
}
