import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/address_model.dart';

class LocalAddressService {
  LocalAddressService._();
  static final LocalAddressService instance = LocalAddressService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _addrCol =>
      _firestore.collection(FirebaseCollections.addresses);

  Future<List<Map<String, dynamic>>> getAddresses(String uid) async {
    final snap = await _addrCol
        .where('userId', isEqualTo: uid)
        .orderBy('isDefault', descending: true)
        .get();
    return snap.docs
        .map((d) => AddressModel.fromMap({
              'id': d.id,
              ...d.data(),
            }).toMap())
        .toList();
  }

  Future<Map<String, dynamic>?> getDefaultAddress(String uid) async {
    final snap = await _addrCol
        .where('userId', isEqualTo: uid)
        .where('isDefault', isEqualTo: true)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return AddressModel.fromMap({
      'id': doc.id,
      ...doc.data(),
    }).toMap();
  }

  Future<void> addAddress({
    required String uid,
    required Map<String, dynamic> address,
  }) async {
    final model = AddressModel.fromMap({
      ...address,
      'userId': uid,
    });
    await _addrCol.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  Future<void> setDefault({
    required String uid,
    required String addressId,
  }) async {
    final snap = await _addrCol.where('userId', isEqualTo: uid).get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      final isDefault = doc.id == addressId;
      batch.update(doc.reference, {'isDefault': isDefault});
    }
    await batch.commit();
  }
}
