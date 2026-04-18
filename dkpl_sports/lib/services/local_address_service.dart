import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_collections.dart';
import '../models/address_model.dart';

/// Service xử lý các nghiệp vụ liên quan đến địa chỉ của người dùng.
/// Tương tác trực tiếp với Firestore collection.
class LocalAddressService {
  // Áp dụng Singleton pattern
  LocalAddressService._();
  static final LocalAddressService instance = LocalAddressService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _addrCol =>
      _firestore.collection(FirebaseCollections.addresses);

  /// Lấy danh sách địa chỉ của người dùng theo [uid].
  /// Danh sách trả về sẽ tự động đưa địa chỉ mặc định (isDefault = true) lên đầu.
  Future<List<Map<String, dynamic>>> getAddresses(String uid) async {
    final snap = await _addrCol.where('userId', isEqualTo: uid).get();
    
    final items = snap.docs
        .map((d) => AddressModel.fromMap({
              'id': d.id,
              ...d.data(),
            }).toMap())
        .toList();

    // Sắp xếp: Đẩy địa chỉ mặc định lên đầu list
    items.sort((a, b) {
      final aDefault = a['isDefault'] == true ? 1 : 0;
      final bDefault = b['isDefault'] == true ? 1 : 0;
      return bDefault.compareTo(aDefault);
    });
    
    return items;
  }

  /// Tìm và trả về địa chỉ mặc định của người dùng.
  /// Trả về [null] nếu không có địa chỉ nào được set làm mặc định.
  Future<Map<String, dynamic>?> getDefaultAddress(String uid) async {
    final addresses = await getAddresses(uid);
    for (final address in addresses) {
      if (address['isDefault'] == true) return address;
    }
    return null;
  }

  /// Thêm mới hoặc ghi đè dữ liệu của một địa chỉ.
  /// Dữ liệu sẽ được tự động gắn thêm [uid] của người dùng hiện tại.
  Future<void> addAddress({
    required String uid,
    required Map<String, dynamic> address,
  }) async {
    final model = AddressModel.fromMap({
      ...address,
      'userId': uid,
    });
    
    // Dùng merge: true để update các trường thay đổi nếu doc đã tồn tại, hoặc tạo mới nếu chưa có
    await _addrCol.doc(model.id).set(model.toMap(), SetOptions(merge: true));
  }

  /// Đặt một địa chỉ thành địa chỉ mặc định.
  /// Sử dụng Firestore Batch để set true cho địa chỉ được chọn và false cho tất cả các địa chỉ còn lại của user.
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
    
    // Thực thi toàn bộ lệnh update cùng một lúc để đảm bảo tính đồng bộ
    await batch.commit();
  }
}