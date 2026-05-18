import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/utils/right_panel.dart';
import '../../../../shared/utils/uz_phone_formatter.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../pharmacy/screens/location/location_picker_screen.dart';
import '../../../../core/services/haptic_service.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';

const _allCouriers = ['yandex', 'noor', 'millennium'];

class BusinessesScreen extends ConsumerStatefulWidget {
  const BusinessesScreen({super.key});

  @override
  ConsumerState<BusinessesScreen> createState() => _BusinessesScreenState();
}

class _BusinessesScreenState extends ConsumerState<BusinessesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _searchVisible = false;
  String? _filterIsActive;
  String? _filterCourier;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(adminPharmaciesProvider.notifier).load(
            search: v.isEmpty ? null : v,
            isActive: _filterIsActive,
            courier: _filterCourier,
          );
    });
  }

  void _toggleSearch() {
    HapticService.light();
    setState(() => _searchVisible = !_searchVisible);
    if (!_searchVisible) {
      _searchController.clear();
      ref.read(adminPharmaciesProvider.notifier).load(
            isActive: _filterIsActive,
            courier: _filterCourier,
          );
    }
  }

  void _openFilter() {
    HapticService.light();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BusinessFilterSheet(
        currentIsActive: _filterIsActive,
        currentCourier: _filterCourier,
        onApply: (isActive, courier) {
          setState(() {
            _filterIsActive = isActive;
            _filterCourier = courier;
          });
          ref.read(adminPharmaciesProvider.notifier).load(
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
                isActive: isActive,
                courier: courier,
              );
        },
        onClear: () {
          setState(() {
            _filterIsActive = null;
            _filterCourier = null;
          });
          ref.read(adminPharmaciesProvider.notifier).load(
                search: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
              );
        },
      ),
    );
  }

  void _openCreate() {
    HapticService.light();
    pushRightPanel(context, const _PharmacyFormPage());
  }

  bool get _hasFilter => _filterIsActive != null || _filterCourier != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(adminPharmaciesProvider);
    final me = ref.watch(adminMeProvider);
    final canCreate =
        me.isSuperAdmin || me.permissions.contains('pharmacies:create');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminBusinessesTitle),
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.search_off : Icons.search),
            onPressed: _toggleSearch,
          ),
          Badge(
            isLabelVisible: _hasFilter,
            backgroundColor: AppColors.primary,
            child: IconButton(
              icon: const Icon(Icons.tune_outlined),
              onPressed: _openFilter,
            ),
          ),
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
                      hintText: l10n.adminSearchBusiness,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                ref
                                    .read(adminPharmaciesProvider.notifier)
                                    .load(
                                      isActive: _filterIsActive,
                                      courier: _filterCourier,
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
      body: state.isLoading && state.pharmacies.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.pharmacies.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(adminPharmaciesProvider.notifier).load(),
                )
              : state.pharmacies.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: l10n.adminNoBusinesses,
                      subtitle: l10n.adminNoBusinessesSub,
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticService.medium();
                        await ref.read(adminPharmaciesProvider.notifier).load();
                      },
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: state.pharmacies.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _PharmacyCard(
                          pharmacy: state.pharmacies[i],
                          onTap: () {
                            HapticService.light();
                            pushRightPanel(
                              context,
                              _PharmacyDetailPage(
                                  pharmacy: state.pharmacies[i]),
                            );
                          },
                        ),
                      ),
                    ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _openCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 26),
            )
          : null,
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _BusinessFilterSheet extends StatefulWidget {
  final String? currentIsActive;
  final String? currentCourier;
  final void Function(String? isActive, String? courier) onApply;
  final VoidCallback onClear;

  const _BusinessFilterSheet({
    required this.currentIsActive,
    required this.currentCourier,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_BusinessFilterSheet> createState() => _BusinessFilterSheetState();
}

class _BusinessFilterSheetState extends State<_BusinessFilterSheet> {
  String? _isActive;
  String? _courier;

  @override
  void initState() {
    super.initState();
    _isActive = widget.currentIsActive;
    _courier = widget.currentCourier;
  }

  int get _count =>
      (_isActive != null ? 1 : 0) + (_courier != null ? 1 : 0);

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
              if (_count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
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
          Text(
            l10n.adminBusinessStatusFilter.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToggleChip(
                label: l10n.all,
                selected: _isActive == null,
                color: AppColors.primary,
                onTap: () {
                  HapticService.selection();
                  setState(() => _isActive = null);
                },
              ),
              _ToggleChip(
                label: l10n.adminBusinessActive,
                selected: _isActive == 'true',
                color: AppColors.success,
                onTap: () {
                  HapticService.selection();
                  setState(() => _isActive = _isActive == 'true' ? null : 'true');
                },
              ),
              _ToggleChip(
                label: l10n.adminBusinessInactive,
                selected: _isActive == 'false',
                color: AppColors.error,
                onTap: () {
                  HapticService.selection();
                  setState(() => _isActive = _isActive == 'false' ? null : 'false');
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.adminOrderCourier.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ToggleChip(
                label: l10n.adminCourierAll,
                selected: _courier == null,
                color: AppColors.primary,
                onTap: () {
                  HapticService.selection();
                  setState(() => _courier = null);
                },
              ),
              ..._allCouriers.map((c) => _ToggleChip(
                    label: c[0].toUpperCase() + c.substring(1),
                    selected: _courier == c,
                    color: AppColors.primary,
                    onTap: () {
                      HapticService.selection();
                      setState(() => _courier = _courier == c ? null : c);
                    },
                  )),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticService.light();
                widget.onApply(_isActive, _courier);
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

// ─── Pharmacy card ────────────────────────────────────────────────────────────

class _PharmacyCard extends ConsumerWidget {
  final AdminPharmacy pharmacy;
  final VoidCallback onTap;

  const _PharmacyCard({required this.pharmacy, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final daysLeft = _daysLeft(pharmacy.subscriptionExpiry);
    final isExpiringSoon = daysLeft != null && daysLeft <= 14;
    final isExpired = daysLeft != null && daysLeft <= 0;

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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: pharmacy.isActive
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.mutedForegroundLight
                            .withValues(alpha: 0.15),
                    child: Text(
                      pharmacy.name.isNotEmpty
                          ? pharmacy.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: pharmacy.isActive
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pharmacy.name,
                            style: theme.textTheme.titleSmall),
                        Text(pharmacy.login,
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: pharmacy.isActive
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pharmacy.isActive
                          ? l10n.adminBusinessActive
                          : l10n.adminBusinessInactive,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: pharmacy.isActive
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (pharmacy.phone != null)
                _row(context, Icons.phone_outlined, pharmacy.phone!),
              if (pharmacy.address != null)
                _row(context, Icons.location_on_outlined,
                    pharmacy.address!),
              _row(context, Icons.receipt_long_outlined,
                  '${pharmacy.ordersCount} ${l10n.adminBusinessOrders}'),
              if (pharmacy.allowedCouriers != null &&
                  pharmacy.allowedCouriers!.isNotEmpty)
                _row(context, Icons.local_shipping_outlined,
                    pharmacy.allowedCouriers!),
              if (pharmacy.subscriptionExpiry != null) ...[
                const SizedBox(height: 8),
                _SubscriptionBar(
                  l10n: l10n,
                  expiry: pharmacy.subscriptionExpiry!,
                  daysLeft: daysLeft ?? 0,
                  isExpired: isExpired,
                  isExpiringSoon: isExpiringSoon,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext ctx, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon,
                  size: 14,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );

  int? _daysLeft(String? expiry) {
    if (expiry == null) return null;
    final dt = DateTime.tryParse(expiry);
    if (dt == null) return null;
    return dt.difference(DateTime.now()).inDays;
  }
}

// ─── Pharmacy detail page ─────────────────────────────────────────────────────

class _PharmacyDetailPage extends ConsumerWidget {
  final AdminPharmacy pharmacy;
  const _PharmacyDetailPage({required this.pharmacy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final me = ref.watch(adminMeProvider);
    final canEdit =
        me.isSuperAdmin || me.permissions.contains('pharmacies:edit');
    final canDelete =
        me.isSuperAdmin || me.permissions.contains('pharmacies:delete');
    final daysLeft = _daysLeft(pharmacy.subscriptionExpiry);
    final isExpired = daysLeft != null && daysLeft <= 0;
    final isExpiringSoon = daysLeft != null && daysLeft <= 14;

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pharmacy.name,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(pharmacy.login,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontFamily: 'monospace')),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pharmacy.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pharmacy.isActive
                      ? l10n.adminBusinessActive
                      : l10n.adminBusinessInactive,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: pharmacy.isActive
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _InfoRow(
                icon: Icons.receipt_long_outlined,
                label: l10n.adminBusinessOrders,
                value: '${pharmacy.ordersCount}'),
            if (pharmacy.ownerName != null)
              _InfoRow(
                  icon: Icons.person_outline,
                  label: l10n.adminBusinessOwner,
                  value: pharmacy.ownerName!),
            if (pharmacy.phone != null)
              _InfoRow(
                  icon: Icons.phone_outlined,
                  label: l10n.phone,
                  value: pharmacy.phone!),
            if (pharmacy.address != null)
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: l10n.address,
                  value: pharmacy.address!),
            if (pharmacy.allowedCouriers != null &&
                pharmacy.allowedCouriers!.isNotEmpty)
              _InfoRow(
                  icon: Icons.local_shipping_outlined,
                  label: l10n.adminBusinessCouriers,
                  value: pharmacy.allowedCouriers!),
            if (pharmacy.subscriptionExpiry != null)
              _InfoRow(
                icon: Icons.calendar_today,
                label: l10n.adminBusinessSubExpiry,
                value: l10n.fmtDate(pharmacy.subscriptionExpiry!),
                valueColor: isExpired
                    ? AppColors.error
                    : isExpiringSoon
                        ? AppColors.warning
                        : AppColors.success,
              ),
            if (canEdit || canDelete) ...[
              const SizedBox(height: 20),
              if (canEdit)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      HapticService.light();
                      Navigator.pop(context);
                      pushRightPanel(
                        context,
                        _PharmacyFormPage(pharmacy: pharmacy),
                      );
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l10n.adminEditBusiness),
                  ),
                ),
              if (canDelete) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      HapticService.light();
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n.adminDeleteBusiness),
                          content: Text(
                              '"${pharmacy.name}"\n${l10n.adminDeleteBusinessMsg}'),
                          actions: [
                            TextButton(
                                onPressed: () =>
                                    Navigator.pop(ctx, false),
                                child: Text(l10n.cancel)),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppColors.error),
                              child: Text(l10n.yes),
                            ),
                          ],
                        ),
                      );
                      if (ok == true && context.mounted) {
                        final success = await ref
                            .read(adminPharmaciesProvider.notifier)
                            .delete(pharmacy.id);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                                  content: Text(success
                                      ? l10n.adminBusinessDeleted
                                      : l10n.error)));
                        }
                      }
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.error),
                    label: Text(
                        l10n.adminDeleteBusiness.replaceAll('?', '')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  int? _daysLeft(String? expiry) {
    if (expiry == null) return null;
    final dt = DateTime.tryParse(expiry);
    if (dt == null) return null;
    return dt.difference(DateTime.now()).inDays;
  }


}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              )),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: valueColor,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ─── Pharmacy form page ───────────────────────────────────────────────────────

