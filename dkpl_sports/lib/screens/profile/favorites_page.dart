import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  // Dùng list ảo để demo UI hiển thị
  List<int> favoriteItems = [1, 2, 3]; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: favoriteItems.isEmpty
          ? const Center(
              child: Text(
                'Chưa có sản phẩm yêu thích', 
                style: TextStyle(fontSize: 16, color: AppColors.textLight)
              )
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    "Sản phẩm bạn đã thích", 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: AppColors.textDark
                    )
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: favoriteItems.length,
                    itemBuilder: (context, i) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Hình ảnh sản phẩm
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12), 
                                child: Image.asset(
                                  'assets/images/aocr7.jpg', // Đảm bảo bạn có ảnh này
                                  width: 80, 
                                  height: 80, 
                                  fit: BoxFit.cover
                                )
                              ),
                              const SizedBox(width: 16),
                              
                              // Thông tin sản phẩm
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Áo bóng đá CR7', 
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Thun lạnh cao cấp', 
                                      style: TextStyle(color: AppColors.textLight, fontSize: 13)
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      '99.990 đ', 
                                      style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Nút Bỏ thích & Thêm vào giỏ
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.favorite, color: Colors.red), 
                                    onPressed: () { 
                                      setState(() => favoriteItems.removeAt(i)); 
                                    }
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_shopping_cart, color: AppColors.primaryBlue), 
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Đã thêm vào giỏ hàng!"), 
                                          duration: Duration(seconds: 1)
                                        )
                                      );
                                    }
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}