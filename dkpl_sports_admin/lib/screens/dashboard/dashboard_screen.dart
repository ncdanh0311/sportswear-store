import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/dashboard_models.dart';
import 'package:dkpl_sports_admin/models/order_item_model.dart';
import 'package:dkpl_sports_admin/models/order_model.dart';
import 'package:dkpl_sports_admin/models/product_model.dart';
import 'package:dkpl_sports_admin/models/variant_model.dart';
import 'package:dkpl_sports_admin/services/auth_service.dart';

// ── DATA ──────────────────────────────────────────────────────────────────────
// ── SCREEN ────────────────────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _period = 'Tuần này';
  final _periods = ['Hôm nay', 'Tuần này', 'Tháng này', 'Quý này'];

  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  final NumberFormat _moneyFormat =
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  Widget build(BuildContext context) {
    final canViewReport = RolePermissions.canViewRevenueReport(
      AuthService.instance.currentUser?.roleId,
    );

    if (!canViewReport) {
      return BaseBackground(
        appBar: AppBar(
          title: const Text('Báo Cáo Doanh Thu'),
        ),
        child: const Center(
          child: Text(
            'Bạn không có quyền xem báo cáo doanh thu.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return BaseBackground(
      appBar: AppBar(
        title: const Text('Báo Cáo Doanh Thu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {},
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, orderSnap) {
          if (orderSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = orderSnap.data?.docs
                  .map((doc) => OrderModel.fromFirestore(doc))
                  .toList() ??
              [];

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('order_items').snapshots(),
            builder: (context, itemSnap) {
              if (itemSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final orderItems = itemSnap.data?.docs
                      .map((doc) => OrderItemModel.fromMap({
                            'id': doc.id,
                            ...doc.data() as Map<String, dynamic>,
                          }))
                      .toList() ??
                  [];

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('product_variants')
                    .snapshots(),
                builder: (context, variantSnap) {
                  if (variantSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final variantMap = <String, VariantModel>{};
                  for (final doc in variantSnap.data?.docs ?? []) {
                    variantMap[doc.id] = VariantModel.fromFirestore(doc);
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .snapshots(),
                    builder: (context, productSnap) {
                      if (productSnap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final productMap = <String, ProductModel>{};
                      for (final doc in productSnap.data?.docs ?? []) {
                        productMap[doc.id] = ProductModel.fromFirestore(doc);
                      }

                      final data = _computeDashboardData(
                        orders,
                        orderItems,
                        variantMap,
                        productMap,
                      );

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDateRangeRow(),
                            const SizedBox(height: 12),
                            _buildPeriodTabs(),
                            const SizedBox(height: 16),
                            _buildKpiGrid(data.kpis),
                            const SizedBox(height: 16),
                            _buildRevenueChart(
                              data.revenueByDay,
                              data.ordersByDay,
                              data.dayLabels,
                            ),
                            const SizedBox(height: 16),
                            _buildDonutAndWeekly(
                              data.categories,
                              data.weekData,
                            ),
                            const SizedBox(height: 16),
                            _buildCategoryTable(data.categories),
                            const SizedBox(height: 16),
                            _buildTopProducts(data.topProducts),
                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // ── DATE RANGE ──
  Widget _buildDateRangeRow() {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        final datePicker = GestureDetector(
          onTap: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2024),
              lastDate: DateTime.now(),
              initialDateRange: _dateRange,
              builder: (context, child) => Theme(
                data: ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.accentCyan,
                    surface: AppColors.backgroundLight,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _dateRange = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0x1AFFFFFF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded,
                    size: 16, color: AppColors.accentCyan),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${fmt(_dateRange.start)} – ${fmt(_dateRange.end)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        );

        final exportButton = Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accentCyan, AppColors.primaryBlue],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentCyan.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.download_rounded, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Xuất Excel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              datePicker,
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: exportButton),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: datePicker),
            const SizedBox(width: 10),
            exportButton,
          ],
        );
      },
    );
  }

  // ── PERIOD TABS ──
  Widget _buildPeriodTabs() {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: _periods.map((p) {
          final active = _period == p;
          return Expanded(
            child: GestureDetector(
              onTap: () => _setPeriod(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.accentCyan.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: active
                      ? Border.all(color: AppColors.accentCyan.withOpacity(0.3))
                      : null,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.accentCyan : AppColors.textSecondary,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _setPeriod(String p) {
    setState(() {
      _period = p;
      _dateRange = _rangeForPeriod(p);
    });
  }

  DateTimeRange _rangeForPeriod(String p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (p == 'Hôm nay') {
      return DateTimeRange(start: today, end: now);
    }
    if (p == 'Tuần này') {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return DateTimeRange(start: start, end: now);
    }
    if (p == 'Tháng này') {
      final start = DateTime(now.year, now.month, 1);
      return DateTimeRange(start: start, end: now);
    }
    if (p == 'Quý này') {
      final quarter = ((now.month - 1) ~/ 3) + 1;
      final startMonth = (quarter - 1) * 3 + 1;
      final start = DateTime(now.year, startMonth, 1);
      return DateTimeRange(start: start, end: now);
    }
    return DateTimeRange(start: today, end: now);
  }

  String _formatRangeLabel() {
    final start = _dateRange.start;
    final end = _dateRange.end;
    return '${start.day.toString().padLeft(2, '0')}/${start.month.toString().padLeft(2, '0')}'
        ' – ${end.day.toString().padLeft(2, '0')}/${end.month.toString().padLeft(2, '0')}';
  }

  // ── KPI GRID ──
  Widget _buildKpiGrid(List<KpiModel> kpis) {
    final width = MediaQuery.of(context).size.width;
    final cardHeight = width < 380 ? 150.0 : 140.0;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: cardHeight,
      ),
      itemCount: kpis.length,
      itemBuilder: (_, i) => _KpiCard(data: kpis[i]),
    );
  }

  // ── REVENUE CHART ──
  Widget _buildRevenueChart(
    List<double> revenueData,
    List<double> ordersData,
    List<String> dayLabels,
  ) {
    return DKPLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Doanh Thu Theo Ngày',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Trong kỳ ${_formatRangeLabel()} · tổng ${_moneyFormat.format(revenueData.fold(0.0, (a, b) => a + b) * 1000000)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _LegendDot(color: Color(0xFF00D4FF), label: 'Doanh thu'),
                  _LegendDot(color: Color(0xFF00E5A0), label: 'Đơn hàng'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBorder: const BorderSide(
                      color: Color(0x4D00D4FF),
                    ),
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${dayLabels[group.x]}\n${rod.toY}M₫',
                      const TextStyle(
                        color: AppColors.accentCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          dayLabels[v.toInt()],
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (v, _) => Text(
                        '${v.toInt()}M',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0x0DFFFFFF),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  revenueData.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: revenueData[i],
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: i == revenueData.length - 2
                              ? [const Color(0xFF00FFD4), AppColors.accentCyan]
                              : [AppColors.accentCyan, AppColors.primaryBlue],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DONUT + WEEKLY ──
  Widget _buildDonutAndWeekly(
    List<CategoryModel> categories,
    List<_WeekPoint> weekData,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;
        if (isNarrow) {
          return Column(
            children: [
              _buildCategoryDonut(categories),
              const SizedBox(height: 12),
              _buildWeeklyMiniStats(weekData),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: _buildCategoryDonut(categories)),
            const SizedBox(width: 12),
            Expanded(child: _buildWeeklyMiniStats(weekData)),
          ],
        );
      },
    );
  }

  // ── CATEGORY DONUT ──
  Widget _buildCategoryDonut(List<CategoryModel> categories) {
    final topCategories = categories.take(4).toList();
    final totalPct = topCategories.fold<double>(0, (s, c) => s + c.pct);
    final normalized = totalPct == 0 ? topCategories : topCategories;
    return DKPLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Danh Mục',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Tỉ trọng doanh thu',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: normalized.isEmpty
                    ? [
                        PieChartSectionData(
                          value: 100,
                          color: Colors.white24,
                          radius: 28,
                          title: '0%',
                          titleStyle: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ]
                    : normalized
                        .map((c) => PieChartSectionData(
                              value: c.pct,
                              color: c.color,
                              radius: 28,
                              title: '${c.pct.toStringAsFixed(0)}%',
                              titleStyle: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ))
                        .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: normalized
                .map((c) => _LegendDot(color: c.color, label: c.name))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── WEEKLY MINI STATS ──
  Widget _buildWeeklyMiniStats(List<_WeekPoint> weekData) {
    final maxPoint = weekData.isEmpty
        ? null
        : (weekData.firstWhere(
            (e) => e.isMax,
            orElse: () => weekData.first,
          ));
    return DKPLCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Theo Ngày',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Biểu đồ doanh thu 7 ngày',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weekData.map((d) {
              final maxValue =
                  weekData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
              final pct = d.value == 0 ? 0.0 : d.value / maxValue;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            height: 80 * pct,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: d.isMax
                                    ? [const Color(0xFF00FFD4), AppColors.accentCyan]
                                    : [AppColors.accentCyan, AppColors.primaryBlue],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        d.label,
                        style: TextStyle(
                          fontSize: 9,
                          color: d.isMax ? AppColors.accentCyan : AppColors.textSecondary,
                          fontWeight: d.isMax ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: maxPoint == null
                ? []
                : [
                    Expanded(
                      child: _MiniStatChip(
                        label: 'Cao nhất',
                        value: maxPoint.label,
                        color: AppColors.accentCyan,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStatChip(
                        label: 'Đỉnh ngày',
                        value: '${maxPoint.value.toStringAsFixed(1)}M',
                        color: Color(0xFFFFB347),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }

  // ── CATEGORY TABLE ──
  Widget _buildCategoryTable(List<CategoryModel> categories) {
    return DKPLCard(
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
                      'Phân Tích Danh Mục',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Số sản phẩm bán & doanh thu theo danh mục',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text('Danh Mục',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary, letterSpacing: 0.8),
                  ),
                ),
                const SizedBox(
                  width: 40,
                  child: Text('SP', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(
                  width: 70,
                  child: Text('Doanh Thu', textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Color(0xFFE0E0E0), height: 1),
          const SizedBox(height: 4),
          ...categories.map((c) => _CategoryRow(data: c)),
        ],
      ),
    );
  }

  // ── TOP PRODUCTS ──
  Widget _buildTopProducts(List<TopProductModel> products) {
    return DKPLCard(
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
                      'Sản Phẩm Bán Chạy',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Top 5 tuần này theo doanh thu',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentCyan.withOpacity(0.2)),
                ),
                child: const Text(
                  'Xem tất cả →',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.accentCyan,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...products.map((p) => _ProductRow(product: p)),
        ],
      ),
    );
  }

  _DashboardData _computeDashboardData(
    List<OrderModel> orders,
    List<OrderItemModel> orderItems,
    Map<String, VariantModel> variantMap,
    Map<String, ProductModel> productMap,
  ) {
    final orderItemsByOrderId = <String, List<OrderItemModel>>{};
    for (final item in orderItems) {
      if (item.orderId.isEmpty) continue;
      orderItemsByOrderId.putIfAbsent(item.orderId, () => []).add(item);
    }

    final filtered = orders.where((o) => _inRange(o.createdAt)).toList();

    double revenue = 0;
    int completed = 0;
    int cancelled = 0;

    for (final o in filtered) {
      final items = orderItemsByOrderId[o.id] ?? const <OrderItemModel>[];
      final total = _orderTotal(o, items);
      revenue += total;
      if (o.status == 'completed') completed += 1;
      if (o.status == 'cancelled') cancelled += 1;
    }

    final prevRange = _previousRange();
    final prevOrders =
        orders.where((o) => _inRange(o.createdAt, range: prevRange)).toList();
    final prevRevenue = prevOrders.fold<double>(
        0,
        (sum, o) => sum + _orderTotal(o, orderItemsByOrderId[o.id] ?? const []));
    final prevCompleted =
        prevOrders.where((o) => o.status == 'completed').length;
    final prevCancelled =
        prevOrders.where((o) => o.status == 'cancelled').length;

    final totalOrders = filtered.length;
    final cancelRate = totalOrders == 0 ? 0 : (cancelled / totalOrders) * 100;

    final dayStats = _buildDailyStats(filtered, orderItemsByOrderId);

    final kpis = [
      KpiModel(
        'Doanh Thu',
        _moneyFormat.format(revenue),
        _formatChange(revenue, prevRevenue),
        '💰',
        revenue >= prevRevenue,
        AppColors.accentCyan,
        dayStats.revenueByDay,
      ),
      KpiModel(
        'Đơn Hoàn Thành',
        completed.toString(),
        _formatChange(completed.toDouble(), prevCompleted.toDouble()),
        '📦',
        completed >= prevCompleted,
        Color(0xFF00E5A0),
        dayStats.completedByDay,
      ),
      KpiModel(
        'Tổng Đơn',
        totalOrders.toString(),
        _formatChange(totalOrders.toDouble(), prevOrders.length.toDouble()),
        '🧾',
        totalOrders >= prevOrders.length,
        Color(0xFFFFB347),
        dayStats.ordersByDay,
      ),
      KpiModel(
        'Hủy/Hoàn',
        '${cancelRate.toStringAsFixed(1)}%',
        _formatChange(cancelled.toDouble(), prevCancelled.toDouble()),
        '↩️',
        cancelled <= prevCancelled,
        AppColors.error,
        dayStats.cancelledByDay,
      ),
    ];

    final categories = _buildCategoryStats(
      filtered,
      orderItemsByOrderId,
      variantMap,
      productMap,
    );
    final topProducts = _buildTopProductsStats(
      filtered,
      orderItemsByOrderId,
      variantMap,
      productMap,
    );

    return _DashboardData(
      kpis: kpis,
      revenueByDay: dayStats.revenueByDay,
      ordersByDay: dayStats.ordersByDay,
      dayLabels: dayStats.labels,
      weekData: dayStats.weekPoints,
      categories: categories,
      topProducts: topProducts,
    );
  }

  bool _inRange(DateTime? dt, {DateTimeRange? range}) {
    if (dt == null) return false;
    final r = range ?? _dateRange;
    return !dt.isBefore(r.start) && !dt.isAfter(r.end);
  }

  DateTimeRange _previousRange() {
    final days = _dateRange.duration.inDays == 0 ? 1 : _dateRange.duration.inDays;
    final prevEnd = _dateRange.start.subtract(const Duration(days: 1));
    final prevStart = prevEnd.subtract(Duration(days: days));
    return DateTimeRange(start: prevStart, end: prevEnd);
  }

  String _formatChange(double current, double previous) {
    if (previous == 0) {
      return current == 0 ? '0%' : '+100%';
    }
    final diff = ((current - previous) / previous) * 100;
    final sign = diff >= 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)}%';
  }

  _DayStats _buildDailyStats(
    List<OrderModel> orders,
    Map<String, List<OrderItemModel>> orderItemsByOrderId,
  ) {
    final end = DateTime(
      _dateRange.end.year,
      _dateRange.end.month,
      _dateRange.end.day,
    );
    final days = List<DateTime>.generate(
      7,
      (i) => end.subtract(Duration(days: 6 - i)),
    );

    final revenueByDay = List<double>.filled(7, 0);
    final ordersByDay = List<double>.filled(7, 0);
    final completedByDay = List<double>.filled(7, 0);
    final cancelledByDay = List<double>.filled(7, 0);

    for (final o in orders) {
      final dt = o.createdAt;
      if (dt == null) continue;
      for (int i = 0; i < days.length; i++) {
        final d = days[i];
        if (dt.year == d.year && dt.month == d.month && dt.day == d.day) {
          final items = orderItemsByOrderId[o.id] ?? const <OrderItemModel>[];
          final total = _orderTotal(o, items);
          revenueByDay[i] += total / 1000000;
          ordersByDay[i] += 1;
          if (o.status == 'completed') completedByDay[i] += 1;
          if (o.status == 'cancelled') cancelledByDay[i] += 1;
        }
      }
    }

    final maxRevenue = revenueByDay.isEmpty
        ? 0
        : revenueByDay.reduce((a, b) => a > b ? a : b);
    final weekPoints = List<_WeekPoint>.generate(7, (i) {
      return _WeekPoint(
        label: _weekdayLabel(days[i]),
        value: revenueByDay[i],
        isMax: revenueByDay[i] == maxRevenue && maxRevenue > 0,
      );
    });

    final labels = days.map(_weekdayLabel).toList();

    return _DayStats(
      revenueByDay: revenueByDay,
      ordersByDay: ordersByDay,
      completedByDay: completedByDay,
      cancelledByDay: cancelledByDay,
      labels: labels,
      weekPoints: weekPoints,
    );
  }

  List<CategoryModel> _buildCategoryStats(
    List<OrderModel> orders,
    Map<String, List<OrderItemModel>> orderItemsByOrderId,
    Map<String, VariantModel> variantMap,
    Map<String, ProductModel> productMap,
  ) {
    final map = <String, _CategoryAgg>{};

    for (final o in orders) {
      final items = orderItemsByOrderId[o.id] ?? const <OrderItemModel>[];
      for (final item in items) {
        final variant = variantMap[item.variantId];
        final product =
            variant == null ? null : productMap[variant.productId];
        final category = (product?.categoryId.isNotEmpty == true)
            ? product!.categoryId
            : 'Khác';
        map.putIfAbsent(category, () => _CategoryAgg(category));
        map[category]!.revenue += item.price * item.quantity;
        map[category]!.sold += item.quantity;
      }
    }

    final totalRevenue =
        map.values.fold<double>(0, (s, c) => s + c.revenue);
    final colors = [
      AppColors.accentCyan,
      Color(0xFF00E5A0),
      Color(0xFFFFB347),
      Color(0xFFA78BFA),
      Color(0xFF4FD1C5),
    ];

    final sorted = map.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return List<CategoryModel>.generate(sorted.length, (i) {
      final c = sorted[i];
      final pct = totalRevenue == 0 ? 0.0 : (c.revenue / totalRevenue) * 100;
      return CategoryModel(
        c.name,
        _emojiForCategory(c.name),
        c.sold,
        _moneyFormat.format(c.revenue),
        pct,
        colors[i % colors.length],
      );
    });
  }

  List<TopProductModel> _buildTopProductsStats(
    List<OrderModel> orders,
    Map<String, List<OrderItemModel>> orderItemsByOrderId,
    Map<String, VariantModel> variantMap,
    Map<String, ProductModel> productMap,
  ) {
    final map = <String, _ProductAgg>{};
    for (final o in orders) {
      final items = orderItemsByOrderId[o.id] ?? const <OrderItemModel>[];
      for (final item in items) {
        final variant = variantMap[item.variantId];
        final product =
            variant == null ? null : productMap[variant.productId];
        final name = product?.name ?? 'Sản phẩm';
        map.putIfAbsent(name, () => _ProductAgg(name));
        map[name]!.sold += item.quantity;
        map[name]!.revenue += item.price * item.quantity;
      }
    }

    final sorted = map.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return List<TopProductModel>.generate(
      sorted.take(5).length,
      (i) {
        final p = sorted[i];
        return TopProductModel(
          i + 1,
          p.name,
          _emojiForCategory(p.name),
          p.sold,
          'Đã bán',
          _moneyFormat.format(p.revenue),
        );
      },
    );
  }

  double _orderTotal(
    OrderModel order,
    List<OrderItemModel> items,
  ) {
    if (order.total > 0) return order.total;
    return items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  String _weekdayLabel(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      default:
        return 'CN';
    }
  }

  String _emojiForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('áo')) return '👕';
    if (lower.contains('quần')) return '👖';
    if (lower.contains('giày')) return '👟';
    if (lower.contains('phụ kiện')) return '🧢';
    return '🏷️';
  }
}

class _DashboardData {
  final List<KpiModel> kpis;
  final List<double> revenueByDay;
  final List<double> ordersByDay;
  final List<String> dayLabels;
  final List<_WeekPoint> weekData;
  final List<CategoryModel> categories;
  final List<TopProductModel> topProducts;

  _DashboardData({
    required this.kpis,
    required this.revenueByDay,
    required this.ordersByDay,
    required this.dayLabels,
    required this.weekData,
    required this.categories,
    required this.topProducts,
  });
}

class _DayStats {
  final List<double> revenueByDay;
  final List<double> ordersByDay;
  final List<double> completedByDay;
  final List<double> cancelledByDay;
  final List<String> labels;
  final List<_WeekPoint> weekPoints;

  _DayStats({
    required this.revenueByDay,
    required this.ordersByDay,
    required this.completedByDay,
    required this.cancelledByDay,
    required this.labels,
    required this.weekPoints,
  });
}

class _WeekPoint {
  final String label;
  final double value;
  final bool isMax;

  _WeekPoint({
    required this.label,
    required this.value,
    required this.isMax,
  });
}

class _CategoryAgg {
  final String name;
  double revenue = 0;
  int sold = 0;

  _CategoryAgg(this.name);
}

class _ProductAgg {
  final String name;
  double revenue = 0;
  int sold = 0;

  _ProductAgg(this.name);
}

// ── REUSABLE WIDGETS ──────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final KpiModel data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F274D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: data.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(data.icon, style: const TextStyle(fontSize: 18)),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (data.isUp ? const Color(0xFF00E5A0) : const Color(0xFFFF5252))
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.change,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: data.isUp ? Color(0xFF00E5A0) : Color(0xFFFF5252),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const Spacer(),
          SizedBox(height: 22, child: _Sparkline(data: data.spark, color: data.accent)),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = max - min == 0 ? 1.0 : max - min;

    return SizedBox(
      height: 28,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: min - range * 0.1,
          maxY: max + range * 0.1,
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                data.length,
                (i) => FlSpot(i.toDouble(), data[i]),
              ),
              isCurved: true,
              color: color,
              barWidth: 1.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final CategoryModel data;
  const _CategoryRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: data.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '${data.sold}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(
                  data.revenue,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: data.color,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: data.pct / 100,
                    backgroundColor: Colors.white.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation(data.color),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                child: Text(
                  '${data.pct.toInt()}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final TopProductModel product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final isGold = product.rank == 1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isGold
                  ? const Color(0xFFFFD700).withOpacity(0.1)
                  : Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '${product.rank}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isGold ? const Color(0xFFFFD700) : AppColors.textSecondary,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.primaryNavy],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(product.emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.sold} đã bán · ${product.variants}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            product.revenue,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.accentCyan,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniStatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}


