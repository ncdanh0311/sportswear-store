import 'model_utils.dart';

class ProductNeckStyleModel {
  final String productId;
  final String neckStyleId;

  ProductNeckStyleModel({
    required this.productId,
    required this.neckStyleId,
  });

  factory ProductNeckStyleModel.fromMap(Map<String, dynamic> map) {
    return ProductNeckStyleModel(
      productId: ModelUtils.readString(map['productId']),
      neckStyleId: ModelUtils.readString(map['neckStyleId']),
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'neckStyleId': neckStyleId,
      };
}
