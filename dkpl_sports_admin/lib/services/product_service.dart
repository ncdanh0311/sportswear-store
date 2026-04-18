import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProductService {
  // Khởi tạo các instance của Firestore và Firebase Storage
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Hàm lấy các cấu hình/thuộc tính cơ bản của ứng dụng (dùng cho các dropdown chọn loại, hãng, màu...)
  Future<Map<String, dynamic>> fetchAppConfig() async {
    // Chạy song song hoặc tuần tự các truy vấn lấy danh sách thuộc tính
    final categories = await _fetchNames('categories');
    final sports = await _fetchNames('sports');
    final brands = await _fetchNames('brands');
    final materials = await _fetchNames('materials');
    final neckStyles = await _fetchNames('neck_styles');
    final sleeveStyles = await _fetchNames('sleeve_styles');
    final colors = await _fetchNames('colors');

    // Trả về một Map chứa toàn bộ dữ liệu cấu hình
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

  /// Hàm phụ trợ (Helper): Lấy danh sách tên từ một collection cụ thể
  Future<List<String>> _fetchNames(String collection) async {
    final snapshot = await _firestore.collection(collection).get();
    return snapshot.docs
        // Lấy trường 'name', nếu không có thì lấy Document ID
        .map((e) => (e.data()['name'] ?? e.id).toString())
        .where((e) => e.isNotEmpty) // Lọc bỏ các giá trị rỗng
        .toList();
  }

  /// Hàm thêm một thuộc tính mới vào cấu hình (ví dụ: thêm một thương hiệu mới)
  Future<void> addAttributeToConfig(String collection, String newValue) async {
    final id = newValue.trim();
    if (id.isEmpty) return;
    
    // Lưu vào Firestore với Document ID chính là tên thuộc tính (đã trim)
    await _firestore.collection(collection).doc(id).set({
      'id': id,
      'name': newValue.trim(),
    });
  }

  /// Hàm upload danh sách hình ảnh lên Firebase Storage
  Future<List<String>> uploadImages(List<File> images, {String? productId}) async {
    List<String> imageUrls = [];
    // Nếu chưa có productId thì dùng timestamp làm ID tạm
    String id = productId ?? DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < images.length; i++) {
      File imageFile = images[i];
      if (!imageFile.existsSync()) continue; // Bỏ qua nếu file không tồn tại

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      // Đặt tên file đảm bảo tính duy nhất
      String fileName = "product_${id}_${timestamp}_$i.jpg";

      // Khởi tạo reference tới Storage với bucket chỉ định
      final storageRef = FirebaseStorage.instanceFor(
        bucket: "gs://dkpl-sports-storage",
      ).ref().child('uploads/products/$fileName');

      // Set metadata định dạng ảnh là jpeg
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      // Thực hiện upload
      TaskSnapshot snapshot = await storageRef.putFile(imageFile, metadata);

      // Nếu upload thành công, lấy URL tải xuống và đưa vào mảng
      if (snapshot.state == TaskState.success) {
        String downloadUrl = await snapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    }
    return imageUrls; // Trả về danh sách URL ảnh đã upload
  }

  /// Hàm thêm sản phẩm mới
  Future<String> addProduct(Map<String, dynamic> data, {List<String> images = const []}) async {
    // Thêm trường thời gian tạo tự động từ server Firebase
    data['createdAt'] = FieldValue.serverTimestamp();
    
    // Tạo reference mới cho sản phẩm (sẽ tự gen ra một ID ngẫu nhiên)
    final docRef = _firestore.collection('products').doc();
    
    // Lưu thông tin sản phẩm
    await docRef.set({
      'id': docRef.id,
      ...data,
    });

    // Nếu có ảnh, sử dụng Batch Write để ghi toàn bộ URL ảnh vào collection 'product_images' cùng một lúc
    if (images.isNotEmpty) {
      final batch = _firestore.batch();
      for (final url in images) {
        final imgRef = _firestore.collection('product_images').doc();
        batch.set(imgRef, {
          'id': imgRef.id,
          'productId': docRef.id, // Liên kết ảnh với ID sản phẩm vừa tạo
          'imageUrl': url,
        });
      }
      await batch.commit(); // Thực thi Batch
    }

    return docRef.id; // Trả về ID sản phẩm
  }

  /// Cập nhật thông tin cơ bản của sản phẩm
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _firestore.collection('products').doc(productId).update(data);
  }

  /// Thay thế toàn bộ hình ảnh của một sản phẩm
  Future<void> replaceProductImages(String productId, List<String> images) async {
    // 1. Lấy danh sách ảnh cũ
    final existing = await _firestore
        .collection('product_images')
        .where('productId', isEqualTo: productId)
        .get();

    final batch = _firestore.batch();
    
    // 2. Thêm lệnh xóa các document ảnh cũ vào Batch
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }
    
    // 3. Thêm lệnh tạo document ảnh mới vào Batch
    for (final url in images) {
      final imgRef = _firestore.collection('product_images').doc();
      batch.set(imgRef, {
        'id': imgRef.id,
        'productId': productId,
        'imageUrl': url,
      });
    }
    
    // 4. Thực thi đồng thời việc xóa ảnh cũ và thêm ảnh mới
    await batch.commit();
  }

  /// Xóa hoàn toàn một sản phẩm và các dữ liệu liên quan (Cascade Delete)
  Future<void> deleteProduct(String productId) async {
    final productRef = _firestore.collection('products').doc(productId);

    // Tìm các biến thể (variant) của sản phẩm
    final variants = await _firestore
        .collection('product_variants')
        .where('productId', isEqualTo: productId)
        .get();
        
    // Tìm các ảnh của sản phẩm
    final images = await _firestore
        .collection('product_images')
        .where('productId', isEqualTo: productId)
        .get();

    final batch = _firestore.batch();

    // Đưa lệnh xóa biến thể và xóa kho (inventory) tương ứng vào Batch
    for (final doc in variants.docs) {
      batch.delete(doc.reference);
      batch.delete(_firestore.collection('inventory').doc(doc.id));
    }
    
    // Đưa lệnh xóa dữ liệu ảnh vào Batch
    for (final doc in images.docs) {
      batch.delete(doc.reference);
    }
    
    // Đưa lệnh xóa document sản phẩm chính vào Batch
    batch.delete(productRef);

    // Thực thi xóa toàn bộ cùng lúc
    await batch.commit();
  }

  // Lấy dữ liệu 1 sản phẩm (Future - Lấy 1 lần)
  Future<DocumentSnapshot> getProduct(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  // Lắng nghe danh sách toàn bộ sản phẩm (Stream - Lắng nghe realtime), xếp theo thời gian tạo giảm dần
  Stream<QuerySnapshot> getProductsStream() {
    return _firestore.collection('products').orderBy('createdAt', descending: true).snapshots();
  }

  // Lắng nghe dữ liệu của 1 sản phẩm cụ thể
  Stream<DocumentSnapshot> getProductStream(String productId) {
    return _firestore.collection('products').doc(productId).snapshots();
  }

  // Lắng nghe danh sách ảnh của 1 sản phẩm, trả về Stream<List<String>> thay vì QuerySnapshot
  Stream<List<String>> getProductImagesStream(String productId) {
    return _firestore
        .collection('product_images')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((e) => (e.data()['imageUrl'] ?? '').toString()).toList());
  }

  /// Lắng nghe danh sách biến thể (variant) của sản phẩm, ĐỒNG THỜI map (kết hợp) với số lượng tồn kho (inventory)
  Stream<List<Map<String, dynamic>>> getVariantsStream(String productId) {
    return _firestore
        .collection('product_variants')
        .where('productId', isEqualTo: productId)
        .snapshots()
        .asyncMap((snapshot) async { // Sử dụng asyncMap vì bên trong cần gọi Future (_fetchInventoryMap)
          final variantDocs = snapshot.docs;
          if (variantDocs.isEmpty) return <Map<String, dynamic>>[];

          final variantIds = variantDocs.map((doc) => doc.id).toList();
          
          // Đi lấy số lượng tồn kho của các variant này
          final inventoryMap = await _fetchInventoryMap(variantIds);

          // Trộn dữ liệu variant với dữ liệu tồn kho (stock) tương ứng
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

  /// Thêm một biến thể (size, màu sắc) cho sản phẩm
  Future<void> addVariant(String productId, Map<String, dynamic> data) async {
    final stock = (data['stock'] ?? 0) as int;

    // 1. Tạo biến thể
    final variantRef = _firestore.collection('product_variants').doc();
    await variantRef.set({
      'id': variantRef.id,
      'productId': productId,
      'size': data['size'],
      'colorId': data['colorId'],
      'price': data['price'],
    });

    // 2. Tạo record kho hàng (inventory) tương ứng, lấy variantId làm Document ID luôn
    await _firestore.collection('inventory').doc(variantRef.id).set({
      'id': variantRef.id,
      'variantId': variantRef.id,
      'quantity': stock,
    });

    // 3. Cập nhật lại khoảng giá (minPrice, maxPrice) cho sản phẩm chính
    await _updateProductPriceRange(productId);
  }

  /// Cập nhật thông tin biến thể
  Future<void> updateVariant(String productId, String variantId, Map<String, dynamic> data) async {
    // 1. Cập nhật data biến thể
    await _firestore.collection('product_variants').doc(variantId).update({
      'productId': productId,
      'size': data['size'],
      'colorId': data['colorId'],
      'price': data['price'],
    });

    // 2. Nếu có truyền data 'stock' lên thì cập nhật lại số lượng tồn kho
    if (data.containsKey('stock')) {
      await _firestore.collection('inventory').doc(variantId).set({
        'id': variantId,
        'variantId': variantId,
        'quantity': data['stock'],
      }, SetOptions(merge: true)); // Dùng merge để không ghi đè mất các field khác (nếu có)
    }

    // 3. Cập nhật lại khoảng giá của sản phẩm chính
    await _updateProductPriceRange(productId);
  }

  /// Xóa biến thể và kho tương ứng
  Future<void> deleteVariant(String productId, String variantId) async {
    await _firestore.collection('product_variants').doc(variantId).delete();
    await _firestore.collection('inventory').doc(variantId).delete();
    await _updateProductPriceRange(productId);
  }

  /// Hàm phụ trợ: Tự động tính toán lại mức giá nhỏ nhất (minPrice) và lớn nhất (maxPrice) của 1 sản phẩm
  /// dựa trên giá của tất cả các biến thể của nó.
  Future<void> _updateProductPriceRange(String productId) async {
    final snapshot = await _firestore
        .collection('product_variants')
        .where('productId', isEqualTo: productId)
        .get();

    // Nếu sản phẩm không có biến thể nào, set giá trị về 0
    if (snapshot.docs.isEmpty) {
      await _firestore.collection('products').doc(productId).update({
        'minPrice': 0,
        'maxPrice': 0,
      });
      return;
    }

    // Lấy danh sách giá của các biến thể
    final prices = snapshot.docs
        .map((doc) => (doc.data()['price'] as num?)?.toDouble() ?? 0)
        .toList();
        
    // Tìm giá nhỏ nhất và lớn nhất
    double minPrice = prices.reduce((curr, next) => curr < next ? curr : next);
    double maxPrice = prices.reduce((curr, next) => curr > next ? curr : next);

    // Cập nhật vào document sản phẩm
    await _firestore.collection('products').doc(productId).update({
      'minPrice': minPrice,
      'maxPrice': maxPrice,
    });
  }

  /// Hàm phụ trợ: Lấy thông tin tồn kho cho một mảng các variantId
  Future<Map<String, int>> _fetchInventoryMap(List<String> variantIds) async {
    if (variantIds.isEmpty) return {};
    final Map<String, int> result = {};

    // Do Firebase Firestore giới hạn mệnh đề `whereIn` chỉ chấp nhận tối đa 10 phần tử,
    // ta phải chia nhỏ mảng variantIds ra thành các chunk (mảnh) nhỏ hơn (tối đa 10 ID/chunk)
    final chunks = <List<String>>[];
    for (var i = 0; i < variantIds.length; i += 10) {
      chunks.add(variantIds.sublist(i, i + 10 > variantIds.length ? variantIds.length : i + 10));
    }

    // Query từng chunk và gom kết quả lại
    for (final chunk in chunks) {
      final snap = await _firestore
          .collection('inventory')
          .where('variantId', whereIn: chunk)
          .get();
          
      for (final doc in snap.docs) {
        final data = doc.data();
        final variantId = (data['variantId'] ?? doc.id).toString();
        final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
        result[variantId] = quantity; // Map lại theo dạng: { "id_bien_the" : so_luong_ton }
      }
    }
    return result;
  }

  /// Tính tổng số lượng tồn kho của một sản phẩm (cộng tổng stock của tất cả các variants)
  Future<int> getTotalStockForProduct(String productId) async {
    final snapshot = await _firestore
        .collection('product_variants')
        .where('productId', isEqualTo: productId)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final variantIds = snapshot.docs.map((doc) => doc.id).toList();
    final inventoryMap = await _fetchInventoryMap(variantIds);
    
    int total = 0;
    for (final id in variantIds) {
      total += inventoryMap[id] ?? 0; // Cộng dồn
    }
    return total;
  }

  // --- CÁC HÀM XỬ LÝ SỰ KIỆN (EVENTS) VÀ VOUCHER ---

  // Lắng nghe danh sách sự kiện (sắp xếp theo ngày bắt đầu giảm dần)
  Stream<QuerySnapshot> getEventsStream() {
    return _firestore.collection('events').orderBy('startDate', descending: true).snapshots();
  }

  // Tạo sự kiện mới
  Future<void> createEvent(Map<String, dynamic> data) async {
    final docRef = _firestore.collection('events').doc();
    await docRef.set({
      'id': docRef.id,
      ...data,
    });
  }

  // Cập nhật sự kiện
  Future<void> updateEvent(String eventId, Map<String, dynamic> data) async {
    await _firestore.collection('events').doc(eventId).update(data);
  }

  // Lắng nghe danh sách voucher (sắp xếp theo mã code)
  Stream<QuerySnapshot> getVouchersStream() {
    return _firestore.collection('vouchers').orderBy('code', descending: false).snapshots();
  }

  // Thêm voucher mới
  Future<void> addVoucher(Map<String, dynamic> data) async {
    final docRef = _firestore.collection('vouchers').doc();
    await docRef.set({
      'id': docRef.id,
      ...data,
    });
  }

  // Bật/tắt trạng thái hoạt động của voucher
  Future<void> updateVoucherStatus(String voucherId, bool isActive) async {
    await _firestore.collection('vouchers').doc(voucherId).update({
      'isActive': isActive,
    });
  }

  // Cập nhật thông tin voucher
  Future<void> updateVoucher(String voucherId, Map<String, dynamic> data) async {
    await _firestore.collection('vouchers').doc(voucherId).update(data);
  }
}