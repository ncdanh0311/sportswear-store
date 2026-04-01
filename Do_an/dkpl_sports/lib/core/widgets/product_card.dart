import 'package:flutter/material.dart';
import '../../screens/products/product_detail_screen.dart';
import '../../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final String image;
  final String name;
  final String weight;

  const ProductCard({
    super.key,
    required this.image,
    required this.name,
    required this.weight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        /// ===== Fake product truyền sang Detail =====
        final product = ProductModel(
          id: name,
          name: name,
          description:
              "Đây là mô tả chi tiết của $name. "
              "Sản phẩm chất lượng cao, thiết kế đẹp, phù hợp mọi nhu cầu.",
          price: 99.99,
          rating: 4.5,
          category: "football",
          weight: weight, // 👈 THÊM DÒNG NÀY
          themeColor: Colors.blue,
          images: [
            image, // dùng luôn ảnh asset
          ],
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },

      /// ===== UI CARD =====
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),

            /// NAME
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            /// WEIGHT
            Text(
              weight,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
