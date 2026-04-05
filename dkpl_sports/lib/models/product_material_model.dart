class ProductMaterialModel {
  final String productId;
  final String materialId;

  ProductMaterialModel({
    required this.productId,
    required this.materialId,
  });

  factory ProductMaterialModel.fromMap(Map<String, dynamic> map) {
    return ProductMaterialModel(
      productId: (map['productId'] ?? '').toString(),
      materialId: (map['materialId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'materialId': materialId,
    };
  }
}
