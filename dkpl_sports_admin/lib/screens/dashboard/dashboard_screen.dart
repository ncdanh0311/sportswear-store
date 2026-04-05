import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dkpl_sports_admin/core/constants/app_colors.dart';
import 'package:dkpl_sports_admin/core/constants/role_permissions.dart';
import 'package:dkpl_sports_admin/core/widgets/base_background.dart';
import 'package:dkpl_sports_admin/core/widgets/dkpl_card.dart';
import 'package:dkpl_sports_admin/models/dashboard_models.dart';
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

  // KPI Data
  final _kpis = const [
    KpiModel('Doanh Thu', '47.8M₫', '+12.4%', '💰', true, AppColors.accentCyan,
        [28, 32, 30, 38, 35, 42, 48]),
    KpiModel('Đơn Hoàn Thành', '324', '+8.1%', '📦', true, Color(0xFF00E5A0),
        [260, 275, 285, 290, 300, 310, 324]),
    KpiModel('Tương Tác', '1,248', '+23%', '💬', true, Color(0xFFFFB347),
        [800, 950, 880, 1050, 1100, 1180, 1248]),
    KpiModel('Hoàn Hàng', '1.8%', '-2.1%', '↩️', false, AppColors.error,
        [2.8, 2.5, 2.3, 2.0, 1.9, 1.85, 1.8]),
  ];

  // Revenue by day
  final _revenueData = const [5.2, 6.8, 8.9, 7.4, 7.1, 8.2, 4.2];
  final _ordersData = const [36.0, 48.0, 62.0, 52.0, 49.0, 57.0, 31.0];
  final _dayLabels = const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  // Categories
  final _categories = const [
    CategoryModel('Áo các loại', '👕', 148, '18.1M₫', 38, AppColors.accentCyan),
    CategoryModel('Quần các loại', '👖', 106, '12.9M₫', 27, Color(0xFF00E5A0)),
    CategoryModel('Phụ kiện', '🧢', 89, '8.6M₫', 18, Color(0xFFFFB347)),
    CategoryModel('Giày dép', '👟', 67, '8.1M₫', 17, Color(0xFFA78BFA)),
  ];

  // Top products
  final _topProducts = const [
    TopProductModel(1, 'Áo Polo Nam DKPL Slim Fit', '👕', 62, 'Đen, Trắng, Navy', '7.2M₫'),
    TopProductModel(2, 'Quần Jogger Premium', '👖', 48, 'Xám, Đen', '5.8M₫'),
    TopProductModel(3, 'Mũ Lưỡi Trai Logo DKPL', '🧢', 95, 'All màu', '4.3M₫'),
    TopProductModel(4, 'Giày Sneaker Low-Top', '👟', 31, 'Trắng, Đen', '3.9M₫'),
    TopProductModel(5, 'Áo Hoodie Oversize DKPL', '👚', 29, 'Đen, Tím', '3.5M₫'),
  ];

  @override
  Widget build(BuildContext context) {
    final canViewReport = RolePermissions.canViewRevenueReport(
      AuthService.instance.currentUser?.role,
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateRangeRow(),
            const SizedBox(height: 12),
            _buildPeriodTabs(),
            const SizedBox(height: 16),
            _buildKpiGrid(),
            const SizedBox(height: 16),
            _buildRevenueChart(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildCategoryDonut()),
                const SizedBox(width: 12),
                Expanded(child: _buildWeeklyMiniStats()),
              ],
            ),
            const SizedBox(height: 16),
            _buildCategoryTable(),
            const SizedBox(height: 16),
            _buildTopProducts(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── DATE RANGE ──
  Widget _buildDateRangeRow() {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
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
                  Text(
                    '${fmt(_dateRange.start)} – ${fmt(_dateRange.end)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
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
        ),
      ],
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
              onTap: () => setState(() => _period = p),
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
          );
        }).toList(),
      ),
    );
  }

  // ── KPI GRID ──
  Widget _buildKpiGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemCount: _kpis.length,
      itemBuilder: (_, i) => _KpiCard(data: _kpis[i]),
    );
  }

  // ── REVENUE CHART ──
  Widget _buildRevenueChart() {
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
                      'Doanh Thu Theo Ngày',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Tuần 10/02 – 16/02 · tổng 47.8M₫',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _LegendDot(color: Color(0xFF00D4FF), label: 'Doanh thu'),
                  const SizedBox(width: 12),
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
                      '${_dayLabels[group.x]}\n${rod.toY}M₫',
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
                          _dayLabels[v.toInt()],
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
                  _revenueData.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _revenueData[i],
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: i == 2
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

  // ── CATEGORY DONUT ──
  Widget _buildCategoryDonut() {
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
                sections: [
                  PieChartSectionData(
                    value: 38, color: AppColors.accentCyan,
                    radius: 28, title: '38%',
                    titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 27, color: Color(0xFF00E5A0),
                    radius: 28, title: '27%',
                    titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 18, color: Color(0xFFFFB347),
                    radius: 28, title: '18%',
                    titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  PieChartSectionData(
                    value: 17, color: Color(0xFFA78BFA),
                    radius: 28, title: '17%',
                    titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: const [
              _LegendDot(color: Color(0xFF00D4FF), label: 'Áo'),
              _LegendDot(color: Color(0xFF00E5A0), label: 'Quần'),
              _LegendDot(color: Color(0xFFFFB347), label: 'Phụ kiện'),
              _LegendDot(color: Color(0xFFA78BFA), label: 'Giày'),
            ],
          ),
        ],
      ),
    );
  }

  // ── WEEKLY MINI STATS ──
  Widget _buildWeeklyMiniStats() {
    final weekData = [
      ('T2', 5.2, false), ('T3', 6.8, false), ('T4', 8.9, false),
      ('T5', 7.4, false), ('T6', 7.1, false), ('T7', 8.2, false), ('CN', 4.2, true),
    ];
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
              final pct = d.$2 / 10.0;
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
                                colors: d.$3
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
                        d.$1,
                        style: TextStyle(
                          fontSize: 9,
                          color: d.$3 ? AppColors.accentCyan : AppColors.textSecondary,
                          fontWeight: d.$3 ? FontWeight.bold : FontWeight.normal,
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
            children: [
              Expanded(
                child: _MiniStatChip(
                  label: 'Cao nhất',
                  value: 'T4',
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatChip(
                  label: 'Đỉnh ngày',
                  value: '8.9M',
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
  Widget _buildCategoryTable() {
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
          ..._categories.map((c) => _CategoryRow(data: c)),
        ],
      ),
    );
  }

  // ── TOP PRODUCTS ──
  Widget _buildTopProducts() {
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
          ..._topProducts.map((p) => _ProductRow(product: p)),
        ],
      ),
    );
  }
}

// ── REUSABLE WIDGETS ──────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final KpiModel data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE0E0E0)),
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
                  color: (data.isUp ? Color(0xFF00E5A0) : Color(0xFFFF5252))
                      .withOpacity(0.1),
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
          const Spacer(),
          Text(
            data.value,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _Sparkline(data: data.spark, color: data.accent),
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


