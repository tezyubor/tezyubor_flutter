import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../shared/widgets/pill_nav_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import 'orders/orders_screen.dart';
import 'analytics/analytics_screen.dart';
import 'clients/clients_screen.dart';
import 'settings/settings_screen.dart';
import 'subscription_expired_modal.dart';

class PharmacyMainScreen extends ConsumerStatefulWidget {
  final String initialTab;
  final bool openCreateOrder;

  const PharmacyMainScreen({
    super.key,
    this.initialTab = 'orders',
    this.openCreateOrder = false,
  });

  @override
  ConsumerState<PharmacyMainScreen> createState() => _PharmacyMainScreenState();
}

class _PharmacyMainScreenState extends ConsumerState<PharmacyMainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _tabIndexFromString(widget.initialTab);
    final user = ref.read(authStateProvider).user;
    ref.read(subscriptionProvider.notifier).checkExpiry(user?.subscriptionExpiry);
  }

  int _tabIndexFromString(String tab) => switch (tab) {
        'analytics' => 1,
        'clients' => 2,
        'settings' => 3,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isExpired = ref.watch(subscriptionProvider).isExpired;

    final pages = [
      OrdersScreen(openCreate: widget.openCreateOrder),
      const AnalyticsScreen(),
      const ClientsScreen(),
      const SettingsScreen(),
    ];

    final navItems = [
      PillNavItem(
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long,
        label: l10n.orders,
      ),
      PillNavItem(
        icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart,
        label: l10n.analytics,
      ),
      PillNavItem(
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        label: l10n.clients,
      ),
      PillNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: l10n.profile,
      ),
    ];

    final scaffold = Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: PillNavBar(
        currentIndex: _currentIndex,
        items: navItems,
        onItemSelected: (i) { HapticService.selection(); setState(() => _currentIndex = i); },
      ),
    );

    if (!isExpired) return scaffold;

    return Stack(
      children: [
        scaffold,
        const SubscriptionExpiredModal(),
      ],
    );
  }
}
