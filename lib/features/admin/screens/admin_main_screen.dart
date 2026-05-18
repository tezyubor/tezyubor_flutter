import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../features/auth/models/auth_models.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/pill_nav_bar.dart';
import '../../admin/providers/admin_provider.dart';
import 'orders/admin_orders_screen.dart';
import 'businesses/businesses_screen.dart';
import 'analytics/admin_analytics_screen.dart';
import 'clients/admin_clients_screen.dart';
import 'activations/activations_screen.dart';
import 'settings/admin_settings_screen.dart';

class AdminMainScreen extends ConsumerStatefulWidget {
  final String initialTab;

  const AdminMainScreen({super.key, this.initialTab = 'orders'});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabIndexFromString(widget.initialTab);
    Future.microtask(() => ref.read(adminMeProvider.notifier).load());
  }

  List<_AdminTab> _buildTabs(AuthUser user, AppL10n l10n) {
    final tabs = <_AdminTab>[
      _AdminTab(
        key: 'orders',
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: l10n.adminOrdersTitle,
        permission: 'orders:view',
      ),
      _AdminTab(
        key: 'businesses',
        icon: Icons.storefront_outlined,
        activeIcon: Icons.storefront,
        label: l10n.adminBusinessesTitle,
        permission: 'pharmacies:view',
      ),
      _AdminTab(
        key: 'analytics',
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: l10n.adminAnalyticsTitle,
        permission: 'analytics:view',
      ),
      _AdminTab(
        key: 'clients',
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: l10n.adminClientsTitle,
        permission: 'clients:view',
      ),
      _AdminTab(
        key: 'activations',
        icon: Icons.how_to_reg_outlined,
        activeIcon: Icons.how_to_reg,
        label: l10n.adminActivationsTitle,
        permission: 'activations:view',
      ),
      _AdminTab(
        key: 'settings',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: user.isSuperAdmin ? l10n.adminSettingsTitle : l10n.adminProfileTitle,
        permission: null,
      ),
    ];

    return tabs
        .where((t) => t.permission == null || user.hasPermission(t.permission!))
        .toList();
  }

  int _tabIndexFromString(String tab) {
    const order = [
      'orders',
      'businesses',
      'analytics',
      'clients',
      'activations',
      'settings',
    ];
    final idx = order.indexOf(tab);
    return idx < 0 ? 0 : idx;
  }

  Widget _buildPage(String key) => switch (key) {
        'businesses' => const BusinessesScreen(),
        'analytics' => const AdminAnalyticsScreen(),
        'clients' => const AdminClientsScreen(),
        'activations' => const ActivationsScreen(),
        'settings' => const AdminSettingsScreen(),
        _ => const AdminOrdersScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    if (user == null) return const SizedBox();

    final tabs = _buildTabs(user, l10n);
    final safeIndex = _currentIndex.clamp(0, tabs.length - 1);

    final navItems = tabs
        .map((t) => PillNavItem(
              icon: t.icon,
              activeIcon: t.activeIcon,
              label: t.label,
            ))
        .toList();

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: tabs.map((t) => _buildPage(t.key)).toList(),
      ),
      bottomNavigationBar: PillNavBar(
        currentIndex: safeIndex,
        items: navItems,
        onItemSelected: (i) { HapticService.selection(); setState(() => _currentIndex = i); },
      ),
    );
  }
}

class _AdminTab {
  final String key;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? permission;

  const _AdminTab({
    required this.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.permission,
  });
}
