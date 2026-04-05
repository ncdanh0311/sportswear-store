import 'model_utils.dart';
import 'product_variant_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String brandId;
  final String sportId;
  final String thumbnail;
  final String image;
  final bool isActive;
  final double minPrice;
  final double maxPrice;
  final double rating;
  final int ratingCount;
  final int sold;
  final List<String> images;
  final List<ProductVariantModel> variants;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.brandId,
    required this.sportId,
    required this.thumbnail,
    required this.image,
    required this.isActive,
    required this.minPrice,
    required this.maxPrice,
    required this.rating,
    required this.ratingCount,
    required this.sold,
    required this.images,
    required this.variants,
  });

  factory ProductModel.fromMap(
    Map<String, dynamic> json, {
    List<String> images = const [],
    List<ProductVariantModel> variants = const [],
  }) {
    final thumbnail = (json['thumbnail'] ?? '').toString();
    final image = thumbnail.isNotEmpty ? thumbnail : (images.isNotEmpty ? images.first : '');
    return ProductModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      brandId: (json['brandId'] ?? '').toString(),
      sportId: (json['sportId'] ?? '').toString(),
      thumbnail: thumbnail,
      image: image,
      isActive: ModelUtils.readBool(json['isActive'], fallback: true),
      minPrice: ModelUtils.readDouble(json['minPrice']),
      maxPrice: ModelUtils.readDouble(json['maxPrice']),
      rating: ModelUtils.readDouble(json['rating']),
      ratingCount: ModelUtils.readInt(json['ratingCount']),
      sold: ModelUtils.readInt(json['sold']),
      images: images,
      variants: variants,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'brandId': brandId,
      'sportId': sportId,
      'thumbnail': thumbnail,
      'image': image,
      'isActive': isActive,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'rating': rating,
      'ratingCount': ratingCount,
      'sold': sold,
    };
  }

  List<String> get gallery {
    if (images.isNotEmpty) return images;
    if (thumbnail.isNotEmpty) return [thumbnail];
    if (image.isNotEmpty) return [image];
    return const [];
  }

  ProductVariantModel get defaultVariant {
    if (variants.isEmpty) return ProductVariantModel.empty;
    return variants.first;
  }

  double get price {
    if (minPrice > 0 && maxPrice > 0) {
      return minPrice == maxPrice ? minPrice : minPrice;
    }
    return defaultVariant.price;
  }

  String get size => defaultVariant.size;

  int get quantity {
    if (variants.isEmpty) return 0;
    return variants.fold<int>(0, (sum, v) => sum + v.quantity);
  }
}
