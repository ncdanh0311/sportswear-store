import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/product_image.dart';
import '../../core/user_session.dart';
import '../../models/model_utils.dart';
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';
import '../../services/local_cart_service.dart';
import '../../services/product_repository.dart';
import '../products/product_detail_screen.dart';
import 'order_confirmation_screen.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _session = UserSession();
  final Set<String> _selectedIds = {};
  bool _selectionInitialized = false;

  Future<List<ProductModel>> _loadProducts() {
    return ProductRepository.loadProducts();
  }

  Future<List<Map<String, dynamic>>> _loadCart() {
    final uid = _session.uid;
    if (uid == null) return Future.value([]);
    return LocalCartService.instance.getCart(uid);
  }

  Map<String, ProductVariantModel> _buildVariantMap(
    List<ProductModel> products,
  ) {
    final map = <String, ProductVariantModel>{};
    for (final product in products) {
      for (final variant in product.variants) {
        map[variant.id] = variant;
      }
    }
    return map;
  }

  Map<String, ProductModel> _buildProductMap(List<ProductModel> products) {
    final map = <String, ProductModel>{};
    for (final product in products) {
      for (final variant in product.variants) {
        map[variant.id] = product;
      }
    }
    return map;
  }

  double _calcTotal(
    Map<String, ProductVariantModel> variants,
    List<Map<String, dynamic>> cart,
    Set<String> selectedIds,
  ) {
    double total = 0;
    for (final item in cart) {
      final id = item['variantId'];
      if (id == null || !selectedIds.contains(id.toString())) continue;
      final qty = (item['quantity'] as num?)?.toInt() ?? 1;
      final variant = variants[id.toString()];
      total += (variant?.price ?? 0) * qty;
    }
    return total;
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
            'Gi? h�ng',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Vui l?ng ��ng nh?p �? xem gi? h�ng.',
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
          'Giỏ hàng',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_loadProducts(), _loadCart()]),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Không thể tải giỏ hàng.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          final products = snapshot.data?[0] as List<ProductModel>? ?? [];
          final cart = snapshot.data?[1] as List<Map<String, dynamic>>? ?? [];
          final variantMap = _buildVariantMap(products);
          final productMap = _buildProductMap(products);

          if (cart.isEmpty) {
            return const Center(
              child: Text(
                'Giỏ hàng trống',
                style: TextStyle(fontSize: 16, color: AppColors.textLight),
              ),
            );
          }

          if (!_selectionInitialized) {
            for (final item in cart) {
              final id = item['variantId'];
              if (id != null) _selectedIds.add(id.toString());
            }
            _selectionInitialized = true;
          }

          final total = _calcTotal(variantMap, cart, _selectedIds);

          return Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cart.length,
                  itemBuilder: (context, index) {
                    final item = cart[index];
                    final id = item['variantId'];
                    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                    final product =
                        productMap[id.toString()] ??
                        ProductModel(
                          id: '',
                          name: 'Sản phẩm không tồn tại',
                          description: '',
                          categoryId: '',
                          brandId: '',
                          sportId: '',
                          thumbnail: '',
                          image: '',
                          isActive: false,
                          minPrice: 0,
                          maxPrice: 0,
                          images: const [],
                          rating: 0,
                          ratingCount: 0,
                          sold: 0,
                          variants: const [],
                        );
                    final variant = variantMap[id.toString()];
                    final isSelected = _selectedIds.contains(variant?.id ?? '');
                    return _CartItemCard(
                      product: product,
                      variant: variant,
                      quantity: qty,
                      isSelected: isSelected,
                      onToggleSelected: () {
                        setState(() {
                          final variantId = variant?.id ?? '';
                          if (variantId.isEmpty) return;
                          if (isSelected) {
                            _selectedIds.remove(variantId);
                          } else {
                            _selectedIds.add(variantId);
                          }
                        });
                      },
                      onOpenDetail: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: product),
                          ),
                        );
                      },
                      onRemove: () async {
                        final variantId = variant?.id ?? '';
                        if (variantId.isEmpty) return;
                        await LocalCartService.instance.removeFromCart(
                          uid: _session.uid!,
                          variantId: variantId,
                        );
                        _selectedIds.remove(variantId);
                        setState(() {});
                      },
                      onQuantityChanged: (newQty) async {
                        final variantId = variant?.id ?? '';
                        if (variantId.isEmpty) return;
                        await LocalCartService.instance.updateQuantity(
                          uid: _session.uid!,
                          variantId: variantId,
                          quantity: newQty,
                        );
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
              _CartSummary(
                total: total,
                selectedCount: _selectedIds.length,
                onCheckout: () {
                  if (_selectedIds.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Hãy chọn sản phẩm để mua')),
                    );
                    return;
                  }
                  final items = <OrderItem>[];
                  for (final item in cart) {
                    final id = item['variantId'];
                    if (id == null || !_selectedIds.contains(id)) continue;
                    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
                    final product = productMap[id.toString()];
                    final variant = variantMap[id.toString()];
                    if (product != null && variant != null) {
                      items.add(
                        OrderItem(
                          product: product,
                          variant: variant,
                          quantity: qty,
                        ),
                      );
                    }
                  }
                  if (items.isEmpty) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderConfirmationScreen(
                        items: items,
                        cartVariantIdsToClear: _selectedIds
                            .map((e) => e.toString())
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final ProductModel product;
  final ProductVariantModel? variant;
  final int quantity;
  final bool isSelected;
  final VoidCallback onToggleSelected;
  final VoidCallback onOpenDetail;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const _CartItemCard({
    required this.product,
    required this.variant,
    required this.quantity,
    required this.isSelected,
    required this.onToggleSelected,
    required this.onOpenDetail,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (_) => onToggleSelected(),
            activeColor: AppColors.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          GestureDetector(
            onTap: onOpenDetail,
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ProductImage(
                      src: product.image,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onOpenDetail,
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
                    variant?.size ?? '',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ModelUtils.formatVnd(variant?.price ?? 0),
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: onRemove,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 16),
                      onPressed: quantity > 1
                          ? () => onQuantityChanged(quantity - 1)
                          : null,
                    ),
                    Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 16),
                      onPressed: () => onQuantityChanged(quantity + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double total;
  final int selectedCount;
  final VoidCallback onCheckout;

  const _CartSummary({
    required this.total,
    required this.selectedCount,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đã chọn $selectedCount sản phẩm',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ModelUtils.formatVnd(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: onCheckout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mua ngay',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
