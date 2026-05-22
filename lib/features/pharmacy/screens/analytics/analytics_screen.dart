import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../core/services/haptic_service.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(analyticsProvider);
    final data = state.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.analytics),
      ),
      body: state.isLoading && data == null
          ? const CenteredLoader()
          : state.error != null && data == null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () => ref.read(analyticsProvider.notifier).load(),
                )
              : data == null
                  ? const SizedBox()
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticService.medium();
                        await ref.read(analyticsProvider.notifier).load();
                      },
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _MetricsGrid(data: data, l10n: l10n),
                          const SizedBox(height: 20),

                          if (data.ordersByDay.isNotEmpty) ...[
                            _SectionHeader(title: l10n.ordersByDayLbl),
                            const SizedBox(height: 12),
                            _DailyOrdersChart(days: data.ordersByDay),
                            const SizedBox(height: 20),
                          ],

                          if (data.ordersByStatus.isNotEmpty) ...[
                            _SectionHeader(title: l10n.ordersByStatusLbl),
                            const SizedBox(height: 12),
                            _StatusBreakdown(statusMap: data.ordersByStatus),
                            const SizedBox(height: 20),
                          ],

                          if (data.ordersByCourier.isNotEmpty) ...[
                            _SectionHeader(title: l10n.ordersByCourierLbl),
                            const SizedBox(height: 12),
                            _CourierBreakdown(
                                courierMap: data.ordersByCourier,
                                l10n: l10n),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final dynamic data;
  final AppL10n l10n;

  const _MetricsGrid({required this.data, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MetricItem(
        label: l10n.totalOrdersLbl,
        value: data.totalOrders.toString(),
        icon: Icons.receipt_long,
        color: AppColors.primary,
      ),
      _MetricItem(
        label: l10n.medicinesAmountLbl,
        value: _fmt(data.totalMedicines as double),
        icon: Icons.shopping_bag_outlined,
        color: AppColors.info,
      ),
      _MetricItem(
        label: l10n.deliveryRevenueLbl,
        value: _fmt(data.totalDelivery as double),
        icon: Icons.delivery_dining,
        color: AppColors.success,
      ),
      _MetricItem(
        label: l10n.totalRevenueLbl,
        value: _fmt(data.totalRevenue as double),
        icon: Icons.attach_money,
        color: AppColors.warning,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: items.map((item) => _MetricCard(item: item)).toList(),
    );
  }

  String _fmt(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M'
      : '${v.toStringAsFixed(0)} сум';
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricCard extends StatelessWidget {
  final _MetricItem item;

  const _MetricCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 18, color: item.color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: item.color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _DailyOrdersChart extends StatelessWidget {
  final List<dynamic> days;

  const _DailyOrdersChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final last14 =
        days.length > 14 ? days.sublist(days.length - 14) : days;
    final maxY = last14
        .fold<int>(0, (m, d) => m > (d.count as int) ? m : (d.count as int))
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) =>
                      Theme.of(context).colorScheme.inverseSurface,
                  tooltipBorder: BorderSide.none,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                    rod.toY.toInt().toString(),
                    TextStyle(
                      color:
                          Theme.of(context).colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              maxY: (maxY * 1.2).ceilToDouble(),
              barGroups: last14.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: (e.value.count as int).toDouble(),
                      color: AppColors.primary,
                      width: 12,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4)),
                    ),
                  ],
                );
              }).toList(),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= last14.length) {
                        return const SizedBox();
                      }
                      final date =
                          (last14[idx].date as String).length >= 7
                              ? (last14[idx].date as String).substring(5)
                              : last14[idx].date as String;
                      return Text(date,
                          style: const TextStyle(fontSize: 9));
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final Map<String, int> statusMap;

  const _StatusBreakdown({required this.statusMap});

  @override
  Widget build(BuildContext context) {
    final total = statusMap.values.fold(0, (a, b) => a + b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: statusMap.entries.map((e) {
            final pct = total > 0 ? e.value / total : 0.0;
            final color = StatusBadge.colorFor(e.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(StatusBadge.labelFor(e.key),
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(color),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value}',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              )),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CourierBreakdown extends StatelessWidget {
  final Map<String, int> courierMap;
  final AppL10n l10n;

  const _CourierBreakdown(
      {required this.courierMap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: courierMap.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text(e.key,
                      style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text(
                    '${e.value} ${l10n.ordersCount}',
                    style:
                        Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
