import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../providers/admin_provider.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminAnalyticsProvider);
    final data = state.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.adminAnalyticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticService.light();
              ref.read(adminAnalyticsProvider.notifier).load();
            },
          ),
        ],
      ),
      body: state.isLoading && data == null
          ? const CenteredLoader()
          : state.error != null && data == null
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(adminAnalyticsProvider.notifier).load(),
                )
              : data == null
                  ? const SizedBox()
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticService.medium();
                        await ref.read(adminAnalyticsProvider.notifier).load();
                      },
                      color: AppColors.primary,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Top KPIs
                          Row(
                            children: [
                              Expanded(
                                child: _KpiCard(
                                  label: context.l10n.adminTotalOrders,
                                  value: data.totalOrders.toString(),
                                  icon: Icons.receipt_long,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _KpiCard(
                                  label: context.l10n.adminActivePharmacies,
                                  value: data.activePharmacies.toString(),
                                  icon: Icons.storefront,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _KpiCard(
                            label: context.l10n.adminTotalRevenue,
                            value: _fmt(data.totalMedicinesAmount + data.totalDeliveryAmount),
                            icon: Icons.attach_money,
                            color: AppColors.success,
                            wide: true,
                          ),
                          const SizedBox(height: 20),

                          // Daily chart
                          if (data.ordersByDay.isNotEmpty) ...[
                            Text(context.l10n.adminOrdersByDay,
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 12),
                            _DailyChart(days: data.ordersByDay),
                            const SizedBox(height: 20),
                          ],

                          // Status breakdown
                          if (data.ordersByStatus.isNotEmpty) ...[
                            Text(context.l10n.adminByStatus,
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 12),
                            _BreakdownCard(
                              items: data.ordersByStatus
                                  .map((e) => _BreakdownItem(
                                        label: StatusBadge.labelFor(
                                            e['status'] as String? ?? ''),
                                        count: (e['count'] as num?)?.toInt() ?? 0,
                                        color: _statusColor(
                                            e['status'] as String? ?? ''),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Courier breakdown
                          if (data.ordersByCourier.isNotEmpty) ...[
                            Text(context.l10n.adminByCourier,
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 12),
                            _BreakdownCard(
                              items: data.ordersByCourier
                                  .map((e) => _BreakdownItem(
                                        label: (e['courier'] as String? ?? '').toUpperCase(),
                                        count: (e['count'] as num?)?.toInt() ?? 0,
                                        color: AppColors.primary,
                                      ))
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  String _fmt(double v) => v >= 1000000
      ? '${(v / 1000000).toStringAsFixed(1)}M сум'
      : '${v.toStringAsFixed(0)} сум';



  Color _statusColor(String s) => switch (s) {
        'pending' => AppColors.statusPending,
        'awaiting_confirmation' => AppColors.statusAwaiting,
        'confirmed' => AppColors.statusConfirmed,
        'delivered' => AppColors.statusDelivered,
        'cancelled' => AppColors.statusCancelled,
        _ => AppColors.primary,
      };
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: wide
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text(label, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
      ),
    );
  }
}

class _BreakdownItem {
  final String label;
  final int count;
  final Color color;

  const _BreakdownItem({
    required this.label,
    required this.count,
    required this.color,
  });
}

class _BreakdownCard extends StatelessWidget {
  final List<_BreakdownItem> items;

  const _BreakdownCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold(0, (a, b) => a + b.count);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: items.map((item) {
            final pct = total > 0 ? item.count / total : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(item.label,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation(item.color),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${item.count}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.right,
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

class _DailyChart extends StatelessWidget {
  final List<dynamic> days;

  const _DailyChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final last14 = days.length > 14 ? days.sublist(days.length - 14) : days;
    final maxY = last14.fold<int>(
            0, (m, d) => m > (d.count as int) ? m : (d.count as int))
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
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
                    getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                        style: const TextStyle(fontSize: 10)),
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
                          (last14[idx].date as String).substring(5);
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
