import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/order_item_model.dart';
import '../services/product_repository.dart';

/// Service quản lý nghiệp vụ Đơn hàng.
/// Xử lý việc tạo đơn hàng mới (ghi theo Batch) và truy vấn lịch sử đơn hàng.
class LocalOrderService {
  LocalOrderService._();
  static final LocalOrderService instance = LocalOrderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ordersCol =>
      _firestore.collection(FirebaseCollections.orders);

  CollectionReference<Map<String, dynamic>> get _orderItemsCol =>
      _firestore.collection(FirebaseCollections.orderItems);

  CollectionReference<Map<String, dynamic>> get _addressesCol =>
      _firestore.collection(FirebaseCollections.addresses);

  /// Lấy danh sách toàn bộ đơn hàng của người dùng.
  /// Hàm này thực hiện thủ công thao tác "Join" dữ liệu từ nhiều collection 
  /// (Orders, OrderItems, Products, Variants, Addresses) vì Firestore là NoSQL.
  Future<List<Map<String, dynamic>>> getOrders(String uid) async {
    // 1. Lấy danh sách đơn hàng gốc và sắp xếp mới nhất lên đầu
    final snap = await _ordersCol.where('userId', isEqualTo: uid).get();
    final docs = snap.docs.toList()
      ..sort((a, b) {
        final aCreated = a.data()['createdAt'];
        final bCreated = b.data()['createdAt'];
        // Xử lý an toàn kiểu dữ liệu thời gian (Timestamp từ server hoặc DateTime local)
        final aTime = aCreated is Timestamp
            ? aCreated.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = bCreated is Timestamp
            ? bCreated.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

    // 2. Tải toàn bộ sản phẩm từ Cache để map thông tin (Tên, Ảnh, Size...)
    final products = await ProductRepository.loadProducts();
    final variantInfo = <String, Map<String, dynamic>>{};
    for (final product in products) {
      for (final variant in product.variants) {
        variantInfo[variant.id] = {
          'product': product,
          'variant': variant,
        };
      }
    }

    // 3. Tải danh sách địa chỉ của user để map vào đơn hàng
    final addressSnap =
        await _addressesCol.where('userId', isEqualTo: uid).get();
    final addressById = <String, String>{};
    for (final doc in addressSnap.docs) {
      final data = doc.data();
      addressById[doc.id] = (data['detail'] ?? '').toString();
    }

    // 4. Lắp ráp dữ liệu cuối cùng
    final orders = <Map<String, dynamic>>[];
    for (final doc in docs) {
      final orderId = doc.id;
      final orderData = doc.data();
      
      // Lấy các chi tiết sản phẩm (items) của đơn hàng này
      final itemsSnap = await _orderItemsCol
          .where('orderId', isEqualTo: orderId)
          .get();

      final items = itemsSnap.docs.map((d) {
        final item = OrderItemModel.fromMap({
          'id': d.id,
          ...d.data(),
        });
        
        // Nhặt thông tin từ dictionary variantInfo đã tạo ở bước 2
        final info = variantInfo[item.variantId];
        final product = info?['product'];
        final variant = info?['variant'];
        final thumb = product?.thumbnail ?? '';
        
        return {
          'variantId': item.variantId,
          'quantity': item.quantity,
          'price': item.price,
          'name': product?.name ?? '',
          'image': thumb,
          'size': variant?.size ?? '',
          'colorId': variant?.colorId ?? '',
        };
      }).toList();

      final orderMap = {
        'id': orderId,
        ...orderData,
        'items': items,
      };

      // Nhặt địa chỉ từ dictionary addressById ở bước 3
      final addressId = (orderData['addressId'] ?? '').toString();
      orderMap['address'] = addressById[addressId] ?? '';
      
      orders.add(orderMap);
    }
    return orders;
  }

  /// Tạo một đơn hàng mới.
  /// Sử dụng Firestore Batch để đảm bảo tạo Document Đơn hàng và các Document Chi tiết (Items)
  /// cùng một lúc. Nếu 1 cái lỗi thì toàn bộ rollback, tránh tình trạng đơn hàng mất ruột.
  Future<void> addOrder({
    required String uid,
    required Map<String, dynamic> order,
  }) async {
    final orderRef = _ordersCol.doc(order['id'] ?? _ordersCol.doc().id);
    final items = (order['items'] as List?) ?? [];

    final batch = _firestore.batch();
    
    // Ghi thông tin chung của đơn hàng
    batch.set(orderRef, {
      'id': orderRef.id,
      'userId': uid,
      'addressId': order['addressId'],
      'total': order['total'],
      'status': order['status'] ?? 'pending',
      'paymentMethod': order['paymentMethod'] ?? '',
      'expectedDelivery': order['expectedDelivery'],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Ghi từng chi tiết sản phẩm vào collection orderItems
    for (final raw in items) {
      final map = Map<String, dynamic>.from(raw);
      // Tạo ID ghép để dễ quản lý và truy vết
      final itemId = map['id'] ?? '${orderRef.id}_${map['variantId']}';
      final itemRef = _orderItemsCol.doc(itemId);
      
      batch.set(itemRef, {
        'id': itemId,
        'orderId': orderRef.id,
        'variantId': map['variantId'],
        'quantity': map['quantity'],
        'price': map['price'],
      });
    }

    await batch.commit();
  }

  /// Đếm số lượng đơn hàng theo từng trạng thái (để hiển thị badge trên UI).
  Future<Map<String, int>> getStatusCounts(String uid) async {
    final orders = await getOrders(uid);
    int pending = 0, shipping = 0, delivered = 0, review = 0;
    
    for (final order in orders) {
      final status = (order['status'] ?? '').toString();
      if (status == 'pending') pending++;
      if (status == 'shipping') shipping++;
      if (status == 'delivered') delivered++;
      if (status == 'review') review++;
    }
    
    return {
      'pending': pending,
      'shipping': shipping,
      'delivered': delivered,
      'review': review,
    };
  }
}