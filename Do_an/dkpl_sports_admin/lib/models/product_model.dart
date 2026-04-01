class ProductModel {
  final String id;
  final String name;
  final String thumbnail;
  final double minPrice;
  final double maxPrice;
  final bool isActive;
  final String categoryId;
  final int variantsCount;

  const ProductModel({
    required this.id,
    required this.name,
    required this.thumbnail,
    required this.minPrice,
    required this.maxPrice,
    required this.isActive,
    required this.categoryId,
    required this.variantsCount,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json, String documentId) {
    return ProductModel(
      id: documentId,
      name: json['name'] ?? 'Khong ten',
      thumbnail: json['thumbnail'] ?? '',
      minPrice: (json['min_price'] ?? 0).toDouble(),
      maxPrice: (json['max_price'] ?? 0).toDouble(),
      isActive: json['is_active'] ?? false,
      categoryId: json['category_id'] ?? '-',
      variantsCount: json['variants_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'thumbnail': thumbnail,
        'min_price': minPrice,
        'max_price': maxPrice,
        'is_active': isActive,
        'category_id': categoryId,
        'variants_count': variantsCount,
      };
}
