import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/utils/right_panel.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../core/services/haptic_service.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';

class AdminClientsScreen extends ConsumerStatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  ConsumerState<AdminClientsScreen> createState() =>
      _AdminClientsScreenState();
}

class _AdminClientsScreenState extends ConsumerState<AdminClientsScreen> {
  final _searchController = TextEditingController();
  bool _searchVisible = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final current = ref.read(adminClientsProvider).filter;
      ref.read(adminClientsProvider.notifier).applyFilter(
            current.copyWith(
              search: value.isEmpty ? null : value,
              clearSearch: value.isEmpty,
            ),
          );
    });
  }

  void _toggleSearch() {
    HapticService.light();
    setState(() => _searchVisible = !_searchVisible);
    if (!_searchVisible) {
      _debounce?.cancel();
      _searchController.clear();
      final current = ref.read(adminClientsProvider).filter;
      ref.read(adminClientsProvider.notifier).applyFilter(
            current.copyWith(search: null, clearSearch: true),
          );
    }
  }

  int _activeFilterCount(AdminClientsFilter f) {
    int c = 0;
    if (f.dateFrom != null) c++;
    if (f.dateTo != null) c++;
    if (f.minOrders != null && f.minOrders! > 0) c++;
    return c;
  }

  void _openFilterSheet() {
    HapticService.light();
    final current = ref.read(adminClientsProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ClientFilterSheet(
        initial: current,
        onApply: (f) {
          final withSearch = f.copyWith(search: current.search);
          ref.read(adminClientsProvider.notifier).applyFilter(withSearch);
        },
        onClear: () => ref.read(adminClientsProvider.notifier).applyFilter(
              AdminClientsFilter(search: current.search),
            ),
      ),
    );
  }

  void _showDetail(AdminClient client) {
    pushRightPanel(context, _ClientDetailPage(client: client));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(adminClientsProvider);
    final filterCount = _activeFilterCount(state.filter);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminClientsTitle),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.search_off : Icons.search),
            tooltip: l10n.adminSearchClients,
            onPressed: _toggleSearch,
          ),
          Badge(
            isLabelVisible: filterCount > 0,
            label: Text('$filterCount'),
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.tune_outlined),
              onPressed: _openFilterSheet,
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: _searchVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.adminSearchClients,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                _onSearchChanged('');
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
              )
            : null,
      ),
      body: state.isLoading && state.clients.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.clients.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(adminClientsProvider.notifier).load(),
                )
              : state.clients.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: l10n.adminNoClients,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticService.medium();
                        await ref.read(adminClientsProvider.notifier).load();
                      },
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.clients.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _ClientCard(
                          client: state.clients[i],
                          onTap: () {
                            HapticService.light();
                            _showDetail(state.clients[i]);
                          },
                        ),
                      ),
                    ),
    );
  }
}

