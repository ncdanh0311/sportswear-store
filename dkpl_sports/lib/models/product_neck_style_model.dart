class ProductNeckStyleModel {
  final String productId;
  final String neckStyleId;

  ProductNeckStyleModel({
    required this.productId,
    required this.neckStyleId,
  });

  factory ProductNeckStyleModel.fromMap(Map<String, dynamic> map) {
    return ProductNeckStyleModel(
      productId: (map['productId'] ?? '').toString(),
      neckStyleId: (map['neckStyleId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'neckStyleId': neckStyleId,
    };
  }
}
