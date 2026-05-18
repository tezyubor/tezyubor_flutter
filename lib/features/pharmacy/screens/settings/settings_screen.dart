import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/utils/right_panel.dart';
import '../../../../shared/utils/uz_phone_formatter.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';
import '../location/location_picker_screen.dart';
import '../../providers/subscription_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profileState = ref.watch(pharmacyProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final profile = profileState.profile;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: profileState.isLoading && profile == null
          ? const CenteredLoader()
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(pharmacyProfileProvider.notifier).load(),
              color: AppColors.primary,
              child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // Profile card
                if (profile != null) _ProfileCard(profile: profile),
                const SizedBox(height: 12),

                // ── Subscription card ────────────────────────────────────
                _SubscriptionCard(
                  profile: profile,
                  onTap: () => pushRightPanel(
                    context,
                    _SubscriptionPage(profile: profile),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Account ─────────────────────────────────────────────
                _SettingsSection(
                  title: l10n.account,
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline,
                      title: l10n.profileStore,
                      onTap: () =>
                          _showEditProfile(context, ref, profile, l10n),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline,
                      title: l10n.changePassword,
                      onTap: () => _showChangePassword(context, ref, l10n),
                    ),
                    _SettingsTile(
                      icon: Icons.location_on_outlined,
                      title: l10n.location,
                      subtitle: profile?.address,
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const LocationPickerScreen(),
                          transitionsBuilder: (_, animation, __, child) =>
                              SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
                                child: child,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Appearance ──────────────────────────────────────────
                _SettingsSection(
                  title: l10n.appearance,
                  children: [
                    // Theme
                    _SettingsTile(
                      icon: Icons.palette_outlined,
                      title: l10n.theme,
                      subtitle: _themeLabel(themeMode, l10n),
                      onTap: () => _showThemePicker(context, ref, l10n),
                    ),
                    // Language
                    _SettingsTile(
                      icon: Icons.language_outlined,
                      title: l10n.language,
                      subtitle: _localeName(locale.languageCode),
                      onTap: () => _showLanguagePicker(context, ref, l10n),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── App ─────────────────────────────────────────────────
                _SettingsSection(
                  title: l10n.application,
                  children: [
                    _AboutAppTile(l10n: l10n),
                  ],
                ),
                const SizedBox(height: 24),

                // Logout
                OutlinedButton.icon(
                  onPressed: () => _logout(context, ref, l10n),
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: Text(
                    l10n.logout,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _themeLabel(ThemeMode mode, AppL10n l10n) => switch (mode) {
        ThemeMode.dark => l10n.themeDark,
        ThemeMode.light => l10n.themeLight,
        _ => l10n.themeSystem,
      };

  String _localeName(String code) => switch (code) {
        'uz' => "O'zbekcha",
        'en' => 'English',
        _ => 'Русский',
      };

  void _showThemePicker(BuildContext context, WidgetRef ref, AppL10n l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ThemePickerSheet(l10n: l10n),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, AppL10n l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LanguagePickerSheet(l10n: l10n),
    );
  }

  void _showEditProfile(
      BuildContext context, WidgetRef ref, dynamic profile, AppL10n l10n) {
    pushRightPanel(context, _EditProfilePage(profile: profile, ref: ref, l10n: l10n));
  }

  void _showChangePassword(BuildContext context, WidgetRef ref, AppL10n l10n) {
    pushRightPanel(context, _ChangePasswordPage(ref: ref, l10n: l10n));
  }

  Future<void> _logout(
      BuildContext context, WidgetRef ref, AppL10n l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }
}

// ─── Theme picker sheet ───────────────────────────────────────────────────────

class _ThemePickerSheet extends ConsumerWidget {
  final AppL10n l10n;
  const _ThemePickerSheet({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              Text(l10n.theme,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _ThemeOption(
            icon: Icons.light_mode_outlined,
            label: l10n.themeLight,
            selected: current == ThemeMode.light,
            onTap: () {
              ref.read(themeModeProvider.notifier).setMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          _ThemeOption(
            icon: Icons.dark_mode_outlined,
            label: l10n.themeDark,
            selected: current == ThemeMode.dark,
            onTap: () {
              ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
          _ThemeOption(
            icon: Icons.brightness_auto_outlined,
            label: l10n.themeSystem,
            selected: current == ThemeMode.system,
            onTap: () {
              ref.read(themeModeProvider.notifier).setMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Language picker sheet ────────────────────────────────────────────────────

class _LanguagePickerSheet extends ConsumerWidget {
  final AppL10n l10n;
  const _LanguagePickerSheet({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
              Text(l10n.language,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RadioGroup<String>(
            groupValue: current.languageCode,
            onChanged: (v) {
              if (v != null) {
                ref.read(localeProvider.notifier).setLocale(Locale(v));
                Navigator.pop(context);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (code, name) in [
                  ('ru', 'Русский'),
                  ('uz', "O'zbekcha"),
                  ('en', 'English'),
                ])
                  ListTile(
                    title: Text(name),
                    leading: Radio<String>(
                      value: code,
                      activeColor: AppColors.primary,
                    ),
                    onTap: () {
                      ref
                          .read(localeProvider.notifier)
                          .setLocale(Locale(code));
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Theme option tile ────────────────────────────────────────────────────────

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon,
            color: selected ? AppColors.primary : null),
        title: Text(label,
            style: TextStyle(
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal)),
        trailing: selected
            ? const Icon(Icons.check, color: AppColors.primary)
            : null,
        onTap: onTap,
      );
}

// ─── Edit profile page ────────────────────────────────────────────────────────

class _EditProfilePage extends StatefulWidget {
  final dynamic profile;
  final WidgetRef ref;
  final AppL10n l10n;

  const _EditProfilePage(
      {required this.profile, required this.ref, required this.l10n});

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.profile?.name as String? ?? '');
    _phoneCtrl = TextEditingController(
        text: UzPhoneFormatter.toDisplay(widget.profile?.phone as String?));
    _emailCtrl = TextEditingController(
        text: widget.profile?.email as String? ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = widget.l10n;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.nameCantBeEmpty);
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final ok = await widget.ref
        .read(pharmacyProfileProvider.notifier)
        .update(
          name: name,
          phone: UzPhoneFormatter.isComplete(_phoneCtrl.text)
              ? UzPhoneFormatter.toE164(_phoneCtrl.text)
              : _phoneCtrl.text.trim().isEmpty
                  ? null
                  : _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _error = l10n.saveError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Text(l10n.profileStore),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          children: [
            if (_error != null) _ErrorBanner(message: _error!),
            CustomTextField(
              label: l10n.storeNameLbl,
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: l10n.phoneLbl,
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: [UzPhoneFormatter()],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: l10n.emailLbl,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            CustomButton(label: l10n.save, isLoading: _isLoading, onPressed: _save),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              label: Text(
                l10n.deleteProfile,
                style: const TextStyle(color: AppColors.error),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = widget.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteProfile),
        content: Text(l10n.deleteProfileConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deleteProfile),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await ApiClient.instance.delete('/pharmacy/me');
      if (!mounted) return;
      await widget.ref.read(authStateProvider.notifier).logout();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.deleteProfileError)),
      );
    }
  }
}

// ─── Change password page ─────────────────────────────────────────────────────

class _ChangePasswordPage extends StatefulWidget {
  final WidgetRef ref;
  final AppL10n l10n;

  const _ChangePasswordPage({required this.ref, required this.l10n});

  @override
  State<_ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<_ChangePasswordPage> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = widget.l10n;
    final old = _oldCtrl.text;
    final newP = _newCtrl.text;
    final conf = _confirmCtrl.text;

    if (old.isEmpty || newP.isEmpty || conf.isEmpty) {
      setState(() => _error = l10n.fillAllFields);
      return;
    }
    if (newP != conf) {
      setState(() => _error = l10n.passwordsNoMatch);
      return;
    }
    if (newP.length < 6) {
      setState(() => _error = l10n.passwordTooShort);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });
    try {
      await ApiClient.instance.put('/pharmacy/me/password', data: {
        'oldPassword': old,
        'newPassword': newP,
      });
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _success = l10n.passwordChanged;
      });
      _oldCtrl.clear();
      _newCtrl.clear();
      _confirmCtrl.clear();
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      String msg = l10n.changPasswordError;
      try {
        final data = (e as dynamic).response?.data;
        if (data is Map) msg = data['message'] as String? ?? msg;
      } catch (_) {}
      setState(() {
        _isLoading = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Text(l10n.changePasswordTitle),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          children: [
            if (_error != null) _ErrorBanner(message: _error!),
            if (_success != null) _SuccessBanner(message: _success!),
            CustomTextField(
              label: l10n.oldPasswordLbl,
              controller: _oldCtrl,
              isPassword: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: l10n.newPasswordLbl,
              controller: _newCtrl,
              isPassword: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: l10n.confirmPasswordLbl,
              controller: _confirmCtrl,
              isPassword: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: l10n.changePassword,
              isLoading: _isLoading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final dynamic profile;
  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile.name as String;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 56,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, Color(0xFFFF9A62)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (profile.login != null)
                          Text(
                            profile.login as String,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (profile.phone != null)
                          Text(
                            profile.phone as String,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
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

// ─── Settings section & tile ──────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection(
      {required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Card(
          child: Column(
            children: children
                .asMap()
                .entries
                .map((e) => Column(
                      children: [
                        e.value,
                        if (e.key < children.length - 1)
                          Divider(
                            height: 1,
                            indent: 52,
                            color: Theme.of(context)
                                .colorScheme
                                .outline
                                .withValues(alpha: 0.5),
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title,
          style: Theme.of(context).textTheme.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis)
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(message,
            style: const TextStyle(color: AppColors.error)),
      );
}

class _SuccessBanner extends StatelessWidget {
  final String message;
  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(message,
            style: const TextStyle(color: AppColors.success)),
      );
}

// ─── Subscription card ────────────────────────────────────────────────────────

class _SubscriptionCard extends StatelessWidget {
  final dynamic profile;
  final VoidCallback onTap;

  const _SubscriptionCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final days = profile?.daysUntilExpiry as int?;
    final expiry = profile?.subscriptionExpiry as String?;
    final isExpired = days != null && days < 0;
    final isSoon = days != null && days >= 0 && days <= 14;

    final statusColor = isExpired
        ? AppColors.error
        : isSoon
            ? AppColors.warning
            : AppColors.success;

    final statusLabel = isExpired
        ? l10n.subscriptionExpired
        : isSoon
            ? l10n.subscriptionExpiringSoon
            : l10n.subscriptionActive;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isExpired
                ? [
                    AppColors.error.withValues(alpha: isDark ? 0.25 : 0.12),
                    AppColors.error.withValues(alpha: isDark ? 0.10 : 0.05),
                  ]
                : [
                    AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                    AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.04),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpired
                ? AppColors.error.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isExpired
                    ? Icons.credit_card_off_outlined
                    : Icons.verified_outlined,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.subscription,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (days != null && !isExpired) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$days ${l10n.daysLeft}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (expiry != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${l10n.subscriptionValidUntil}: ${l10n.fmtDate(expiry)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Subscription page ────────────────────────────────────────────────────────

class _SubscriptionPage extends ConsumerStatefulWidget {
  final dynamic profile;
  const _SubscriptionPage({required this.profile});

  @override
  ConsumerState<_SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<_SubscriptionPage> {
  bool _isLoading = false;

  Future<void> _pay() async {
    setState(() => _isLoading = true);
    final url =
        await ref.read(subscriptionProvider.notifier).createPayment();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } else {
      final err = ref.read(subscriptionProvider).payError;
      if (err != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = widget.profile;

    final days = profile?.daysUntilExpiry as int?;
    final expiry = profile?.subscriptionExpiry as String?;
    final isExpired = days != null && days < 0;
    final isSoon = days != null && days >= 0 && days <= 14;

    final statusColor = isExpired
        ? AppColors.error
        : isSoon
            ? AppColors.warning
            : AppColors.success;

    final statusLabel = isExpired
        ? l10n.subscriptionExpired
        : isSoon
            ? l10n.subscriptionExpiringSoon
            : l10n.subscriptionActive;

    return SwipeToDismiss(
      child: Scaffold(
        appBar: AppBar(
          leading: const PanelBackButton(),
          title: Text(l10n.subscription),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            children: [
              // ── Header icon ──────────────────────────────────────────
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.25)),
                  ),
                  child: Icon(
                    isExpired
                        ? Icons.credit_card_off_outlined
                        : Icons.verified_outlined,
                    color: statusColor,
                    size: 48,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Info block ───────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  children: [
                    if (expiry != null)
                      _SubInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.subscriptionValidUntil,
                        value: l10n.fmtDate(expiry),
                        valueColor: isExpired ? AppColors.error : null,
                      ),
                    if (days != null) ...[
                      if (expiry != null)
                        Divider(
                          height: 1,
                          indent: 52,
                          color: theme.colorScheme.outline
                              .withValues(alpha: 0.4),
                        ),
                      _SubInfoRow(
                        icon: Icons.hourglass_bottom_outlined,
                        label: isExpired
                            ? l10n.subscriptionExpired
                            : l10n.daysLeft,
                        value: isExpired
                            ? '${days.abs()} ${l10n.daysLeft}'
                            : '$days ${l10n.daysLeft}',
                        valueColor: statusColor,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Renew button ─────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pay,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.refresh_outlined, size: 20),
                  label: Text(l10n.paySubscription),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Payments section (coming soon) ───────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  l10n.payments.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SubInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── About app tile (shows dynamic version) ──────────────────────────────────

class _AboutAppTile extends ConsumerWidget {
  final dynamic l10n;
  const _AboutAppTile({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final version = snap.data?.version ?? '...';
        return _SettingsTile(
          icon: Icons.info_outline,
          title: l10n.aboutApp,
          subtitle: 'tezyubor v$version',
          onTap: () => pushRightPanel(context, const _AboutAppPage()),
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
