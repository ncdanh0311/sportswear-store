import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/product_card.dart';
import '../../models/product_model.dart';
import '../../services/product_repository.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<ProductModel> _allProducts = [];
  List<ProductModel> _results = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await ProductRepository.loadProducts();
    if (!mounted) return;
    setState(() {
      _allProducts = data;
      _results = data;
    });
  }

  void _onSearchChanged(String value) {
    final keyword = value.trim().toLowerCase();
    if (keyword.isEmpty) {
      setState(() => _results = _allProducts);
      return;
    }
    setState(() {
      _results = _allProducts.where((p) {
        return p.name.toLowerCase().contains(keyword) ||
            p.categoryId.toLowerCase().contains(keyword) ||
            p.description.toLowerCase().contains(keyword);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: _buildSearchBar(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kết quả (${_results.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy sản phẩm phù hợp',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    )
                  : GridView.builder(
                      itemCount: _results.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemBuilder: (context, index) {
                        return ProductCard(product: _results[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
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
          const SizedBox(width: 12),
          const Icon(Icons.search, color: AppColors.textLight),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textLight),
            onPressed: () {
              _searchCtrl.clear();
              _onSearchChanged('');
            },
          ),
        ],
      ),
    );
  }
}
