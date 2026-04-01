import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Dùng list ảo để hiển thị cho đẹp
  List<int> cartItems = [1, 2]; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: cartItems.isEmpty
          ? const Center(child: Text('Giỏ hàng trống', style: TextStyle(fontSize: 16, color: AppColors.textLight)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cartItems.length,
              itemBuilder: (context, i) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/images/aocr7.jpg', width: 80, height: 80, fit: BoxFit.cover)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Áo bóng đá CR7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              const Text('Size: XL • Màu Đỏ', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('99.990 đ', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () { setState(() => cartItems.removeAt(i)); }),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}