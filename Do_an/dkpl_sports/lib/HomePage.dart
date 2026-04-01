import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import 'core/widgets/category_card.dart';
import 'core/widgets/product_card.dart';
import 'models/category_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/orders/cart_page.dart';
import 'screens/products/search_page.dart';
import 'screens/profile/favorites_page.dart';
import 'screens/profile/profile_screen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _selectedIndex = 0;
  bool isLogin = false;
  User? currentUser;

  // Khai báo key để có thể mở Drawer (Menu bên trái)
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    final user = FirebaseAuth.instance.currentUser;
    if (mounted) {
      setState(() {
        isLogin = user != null;
        currentUser = user;
      });
    }
  }

  void _handleProfileClick() {
    if (isLogin) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      ).then((_) {
        _checkLogin();
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      ).then((_) {
        _checkLogin();
      });
    }
  }

  void _swapTab(int index) {
    if (index == 3) {
      // Nếu bấm vào tab "Tài khoản", gọi luôn hàm xử lý profile/login (Không cần chuyển Tab)
      _handleProfileClick();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // ===== DATA DUMMY CHO TRANG CHỦ =====
  final categories = [
    CategoryModel(title: 'Bóng đá', image: 'assets/images/bongda.jpg'),
    CategoryModel(title: 'Bóng rổ', image: 'assets/images/bongro.jpg'),
    CategoryModel(title: 'Cầu lông', image: 'assets/images/caulong.jpg'),
    CategoryModel(title: 'Tennis', image: 'assets/images/tennis.jpg'),
  ];

  final products = List.generate(
    6,
    (index) => {
      "image": "assets/images/aocr7.jpg",
      "name": "Áo bóng đá Cristiano Ronaldo SIUU ${index + 1}",
      "weight": "Size XL",
    },
  );

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
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'DKPL SPORTS',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // Avatar góc phải
          GestureDetector(
            onTap: _handleProfileClick,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(
                  isLogin
                      ? 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRD0Y5uEmFetc0Xb25SAiiO4ZwYE8g7r8HBug&s'
                      : 'https://i.pinimg.com/736x/8f/1c/a2/8f1ca2029e2efceebd22fa05cca423d7.jpg',
                ),
              ),
            ),
          ),
        ],
      ),

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
      default:
        // Tab 3 được chặn bằng nút xử lý Login ở trên nên trả về rỗng
        return const SizedBox();
    }
  }

  // ================= GIAO DIỆN TAB TRANG CHỦ =================
  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== MENU TRƯỢT & TÌM KIẾM =====
          Row(
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
                  onPressed: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                ),
              ),
              const SizedBox(width: 12),

              // Nút Search nhảy sang SearchPage
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
          const SizedBox(height: 24),

          // ===== DANH MỤC THỂ THAO =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Danh mục',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: categories.map((category) {
                    return Expanded(
                      child: Center(child: CategoryCard(category: category)),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ===== SẢN PHẨM NỔI BẬT =====
          const Text(
            'Sản phẩm nổi bật',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),

          // ===== GRID VIEW SẢN PHẨM =====
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio:
                  0.60, // Tùy chỉnh để không bị lỗi tràn viền (overflow)
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                image: product["image"]!,
                name: product["name"]!,
                weight: product["weight"]!,
              );
            },
          ),
        ],
      ),
    );
  }
}
