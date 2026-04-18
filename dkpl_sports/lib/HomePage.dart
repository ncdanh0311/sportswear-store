import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'core/constants/app_colors.dart';
import 'core/user_session.dart';
import 'core/widgets/category_card.dart';
import 'core/widgets/product_card.dart';
import 'models/category_model.dart';
import 'models/product_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/orders/cart_page.dart';
import 'screens/products/search_page.dart';
import 'screens/profile/favorites_page.dart';
import 'screens/profile/profile_screen.dart';
import 'services/product_repository.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  bool isLogin = false;
  User? currentUser;
  late Future<List<ProductModel>> _productsFuture;
  String? _selectedCategory;
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  final Map<String, String> _categoryImages = const {
    'Bóng đá': 'assets/images/bongda.jpg',
    'Bóng rổ': 'assets/images/bongro.jpg',
    'Cầu lông': 'assets/images/caulong.jpg',
    'Tennis': 'assets/images/tennis.jpg',
  };

  // Khai báo key để có thể mở Drawer (Menu bên trái)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _productsFuture = ProductRepository.loadProducts();
  }

  void _checkLogin() {
    final user = FirebaseAuth.instance.currentUser;
    final localLoggedIn = UserSession().uid != null;
    if (mounted) {
      setState(() {
        isLogin = localLoggedIn || user != null;
        currentUser = user;
      });
    }
  }

  void _handleProfileClick() {
    _checkLogin();
    setState(() => _selectedIndex = 4);
  }

  void _swapTab(int index) {
    if (index == 4) {
      _checkLogin();
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  List<CategoryModel> _buildCategories(List<ProductModel> products) {
    final categories = <String>{};
    for (final item in products) {
      if (item.categoryId.isNotEmpty) categories.add(item.categoryId);
    }
    return categories
        .map(
          (name) => CategoryModel(
            id: name,
            name: name,
            image: _categoryImages[name] ?? 'assets/images/bongda.jpg',
          ),
        )
        .toList();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    if (_selectedCategory == null) return products;
    return products.where((p) => p.categoryId == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,

      // ================= DRAWER (MENU BÊN TRÁI) =================
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: Drawer(
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.primaryBlue,
                  child: const Text(
                    "Danh mục",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.sports_soccer, color: AppColors.textDark),
                  title: Text("Bóng đá"),
                ),
                const ListTile(
                  leading: Icon(
                    Icons.sports_basketball,
                    color: AppColors.textDark,
                  ),
                  title: Text("Bóng rổ"),
                ),
                const ListTile(
                  leading: Icon(Icons.sports_tennis, color: AppColors.textDark),
                  title: Text("Cầu lông"),
                ),
                const ListTile(
                  leading: Icon(Icons.sports_tennis, color: AppColors.textDark),
                  title: Text("Tennis"),
                ),
              ],
            ),
          ),
        ),
      ),

      // ================= APPBAR CHÍNH =================
      appBar: _selectedIndex == 0
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: const [
                  Text(
                    'DKPL',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    ' SPORTS',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: _handleProfileClick,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primaryBlue.withOpacity(.1),
                      backgroundImage: (() {
                        final avatar = UserSession().avatar?.trim() ?? '';
                        if (isLogin && avatar.isNotEmpty) {
                          return NetworkImage(avatar);
                        }
                        return const AssetImage('assets/images/avatar.jpg');
                      })() as ImageProvider<Object>,
                    ),
                  ),
                ),
              ],
            )
          : null,

      // ================= PHẦN THÂN CỦA APP (BODY) =================
      body: _buildBody(),

      // ================= THANH ĐIỀU HƯỚNG DƯỚI (BOTTOM NAV) =================
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: _selectedIndex,
        onTap: _swapTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Giỏ hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Yêu thích',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
        ],
      ),
    );
  }

  // Quản lý việc hiển thị Nội dung dựa trên Tab đang chọn
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab(); // Trang chủ
      case 1:
        return const CartPage(); // Nhúng trang Giỏ hàng
      case 2:
        return const FavoritesPage(); // Nhúng trang Yêu thích
      case 3:
        return const ChatListScreen();
      case 4:
        return _buildAccountTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildAccountTab() {
    if (isLogin) {
      return ProfileScreen(
        embedded: true,
        onLoggedOut: () {
          _checkLogin();
        },
      );
    }
    return LoginScreen(
      embedded: true,
      onLoginSuccess: () {
        _checkLogin();
        setState(() => _selectedIndex = 4);
      },
    );
  }

  // ================= GIAO DIỆN TAB TRANG CHỦ =================
  Widget _buildHomeTab() {
    return FutureBuilder<List<ProductModel>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoadingHome();
        }
        if (snapshot.hasError) {
          return _buildErrorHome(snapshot.error);
        }

        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return _buildEmptyHome();
        }

        final categories = _buildCategories(products);
        final filteredProducts = _filterProducts(products);
        if (filteredProducts.isEmpty) {
          return _buildEmptyCategory();
        }

        final totalPages =
            (filteredProducts.length / _itemsPerPage).ceil().clamp(1, 9999);
        final safePage = _currentPage.clamp(1, totalPages);
        final startIndex = (safePage - 1) * _itemsPerPage;
        final displayProducts = filteredProducts
            .skip(startIndex)
            .take(_itemsPerPage)
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(),
              const SizedBox(height: 6),
              _buildSearchRow(),
              const SizedBox(height: 24),
              _buildSectionHeader(
                title: 'Danh mục nổi bật',
                subtitle: 'Chọn nhanh theo môn thể thao',
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (categories.length <= 4) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: categories.map((category) {
                          final isSelected =
                              _selectedCategory == category.name;
                          return Expanded(
                            child: Center(
                              child: CategoryCard(
                                category: category,
                                isSelected: isSelected,
                                margin: EdgeInsets.zero,
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedCategory = null;
                                    } else {
                                      _selectedCategory = category.name;
                                    }
                                    _currentPage = 1;
                                  });
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }

                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: categories.map((category) {
                        final isSelected =
                            _selectedCategory == category.name;
                        return CategoryCard(
                          category: category,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedCategory = null;
                              } else {
                                      _selectedCategory = category.name;
                              }
                              _currentPage = 1;
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionHeader(
                title: _selectedCategory == null
                    ? 'Tất cả sản phẩm'
                    : 'Danh mục: $_selectedCategory',
                subtitle: _selectedCategory == null
                    ? 'Khám phá đầy đủ sản phẩm'
                    : 'Bấm lại danh mục để bỏ lọc',
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  itemBuilder: (context, index) {
                    return ProductCard(product: displayProducts[index]);
                  },
                ),
              ),
              _buildPagination(totalPages, safePage),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Sẵn sàng bứt phá',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Chọn đồ thể thao chính hãng, chuẩn phong độ.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.sports_soccer, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildHeroChip('Giao nhanh 2H', Icons.local_shipping),
              _buildHeroChip('Đổi trả 7 ngày', Icons.verified),
              _buildHeroChip('Ưu đãi mỗi tuần', Icons.local_offer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textDark),
              onPressed: () => _scaffoldKey.currentState!.openDrawer(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchPage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
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
                  children: const [
                    Icon(Icons.search, color: AppColors.textLight),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn cần tìm sản phẩm nào?',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingHome() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryBlue),
    );
  }

  Widget _buildErrorHome(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Không thể tải dữ liệu sản phẩm. Vui lòng thử lại.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textLight),
        ),
      ),
    );
  }

  Widget _buildEmptyHome() {
    return const Center(
      child: Text(
        'Chưa có dữ liệu sản phẩm.',
        style: TextStyle(color: AppColors.textLight),
      ),
    );
  }

  Widget _buildEmptyCategory() {
    return const Center(
      child: Text(
        'Danh mục này chưa có sản phẩm.',
        style: TextStyle(color: AppColors.textLight),
      ),
    );
  }

  Widget _buildPagination(int totalPages, int currentPage) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(totalPages, (index) {
            final page = index + 1;
            final isActive = page == currentPage;
            return GestureDetector(
              onTap: () {
                setState(() => _currentPage = page);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Text(
                  '$page',
                  style: TextStyle(
                    color: isActive ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
