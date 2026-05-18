import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/utils/right_panel.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/status_tab_bar.dart';
import '../../models/order_model.dart';
import '../../providers/orders_provider.dart';
import 'create_order_screen.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmtAmount(double? v) {
  if (v == null) return '—';
  final str = v.toStringAsFixed(0);
  final buf = StringBuffer();
  final len = str.length;
  for (var i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write(' ');
    buf.write(str[i]);
  }
  return '${buf.toString()} сум';
}

String _fmtDate(String iso, AppL10n l10n) => l10n.fmtDateTime(iso);
String _fmtDateShort(String iso, AppL10n l10n) => l10n.fmtDateTimeShort(iso);

const _statusOrder = [
  'pending',
  'awaiting_confirmation',
  'confirmed',
  'courier_pickup',
  'courier_picked',
  'courier_delivery',
  'delivered',
  'cancelled',
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class OrdersScreen extends ConsumerStatefulWidget {
  final bool openCreate;
  const OrdersScreen({super.key, this.openCreate = false});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _searchVisible = false;

  static const _tabStatuses = ['all', ..._statusOrder];

  String _tabLabel(String status, AppL10n l10n) {
    if (status == 'all') return l10n.all;
    return StatusBadge.labelForL10n(status, l10n);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabStatuses.length, vsync: this);
    if (widget.openCreate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate());
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _openCreate() {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateOrderSheet(),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final f = ref.read(ordersProvider).filter.copyWith(
            search: value,
            clearSearch: value.isEmpty,
          );
      ref.read(ordersProvider.notifier).applyFilter(f);
    });
  }

  void _toggleSearch() {
    HapticService.light();
    setState(() => _searchVisible = !_searchVisible);
    if (!_searchVisible) {
      _searchController.clear();
      final f = ref.read(ordersProvider).filter.copyWith(clearSearch: true);
      ref.read(ordersProvider.notifier).applyFilter(f);
    }
  }

  void _openFilter() {
    HapticService.light();
    final current = ref.read(ordersProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OrderFilterSheet(
        current: current,
        onApply: (f) => ref.read(ordersProvider.notifier).applyFilter(f),
        onClear: () => ref.read(ordersProvider.notifier).clearFilter(),
      ),
    );
  }

  void _showDetail(PharmacyOrder order) {
    pushRightPanel(context, _OrderDetailPage(order: order));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(ordersProvider);
    final hasFilter = state.filter.isActive;
    final hasCourierDateFilter = state.filter.couriers.isNotEmpty ||
        state.filter.dateFrom != null ||
        state.filter.dateTo != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.orders),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          Badge(
            isLabelVisible: hasFilter,
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.tune_outlined),
              onPressed: _openFilter,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_searchVisible ? 100 : 48),
          child: Column(
            children: [
              if (_searchVisible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.search,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                ref
                                    .read(ordersProvider.notifier)
                                    .applyFilter(ref
                                        .read(ordersProvider)
                                        .filter
                                        .copyWith(clearSearch: true));
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      setState(() {});
                      _onSearchChanged(v);
                    },
                  ),
                ),
              StatusTabBar(
                statuses: _tabStatuses,
                controller: _tabController,
                getLabel: (s) => _tabLabel(s, l10n),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (hasCourierDateFilter)
            _ActiveFilterRow(
              filter: state.filter,
              onClear: () => ref.read(ordersProvider.notifier).clearFilter(),
            ),
          Expanded(
            child: state.isLoading && state.orders.isEmpty
                ? const CenteredLoader()
                : state.error != null && state.orders.isEmpty
                    ? AppErrorWidget(
                        message: state.error!,
                        onRetry: () =>
                            ref.read(ordersProvider.notifier).load(),
                      )
                    : TabBarView(
                        controller: _tabController,
                        children: _tabStatuses.map((status) {
                          final orders = status == 'all'
                              ? state.orders
                              : state.orders
                                  .where((o) => o.status == status)
                                  .toList();
                          return _TabOrderList(
                            key: ValueKey(status),
                            orders: orders,
                            isAllTab: status == 'all',
                            hasFilter: hasFilter,
                            onClearFilter: () => ref
                                .read(ordersProvider.notifier)
                                .clearFilter(),
                            onOpenCreate: _openCreate,
                            onShowDetail: _showDetail,
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}

// ─── Tab order list ───────────────────────────────────────────────────────────

class _TabOrderList extends ConsumerWidget {
  final List<PharmacyOrder> orders;
  final bool hasFilter;
  final bool isAllTab;
  final VoidCallback onClearFilter;
  final VoidCallback onOpenCreate;
  final void Function(PharmacyOrder) onShowDetail;

  const _TabOrderList({
    super.key,
    required this.orders,
    required this.hasFilter,
    required this.isAllTab,
    required this.onClearFilter,
    required this.onOpenCreate,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    if (orders.isEmpty) {
      if (isAllTab) {
        return EmptyState(
          icon: Icons.receipt_long,
          title: l10n.noOrders,
          subtitle: hasFilter ? l10n.clear : l10n.createFirstOrder,
          action: hasFilter
              ? OutlinedButton(
                  onPressed: onClearFilter,
                  child: Text(l10n.clear),
                )
              : ElevatedButton.icon(
                  onPressed: onOpenCreate,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createOrder),
                ),
        );
      }
      return EmptyState(
        icon: Icons.receipt_long,
        title: l10n.noOrders,
        subtitle: '',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticService.medium();
        await ref.read(ordersProvider.notifier).load();
      },
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _OrderCard(
          order: orders[i],
          onTap: () => onShowDetail(orders[i]),
        ),
      ),
    );
  }
}

// ─── Active filter chips row ──────────────────────────────────────────────────

class _ActiveFilterRow extends StatelessWidget {
  final OrdersFilter filter;
  final VoidCallback onClear;
  const _ActiveFilterRow({required this.filter, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...filter.couriers.map((c) => _FilterChip(
                      label: c[0].toUpperCase() + c.substring(1),
                      color: AppColors.primary,
                    )),
                if (filter.dateFrom != null || filter.dateTo != null)
                  _FilterChip(
                    label: [
                      if (filter.dateFrom != null)
                        '${l10n.from} ${l10n.fmtDateShort(filter.dateFrom!)}',
                      if (filter.dateTo != null)
                        '${l10n.to} ${l10n.fmtDateShort(filter.dateTo!)}',
                    ].join(' '),
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onClear,
            tooltip: l10n.clear,
          ),
        ],
      ),
    );
  }

}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FilterChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      );
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends ConsumerWidget {
  final PharmacyOrder order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final total = order.totalPrice ??
        ((order.medicinesTotal ?? 0.0) + (order.deliveryPrice ?? 0.0));
    final statusColor = StatusBadge.colorFor(order.status);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '#${order.token.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: mutedFg,
                            ),
                          ),
                          const Spacer(),
                          StatusBadge(status: order.status),
                        ],
                      ),
                      if (order.customerName != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          order.customerName!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.foregroundDark
                                : AppColors.foregroundLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (order.pharmacyComment != null &&
                          order.pharmacyComment!.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.mutedDark
                                : AppColors.mutedLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            order.pharmacyComment!,
                            style:
                                TextStyle(fontSize: 12, color: mutedFg),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (order.customerPhone != null) ...[
                        const SizedBox(height: 7),
                        _CardRow(
                          icon: Icons.phone_outlined,
                          value: order.customerPhone!,
                        ),
                      ],
                      if (order.customerAddress != null) ...[
                        const SizedBox(height: 4),
                        _CardRow(
                          icon: Icons.location_on_outlined,
                          value: order.customerAddress!,
                        ),
                      ],
                      if (order.courierType != null) ...[
                        const SizedBox(height: 4),
                        _CardRow(
                          icon: Icons.local_shipping_outlined,
                          value: order.courierType!,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.access_time_outlined,
                              size: 12, color: mutedFg),
                          const SizedBox(width: 4),
                          Text(
                            _fmtDateShort(order.createdAt, l10n),
                            style:
                                TextStyle(fontSize: 11, color: mutedFg),
                          ),
                          const Spacer(),
                          if (total > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _fmtAmount(total),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (order.status == 'awaiting_confirmation') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () { HapticService.light(); _cancel(context, ref); },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                      color: AppColors.error),
                                  minimumSize: const Size(0, 38),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: Text(l10n.cancel),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () { HapticService.light(); _confirm(context, ref); },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(0, 38),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                ),
                                child: Text(l10n.confirm),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final ok =
        await ref.read(ordersProvider.notifier).confirmOrder(order.token);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              ok ? context.l10n.orderConfirmed : context.l10n.error)));
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelOrderTitle),
        content: Text(l10n.cancelOrderMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.no)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(ordersProvider.notifier).cancelOrder(order.token);
    }
  }
}

