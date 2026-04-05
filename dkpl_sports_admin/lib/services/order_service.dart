import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dkpl_sports_admin/models/order_model.dart';
import 'package:dkpl_sports_admin/models/product_model.dart';

class OrderService {
  OrderService._();
  static final OrderService instance = OrderService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<OrderModel>> watchOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _firestore.collection('orders').doc(orderId).set({
      'status': status,
    }, SetOptions(merge: true));
  }

  Future<ProductModel?> fetchProduct(String productId) async {
    if (productId.isEmpty) return null;
    final doc = await _firestore.collection('products').doc(productId).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(doc);
  }

  Future<Map<String, dynamic>?> fetchVariant(String variantId) async {
    if (variantId.isEmpty) return null;
    final doc = await _firestore.collection('product_variants').doc(variantId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<Map<String, dynamic>?> fetchUser(String userId) async {
    if (userId.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<Map<String, dynamic>?> fetchAddress(String addressId) async {
    if (addressId.isEmpty) return null;
    final doc = await _firestore.collection('addresses').doc(addressId).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> fetchOrderItems(String orderId) async {
    if (orderId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('order_items')
        .where('orderId', isEqualTo: orderId)
        .get();
    return snapshot.docs.map((e) => e.data()).toList();
  }
}
