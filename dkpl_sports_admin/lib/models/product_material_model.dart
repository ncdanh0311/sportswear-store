import 'model_utils.dart';

class ProductMaterialModel {
  final String productId;
  final String materialId;

  ProductMaterialModel({
    required this.productId,
    required this.materialId,
  });

  factory ProductMaterialModel.fromMap(Map<String, dynamic> map) {
    return ProductMaterialModel(
      productId: ModelUtils.readString(map['productId']),
      materialId: ModelUtils.readString(map['materialId']),
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'materialId': materialId,
      };
}
