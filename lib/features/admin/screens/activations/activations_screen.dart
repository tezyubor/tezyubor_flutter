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

class ActivationsScreen extends ConsumerStatefulWidget {
  const ActivationsScreen({super.key});

  @override
  ConsumerState<ActivationsScreen> createState() => _ActivationsScreenState();
}

class _ActivationsScreenState extends ConsumerState<ActivationsScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchVisible = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    final current = ref.read(adminActivationsProvider).filter;
    if (text.length >= 2 || text.isEmpty) {
      ref.read(adminActivationsProvider.notifier).applyFilter(
            current.copyWith(
              search: text.isEmpty ? null : text,
              clearSearch: text.isEmpty,
            ),
          );
    }
  }

  void _toggleSearch() {
    HapticService.light();
    setState(() => _searchVisible = !_searchVisible);
    if (_searchVisible) {
      Future.delayed(
          const Duration(milliseconds: 80), () => _searchFocus.requestFocus());
    } else {
      _searchFocus.unfocus();
      if (_searchController.text.isNotEmpty) _searchController.clear();
    }
  }

  int _filterCount(AdminActivationsFilter f) {
    int c = 0;
    if (f.creatorType != null) c++;
    if (f.status != null) c++;
    if (f.dateFrom != null) c++;
    if (f.dateTo != null) c++;
    return c;
  }

  void _openFilterSheet() {
    HapticService.light();
    final current = ref.read(adminActivationsProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ActivationFilterSheet(
        initial: current,
        onApply: (f) => ref
            .read(adminActivationsProvider.notifier)
            .applyFilter(f.copyWith(search: current.search)),
        onClear: () => ref
            .read(adminActivationsProvider.notifier)
            .applyFilter(AdminActivationsFilter(search: current.search)),
      ),
    );
  }

  void _showDetail(AdminActivation activation) {
    final me = ref.read(adminMeProvider);
    pushRightPanel(
      context,
      _ActivationDetailPage(
        activation: activation,
        canReassign: me.isSuperAdmin,
        onReassign: () => _openReassignSheet(activation),
      ),
    );
  }

  void _openReassignSheet(AdminActivation activation) {
    pushRightPanel(
      context,
      _ReassignPage(
        activation: activation,
        onDone: (createdById, selfRegistered) async {
          final ok = await ref
              .read(adminActivationsProvider.notifier)
              .reassign(activation.id,
                  createdById: createdById, selfRegistered: selfRegistered);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok
                    ? context.l10n.adminActivationReassigned
                    : context.l10n.error),
                backgroundColor: ok ? AppColors.success : AppColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(adminActivationsProvider);
    final filterCount = _filterCount(state.filter);

    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  hintText: l10n.adminActivationSearch,
                  border: InputBorder.none,
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              )
            : Text(l10n.adminActivationsTitle),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
          Badge(
            isLabelVisible: filterCount > 0,
            label: Text('$filterCount'),
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              onPressed: _openFilterSheet,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: state.isLoading && state.activations.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.activations.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(adminActivationsProvider.notifier).load(),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    HapticService.medium();
                    await ref.read(adminActivationsProvider.notifier).load();
                  },
                  color: AppColors.primary,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _StatsSection(stats: state.stats),
                      ),
                      if (state.activations.isEmpty)
                        SliverFillRemaining(
                          child: EmptyState(
                            icon: Icons.how_to_reg_outlined,
                            title: l10n.adminActivationsTitle,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList.separated(
                            itemCount: state.activations.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) => _ActivationCard(
                              activation: state.activations[i],
                              onTap: () {
                                HapticService.light();
                                _showDetail(state.activations[i]);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

// ─── Stats Section ────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  final AdminActivationStats stats;

  const _StatsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        children: [
          _StatCard(
            label: l10n.adminActivationTotal,
            value: '${stats.total}',
            icon: Icons.how_to_reg_outlined,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: l10n.adminActivationSelfRegistered,
            value: '${stats.selfRegisteredCount}',
            icon: Icons.person_outlined,
            color: Colors.teal,
          ),
          const SizedBox(width: 8),
          _StatCard(
            label: l10n.adminActivationSuperAdmin,
            value: '${stats.superAdminCount}',
            icon: Icons.admin_panel_settings_outlined,
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Activation Card ──────────────────────────────────────────────────────────

class _ActivationCard extends StatelessWidget {
  final AdminActivation activation;
  final VoidCallback onTap;

  const _ActivationCard({required this.activation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final a = activation;

    final expiryLabel = a.subscriptionExpiry != null
        ? l10n.fmtDate(a.subscriptionExpiry!)
        : null;
    final dateLabel = l10n.fmtDate(a.createdAt);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.pharmacyName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(isActive: a.isActive),
                ],
              ),
              if (a.login.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  a.login,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              if (a.phone != null) ...[
                const SizedBox(height: 2),
                Text(
                  a.phone!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  _CreatorBadge(activation: a, l10n: l10n),
                  const Spacer(),
                  if (expiryLabel != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_outlined,
                            size: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45)),
                        const SizedBox(width: 3),
                        Text(
                          expiryLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline,
                            size: 12,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.4)),
                        const SizedBox(width: 3),
                        Text(
                          dateLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
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

class _StatusBadge extends StatelessWidget {
  final bool isActive;

  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isActive ? l10n.adminBusinessActive : l10n.adminBusinessInactive,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }
}

class _CreatorBadge extends StatelessWidget {
  final AdminActivation activation;
  final AppL10n l10n;

  const _CreatorBadge({required this.activation, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final a = activation;
    final Color color;
    final IconData icon;
    final String label;

    if (a.selfRegistered) {
      color = Colors.teal;
      icon = Icons.person_outline;
      label = l10n.adminActivationSelfRegistered;
    } else if (a.createdByName != null) {
      color = Colors.indigo;
      icon = Icons.manage_accounts_outlined;
      label = a.createdByName!;
    } else {
      color = Colors.deepPurple;
      icon = Icons.admin_panel_settings_outlined;
      label = l10n.adminActivationSuperAdmin;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Page ──────────────────────────────────────────────────────────────

class _ActivationDetailPage extends StatelessWidget {
  final AdminActivation activation;
  final bool canReassign;
  final VoidCallback onReassign;

  const _ActivationDetailPage({
    required this.activation,
    required this.canReassign,
    required this.onReassign,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final a = activation;

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.pharmacyName,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (a.login.isNotEmpty)
                Text(a.login,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      fontFamily: 'monospace',
                    )),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _StatusBadge(isActive: a.isActive),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            if (a.phone != null)
              _DetailRow(icon: Icons.phone_outlined, label: 'Телефон', value: a.phone!),
            _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: l10n.adminActivationDateAdded,
                value: l10n.fmtDate(a.createdAt)),
            if (a.subscriptionExpiry != null)
              _DetailRow(
                  icon: Icons.event_outlined,
                  label: 'Подписка до',
                  value: l10n.fmtDate(a.subscriptionExpiry!)),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.person_add_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(l10n.adminActivationCreator,
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                const Spacer(),
                _CreatorBadge(activation: a, l10n: l10n),
              ],
            ),
            if (canReassign) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  HapticService.light();
                  Navigator.pop(context);
                  onReassign();
                },
                icon: const Icon(Icons.swap_horiz_outlined, size: 18),
                label: Text(l10n.adminActivationReassign),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
          const SizedBox(width: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Reassign Page ────────────────────────────────────────────────────────────

class _ReassignPage extends ConsumerStatefulWidget {
  final AdminActivation activation;
  final Future<void> Function(String? createdById, bool selfRegistered) onDone;

  const _ReassignPage({required this.activation, required this.onDone});

  @override
  ConsumerState<_ReassignPage> createState() => _ReassignPageState();
}

class _ReassignPageState extends ConsumerState<_ReassignPage> {
  bool _isLoading = false;

  Future<void> _reassign(String? userId, bool selfRegistered) async {
    setState(() => _isLoading = true);
    await widget.onDone(userId, selfRegistered);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final usersState = ref.watch(adminUsersProvider);

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminActivationReassign),
              Text(widget.activation.pharmacyName,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _ReassignOption(
                    icon: Icons.person_outline,
                    label: l10n.adminActivationSelfRegistered,
                    color: Colors.teal,
                    onTap: () => _reassign(null, true),
                  ),
                  const SizedBox(height: 8),
                  _ReassignOption(
                    icon: Icons.admin_panel_settings_outlined,
                    label: l10n.adminActivationSuperAdmin,
                    color: Colors.deepPurple,
                    onTap: () => _reassign(null, false),
                  ),
                  if (usersState.users.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    const SizedBox(height: 8),
                    Text(l10n.adminActivationByUser,
                        style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.55))),
                    const SizedBox(height: 8),
                    ...usersState.users
                        .where((u) => u.isActive)
                        .map((u) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _ReassignOption(
                                icon: Icons.manage_accounts_outlined,
                                label: u.name,
                                sublabel: u.email,
                                color: Colors.indigo,
                                onTap: () => _reassign(u.id, false),
                              ),
                            )),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ReassignOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final Color color;
  final VoidCallback onTap;

  const _ReassignOption({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (sublabel != null)
                      Text(
                        sublabel!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 18, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Filter Page ──────────────────────────────────────────────────────────────

class _ActivationFilterSheet extends StatefulWidget {
  final AdminActivationsFilter initial;
  final ValueChanged<AdminActivationsFilter> onApply;
  final VoidCallback onClear;

  const _ActivationFilterSheet({
    required this.initial,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_ActivationFilterSheet> createState() => _ActivationFilterSheetState();
}

class _ActivationFilterSheetState extends State<_ActivationFilterSheet> {
  late String? _creatorType;
  late String? _status;
  late DateTime? _dateFrom;
  late DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _creatorType = widget.initial.creatorType;
    _status = widget.initial.status;
    _dateFrom = widget.initial.dateFrom;
    _dateTo = widget.initial.dateTo;
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
    if (picked != null) {
      setState(() => isFrom ? _dateFrom = picked : _dateTo = picked);
    }
  }

  int get _activeCount {
    int c = 0;
    if (_creatorType != null) c++;
    if (_status != null) c++;
    if (_dateFrom != null) c++;
    if (_dateTo != null) c++;
    return c;
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
              if (_activeCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$_activeCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
              const Spacer(),
              if (_activeCount > 0)
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
          Text(l10n.adminActivationWhoAdded,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _ToggleChip(
                label: l10n.adminActivationSelfRegistered,
                isSelected: _creatorType == 'self',
                onTap: () {
                  HapticService.selection();
                  setState(() => _creatorType = _creatorType == 'self' ? null : 'self');
                },
              ),
              _ToggleChip(
                label: l10n.adminActivationSuperAdmin,
                isSelected: _creatorType == 'superadmin',
                onTap: () {
                  HapticService.selection();
                  setState(() => _creatorType = _creatorType == 'superadmin' ? null : 'superadmin');
                },
              ),
              _ToggleChip(
                label: l10n.adminActivationByUser,
                isSelected: _creatorType == 'user',
                onTap: () {
                  HapticService.selection();
                  setState(() => _creatorType = _creatorType == 'user' ? null : 'user');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.adminActivationStatusFilter,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _ToggleChip(
                label: l10n.adminBusinessActive,
                isSelected: _status == 'active',
                onTap: () {
                  HapticService.selection();
                  setState(() => _status = _status == 'active' ? null : 'active');
                },
              ),
              _ToggleChip(
                label: l10n.adminBusinessInactive,
                isSelected: _status == 'inactive',
                onTap: () {
                  HapticService.selection();
                  setState(() => _status = _status == 'inactive' ? null : 'inactive');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.adminActivationDateAdded,
              style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DateBtn(
                  label:
                      _dateFrom != null ? l10n.fmtDateDt(_dateFrom!) : l10n.from,
                  isSet: _dateFrom != null,
                  onTap: () => _pickDate(true),
                  onClear: _dateFrom != null
                      ? () => setState(() => _dateFrom = null)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DateBtn(
                  label: _dateTo != null ? l10n.fmtDateDt(_dateTo!) : l10n.to,
                  isSet: _dateTo != null,
                  onTap: () => _pickDate(false),
                  onClear: _dateTo != null
                      ? () => setState(() => _dateTo = null)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                HapticService.light();
                widget.onApply(AdminActivationsFilter(
                  creatorType: _creatorType,
                  status: _status,
                  dateFrom: _dateFrom,
                  dateTo: _dateTo,
                ));
                Navigator.pop(context);
              },
              child: Text(l10n.apply),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label;
  final bool isSet;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateBtn({
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
              color: isSet ? AppColors.primary : theme.colorScheme.onSurfaceVariant,
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
                child: const Icon(Icons.close, size: 14, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}
