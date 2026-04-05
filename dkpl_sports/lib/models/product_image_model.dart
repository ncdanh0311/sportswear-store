class ProductImageModel {
  final String id;
  final String productId;
  final String imageUrl;

  ProductImageModel({
    required this.id,
    required this.productId,
    required this.imageUrl,
  });

  factory ProductImageModel.fromMap(Map<String, dynamic> map) {
    return ProductImageModel(
      id: (map['id'] ?? '').toString(),
      productId: (map['productId'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'imageUrl': imageUrl,
    };
  }
}
