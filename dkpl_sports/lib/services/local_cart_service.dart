import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/cart_item_model.dart';

/// Service quản lý các thao tác liên quan đến giỏ hàng của người dùng.
/// Bao gồm việc lấy danh sách, thêm, sửa, xóa sản phẩm trong giỏ.
class LocalCartService {
  // Áp dụng Singleton pattern để tái sử dụng 1 instance duy nhất trên toàn app
  LocalCartService._();
  static final LocalCartService instance = LocalCartService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _cartsCol =>
      _firestore.collection(FirebaseCollections.carts);

  CollectionReference<Map<String, dynamic>> get _cartItemsCol =>
      _firestore.collection(FirebaseCollections.cartItems);

  /// Hàm hỗ trợ nội bộ (private): Đảm bảo người dùng luôn có một Giỏ hàng.
  /// Sử dụng luôn [uid] làm [cartId] để dễ quản lý.
  /// Nếu giỏ hàng chưa tồn tại trên Firestore, hàm sẽ tự động tạo mới.
  Future<String> _ensureCartId(String uid) async {
    final cartId = uid;
    final cartRef = _cartsCol.doc(cartId);
    final cartSnap = await cartRef.get();
    
    if (!cartSnap.exists) {
      await cartRef.set({'userId': uid});
    }
    return cartId;
  }

  /// Lấy toàn bộ danh sách sản phẩm hiện có trong giỏ hàng của người dùng.
  Future<List<Map<String, dynamic>>> getCart(String uid) async {
    final cartId = await _ensureCartId(uid);
    final snap =
        await _cartItemsCol.where('cartId', isEqualTo: cartId).get();
        
    return snap.docs
        .map((d) => CartItemModel.fromMap({
              'id': d.id,
              ...d.data(),
            }).toMap())
        .toList();
  }

  /// Thêm một sản phẩm (dựa theo [variantId]) vào giỏ hàng.
  /// Nếu sản phẩm đã tồn tại, tự động cộng dồn số lượng.
  Future<void> addToCart({
    required String uid,
    required String variantId,
    int quantity = 1,
  }) async {
    final cartId = await _ensureCartId(uid);
    
    // MẸO HAY: Ghép cartId và variantId làm ID cho document.
    // Đảm bảo mỗi variant chỉ có 1 record duy nhất trong giỏ hàng, 
    // và ta có thể get/update trực tiếp mà không cần query tốn kém.
    final docId = '${cartId}_$variantId'; 
    final doc = _cartItemsCol.doc(docId);
    final snap = await doc.get();
    
    // Lấy số lượng hiện tại (nếu có), không có thì mặc định là 0
    final currentQty = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
    final newQty = currentQty + quantity;
    
    // Dùng merge: true để ghi đè số lượng mới mà không làm mất các dữ liệu khác (nếu có)
    await doc.set({
      'cartId': cartId,
      'variantId': variantId,
      'quantity': newQty,
    }, SetOptions(merge: true));
  }

  /// Cập nhật trực tiếp số lượng của một sản phẩm trong giỏ 
  /// (Dùng khi người dùng bấm nút + / - hoặc gõ số lượng trong màn hình Giỏ hàng).
  Future<void> updateQuantity({
    required String uid,
    required String variantId,
    required int quantity,
  }) async {
    final cartId = await _ensureCartId(uid);
    final docId = '${cartId}_$variantId';
    final doc = _cartItemsCol.doc(docId);
    
    await doc.set({
      'cartId': cartId,
      'variantId': variantId,
      'quantity': quantity,
    }, SetOptions(merge: true));
  }

  /// Xóa một sản phẩm cụ thể khỏi giỏ hàng.
  Future<void> removeFromCart({
    required String uid,
    required String variantId,
  }) async {
    final cartId = await _ensureCartId(uid);
    final docId = '${cartId}_$variantId';
    
    // Tìm đúng document bằng ID đã ghép và xóa
    await _cartItemsCol.doc(docId).delete();
  }

  /// Xóa sạch toàn bộ sản phẩm trong giỏ hàng.
  /// Thường được gọi sau khi người dùng đã đặt hàng/thanh toán thành công.
  Future<void> clearCart(String uid) async {
    final cartId = await _ensureCartId(uid);
    final snap =
        await _cartItemsCol.where('cartId', isEqualTo: cartId).get();
        
    // Dùng Firestore Batch để gom tất cả lệnh xóa lại và bắn lên server cùng 1 lúc,
    // giúp tối ưu hiệu suất và đảm bảo xóa sạch (không bị sót nếu rớt mạng giữa chừng).
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
}