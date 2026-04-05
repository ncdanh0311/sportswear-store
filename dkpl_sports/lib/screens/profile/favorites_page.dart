import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/product_image.dart';
import '../../core/user_session.dart';
import '../../models/product_model.dart';
import '../../services/local_favorites_service.dart';
import '../../services/product_repository.dart';
import '../products/product_detail_screen.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _session = UserSession();

  Future<List<ProductModel>> _loadProducts() {
    return ProductRepository.loadProducts();
  }

  Future<List<String>> _loadFavorites() {
    final uid = _session.uid;
    if (uid == null) return Future.value([]);
    return LocalFavoritesService.instance.getFavorites(uid);
  }

  @override
  Widget build(BuildContext context) {
    if (_session.uid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Yêu thích',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Vui lòng đăng nhập để xem yêu thích.',
            style: TextStyle(color: AppColors.textLight),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Yêu thích',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_loadProducts(), _loadFavorites()]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Không thể tải danh sách yêu thích.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          final products = snapshot.data?[0] as List<ProductModel>? ?? [];
          final favorites = snapshot.data?[1] as List<String>? ?? [];
          final favoriteProducts = products
              .where((p) => favorites.contains(p.id))
              .toList(growable: false);

          if (favoriteProducts.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có sản phẩm yêu thích',
                style: TextStyle(fontSize: 16, color: AppColors.textLight),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return _FavoriteCard(
                product: product,
                onRemove: () async {
                  await LocalFavoritesService.instance.removeFavorite(
                    uid: _session.uid!,
                    productId: product.id,
                  );
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRemove;

  const _FavoriteCard({
    required this.product,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ProductImage(src: product.image, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.categoryId,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "\$${product.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}



