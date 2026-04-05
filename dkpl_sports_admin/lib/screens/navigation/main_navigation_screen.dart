import 'package:flutter/material.dart';

// --- IMPORTS CORE & SERVICES ---
import 'package:dkpl_sports_admin/services/product_service.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';

// --- IMPORTS CÁC MÀN HÌNH CHỨC NĂNG CỦA TỪNG TAB ---
import 'package:dkpl_sports_admin/screens/products/product_list_screen.dart';
import 'package:dkpl_sports_admin/screens/events/list_event_screen.dart';
import 'package:dkpl_sports_admin/screens/vouchers/voucher_list_screen.dart';
import 'package:dkpl_sports_admin/screens/dashboard/dashboard_screen.dart';
import 'package:dkpl_sports_admin/screens/chat/chat_list_screen.dart';
import 'package:dkpl_sports_admin/screens/inventory/inventory_screen.dart'; // Đã thay thế thành InventoryScreen kết nối Firebase
import 'package:dkpl_sports_admin/screens/orders/duyetdon.dart';
import 'package:dkpl_sports_admin/screens/staff/staff_list_screen.dart';

// =========================================================================
// MÀN HÌNH ĐIỀU HƯỚNG CHÍNH (HUB) - TỰ ĐỘNG PHÂN TAB THEO ROLE
// =========================================================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final ProductService _productService = ProductService();
  int _currentIndex = 0;

  List<Widget> _pages = [];
  List<BottomNavigationBarItem> _navItems = [];

  @override
  void initState() {
    super.initState();
    _productService.autoCheckExpiredEvents();
    _buildTabsByRole();
  }

  void _buildTabsByRole() {
    final rawRole = AuthService.instance.currentUser?.role;
    final role = RolePermissions.normalizeRole(rawRole);
    final modules = RolePermissions.modulesForRole(role);

    _pages = [];
    _navItems = [];

    // --- KHỞI TẠO CÁC MODULE TAB ---
    final tabSanPham = const ProductListScreen();
    final itemSanPham = const BottomNavigationBarItem(
      icon: Icon(Icons.shopping_bag_outlined),
      label: 'Sản phẩm',
    );

    // Đã thay đổi ở đây: Dùng InventoryScreen
    final tabKho = const InventoryScreen();
    final itemKho = const BottomNavigationBarItem(
      icon: Icon(Icons.inventory_2_outlined),
      label: 'Kho',
    );

    final tabChat = const ChatListScreen();
    final itemChat = const BottomNavigationBarItem(
      icon: Badge(label: Text('7'), child: Icon(Icons.chat_bubble_outline_rounded)),
      label: 'Chat',
    );

    final tabDonHang = DuyetDonScreen(
      canUpdateStatus: RolePermissions.canUpdateOrderStatus(role),
      paidOnlyMode: RolePermissions.paidOnlyModeForOrders(role),
    );
    final itemDonHang = const BottomNavigationBarItem(
      icon: Icon(Icons.receipt_long_outlined),
      label: 'Đơn hàng',
    );

    final tabEvent = const ListEventScreen();
    final itemEvent = const BottomNavigationBarItem(
      icon: Icon(Icons.event_note_rounded),
      label: 'Event',
    );

    final tabVoucher = const VoucherListScreen();
    final itemVoucher = const BottomNavigationBarItem(
      icon: Icon(Icons.local_activity_outlined),
      label: 'Voucher',
    );

    final tabThongKe = const DashboardScreen();
    final itemThongKe = const BottomNavigationBarItem(
      icon: Icon(Icons.bar_chart_rounded),
      label: 'Thống kê',
    );

    final tabNhanVien = const StaffListScreen();
    final itemNhanVien = const BottomNavigationBarItem(
      icon: Icon(Icons.manage_accounts_outlined),
      label: 'Nhân sự',
    );

    // --- PHÂN QUYỀN VÀ LẮP RÁP ---
    for (final module in modules) {
      switch (module) {
        case AppModule.dashboard:
          _pages.add(tabThongKe);
          _navItems.add(itemThongKe);
          break;
        case AppModule.orders:
          _pages.add(tabDonHang);
          _navItems.add(itemDonHang);
          break;
        case AppModule.products:
          _pages.add(tabSanPham);
          _navItems.add(itemSanPham);
          break;
        case AppModule.inventory:
          _pages.add(tabKho);
          _navItems.add(itemKho);
          break;
        case AppModule.chat:
          _pages.add(tabChat);
          _navItems.add(itemChat);
          break;
        case AppModule.events:
          _pages.add(tabEvent);
          _navItems.add(itemEvent);
          break;
        case AppModule.vouchers:
          _pages.add(tabVoucher);
          _navItems.add(itemVoucher);
          break;
        case AppModule.staff:
          _pages.add(tabNhanVien);
          _navItems.add(itemNhanVien);
          break;
      }
    }

    if (_pages.isEmpty) {
      _pages = [tabDonHang];
      _navItems = [itemDonHang];
    }

    if (_currentIndex >= _pages.length) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Theme(
        data: Theme.of(
          context,
        ).copyWith(splashColor: Colors.transparent, highlightColor: Colors.transparent),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppColors.primaryNavy,
          selectedItemColor: AppColors.accentCyan,
          unselectedItemColor: Colors.white54,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 9,
          items: _navItems,
        ),
      ),
    );
  }
}

