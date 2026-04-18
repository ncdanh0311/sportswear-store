import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';

/// Service quản lý danh sách sản phẩm yêu thích (Favorites) của người dùng.
/// Dữ liệu được lưu trữ dưới dạng sub-collection (bộ sưu tập con) bên trong document của từng user.
class LocalFavoritesService {
  // Áp dụng Singleton pattern
  LocalFavoritesService._();
  static final LocalFavoritesService instance = LocalFavoritesService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Trỏ tới sub-collection 'favorites' nằm trong document của user có [uid] tương ứng.
  CollectionReference<Map<String, dynamic>> _favCol(String uid) {
    return _firestore
        .collection(FirebaseCollections.users)
        .doc(uid)
        .collection('favorites');
  }

  /// Lấy danh sách ID của tất cả các sản phẩm đã được user thả tim.
  Future<List<String>> getFavorites(String uid) async {
    final snap = await _favCol(uid).get();
    // Vì ID của document chính là ID của sản phẩm, ta chỉ cần map doc.id là đủ
    return snap.docs.map((d) => d.id).toList();
  }

  /// Kiểm tra xem một sản phẩm có nằm trong danh sách yêu thích hay không.
  Future<bool> isFavorite(String uid, String productId) async {
    final doc = await _favCol(uid).doc(productId).get();
    return doc.exists;
  }

  /// Nút bấm "Thả tim / Bỏ tim" (Toggle).
  /// Nếu sản phẩm đã thích -> Xóa khỏi db.
  /// Nếu sản phẩm chưa thích -> Thêm mới vào db với timestamp.
  Future<void> toggleFavorite({
    required String uid,
    required String productId,
  }) async {
    final ref = _favCol(uid).doc(productId);
    final snap = await ref.get();
    
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({'createdAt': FieldValue.serverTimestamp()});
    }
  }

  /// Xóa trực tiếp một sản phẩm khỏi danh sách yêu thích.
  Future<void> removeFavorite({
    required String uid,
    required String productId,
  }) async {
    await _favCol(uid).doc(productId).delete();
  }
}