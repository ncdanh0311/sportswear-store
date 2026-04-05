import 'model_utils.dart';

class UserFavoriteModel {
  final String id;
  final String userId;
  final String productId;
  final String? createdAt;

  UserFavoriteModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.createdAt,
  });

  factory UserFavoriteModel.fromMap(Map<String, dynamic> map) {
    return UserFavoriteModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      productId: (map['productId'] ?? '').toString(),
      createdAt: ModelUtils.readDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'createdAt': createdAt,
    };
  }
}
