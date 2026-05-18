import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/services/env_config_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../models/auth_models.dart';
import '../providers/auth_provider.dart';
import '../../pharmacy/providers/analytics_provider.dart';
import '../../pharmacy/providers/clients_provider.dart';
import '../../pharmacy/providers/orders_provider.dart';
import '../../pharmacy/providers/pharmacy_provider.dart';

class _LanguageSwitcher extends ConsumerWidget {
  const _LanguageSwitcher();

  static const _langs = [
    ('uz', "O'zbek"),
    ('ru', 'Русский'),
    ('en', 'English'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.language_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 20,
      ),
      tooltip: 'Language',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (code) =>
          ref.read(localeProvider.notifier).setLocale(Locale(code)),
      itemBuilder: (_) => _langs
          .map(
            (lang) => PopupMenuItem<String>(
              value: lang.$1,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lang.$2,
                      style: TextStyle(
                        fontWeight: current == lang.$1
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: current == lang.$1 ? AppColors.primary : null,
                      ),
                    ),
                  ),
                  if (current == lang.$1)
                    const Icon(Icons.check, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  int _logoTapCount = 0;
  bool _localeInitialized = false;
  Timer? _serverHoldTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_localeInitialized) {
      _localeInitialized = true;
      final saved = ref.read(localeProvider).languageCode;
      if (saved == 'ru') {
        final deviceLang =
            WidgetsBinding.instance.platformDispatcher.locale.languageCode;
        if (deviceLang == 'uz' || deviceLang == 'en') {
          ref.read(localeProvider.notifier).setLocale(Locale(deviceLang));
        }
      }
    }
  }

  @override
  void dispose() {
    _serverHoldTimer?.cancel();
    _loginController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onServerHoldStart(LongPressStartDetails _) {
    _serverHoldTimer = Timer(const Duration(seconds: 10), () async {
      await ref.read(serverConfigProvider.notifier).toggle();
      if (!mounted) return;
      final label = ref.read(serverConfigProvider).label;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(label), duration: const Duration(seconds: 2)),
      );
    });
  }

  void _onServerHoldEnd(LongPressEndDetails _) => _serverHoldTimer?.cancel();
  void _onServerHoldCancel() => _serverHoldTimer?.cancel();

  void _onLogoTap() {
    _logoTapCount++;
    if (_logoTapCount >= AppConstants.logoTapCountToSwitchEnv) {
      _logoTapCount = 0;
      ref.read(environmentProvider.notifier).toggle();
      final env = ref.read(environmentProvider);
      final envName = env == AppEnvironment.admin ? 'Admin' : 'App';
      _loginController.clear();
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(envName),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final env = ref.read(environmentProvider);
    final notifier = ref.read(authStateProvider.notifier);
    bool success;

    if (env == AppEnvironment.admin) {
      success = await notifier.loginAdmin(
        email: _loginController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await notifier.loginPharmacy(
        login: _loginController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (success && mounted) {
      ref.invalidate(ordersProvider);
      ref.invalidate(pharmacyProfileProvider);
      ref.invalidate(clientsProvider);
      ref.invalidate(analyticsProvider);

      final user = ref.read(authStateProvider).user;
      if (user?.role == UserRole.admin) {
        context.go('/admin/orders');
      } else if (user?.requiresLocation == true) {
        context.go('/pharmacy/location-setup');
      } else {
        context.go('/pharmacy/orders');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final env = ref.watch(environmentProvider);
    final authState = ref.watch(authStateProvider);
    final isAdmin = env == AppEnvironment.admin;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top bar: theme toggle + language
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () =>
                          ref.read(themeModeProvider.notifier).toggle(),
                    ),
                    const _LanguageSwitcher(),
                  ],
                ),

                const SizedBox(height: 32),

                // Logo
                GestureDetector(
                  onTap: _onLogoTap,
                  onLongPressStart: _onServerHoldStart,
                  onLongPressEnd: _onServerHoldEnd,
                  onLongPressCancel: _onServerHoldCancel,
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/images/logo.svg',
                            width: 52,
                            height: 52,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                          children: [
                            TextSpan(
                              text: 'tez',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.foregroundDark
                                    : AppColors.foregroundLight,
                              ),
                            ),
                            const TextSpan(
                              text: 'yubor',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.quickDelivery,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Glass form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        isAdmin ? l10n.adminLoginTitle : l10n.loginTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.loginHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),

                      const SizedBox(height: 20),

                      // Error
                      if (authState.error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.error!,
                                  style: const TextStyle(
                                      color: AppColors.error, fontSize: 13),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => ref
                                    .read(authStateProvider.notifier)
                                    .clearError(),
                                child: const Icon(Icons.close,
                                    color: AppColors.error, size: 16),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Login field
                      CustomTextField(
                        label: isAdmin ? 'Email' : l10n.loginFieldLbl,
                        controller: _loginController,
                        keyboardType: isAdmin
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        textInputAction: TextInputAction.next,
                        prefixIcon: Icon(
                            isAdmin ? Icons.email_outlined : Icons.person_outline),
                        onSubmitted: (_) =>
                            FocusScope.of(context).requestFocus(_passwordFocus),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l10n.enterLoginHint;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Password field
                      CustomTextField(
                        label: l10n.passwordLbl,
                        controller: _passwordController,
                        isPassword: true,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(Icons.lock_outline),
                        onSubmitted: (_) => _submit(),
                        validator: (v) {
                          if (v == null || v.isEmpty) return l10n.enterPasswordHint;
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

                      // Submit button
                      CustomButton(
                        label: l10n.loginBtn,
                        isLoading: authState.isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
