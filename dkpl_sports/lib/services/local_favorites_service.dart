import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';

class LocalFavoritesService {
  LocalFavoritesService._();
  static final LocalFavoritesService instance = LocalFavoritesService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _favoritesCol =>
      _firestore.collection(FirebaseCollections.userFavorites);

  String _docId(String uid, String productId) => '${uid}_$productId';

  Future<List<String>> getFavorites(String uid) async {
    final snap =
        await _favoritesCol.where('userId', isEqualTo: uid).get();
    return snap.docs
        .map((d) => (d.data()['productId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<bool> isFavorite(String uid, String productId) async {
    final doc = await _favoritesCol.doc(_docId(uid, productId)).get();
    return doc.exists;
  }

  Future<void> toggleFavorite({
    required String uid,
    required String productId,
  }) async {
    final ref = _favoritesCol.doc(_docId(uid, productId));
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'userId': uid,
        'productId': productId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeFavorite({
    required String uid,
    required String productId,
  }) async {
    await _favoritesCol.doc(_docId(uid, productId)).delete();
  }
}
