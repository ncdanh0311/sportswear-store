class ProductSleeveStyleModel {
  final String productId;
  final String sleeveStyleId;

  ProductSleeveStyleModel({
    required this.productId,
    required this.sleeveStyleId,
  });

  factory ProductSleeveStyleModel.fromMap(Map<String, dynamic> map) {
    return ProductSleeveStyleModel(
      productId: (map['productId'] ?? '').toString(),
      sleeveStyleId: (map['sleeveStyleId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sleeveStyleId': sleeveStyleId,
    };
  }
}
