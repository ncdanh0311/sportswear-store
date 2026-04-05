import 'model_utils.dart';

class ProductSleeveStyleModel {
  final String productId;
  final String sleeveStyleId;

  ProductSleeveStyleModel({
    required this.productId,
    required this.sleeveStyleId,
  });

  factory ProductSleeveStyleModel.fromMap(Map<String, dynamic> map) {
    return ProductSleeveStyleModel(
      productId: ModelUtils.readString(map['productId']),
      sleeveStyleId: ModelUtils.readString(map['sleeveStyleId']),
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'sleeveStyleId': sleeveStyleId,
      };
}
