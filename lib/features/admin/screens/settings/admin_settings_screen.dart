import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../shared/utils/right_panel.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/admin_provider.dart';
import '../roles/roles_screen.dart';

/// Single screen used for both SuperAdmin (Settings) and regular admin users (Profile).
/// - SuperAdmin: shows profile info + role management section + appearance
/// - Regular user: shows profile info + their permissions + appearance
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(authStateProvider).user;
    final meState = ref.watch(adminMeProvider);

    final isSuperAdmin = user?.isSuperAdmin ?? meState.isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSuperAdmin ? l10n.adminSettingsTitle : l10n.adminProfileTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile info section ────────────────────────────────────────
          _SectionCard(
            title: l10n.adminProfileInfo,
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: l10n.adminProfileName,
                value: user?.name ?? '—',
              ),
              if (user?.email != null)
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: l10n.adminProfileEmail,
                  value: user!.email!,
                ),
              _InfoRow(
                icon: Icons.shield_outlined,
                label: l10n.adminProfileRole,
                value: isSuperAdmin
                    ? l10n.adminSuperAdmin
                    : l10n.adminRegularUser,
                valueColor: isSuperAdmin ? AppColors.primary : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Permissions section (only for non-super-admin) ──────────────
          if (!isSuperAdmin && meState.permissions.isNotEmpty) ...[
            _SectionCard(
              title: l10n.adminProfilePermissionsSection,
              children: meState.permissions
                  .map((perm) => _PermissionRow(
                        permission: perm,
                        l10n: l10n,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // ── Role management section (superadmin only) ───────────────────
          if (isSuperAdmin) ...[
            _SectionCard(
              title: l10n.adminRoleManagementSection,
              children: [
                _NavRow(
                  icon: Icons.manage_accounts_outlined,
                  label: l10n.adminGoToRoles,
                  onTap: () {
                    HapticService.light();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RolesScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ── Appearance ─────────────────────────────────────────────────
          _SectionCard(
            title: l10n.adminAppearanceSection,
            children: [
              _ThemeSwitcherRow(l10n: l10n, ref: ref),
              _LanguageRow(l10n: l10n, ref: ref),
              _HapticRow(l10n: l10n, ref: ref),
            ],
          ),
          const SizedBox(height: 16),

          // ── Application ────────────────────────────────────────────────
          _SectionCard(
            title: l10n.application,
            children: [
              _AboutAppTile(l10n: l10n),
            ],
          ),
          const SizedBox(height: 16),

          // ── Logout ─────────────────────────────────────────────────────
          _LogoutButton(l10n: l10n),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
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
                          indent: 48,
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.3),
                        ),
                    ],
                  );
                })
                .toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: Icon(icon,
          color: theme.colorScheme.onSurfaceVariant, size: 20),
      title: Text(label,
          style:
              theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: valueColor,
        ),
      ),
    );
  }
}

// ─── Permission Row ───────────────────────────────────────────────────────────

class _PermissionRow extends StatelessWidget {
  final String permission;
  final AppL10n l10n;

  const _PermissionRow({required this.permission, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      leading: const Icon(Icons.check_circle_outline,
          color: AppColors.success, size: 18),
      title: Text(
        l10n.permissionLabel(permission),
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        permission,
        style: theme.textTheme.labelSmall
            ?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

// ─── Nav Row ──────────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

// ─── Theme switcher ───────────────────────────────────────────────────────────

class _ThemeSwitcherRow extends StatelessWidget {
  final AppL10n l10n;
  final WidgetRef ref;

  const _ThemeSwitcherRow({required this.l10n, required this.ref});

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return ListTile(
      leading: Icon(
        themeMode == ThemeMode.dark
            ? Icons.dark_mode_outlined
            : Icons.light_mode_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(l10n.theme),
      trailing: Text(
        switch (themeMode) {
          ThemeMode.dark => l10n.themeDark,
          ThemeMode.light => l10n.themeLight,
          _ => l10n.themeSystem,
        },
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      onTap: () { HapticService.light(); _showThemePicker(context); },
    );
  }

  void _showThemePicker(BuildContext context) {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) HapticService.medium();
        },
        child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(l10n.theme,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _themeOption(context, Icons.light_mode_outlined, l10n.themeLight,
                current == ThemeMode.light, ThemeMode.light),
            _themeOption(context, Icons.dark_mode_outlined, l10n.themeDark,
                current == ThemeMode.dark, ThemeMode.dark),
            _themeOption(context, Icons.brightness_auto_outlined, l10n.themeSystem,
                current == ThemeMode.system, ThemeMode.system),
          ],
        ),
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, IconData icon, String label,
      bool selected, ThemeMode mode) {
    return ListTile(
      leading: Icon(icon,
          color: selected ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? AppColors.primary : null,
          )),
      trailing: selected ? const Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        HapticService.selection();
        ref.read(themeModeProvider.notifier).setMode(mode);
        Navigator.pop(context);
      },
    );
  }
}

