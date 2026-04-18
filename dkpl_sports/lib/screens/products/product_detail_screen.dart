// File: lib/screens/product/product_detail_screen.dart (hoáº·c Ä‘Æ°á»ng dáº«n tÆ°Æ¡ng á»©ng)
import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';
import '../../models/model_utils.dart';
import '../../core/constants/app_colors.dart'; // Äá»•i Ä‘Æ°á»ng dáº«n import AppColors náº¿u cáº§n
import '../../core/widgets/product_image.dart';
import '../orders/order_confirmation_screen.dart';
import '../../services/product_repository.dart';
import '../../core/user_session.dart';
import '../../services/local_cart_service.dart';
import '../../services/local_favorites_service.dart';
import '../chat/chat_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int currentImage = 0;
  int quantity = 1;
  bool isFavorite = false;
  String? _selectedVariantId;
  final _session = UserSession();

  @override
  void initState() {
    super.initState();
    _loadFavorite();
    final variants = widget.product.variants;
    if (variants.isNotEmpty) {
      _selectedVariantId = variants.first.id;
    }
  }

  Future<void> _loadFavorite() async {
    final uid = _session.uid;
    if (uid == null) return;
    final fav = await LocalFavoritesService.instance.isFavorite(
      uid,
      widget.product.id,
    );
    if (mounted) {
      setState(() => isFavorite = fav);
    }
  }

  List<ProductModel> get relatedProducts {
    final allProducts = ProductRepository.cache;
    if (allProducts.isEmpty) return [];
    return allProducts
        .where(
          (p) =>
              p.categoryId == widget.product.categoryId &&
              p.id != widget.product.id,
        )
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildBrandHeader(context),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildImageGallery(product),
                  _buildProductInfo(product),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(product),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Container(
      color: AppColors.primaryBlue, // ÄÃ£ sá»­a
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'DKPL SPORTS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red.shade300 : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage: (() {
                    final avatar = _session.avatar?.trim() ?? '';
                    if (avatar.isNotEmpty) {
                      return NetworkImage(avatar);
                    }
                    return const AssetImage('assets/images/avatar.jpg');
                  })() as ImageProvider<Object>,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(ProductModel product) {
    final gallery = product.gallery;
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            itemCount: gallery.length,
            onPageChanged: (index) => setState(() => currentImage = index),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: ProductImage(
                      src: gallery[index],
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildIndicator(gallery.length),
      ],
    );
  }

  Widget _buildIndicator(int totalImages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalImages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: currentImage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: currentImage == index
                ? AppColors.primaryBlue
                : Colors.grey.shade300, // ÄÃ£ sá»­a
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo(ProductModel product) {
    final selectedVariant = _getSelectedVariant(product);
    final hasVariants = product.variants.isNotEmpty;
    final displayPrice =
        selectedVariant.id.isNotEmpty ? selectedVariant.price : product.price;
    final displayStock = selectedVariant.id.isNotEmpty
        ? selectedVariant.quantity
        : product.quantity;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.amber.shade600, size: 18),
                const SizedBox(width: 6),
                Text(
                  product.rating.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "(${product.ratingCount} ðánh giá)",
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaChip("${product.sold} đã bán"),
              _buildMetaChip("Còn $displayStock"),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                ModelUtils.formatVnd(displayPrice),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ), // ÄÃ£ sá»­a
            ],
          ),
          const SizedBox(height: 24),
          if (hasVariants) ...[
            const Text(
              "Chọn size",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.variants.map((variant) {
                final isSelected = variant.id == selectedVariant.id;
                final isOutOfStock = variant.quantity <= 0;
                final sizeLabel = variant.size.isNotEmpty ? variant.size : '--';
                return InkWell(
                  onTap: isOutOfStock
                      ? null
                      : () => setState(() => _selectedVariantId = variant.id),
                  borderRadius: BorderRadius.circular(10),
                  child: Opacity(
                    opacity: isOutOfStock ? 0.6 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryBlue.withOpacity(0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sizeLabel,
                            style: TextStyle(
                              color: isOutOfStock
                                  ? Colors.grey.shade500
                                  : (isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.black87),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isOutOfStock) ...[
                            const SizedBox(height: 2),
                            Text(
                              "Hết hàng",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              const Text(
                "Số lượng",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(width: 20),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.remove,
                        color: AppColors.primaryBlue,
                      ),
                      onPressed: () {
                        if (quantity > 1) setState(() => quantity--);
                      },
                    ), // ÄÃ£ sá»­a
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.primaryBlue),
                      onPressed: () => setState(() => quantity++),
                    ), // ÄÃ£ sá»­a
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Divider(height: 1),
          const SizedBox(height: 24),
          const Text(
            "Mô tả sản phẩm",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            "Sản phẩm liên quan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: relatedProducts.length,
              padding: const EdgeInsets.only(right: 20),
              itemBuilder: (context, index) =>
                  _RelatedCard(product: relatedProducts[index]),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildBottomBar(ProductModel product) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      child: Row(
        children: [
          // 💬 Chat button
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.primaryBlue,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(product: product),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 12),

          // ❤️ Favorite button
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryBlue.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : AppColors.primaryBlue,
              ),
              onPressed: _toggleFavorite,
            ),
          ),

          const SizedBox(width: 12),

          // 🛒 Add to cart
          Expanded(
            child: GestureDetector(
              onTap: _handleAddToCart,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryBlue,
                    width: 2,
                  ),
                  color: Colors.white,
                ),
                child: const Center(
                  child: Text(
                    "Thêm vào giỏ",
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ⚡ Buy now
          Expanded(
            child: GestureDetector(
              onTap: () {
                final variant = _getSelectedVariant(product);

                if (variant.id.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sản phẩm chưa có phân loại hợp lệ'),
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderConfirmationScreen.single(
                      product: product,
                      variant: variant,
                      quantity: quantity,
                    ),
                  ),
                );
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue,
                      AppColors.primaryBlue.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    "Mua ngay",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  Future<void> _handleAddToCart() async {
    final uid = _session.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để thêm vào giỏ hàng'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final variant = _getSelectedVariant(widget.product);
    if (variant.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm chưa có phân loại hợp lệ'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await LocalCartService.instance.addToCart(
      uid: uid,
      variantId: variant.id,
      quantity: quantity,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã thêm vào giỏ hàng!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final uid = _session.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đăng nhập để yêu thích'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    await LocalFavoritesService.instance.toggleFavorite(
      uid: uid,
      productId: widget.product.id,
    );
    setState(() => isFavorite = !isFavorite);
  }

  ProductVariantModel _getSelectedVariant(ProductModel product) {
    final variants = product.variants;
    if (variants.isEmpty) return ProductVariantModel.empty;
    final selectedId = _selectedVariantId;
    if (selectedId == null) return variants.first;
    return variants.firstWhere(
      (v) => v.id == selectedId,
      orElse: () => variants.first,
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final ProductModel product;
  const _RelatedCard({required this.product});

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
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ProductImage(src: product.image, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ModelUtils.formatVnd(product.price),
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ), // ÄÃ£ sá»­a
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}








