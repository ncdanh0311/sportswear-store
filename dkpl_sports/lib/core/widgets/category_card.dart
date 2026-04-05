import 'package:flutter/material.dart';
import '../../models/category_model.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, // tăng width cho cân đối
      margin: const EdgeInsets.only(right: 14),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /// ===== KHUNG TRÒN =====
          Container(
            width: 80,   // to hơn
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,

              /// ĐỔ BÓNG MỀM
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            /// ===== ẢNH PNG =====
            child: Padding(
              padding: const EdgeInsets.all(14), // padding lớn hơn để cân giữa
              child: Image.asset(
                category.image,
                fit: BoxFit.contain, // giữ tỉ lệ PNG
              ),
            ),
          ),

          const SizedBox(height: 10),

          /// ===== TITLE =====
          Text(
            category.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
