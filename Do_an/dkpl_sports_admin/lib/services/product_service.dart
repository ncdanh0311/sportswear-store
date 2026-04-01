import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/event_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- 1. APP CONFIG (Lấy danh sách Dropdown) ---
  Future<Map<String, dynamic>> fetchAppConfig() async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('app_config').doc('attributes').get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print("Lỗi fetchAppConfig: $e");
      return {};
    }
  }

  // Thêm thuộc tính mới vào App Config (VD: Thêm Brand mới)
  Future<void> addAttributeToConfig(String fieldName, String newValue) async {
    await _firestore.collection('app_config').doc('attributes').update({
      fieldName: FieldValue.arrayUnion([newValue]),
    });
  }

  // --- 2. UPLOAD ẢNH ---
  Future<List<String>> uploadImages(List<File> images, {String? productId}) async {
    List<String> imageUrls = [];
    String id = productId ?? DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < images.length; i++) {
      File imageFile = images[i];
      if (!imageFile.existsSync()) continue;

      String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      String fileName = "product_${id}_${timestamp}_$i.jpg";

      // Lưu ý: Bucket phải đúng cấu hình của bạn
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

  // --- 3. SẢN PHẨM (CRUD) ---
  Future<String> addProduct(Map<String, dynamic> data) async {
    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();
    DocumentReference ref = await _firestore.collection('products').add(data);
    return ref.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _firestore.collection('products').doc(productId).update(data);
  }

  Future<DocumentSnapshot> getProduct(String productId) {
    return _firestore.collection('products').doc(productId).get();
  }

  Future<void> deleteVariant(String productId, String variantId) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .doc(variantId)
        .delete();
    await _updateProductPriceRange(productId);
  }

  // Hàm nội bộ: Tính lại giá Min-Max update ngược lại Product cha
  Future<void> _updateProductPriceRange(String productId) async {
    final snapshot = await _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .get();

    if (snapshot.docs.isEmpty) {
      await _firestore.collection('products').doc(productId).update({
        "min_price": 0,
        "max_price": 0,
      });
      return;
    }

    List<double> prices = snapshot.docs.map((doc) => (doc['price'] as num).toDouble()).toList();
    double minPrice = prices.reduce((curr, next) => curr < next ? curr : next);
    double maxPrice = prices.reduce((curr, next) => curr > next ? curr : next);

    await _firestore.collection('products').doc(productId).update({
      "min_price": minPrice,
      "max_price": maxPrice,
      "variants_count": snapshot.docs.length, // Update luôn số lượng biến thể
    });
  }

  // Lấy danh sách sản phẩm (Cho ProductManagementScreen)
  Stream<QuerySnapshot> getProductsStream() {
    return _firestore.collection('products').orderBy('created_at', descending: true).snapshots();
  }

  // Lấy chi tiết 1 sản phẩm (Cho ManageVariantsScreen - phần ảnh)
  Stream<DocumentSnapshot> getProductStream(String productId) {
    return _firestore.collection('products').doc(productId).snapshots();
  }

  // Lấy danh sách biến thể (Cho ManageVariantsScreen - phần list)
  Stream<QuerySnapshot> getVariantsStream(String productId) {
    return _firestore.collection('products').doc(productId).collection('variants').snapshots();
  }

  // Nếu sale_price là số decimal (0.2 = 20%), công thức là: original * (1 - sale)
  double _calculateFinalPrice(double original, double saleRate) {
    if (saleRate < 0) saleRate = 0;
    if (saleRate > 1) saleRate = 1; // Giảm tối đa 100%
    return original * (1.0 - saleRate).roundToDouble();
  }

  Future<void> addVariant(String productId, Map<String, dynamic> data) async {
    double original = (data['original_price'] ?? 0).toDouble();
    double manualSaleRate = (data['sale_price'] ?? 0).toDouble(); 

    // update giá nếu đủ đk
    Map<String, double> priceData = await _getBestPriceWithEvents(productId, original, manualSaleRate);
    
    data['price'] = priceData['price'];
    data['sale_price'] = priceData['sale_price']; // Ghi đè bằng sale rate ngon nhất

    await _firestore.collection('products').doc(productId).collection('variants').add(data);
    await _updateProductPriceRange(productId);
  }

  Future<void> updateVariant(String productId, String variantId, Map<String, dynamic> data) async {
    double original = (data['original_price'] ?? 0).toDouble();
    double manualSaleRate = (data['sale_price'] ?? 0).toDouble();

    // update giá nếu đủ đk
    Map<String, double> priceData = await _getBestPriceWithEvents(productId, original, manualSaleRate);
    
    data['price'] = priceData['price'];
    data['sale_price'] = priceData['sale_price'];

    await _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .doc(variantId)
        .update(data);

    await _updateProductPriceRange(productId);
  }

  // Các hàm xử lí EVENT
  // Lấy danh sách EVENT
  Stream<QuerySnapshot> getEventsStream() {
    return _firestore.collection('events').orderBy('created_at', descending: true).snapshots();
  }

  // Update EVENT
  Future<void> updateEvent(String eventID, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    return await _firestore.collection('events').doc(eventID).update(data);
  }

  Future<void> toggleEventStatus(String eventId, EventModel event, bool isNowActive) async {
    // 1. Lưu trạng thái mới (Bật hoặc Tắt) lên Database
    await _firestore.collection('events').doc(eventId).update({
      'is_active': isNowActive,
      'updated_at': FieldValue.serverTimestamp(),
    });
    await _processEventForProducts(event.toJson(), isApplying: isNowActive);
  }

  // =========================================================================
  // --- XỬ LÝ SỰ KIỆN (ÁP DỤNG & KHÔI PHỤC GIÁ) ---
  // =========================================================================

  // 1. Hàm "Người quét dọn": Quét các event hết hạn để tắt và khôi phục giá
  // Hàm này bạn có thể gọi ở initState của màn hình đầu tiên khi mở App
  Future<void> autoCheckExpiredEvents() async {
    try {
      final now = DateTime.now();
      // Lấy tất cả các event ĐANG CHẠY
      final snapshot = await _firestore
          .collection('events')
          .where('is_active', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final endTs = data['end_date'] as Timestamp?;

        // Nếu có ngày kết thúc VÀ ngày kết thúc đã trôi qua so với hiện tại
        if (endTs != null && endTs.toDate().isBefore(now)) {
          // 1. Tắt công tắc Event
          await doc.reference.update({'is_active': false});

          // 2. Đi dạo 1 vòng các sản phẩm để Khôi phục giá gốc
          await _processEventForProducts(data, isApplying: false);
          print("Đã tự động tắt Event hết hạn: ${data['name']}");
        }
      }
    } catch (e) {
      print("Lỗi khi quét event hết hạn: $e");
    }
  }

  // 2. Hàm lõi (Internal): Làm nhiệm vụ Update hàng loạt giá sản phẩm
  // isApplying = true (Đang giảm giá) | isApplying = false (Khôi phục giá gốc)
  Future<void> _processEventForProducts(
    Map<String, dynamic> eventData, {
    required bool isApplying,
  }) async {
    // Bóc tách điều kiện của Event
    final conditions = eventData['conditions'] ?? {};
    final bool applyAll = conditions['apply_all'] ?? false;
    final List categories = conditions['categories'] ?? [];
    final List sports = conditions['sports'] ?? [];
    final List brands = conditions['brands'] ?? [];

    double discountValue = (eventData['discount_value'] ?? 0).toDouble();
    String discountType = eventData['discount_type'] ?? 'percent';

    // Lấy TOÀN BỘ sản phẩm về để dò (Vì rẽ nhánh logic phức tạp nên dò bằng Dart)
    final productsSnapshot = await _firestore.collection('products').get();

    for (var productDoc in productsSnapshot.docs) {
      final pData = productDoc.data();

      // Kiểm tra xem Sản phẩm này có "Trúng thưởng" điều kiện giảm giá không?
      bool isMatch =
          applyAll ||
          categories.contains(pData['category_id']) ||
          sports.contains(pData['sport_id']) ||
          brands.contains(pData['brand']);

      if (isMatch) {
        // Nếu trúng, chui vào từng Biến Thể (Variant) để sửa giá
        final variantsSnapshot = await productDoc.reference.collection('variants').get();

        for (var variantDoc in variantsSnapshot.docs) {
          double original = (variantDoc.data()['original_price'] ?? 0).toDouble();
          double newPrice = original; // Mặc định là khôi phục giá gốc
          double saleRateOrValue = 0.0; // Dùng để lưu vết xem đang giảm bao nhiêu

          if (isApplying) {
            if (discountType == 'percent') {
              // VD: Giảm 20% -> original * (1 - 0.2)
              saleRateOrValue = discountValue / 100;
              newPrice = original * (1 - saleRateOrValue);
            } else {
              // VD: Giảm cứng 50.000đ
              newPrice = original - discountValue;
              if (newPrice < 0) newPrice = 0; // Không được bán lỗ dưới 0đ
              saleRateOrValue = discountValue;
            }
          }

          // Cập nhật lại Variant
          await variantDoc.reference.update({
            'price': newPrice,
            'sale_price': isApplying ? saleRateOrValue : 0,
          });
        }

        // Cập nhật lại giá Min-Max bên ngoài Product cha
        await _updateProductPriceRange(productDoc.id);
      }
    }
  }

  // 3. (Ghi đè) Thêm hàm tạo Event để gọi luôn chức năng giảm giá
  Future<void> createEventAndApply(Map<String, dynamic> data) async {
    // Lưu event lên database
    await _firestore.collection('events').add(data);
    // Nếu event được tạo ra ở trạng thái BẬT, thì áp dụng giá luôn
    if (data['is_active'] == true) {
      await _processEventForProducts(data, isApplying: true);
    }
  }

  // Cập nhật sale cho sản phẩm đủ đk
  Future<Map<String, double>> _getBestPriceWithEvents(String productId, double originalPrice, double manualSaleRate) async {
    // 1. Tính giá theo Admin nhập tay (Ví dụ Admin nhập giảm 10%)
    double finalPrice = _calculateFinalPrice(originalPrice, manualSaleRate);
    double bestSaleRate = manualSaleRate;

    try {
      // 2. Lấy thông tin gốc của Product để biết nó thuộc Category, Brand nào
      var pDoc = await _firestore.collection('products').doc(productId).get();
      if (!pDoc.exists) return {'price': finalPrice, 'sale_price': bestSaleRate};
      var pData = pDoc.data() as Map<String, dynamic>;

      // 3. Lấy tất cả Event ĐANG CHẠY
      var eventsSnap = await _firestore.collection('events').where('is_active', isEqualTo: true).get();

      // 4. Quét từng Event xem có khớp với Sản phẩm này không
      for (var doc in eventsSnap.docs) {
        var eData = doc.data();
        var conditions = eData['conditions'] ?? {};
        bool applyAll = conditions['apply_all'] ?? false;
        List categories = conditions['categories'] ?? [];
        List sports = conditions['sports'] ?? [];
        List brands = conditions['brands'] ?? [];

        bool isMatch = applyAll ||
                       categories.contains(pData['category_id']) ||
                       sports.contains(pData['sport_id']) ||
                       brands.contains(pData['brand']);

        if (isMatch) {
          double dValue = (eData['discount_value'] ?? 0).toDouble();
          String dType = eData['discount_type'] ?? 'percent';

          double currentEventPrice = originalPrice;
          double currentEventSaleRate = 0.0;

          if (dType == 'percent') {
            currentEventSaleRate = dValue / 100;
            currentEventPrice = originalPrice * (1 - currentEventSaleRate);
          } else { // Giảm thẳng VNĐ
            currentEventPrice = originalPrice - dValue;
            if (currentEventPrice < 0) currentEventPrice = 0;
            currentEventSaleRate = dValue; 
          }

          // CHỐT HẠ: Nếu giá của Event RẺ HƠN giá Admin tự nhập -> Lấy giá Event
          if (currentEventPrice < finalPrice) {
            finalPrice = currentEventPrice;
            bestSaleRate = currentEventSaleRate; // Ưu tiên hiển thị % giảm của Event
          }
        }
      }
    } catch (e) {
      print("Lỗi khi dò Event cho Sản phẩm mới: $e");
    }

    return {'price': finalPrice, 'sale_price': bestSaleRate};
  }

  // =========================================================================
  // --- 4. XỬ LÝ VOUCHER (MÃ GIẢM GIÁ) ---
  // =========================================================================

  // Lấy danh sách Voucher (Stream để tự động cập nhật UI khi có thay đổi)
  Stream<QuerySnapshot> getVouchersStream() {
    return _firestore.collection('vouchers').orderBy('created_at', descending: true).snapshots();
  }

  // Thêm Voucher mới
  Future<void> addVoucher(Map<String, dynamic> data) async {
    // Tự động thêm timestamp để dễ sort danh sách
    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();
    await _firestore.collection('vouchers').add(data);
  }

  // Bật/Tắt trạng thái hoạt động của Voucher
  Future<void> updateVoucherStatus(String voucherId, bool isActive) async {
    await _firestore.collection('vouchers').doc(voucherId).update({
      'is_active': isActive,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Cập nhật Voucher
  Future<void> updateVoucher(String voucherId, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _firestore.collection('vouchers').doc(voucherId).update(data);
  }
}
