import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/cart_item_model.dart';

class LocalCartService {
  LocalCartService._();
  static final LocalCartService instance = LocalCartService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _cartsCol =>
      _firestore.collection(FirebaseCollections.carts);

  CollectionReference<Map<String, dynamic>> get _cartItemsCol =>
      _firestore.collection(FirebaseCollections.cartItems);

  Future<String> _ensureCartId(String uid) async {
    final cartId = uid;
    final cartRef = _cartsCol.doc(cartId);
    final cartSnap = await cartRef.get();
    if (!cartSnap.exists) {
      await cartRef.set({'userId': uid});
    }
    return cartId;
  }

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

  Future<void> addToCart({
    required String uid,
    required String variantId,
    int quantity = 1,
  }) async {
    final cartId = await _ensureCartId(uid);
    final docId = '${cartId}_$variantId';
    final doc = _cartItemsCol.doc(docId);
    final snap = await doc.get();
    final currentQty = (snap.data()?['quantity'] as num?)?.toInt() ?? 0;
    final newQty = currentQty + quantity;
    await doc.set({
      'cartId': cartId,
      'variantId': variantId,
      'quantity': newQty,
    }, SetOptions(merge: true));
  }

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

  Future<void> removeFromCart({
    required String uid,
    required String variantId,
  }) async {
    final cartId = await _ensureCartId(uid);
    final docId = '${cartId}_$variantId';
    await _cartItemsCol.doc(docId).delete();
  }

  Future<void> clearCart(String uid) async {
    final cartId = await _ensureCartId(uid);
    final snap =
        await _cartItemsCol.where('cartId', isEqualTo: cartId).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
