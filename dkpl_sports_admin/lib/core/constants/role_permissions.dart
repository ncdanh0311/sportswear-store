enum AppModule {
  dashboard,
  orders,
  products,
  inventory,
  chat,
  events,
  vouchers,
  staff,
}

class RolePermissions {
  static const String sales = 'sales';
  static const String warehouse = 'warehouse';
  static const String accounting = 'accounting';
  static const String manager = 'manager';
  static const String admin = 'admin';
  static const String owner = 'owner';

  static String normalizeRole(String? role) {
    final raw = (role ?? '').trim().toLowerCase();
    switch (raw) {
      case 'cskh':
      case 'sales_staff':
      case 'sale':
        return sales;
      case 'storage':
      case 'warehouse_staff':
      case 'kho':
        return warehouse;
      case 'account':
      case 'accountant':
      case 'accounting_staff':
      case 'ketoan':
        return accounting;
      case 'manager':
        return manager;
      case 'admin':
        return admin;
      case 'owner':
        return owner;
      default:
        return raw;
    }
  }

  static bool isManagerLike(String? role) {
    final normalized = normalizeRole(role);
    return normalized == manager || normalized == admin || normalized == owner;
  }

  static bool canManageProducts(String? role) => isManagerLike(role);

  static bool canManageVariants(String? role) {
    final normalized = normalizeRole(role);
    return normalized == warehouse || isManagerLike(normalized);
  }

  static bool canManageInventory(String? role) {
    final normalized = normalizeRole(role);
    return normalized == warehouse || isManagerLike(normalized);
  }

  static bool canManageVouchers(String? role) {
    final normalized = normalizeRole(role);
    return normalized == accounting || isManagerLike(normalized);
  }

  static bool canViewRevenueReport(String? role) {
    final normalized = normalizeRole(role);
    return normalized == accounting || isManagerLike(normalized);
  }

  static bool canManageStaff(String? role) => isManagerLike(role);

  static bool canUpdateOrderStatus(String? role) {
    final normalized = normalizeRole(role);
    return normalized == sales || isManagerLike(normalized);
  }

  static bool paidOnlyModeForOrders(String? role) =>
      normalizeRole(role) == accounting;

  static List<AppModule> modulesForRole(String? role) {
    final normalized = normalizeRole(role);

    switch (normalized) {
      case sales:
        return const [AppModule.orders, AppModule.chat];
      case warehouse:
        return const [AppModule.inventory, AppModule.products];
      case accounting:
        return const [AppModule.orders, AppModule.vouchers, AppModule.dashboard];
      case 'content':
        return const [AppModule.products, AppModule.events, AppModule.vouchers];
      case manager:
      case admin:
      case owner:
        return const [
          AppModule.dashboard,
          AppModule.orders,
          AppModule.products,
          AppModule.inventory,
          AppModule.chat,
          AppModule.events,
          AppModule.vouchers,
          AppModule.staff,
        ];
      default:
        return const [AppModule.orders];
    }
  }

  static String roleLabel(String? role) {
    switch (normalizeRole(role)) {
      case sales:
        return 'Bán hàng';
      case warehouse:
        return 'Kho';
      case accounting:
        return 'Kế toán';
      case manager:
        return 'Quản lý';
      case admin:
        return 'Admin';
      case owner:
        return 'Owner';
      case 'content':
        return 'Content/Marketing';
      default:
        return 'Nhân viên';
    }
  }
}