class _CardRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _CardRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final mutedFg = Theme.of(context).brightness == Brightness.dark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 13, color: mutedFg),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12.5, color: mutedFg),
          ),
        ),
      ],
    );
  }
}

// ─── Order detail page ────────────────────────────────────────────────────────

class _OrderDetailPage extends ConsumerWidget {
  final PharmacyOrder order;
  const _OrderDetailPage({required this.order});

  bool get _canShare =>
      order.status != 'cancelled' && order.status != 'delivered';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final total = order.totalPrice ??
        ((order.medicinesTotal ?? 0.0) + (order.deliveryPrice ?? 0.0));

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#${order.token.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                _fmtDate(order.createdAt, l10n),
                style: TextStyle(fontSize: 11, color: mutedFg),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: StatusBadge(status: order.status),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (_canShare && order.orderUrl != null) ...[
              _ShareLinkCard(url: order.orderUrl!, l10n: l10n),
              const SizedBox(height: 14),
            ],
            if (order.pharmacyComment != null &&
                order.pharmacyComment!.isNotEmpty) ...[
              _SheetSection(
                title: l10n.orderCommentLbl,
                rows: [
                  _SheetRow(
                    icon: Icons.comment_outlined,
                    label: l10n.orderCommentLbl,
                    value: order.pharmacyComment!,
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (order.customerName != null ||
                order.customerPhone != null ||
                order.customerAddress != null ||
                order.customerComment != null) ...[
              _SheetSection(
                title: l10n.customer,
                rows: [
                  if (order.customerName != null)
                    _SheetRow(
                      icon: Icons.person_outline,
                      label: l10n.customer,
                      value: order.customerName!,
                    ),
                  if (order.customerPhone != null)
                    _SheetPhoneRow(
                        phone: order.customerPhone!, l10n: l10n),
                  if (order.customerAddress != null)
                    _SheetRow(
                      icon: Icons.location_on_outlined,
                      label: l10n.address,
                      value: order.customerAddress!,
                    ),
                  if (order.customerComment != null &&
                      order.customerComment!.isNotEmpty)
                    _SheetRow(
                      icon: Icons.chat_bubble_outline,
                      label: l10n.customerCommentLbl,
                      value: order.customerComment!,
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (order.medicinesTotal != null ||
                order.deliveryPrice != null) ...[
              _SheetSection(
                title: l10n.totalCost,
                rows: [
                  if (order.medicinesTotal != null)
                    _SheetRow(
                      icon: Icons.shopping_bag_outlined,
                      label: l10n.orderAmountLbl,
                      value: _fmtAmount(order.medicinesTotal),
                    ),
                  if (order.deliveryPrice != null)
                    _SheetRow(
                      icon: Icons.delivery_dining,
                      label: l10n.deliveryCost,
                      value: _fmtAmount(order.deliveryPrice),
                    ),
                  if (total > 0)
                    _SheetRow(
                      icon: Icons.receipt_outlined,
                      label: l10n.totalAmountLbl,
                      value: _fmtAmount(total),
                      bold: true,
                      valueColor: AppColors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (order.courierType != null) ...[
              _SheetSection(
                title: l10n.courier,
                rows: [
                  _SheetRow(
                    icon: Icons.local_shipping_outlined,
                    label: l10n.courier,
                    value: order.courierType!,
                  ),
                  if (order.trackingUrl != null)
                    _TrackingRow(url: order.trackingUrl!, l10n: l10n),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (order.status == 'pending' ||
                order.status == 'awaiting_confirmation')
              _ActionButtons(order: order, ref: ref, l10n: l10n),
          ],
        ),
      ),
    );
  }
}

// ─── Sheet section container ──────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _SheetSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: mutedFg,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              return Column(
                children: [
                  entry.value,
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Sheet row ────────────────────────────────────────────────────────────────

class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _SheetRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    final fg = isDark ? AppColors.foregroundDark : AppColors.foregroundLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedFg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                    color: valueColor ?? fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phone row inside sheet ───────────────────────────────────────────────────

class _SheetPhoneRow extends StatelessWidget {
  final String phone;
  final AppL10n l10n;
  const _SheetPhoneRow({required this.phone, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.phone,
                  style: TextStyle(
                    fontSize: 11,
                    color: mutedFg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () async {
                    HapticService.light();
                    final uri = Uri(scheme: 'tel', path: phone);
                    if (await canLaunchUrl(uri)) await launchUrl(uri);
                  },
                  child: Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tracking row ─────────────────────────────────────────────────────────────

class _TrackingRow extends StatelessWidget {
  final String url;
  final AppL10n l10n;
  const _TrackingRow({required this.url, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const Icon(Icons.link, size: 16, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(l10n.trackingLink,
                  style: TextStyle(fontSize: 13, color: mutedFg))),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  HapticService.light();
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.copied)));
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy,
                      size: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  HapticService.light();
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.inAppWebView);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.open_in_new,
                      size: 14, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Share link card ──────────────────────────────────────────────────────────

class _ShareLinkCard extends StatelessWidget {
  final String url;
  final AppL10n l10n;
  const _ShareLinkCard({required this.url, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.link,
                color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.shareOrderLink,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                Text(url,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.mutedForegroundDark
                          : AppColors.mutedForegroundLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy,
                size: 17, color: AppColors.primary),
            onPressed: () {
              HapticService.light();
              Clipboard.setData(ClipboardData(text: url));
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(l10n.copied)));
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new,
                size: 17, color: AppColors.primary),
            onPressed: () async {
              HapticService.light();
              final uri = Uri.tryParse(url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.inAppWebView);
              }
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final PharmacyOrder order;
  final WidgetRef ref;
  final AppL10n l10n;
  const _ActionButtons(
      {required this.order, required this.ref, required this.l10n});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          if (order.status == 'awaiting_confirmation')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () { HapticService.light(); _confirm(context); },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: Text(l10n.confirm),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          if (order.status == 'awaiting_confirmation')
            const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () { HapticService.light(); _cancel(context); },
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: Text(l10n.cancel),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      );

  Future<void> _confirm(BuildContext context) async {
    final ok =
        await ref.read(ordersProvider.notifier).confirmOrder(order.token);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? l10n.orderConfirmed : l10n.error)));
    }
  }

  Future<void> _cancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelOrderTitle),
        content: Text(l10n.cancelOrderMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.no)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(ordersProvider.notifier).cancelOrder(order.token);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _OrderFilterSheet extends StatefulWidget {
  final OrdersFilter current;
  final void Function(OrdersFilter) onApply;
  final VoidCallback onClear;

  const _OrderFilterSheet({
    required this.current,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<_OrderFilterSheet> {
  late List<String> _couriers;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const _allCouriers = ['yandex', 'noor', 'millennium'];

  @override
  void initState() {
    super.initState();
    _couriers = List.from(widget.current.couriers);
    _dateFrom = widget.current.dateFrom;
    _dateTo = widget.current.dateTo;
  }

  Future<void> _pickDate(bool isFrom) async {
    HapticService.light();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => isFrom ? _dateFrom = picked : _dateTo = picked);
    }
  }

  int get _count =>
      _couriers.length +
      (_dateFrom != null ? 1 : 0) +
      (_dateTo != null ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedFg = isDark
        ? AppColors.mutedForegroundDark
        : AppColors.mutedForegroundLight;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Text(l10n.filter,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (_count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text('$_count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: () {
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: Text(l10n.clear),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.courier.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: mutedFg,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allCouriers.map((c) {
              final sel = _couriers.contains(c);
              return _ToggleChip(
                label: c[0].toUpperCase() + c.substring(1),
                selected: sel,
                color: AppColors.primary,
                onTap: () { HapticService.selection(); setState(() => sel ? _couriers.remove(c) : _couriers.add(c)); },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.dateRange.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: mutedFg,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 15),
                  label: Text(
                    _dateFrom != null ? l10n.fmtDateDt(_dateFrom!) : l10n.from,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 15),
                  label: Text(
                    _dateTo != null ? l10n.fmtDateDt(_dateTo!) : l10n.to,
                    style: const TextStyle(fontSize: 13),
                  ),
                  onPressed: () => _pickDate(false),
                ),
              ),
              if (_dateFrom != null || _dateTo != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () => setState(() {
                    _dateFrom = null;
                    _dateTo = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticService.light();
                widget.onApply(OrdersFilter(
                  search: widget.current.search,
                  statuses: widget.current.statuses,
                  couriers: _couriers,
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                ));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(l10n.apply),
            ),
          ),
        ],
      ),
    );
  }

}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
                color: selected
                    ? color
                    : color.withValues(alpha: 0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      );
}