class _PharmacyFormPage extends ConsumerStatefulWidget {
  final AdminPharmacy? pharmacy;
  const _PharmacyFormPage({this.pharmacy});

  @override
  ConsumerState<_PharmacyFormPage> createState() => _PharmacyFormPageState();
}

class _PharmacyFormPageState extends ConsumerState<_PharmacyFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ownerCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _loginCtrl;
  final _passwordCtrl = TextEditingController();
  late final TextEditingController _addressCtrl;
  DateTime? _expiryDate;
  late bool _isActive;
  late Set<String> _couriers;
  bool _isLoading = false;
  bool _showPass = false;

  bool get _isEdit => widget.pharmacy != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pharmacy;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _ownerCtrl = TextEditingController(text: p?.ownerName ?? '');
    _phoneCtrl = TextEditingController(
        text: UzPhoneFormatter.toDisplay(p?.phone));
    _loginCtrl = TextEditingController(text: p?.login ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _isActive = p?.isActive ?? true;
    _expiryDate = p?.subscriptionExpiry != null
        ? DateTime.tryParse(p!.subscriptionExpiry!)
        : null;
    _couriers = {};
    if (p?.allowedCouriers != null) {
      for (final c in p!.allowedCouriers!.split(',')) {
        final trimmed = c.trim();
        if (trimmed.isNotEmpty) _couriers.add(trimmed);
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _loginCtrl.dispose();
    _passwordCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    HapticService.light();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_nameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty ||
        _loginCtrl.text.trim().isEmpty) {
      return;
    }
    if (!_isEdit && _passwordCtrl.text.trim().length < 6) return;
    if (_expiryDate == null && !_isEdit) return;

    setState(() => _isLoading = true);
    final expiryStr = _expiryDate?.toIso8601String();
    final couriersStr = _couriers.join(',');

    bool ok;
    if (_isEdit) {
      ok = await ref.read(adminPharmaciesProvider.notifier).update(
            widget.pharmacy!.id,
            name: _nameCtrl.text.trim(),
            ownerName: _ownerCtrl.text.trim(),
            phone: UzPhoneFormatter.isComplete(_phoneCtrl.text)
                ? UzPhoneFormatter.toE164(_phoneCtrl.text)
                : _phoneCtrl.text.trim(),
            login: _loginCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            subscriptionExpiry: expiryStr,
            isActive: _isActive,
            newPassword: _passwordCtrl.text.trim().isEmpty
                ? null
                : _passwordCtrl.text.trim(),
            allowedCouriers: couriersStr,
          );
    } else {
      ok = await ref.read(adminPharmaciesProvider.notifier).create(
            name: _nameCtrl.text.trim(),
            ownerName: _ownerCtrl.text.trim(),
            phone: UzPhoneFormatter.isComplete(_phoneCtrl.text)
                ? UzPhoneFormatter.toE164(_phoneCtrl.text)
                : _phoneCtrl.text.trim(),
            login: _loginCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            subscriptionExpiry: expiryStr!,
            allowedCouriers: couriersStr,
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEdit
                ? l10n.adminBusinessUpdated
                : l10n.adminBusinessCreated)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Text(
              _isEdit ? l10n.adminEditBusiness : l10n.adminCreateBusiness),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.storeNameLbl,
                prefixIcon: const Icon(Icons.storefront_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ownerCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminBusinessOwner,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [UzPhoneFormatter()],
              decoration: InputDecoration(
                labelText: l10n.adminBusinessPhoneLbl,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _loginCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminBusinessLoginLbl,
                prefixIcon: const Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: !_showPass,
              decoration: InputDecoration(
                labelText: _isEdit
                    ? '${l10n.adminBusinessPasswordLbl} (${l10n.adminPasswordLeaveBlank})'
                    : l10n.adminBusinessPasswordLbl,
                hintText: _isEdit ? '••••••' : l10n.adminPasswordMin,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showPass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _showPass = !_showPass),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressCtrl,
              decoration: InputDecoration(
                labelText: l10n.adminBusinessAddressLbl,
                prefixIcon: const Icon(Icons.location_on_outlined),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.map_outlined,
                      color: AppColors.primary),
                  onPressed: () {
                    HapticService.light();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => LocationPickerScreen(
                          initialAddress: _addressCtrl.text,
                          onAddressPicked: (addr) =>
                              setState(() => _addressCtrl.text = addr),
                        ),
                        transitionsBuilder: (_, animation, __, child) =>
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeInOut)),
                              child: child,
                            ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickExpiry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _expiryDate == null
                        ? Theme.of(context).colorScheme.outline
                        : AppColors.primary,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 20, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _expiryDate != null
                            ? '${l10n.adminBusinessSubExpiry}: ${l10n.fmtDateDt(_expiryDate!)}'
                            : l10n.adminBusinessSubExpiry,
                        style: TextStyle(
                          color: _expiryDate == null
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.adminBusinessCouriers,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allCouriers.map((c) {
                final sel = _couriers.contains(c);
                return FilterChip(
                  label: Text(
                    c[0].toUpperCase() + c.substring(1),
                    style:
                        TextStyle(color: sel ? Colors.white : null),
                  ),
                  selected: sel,
                  onSelected: (v) => setState(
                      () => v ? _couriers.add(c) : _couriers.remove(c)),
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                );
              }).toList(),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                title: Text(l10n.adminActiveAccount),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                activeTrackColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _isEdit ? l10n.save : l10n.adminCreateBusiness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subscription bar ─────────────────────────────────────────────────────────

class _SubscriptionBar extends StatelessWidget {
  final AppL10n l10n;
  final String expiry;
  final int daysLeft;
  final bool isExpired;
  final bool isExpiringSoon;

  const _SubscriptionBar({
    required this.l10n,
    required this.expiry,
    required this.daysLeft,
    required this.isExpired,
    required this.isExpiringSoon,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpired
        ? AppColors.error
        : isExpiringSoon
            ? AppColors.warning
            : AppColors.success;

    final label = isExpired
        ? l10n.adminSubExpired
        : '${l10n.adminSubDays} $daysLeft ${l10n.adminSubDaysSuffix}';

    return Row(
      children: [
        Icon(Icons.calendar_today, size: 13, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Toggle chip ──────────────────────────────────────────────────────────────

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
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? color
                    : color.withValues(alpha: 0.3)),
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
