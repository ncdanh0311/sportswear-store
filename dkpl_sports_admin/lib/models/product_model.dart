import 'package:cloud_firestore/cloud_firestore.dart';
import 'model_utils.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String brandId;
  final String sportId;
  final String materialId;
  final String neckStyleId;
  final String sleeveStyleId;
  final String thumbnail;
  final bool isActive;
  final double minPrice;
  final double maxPrice;
  final double rating;
  final int ratingCount;
  final int sold;
  final DateTime? createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.brandId,
    required this.sportId,
    required this.materialId,
    required this.neckStyleId,
    required this.sleeveStyleId,
    required this.thumbnail,
    required this.isActive,
    required this.minPrice,
    required this.maxPrice,
    required this.rating,
    required this.ratingCount,
    required this.sold,
    required this.createdAt,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot<Object?> doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel.fromJson(data, doc.id);
  }

  factory ProductModel.fromJson(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: ModelUtils.readString(data['name']),
      description: ModelUtils.readString(data['description']),
      categoryId: ModelUtils.readString(data['categoryId']),
      brandId: ModelUtils.readString(data['brandId']),
      sportId: ModelUtils.readString(data['sportId']),
      materialId: ModelUtils.readString(data['materialId']),
      neckStyleId: ModelUtils.readString(data['neckStyleId']),
      sleeveStyleId: ModelUtils.readString(data['sleeveStyleId']),
      thumbnail: ModelUtils.readString(data['thumbnail']),
      isActive: ModelUtils.readBool(data['isActive'], fallback: true),
      minPrice: ModelUtils.readDouble(data['minPrice']),
      maxPrice: ModelUtils.readDouble(data['maxPrice']),
      rating: ModelUtils.readDouble(data['rating']),
      ratingCount: ModelUtils.readInt(data['ratingCount']),
      sold: ModelUtils.readInt(data['sold']),
      createdAt: ModelUtils.readDateTime(data['createdAt']),
    );
  }
}
