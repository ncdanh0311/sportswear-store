import 'model_utils.dart';

class CartModel {
  final String id;
  final String userId;

  CartModel({
    required this.id,
    required this.userId,
  });

  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      id: ModelUtils.readString(map['id']),
      userId: ModelUtils.readString(map['userId']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
    };
  }
}
