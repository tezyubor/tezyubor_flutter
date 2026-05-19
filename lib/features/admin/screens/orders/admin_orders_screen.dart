import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/utils/uz_phone_formatter.dart';
import '../../../../shared/utils/right_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../../shared/widgets/status_tab_bar.dart';
import '../../models/admin_models.dart';
import '../../providers/admin_provider.dart';

const _adminStatusOrder = [
  'pending',
  'awaiting_confirmation',
  'confirmed',
  'courier_pickup',
  'courier_picked',
  'courier_delivery',
  'delivered',
  'cancelled',
];

const _allCouriers = ['yandex', 'noor', 'millennium'];

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _searchVisible = false;

  static const _tabStatuses = ['all', ..._adminStatusOrder];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabStatuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _tabLabel(String status, AppL10n l10n) {
    if (status == 'all') return l10n.adminStatusAll;
    return StatusBadge.labelForL10n(status, l10n);
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final f = ref.read(adminOrdersProvider).filter.copyWith(
            search: v,
            clearSearch: v.isEmpty,
          );
      ref.read(adminOrdersProvider.notifier).applyFilter(f);
    });
  }

  void _toggleSearch() {
    HapticService.light();
    setState(() => _searchVisible = !_searchVisible);
    if (!_searchVisible) {
      _searchController.clear();
      final f =
          ref.read(adminOrdersProvider).filter.copyWith(clearSearch: true);
      ref.read(adminOrdersProvider.notifier).applyFilter(f);
    }
  }

  void _openFilter() {
    HapticService.light();
    final current = ref.read(adminOrdersProvider).filter;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AdminOrderFilterSheet(
        current: current,
        onApply: (f) => ref.read(adminOrdersProvider.notifier).applyFilter(f),
        onClear: () => ref.read(adminOrdersProvider.notifier).clearFilter(),
      ),
    );
  }

  void _openCreate() {
    HapticService.light();
    if (ref.read(adminPharmaciesProvider).pharmacies.isEmpty) {
      ref.read(adminPharmaciesProvider.notifier).load();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AdminCreateOrderSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(adminOrdersProvider);
    final me = ref.watch(adminMeProvider);
    final hasFilter = state.filter.isActive;

    final canCreate =
        me.isSuperAdmin || me.permissions.contains('orders:create');

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminOrdersTitle),
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
                      hintText: l10n.adminSearchOrders,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                ref
                                    .read(adminOrdersProvider.notifier)
                                    .applyFilter(ref
                                        .read(adminOrdersProvider)
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
      body: state.isLoading && state.orders.isEmpty
          ? const CenteredLoader()
          : state.error != null && state.orders.isEmpty
              ? AppErrorWidget(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(adminOrdersProvider.notifier).load(),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _tabStatuses.map((status) {
                    final orders = status == 'all'
                        ? state.orders
                        : state.orders
                            .where((o) => o.status == status)
                            .toList();
                    return _AdminTabOrderList(
                      key: ValueKey(status),
                      orders: orders,
                      l10n: l10n,
                    );
                  }).toList(),
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

class _AdminOrderFilterSheet extends StatefulWidget {
  final AdminOrdersFilter current;
  final void Function(AdminOrdersFilter) onApply;
  final VoidCallback onClear;

  const _AdminOrderFilterSheet({
    required this.current,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<_AdminOrderFilterSheet> createState() => _AdminOrderFilterSheetState();
}

class _AdminOrderFilterSheetState extends State<_AdminOrderFilterSheet> {
  String? _courier;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  @override
  void initState() {
    super.initState();
    _courier = widget.current.courier;
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
      (_courier != null ? 1 : 0) +
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
                  HapticService.light();
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: Text(l10n.clear),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.adminOrderCourier.toUpperCase(),
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
            children: [
              _ToggleChip(
                label: l10n.adminCourierAll,
                selected: _courier == null,
                color: AppColors.primary,
                onTap: () { HapticService.selection(); setState(() => _courier = null); },
              ),
              ..._allCouriers.map((c) => _ToggleChip(
                    label: c[0].toUpperCase() + c.substring(1),
                    selected: _courier == c,
                    color: AppColors.primary,
                    onTap: () { HapticService.selection(); setState(() => _courier = _courier == c ? null : c); },
                  )),
            ],
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
                  onPressed: () { HapticService.light(); setState(() { _dateFrom = null; _dateTo = null; }); },
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
                widget.onApply(AdminOrdersFilter(
                  search: widget.current.search,
                  courier: _courier,
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
      ),
    );
  }

}

// ─── Create order sheet ───────────────────────────────────────────────────────

class _AdminCreateOrderSheet extends ConsumerStatefulWidget {
  const _AdminCreateOrderSheet();

  @override
  ConsumerState<_AdminCreateOrderSheet> createState() =>
      _AdminCreateOrderSheetState();
}

class _AdminCreateOrderSheetState
    extends ConsumerState<_AdminCreateOrderSheet> {
  final _commentCtrl = TextEditingController();
  final _phoneCtrl =
      TextEditingController(text: UzPhoneFormatter.initialValue);
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _selectedPharmacyId;
  String? _selectedPharmacyName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneCtrl.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    if (UzPhoneFormatter.isComplete(_phoneCtrl.text)) {
      final digits = UzPhoneFormatter.digitsOnly(_phoneCtrl.text);
      final clients = ref.read(adminClientsProvider).clients;
      final match = clients
          .where((c) => UzPhoneFormatter.digitsOnly(c.phone) == digits)
          .firstOrNull;
      if (match?.name != null && _nameCtrl.text.isEmpty) {
        _nameCtrl.text = match!.name!;
      }
    }
  }

  @override
  void dispose() {
    _phoneCtrl.removeListener(_onPhoneChanged);
    _commentCtrl.dispose();
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_selectedPharmacyId == null) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(adminOrdersProvider.notifier).createOrder(
          pharmacyId: _selectedPharmacyId!,
          comment: _commentCtrl.text.trim(),
          medicinesTotal: double.tryParse(_amountCtrl.text.trim()),
          customerPhone: UzPhoneFormatter.isComplete(_phoneCtrl.text)
              ? UzPhoneFormatter.toE164(_phoneCtrl.text)
              : null,
          customerName: _nameCtrl.text.trim().isEmpty
              ? null
              : _nameCtrl.text.trim(),
        );
    if (mounted) {
      setState(() => _isLoading = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.adminOrderCreated)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final pharmacies = ref.watch(adminPharmaciesProvider).pharmacies;

    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) HapticService.medium();
      },
      child: Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: (screenHeight * 0.9 - bottom).clamp(200.0, screenHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
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
                Text(l10n.adminCreateOrderTitle,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
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
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

            _SheetSectionLabel(l10n.adminSelectPharmacy),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () { HapticService.light(); _showPharmacyPicker(context, pharmacies); },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedPharmacyId != null
                        ? AppColors.primary
                        : borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storefront_outlined,
                        size: 18,
                        color: _selectedPharmacyId != null
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedPharmacyName ?? l10n.adminSelectPharmacy,
                        style: TextStyle(
                          color: _selectedPharmacyId == null
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                          fontWeight: _selectedPharmacyId != null
                              ? FontWeight.w600
                              : null,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _SheetSectionLabel(l10n.customer),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.customer,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [UzPhoneFormatter()],
                      decoration: InputDecoration(
                        labelText: l10n.phone,
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SheetSectionLabel(l10n.order),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: TextField(
                      controller: _commentCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: l10n.orderCommentLbl,
                        hintText: l10n.orderCommentHint,
                        prefixIcon: const Icon(Icons.comment_outlined),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.orderAmountLbl,
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      ),
                    ),
                  ),
                ],
              ),
            ),
                  const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 8, 0, bottom > 0 ? 12 : 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      _isLoading || _selectedPharmacyId == null ? null : _submit,
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
                      : Text(l10n.adminCreateOrder),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }

  void _showPharmacyPicker(
      BuildContext context, List<AdminPharmacy> pharmacies) {
    pushRightPanel(
      context,
      _PharmacyPickerPage(
        pharmacies: pharmacies,
        selectedId: _selectedPharmacyId,
        l10n: context.l10n,
        onSelected: (p) {
          setState(() {
            _selectedPharmacyId = p.id;
            _selectedPharmacyName = p.name;
          });
        },
      ),
    );
  }
}

// ─── Pharmacy picker page ─────────────────────────────────────────────────────

class _PharmacyPickerPage extends StatefulWidget {
  final List<AdminPharmacy> pharmacies;
  final String? selectedId;
  final AppL10n l10n;
  final void Function(AdminPharmacy) onSelected;

  const _PharmacyPickerPage({
    required this.pharmacies,
    required this.selectedId,
    required this.l10n,
    required this.onSelected,
  });

  @override
  State<_PharmacyPickerPage> createState() => _PharmacyPickerPageState();
}

class _PharmacyPickerPageState extends State<_PharmacyPickerPage> {
  final _searchCtrl = TextEditingController();
  List<AdminPharmacy> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.pharmacies;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.pharmacies
          : widget.pharmacies
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.login.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Text(l10n.adminSelectPharmacy),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.search,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
        body: ListView.builder(
          itemCount: _filtered.length,
          itemBuilder: (_, i) {
            final p = _filtered[i];
            return ListTile(
              title: Text(p.name),
              subtitle: Text(p.login),
              selected: widget.selectedId == p.id,
              selectedColor: AppColors.primary,
              onTap: () {
                HapticService.selection();
                widget.onSelected(p);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }
}

// ─── Tab list ─────────────────────────────────────────────────────────────────

class _AdminTabOrderList extends ConsumerWidget {
  final List<AdminOrder> orders;
  final AppL10n l10n;

  const _AdminTabOrderList(
      {super.key, required this.orders, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long,
        title: l10n.adminNoOrders,
        subtitle: l10n.adminNoOrdersSub,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticService.medium();
        await ref.read(adminOrdersProvider.notifier).load();
      },
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _AdminOrderCard(
          order: orders[i],
          l10n: l10n,
          onTap: () => pushRightPanel(context, _AdminOrderDetailPage(order: orders[i])),
        ),
      ),
    );
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _AdminOrderCard extends ConsumerWidget {
  final AdminOrder order;
  final AppL10n l10n;
  final VoidCallback onTap;

  const _AdminOrderCard(
      {required this.order, required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final me = ref.watch(adminMeProvider);
    final canConfirm =
        me.isSuperAdmin || me.permissions.contains('orders:confirm');
    final canCancel =
        me.isSuperAdmin || me.permissions.contains('orders:cancel');

    final statusColor = StatusBadge.colorFor(order.status);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.pharmacyName ?? '—',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '#${order.token.toUpperCase()}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurfaceVariant,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (order.customerPhone != null)
                        _CardInfoRow(
                            icon: Icons.phone_outlined,
                            value: order.customerPhone!,
                            theme: theme),
                      if (order.customerAddress != null)
                        _CardInfoRow(
                            icon: Icons.location_on_outlined,
                            value: order.customerAddress!,
                            theme: theme),
                      if (order.selectedCourier != null)
                        _CardInfoRow(
                            icon: Icons.local_shipping_outlined,
                            value: order.selectedCourier!.toUpperCase(),
                            theme: theme),
                      Row(
                        children: [
                          _CardInfoRow(
                              icon: Icons.access_time,
                              value: l10n.fmtDate(order.createdAt),
                              theme: theme),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${order.medicinesTotal.toStringAsFixed(0)} сум',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (order.status == 'awaiting_confirmation' &&
                          (canConfirm || canCancel)) ...[
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outline.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (canConfirm)
                              Expanded(
                                child: SizedBox(
                                  height: 38,
                                  child: ElevatedButton(
                                    onPressed: () { HapticService.light(); _confirmOrder(context, ref); },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.adminConfirmOrder,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                            if (canCancel) ...[
                              if (canConfirm) const SizedBox(width: 8),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: () { HapticService.light(); _cancelOrder(context, ref); },
                                  icon: const Icon(
                                    Icons.cancel_outlined,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
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

  Future<void> _confirmOrder(BuildContext context, WidgetRef ref) async {
    final ok = await ref
        .read(adminOrdersProvider.notifier)
        .confirmOrder(order.token);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok
              ? context.l10n.adminOrderConfirmed
              : context.l10n.adminOrderError)));
    }
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminCancelOrder),
        content: Text(l10n.adminDeleteOrderMsg),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.warning),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(adminOrdersProvider.notifier)
          .cancelOrder(order.token);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? context.l10n.adminOrderCancelled
                : context.l10n.adminOrderError)));
      }
    }
  }
}

// ─── Order detail page ────────────────────────────────────────────────────────

class _AdminOrderDetailPage extends ConsumerWidget {
  final AdminOrder order;
  const _AdminOrderDetailPage({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final me = ref.watch(adminMeProvider);
    final canConfirm =
        me.isSuperAdmin || me.permissions.contains('orders:confirm');
    final canCancel =
        me.isSuperAdmin || me.permissions.contains('orders:cancel');
    final canDelete =
        me.isSuperAdmin || me.permissions.contains('orders:delete');

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${order.token.toUpperCase()}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                l10n.fmtDateTime(order.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: StatusBadge(status: order.status),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            if (order.pharmacyName != null) ...[
              _SheetSectionLabel(l10n.adminPharmacyLbl),
              const SizedBox(height: 8),
              _SectionCard(children: [
                _DetailRow(
                    icon: Icons.storefront_outlined,
                    label: l10n.adminPharmacyLbl,
                    value: order.pharmacyName!),
                if (order.pharmacyPhone != null)
                  _DetailRow(
                      icon: Icons.phone_outlined,
                      label: l10n.phone,
                      value: order.pharmacyPhone!),
                if (order.pharmacyAddress != null)
                  _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: l10n.address,
                      value: order.pharmacyAddress!,
                      wrapValue: true),
                if (order.pharmacyComment != null)
                  _DetailRow(
                      icon: Icons.comment_outlined,
                      label: l10n.orderCommentLbl,
                      value: order.pharmacyComment!,
                      wrapValue: true),
              ]),
              const SizedBox(height: 14),
            ],
            if (order.customerName != null ||
                order.customerPhone != null ||
                order.customerAddress != null) ...[
              _SheetSectionLabel(l10n.customer),
              const SizedBox(height: 8),
              _SectionCard(children: [
                if (order.customerName != null)
                  _DetailRow(
                      icon: Icons.person_outline,
                      label: l10n.customer,
                      value: order.customerName!),
                if (order.customerPhone != null)
                  _DetailRow(
                      icon: Icons.phone_outlined,
                      label: l10n.phone,
                      value: order.customerPhone!),
                if (order.customerAddress != null)
                  _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: l10n.address,
                      value: order.customerAddress!,
                      wrapValue: true),
                if (order.customerComment != null)
                  _DetailRow(
                      icon: Icons.comment_outlined,
                      label: l10n.customerCommentLbl,
                      value: order.customerComment!,
                      wrapValue: true),
              ]),
              const SizedBox(height: 14),
            ],
            _SheetSectionLabel(l10n.totalCost),
            const SizedBox(height: 8),
            _SectionCard(children: [
              _DetailRow(
                  icon: Icons.shopping_bag_outlined,
                  label: l10n.adminOrderSum,
                  value: '${order.medicinesTotal.toStringAsFixed(0)} сум'),
              if (order.deliveryPrice != null)
                _DetailRow(
                    icon: Icons.delivery_dining,
                    label: l10n.deliveryCost,
                    value: '${order.deliveryPrice!.toStringAsFixed(0)} сум'),
              if (order.totalPrice != null)
                _DetailRow(
                    icon: Icons.receipt_outlined,
                    label: l10n.totalAmountLbl,
                    value: '${order.totalPrice!.toStringAsFixed(0)} сум',
                    bold: true,
                    valueColor: AppColors.primary),
            ]),
            if (order.selectedCourier != null) ...[
              const SizedBox(height: 14),
              _SheetSectionLabel(l10n.courier),
              const SizedBox(height: 8),
              _SectionCard(children: [
                _DetailRow(
                    icon: Icons.local_shipping_outlined,
                    label: l10n.courier,
                    value: order.selectedCourier!.toUpperCase()),
                if (order.trackingUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: () async {
                        HapticService.light();
                        final uri = Uri.tryParse(order.trackingUrl!);
                        if (uri != null) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.open_in_new,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            l10n.trackingLink,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ]),
            ],
            const SizedBox(height: 20),

            if (canConfirm && order.status == 'awaiting_confirmation') ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticService.light();
                    final ok = await ref
                        .read(adminOrdersProvider.notifier)
                        .confirmOrder(order.token);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok
                              ? l10n.adminOrderConfirmed
                              : l10n.adminOrderError)));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l10n.adminConfirmOrder),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (canCancel &&
                order.status != 'cancelled' &&
                order.status != 'delivered') ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () async {
                    HapticService.light();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.adminCancelOrder),
                        content: Text(l10n.adminDeleteOrderMsg),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.cancel)),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.warning),
                            child: Text(l10n.yes),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      final ok = await ref
                          .read(adminOrdersProvider.notifier)
                          .cancelOrder(order.token);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? l10n.adminOrderCancelled
                                : l10n.adminOrderError)));
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(l10n.adminCancelOrder),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (canDelete)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    HapticService.light();
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l10n.adminDeleteOrder),
                        content: Text(l10n.adminDeleteOrderMsg),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
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
                    if (confirmed == true && context.mounted) {
                      await ref
                          .read(adminOrdersProvider.notifier)
                          .deleteOrder(order.id);
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  label: Text(l10n.adminDeleteOrder.replaceAll('?', '')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _SheetSectionLabel extends StatelessWidget {
  final String text;
  const _SheetSectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: children
              .asMap()
              .entries
              .map((entry) {
                final isLast = entry.key == children.length - 1;
                return Column(
                  children: [
                    entry.value,
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                  ],
                );
              })
              .toList(),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  final bool wrapValue;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
    this.wrapValue = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: bold ? FontWeight.bold : FontWeight.w500,
      color: valueColor,
    );

    if (wrapValue) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(label, style: labelStyle),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(value, style: valueStyle),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label, style: labelStyle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardInfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final ThemeData theme;

  const _CardInfoRow({
    required this.icon,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
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
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color : color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? color : color.withValues(alpha: 0.3)),
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