// ─── Language row ─────────────────────────────────────────────────────────────

class _LanguageRow extends StatelessWidget {
  final AppL10n l10n;
  final WidgetRef ref;

  const _LanguageRow({required this.l10n, required this.ref});

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return ListTile(
      leading: Icon(Icons.language_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
      title: Text(l10n.language),
      trailing: Text(
        locale.languageCode.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
      onTap: () { HapticService.light(); _showLanguageSheet(context, ref); },
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) HapticService.medium();
        },
        child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in const [
              ('ru', 'Русский'),
              ('uz', "O'zbek"),
              ('en', 'English'),
            ])
              ListTile(
                title: Text(entry.$2),
                onTap: () {
                  HapticService.selection();
                  Navigator.pop(ctx);
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(Locale(entry.$1));
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }
}

// ─── Logout button ────────────────────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  final AppL10n l10n;

  const _LogoutButton({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () { HapticService.light(); _confirmLogout(context, ref); },
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: Text(
          l10n.logout,
          style: const TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }
}

// ─── Haptic feedback row ──────────────────────────────────────────────────────

class _HapticRow extends ConsumerWidget {
  final AppL10n l10n;
  final WidgetRef ref;

  const _HapticRow({required this.l10n, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticEnabled = ref.watch(hapticEnabledProvider);
    return ListTile(
      leading: Icon(
        Icons.vibration_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      title: Text(l10n.hapticFeedback),
      trailing: Switch(
        value: hapticEnabled,
        onChanged: (_) => ref.read(hapticEnabledProvider.notifier).toggle(),
        activeTrackColor: AppColors.primary,
      ),
    );
  }
}

// ─── About app tile ───────────────────────────────────────────────────────────

class _AboutAppTile extends StatelessWidget {
  final AppL10n l10n;
  const _AboutAppTile({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final version = snap.data?.version ?? '...';
        return ListTile(
          leading: Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          title: Text(l10n.aboutApp),
          subtitle: Text('tezyubor v$version'),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () {
            HapticService.light();
            pushRightPanel(context, const _AboutAppPage());
          },
        );
      },
    );
  }
}

// ─── About app page ───────────────────────────────────────────────────────────

class _AboutAppPage extends StatefulWidget {
  const _AboutAppPage();

  @override
  State<_AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<_AboutAppPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = Localizations.localeOf(context).languageCode;
    final prefix = switch (lang) { 'uz' => 'uz', 'en' => 'en', _ => 'ru' };

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Text(l10n.aboutApp),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: SvgPicture.asset('assets/images/logo.svg', width: 72, height: 72),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.5),
                    children: [
                      TextSpan(
                        text: 'tez',
                        style: TextStyle(color: isDark ? AppColors.foregroundDark : AppColors.foregroundLight),
                      ),
                      const TextSpan(text: 'yubor', style: TextStyle(color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'v${_version.isEmpty ? '...' : _version}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 32),
              _LinkTile(
                icon: Icons.description_outlined,
                label: l10n.termsOfService,
                url: 'https://tezyubor.uz/$prefix/terms',
              ),
              const SizedBox(height: 10),
              _LinkTile(
                icon: Icons.privacy_tip_outlined,
                label: l10n.privacyPolicy,
                url: 'https://tezyubor.uz/$prefix/privacy',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Link tile ────────────────────────────────────────────────────────────────

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          HapticService.light();
          final uri = Uri.tryParse(url);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.inAppWebView);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
