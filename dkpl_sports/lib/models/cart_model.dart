class CartModel {
  final String id;
  final String userId;

  CartModel({
    required this.id,
    required this.userId,
  });

  factory CartModel.fromMap(Map<String, dynamic> map) {
    return CartModel(
      id: (map['id'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
    };
  }
}