// ─── Client Card ──────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final AdminClient client;
  final VoidCallback onTap;

  const _ClientCard({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final initials = client.name?.isNotEmpty == true
        ? client.name![0].toUpperCase()
        : (client.phone.isNotEmpty ? client.phone[0] : '?');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.name ?? client.phone,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (client.name != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        client.phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                    if (client.pharmacies.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        client.pharmacies.join(', '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary.withValues(alpha: 0.85),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${client.ordersCount}',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: AppColors.primary),
                  ),
                  Text(
                    l10n.adminClientsOrders,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Client Detail Page ───────────────────────────────────────────────────────

class _ClientDetailPage extends StatelessWidget {
  final AdminClient client;

  const _ClientDetailPage({required this.client});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final initials = client.name?.isNotEmpty == true
        ? client.name![0].toUpperCase()
        : (client.phone.isNotEmpty ? client.phone[0] : '?');

    final formattedLastOrder =
        client.lastOrderAt != null ? l10n.fmtDate(client.lastOrderAt!) : null;

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (client.name != null)
                      Text(client.name!,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(
                      client.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                _StatTile(
                  icon: Icons.receipt_long_outlined,
                  label: l10n.adminClientsOrders,
                  value: '${client.ordersCount}',
                ),
                const SizedBox(width: 12),
                _StatTile(
                  icon: Icons.access_time_outlined,
                  label: l10n.adminClientLastOrder,
                  value: formattedLastOrder ?? '—',
                ),
              ],
            ),
            if (client.pharmacies.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader(
                icon: Icons.store_outlined,
                title: l10n.adminClientCompanies,
                count: client.pharmacies.length,
              ),
              const SizedBox(height: 8),
              ...client.pharmacies.map(
                (p) => _InfoRow(icon: Icons.store_mall_directory_outlined, text: p),
              ),
            ],
            if (client.addresses.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionHeader(
                icon: Icons.location_on_outlined,
                title: l10n.adminClientAddresses,
                count: client.addresses.length,
              ),
              const SizedBox(height: 8),
              ...client.addresses.map(
                (a) => _InfoRow(icon: Icons.place_outlined, text: a),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Sheet ─────────────────────────────────────────────────────────────

class _ClientFilterSheet extends StatefulWidget {
  final AdminClientsFilter initial;
  final ValueChanged<AdminClientsFilter> onApply;
  final VoidCallback onClear;

  const _ClientFilterSheet({
    required this.initial,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_ClientFilterSheet> createState() => _ClientFilterSheetState();
}

class _ClientFilterSheetState extends State<_ClientFilterSheet> {
  late DateTime? _dateFrom;
  late DateTime? _dateTo;
  final _minOrdersController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;
    _minOrdersController.text = widget.initial.minOrders?.toString() ?? '';
  }

  @override
  void dispose() {
    _minOrdersController.dispose();
    super.dispose();
  }

  int get _activeCount {
    int c = 0;
    if (_dateFrom != null) c++;
    if (_dateTo != null) c++;
    if (_minOrdersController.text.trim().isNotEmpty) c++;
    return c;
  }

  Future<void> _pickDate(bool isFrom) async {
    HapticService.light();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _dateFrom : _dateTo) ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) setState(() => isFrom ? _dateFrom = picked : _dateTo = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedFg = theme.colorScheme.onSurface.withValues(alpha: 0.6);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) HapticService.medium();
      },
      child: Padding(
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
                if (_activeCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('$_activeCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () {
                    HapticService.light();
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: Text(l10n.clear),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${l10n.from} — ${l10n.to}'.toUpperCase(),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: mutedFg),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateButton(
                    label: _dateFrom != null ? l10n.fmtDateDt(_dateFrom!) : l10n.from,
                    isSet: _dateFrom != null,
                    onTap: () => _pickDate(true),
                    onClear: _dateFrom != null ? () => setState(() => _dateFrom = null) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateButton(
                    label: _dateTo != null ? l10n.fmtDateDt(_dateTo!) : l10n.to,
                    isSet: _dateTo != null,
                    onTap: () => _pickDate(false),
                    onClear: _dateTo != null ? () => setState(() => _dateTo = null) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l10n.adminMinOrders.toUpperCase(),
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: mutedFg),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _minOrdersController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '2',
                isDense: true,
                prefixIcon: const Icon(Icons.receipt_long_outlined, size: 18),
                suffixIcon: _minOrdersController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () => setState(() => _minOrdersController.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  HapticService.light();
                  final minOrders = int.tryParse(_minOrdersController.text.trim());
                  widget.onApply(AdminClientsFilter(
                    dateFrom: _dateFrom,
                    dateTo: _dateTo,
                    minOrders: minOrders,
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
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final bool isSet;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateButton({
    required this.label,
    required this.isSet,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSet
              ? AppColors.primary.withValues(alpha: 0.08)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSet
                ? AppColors.primary.withValues(alpha: 0.4)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: isSet
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isSet
                      ? AppColors.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSet ? FontWeight.w500 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close,
                    size: 14, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
