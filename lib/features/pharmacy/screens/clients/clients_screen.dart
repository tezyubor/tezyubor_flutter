import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/utils/right_panel.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../core/services/haptic_service.dart';
import '../../models/client_model.dart';
import '../../providers/clients_provider.dart';

class ClientsScreen extends ConsumerStatefulWidget {
  const ClientsScreen({super.key});

  @override
  ConsumerState<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends ConsumerState<ClientsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _searchVisible = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final f = ref.read(clientsProvider).filter.copyWith(
            search: value,
            clearSearch: value.isEmpty,
          );
      ref.read(clientsProvider.notifier).applyFilter(f);
    });
  }

  void _toggleSearch() {
    HapticService.light();
    setState(() => _searchVisible = !_searchVisible);
    if (!_searchVisible) {
      _searchController.clear();
      final f =
          ref.read(clientsProvider).filter.copyWith(clearSearch: true);
      ref.read(clientsProvider.notifier).applyFilter(f);
    }
  }

  void _openFilter() {
    HapticService.light();
    final current = ref.read(clientsProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ClientFilterSheet(
        current: current,
        onApply: (f) => ref.read(clientsProvider.notifier).applyFilter(f),
        onClear: () => ref.read(clientsProvider.notifier).clearFilter(),
      ),
    );
  }

  void _showDetail(PharmacyClient client) {
    pushRightPanel(context, _ClientDetailPage(client: client));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(clientsProvider);
    final hasFilter = state.filter.isActive;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clients),
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
        bottom: _searchVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.searchByPhone,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                ref.read(clientsProvider.notifier).applyFilter(
                                      ref
                                          .read(clientsProvider)
                                          .filter
                                          .copyWith(clearSearch: true),
                                    );
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) {
                      setState(() {});
                      _onSearch(v);
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
                      ref.read(clientsProvider.notifier).load(),
                )
              : state.clients.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: l10n.noClients,
                      subtitle: hasFilter
                          ? l10n.clear
                          : l10n.clientsSubtitle,
                      action: hasFilter
                          ? OutlinedButton(
                              onPressed: () => ref
                                  .read(clientsProvider.notifier)
                                  .clearFilter(),
                              child: Text(l10n.clear),
                            )
                          : null,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticService.medium();
                        await ref.read(clientsProvider.notifier).load();
                      },
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.clients.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final c = state.clients[i];
                          return _ClientCard(
                            client: c,
                            onTap: () {
                              HapticService.light();
                              _showDetail(c);
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

// ─── Client card ──────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final PharmacyClient client;
  final VoidCallback onTap;

  const _ClientCard({required this.client, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = client;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              c.name?.isNotEmpty == true
                  ? c.name![0].toUpperCase()
                  : c.phone[0],
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            c.name ?? c.phone,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (c.name != null)
                Text(c.phone,
                    style: Theme.of(context).textTheme.bodySmall),
              if (c.lastAddress != null)
                Text(
                  c.lastAddress!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${c.ordersCount}',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: AppColors.primary),
              ),
              Text(l10n.ordersCount,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          isThreeLine: c.lastAddress != null,
        ),
      ),
    );
  }
}

// ─── Client detail page ───────────────────────────────────────────────────────

class _ClientDetailPage extends StatelessWidget {
  final PharmacyClient client;
  const _ClientDetailPage({required this.client});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Text(l10n.clientDetails),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  client.name?.isNotEmpty == true
                      ? client.name![0].toUpperCase()
                      : client.phone[0],
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (client.name != null)
              Center(
                child: Text(client.name!,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
            Center(
              child: Text(client.phone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                    icon: Icons.receipt_long,
                    value: '${client.ordersCount}',
                    label: l10n.ordersCount),
                if (client.lastOrderAt != null)
                  _StatChip(
                      icon: Icons.access_time,
                      value: l10n.fmtDate(client.lastOrderAt!),
                      label: l10n.lastOrder),
              ],
            ),
            if (client.lastAddress != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.address,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text(client.lastAddress!,
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

// ─── Client filter sheet ──────────────────────────────────────────────────────

class _ClientFilterSheet extends StatefulWidget {
  final ClientsFilter current;
  final void Function(ClientsFilter) onApply;
  final VoidCallback onClear;

  const _ClientFilterSheet({
    required this.current,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_ClientFilterSheet> createState() => _ClientFilterSheetState();
}

class _ClientFilterSheetState extends State<_ClientFilterSheet> {
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
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
              const Spacer(),
              TextButton(
                onPressed: () {
                  HapticService.light();
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: Text(l10n.clear,
                    style: const TextStyle(color: AppColors.primary)),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.dateRange,
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                      _dateFrom != null ? l10n.fmtDateDt(_dateFrom!) : l10n.from,
                      style: const TextStyle(fontSize: 13)),
                  onPressed: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dateTo != null ? l10n.fmtDateDt(_dateTo!) : l10n.to,
                      style: const TextStyle(fontSize: 13)),
                  onPressed: () => _pickDate(false),
                ),
              ),
              if (_dateFrom != null || _dateTo != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() {
                    _dateFrom = null;
                    _dateTo = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticService.light();
                widget.onApply(ClientsFilter(
                  search: widget.current.search,
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }

}
