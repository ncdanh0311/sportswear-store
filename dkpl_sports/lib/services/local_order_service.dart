import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/order_item_model.dart';
import '../services/product_repository.dart';

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

  Future<List<Map<String, dynamic>>> getOrders(String uid) async {
    final snap = await _ordersCol.where('userId', isEqualTo: uid).get();
    final docs = snap.docs.toList()
      ..sort((a, b) {
        final aCreated = a.data()['createdAt'];
        final bCreated = b.data()['createdAt'];
        final aTime = aCreated is Timestamp
            ? aCreated.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = bCreated is Timestamp
            ? bCreated.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

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

    final addressSnap =
        await _addressesCol.where('userId', isEqualTo: uid).get();
    final addressById = <String, String>{};
    for (final doc in addressSnap.docs) {
      final data = doc.data();
      addressById[doc.id] = (data['detail'] ?? '').toString();
    }

    final orders = <Map<String, dynamic>>[];
    for (final doc in docs) {
      final orderId = doc.id;
      final orderData = doc.data();
      final itemsSnap = await _orderItemsCol
          .where('orderId', isEqualTo: orderId)
          .get();

      final items = itemsSnap.docs.map((d) {
        final item = OrderItemModel.fromMap({
          'id': d.id,
          ...d.data(),
        });
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

      final addressId = (orderData['addressId'] ?? '').toString();
      orderMap['address'] = addressById[addressId] ?? '';
      orders.add(orderMap);
    }
    return orders;
  }

  Future<void> addOrder({
    required String uid,
    required Map<String, dynamic> order,
  }) async {
    final orderRef = _ordersCol.doc(order['id'] ?? _ordersCol.doc().id);
    final items = (order['items'] as List?) ?? [];

    final batch = _firestore.batch();
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

    for (final raw in items) {
      final map = Map<String, dynamic>.from(raw);
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

  Future<Map<String, int>> getStatusCounts(String uid) async {
    final orders = await getOrders(uid);
    int pending = 0;
    int shipping = 0;
    int delivered = 0;
    int review = 0;
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
