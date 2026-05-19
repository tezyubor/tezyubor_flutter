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

const _allPermissions = [
  'orders:view',
  'orders:create',
  'orders:confirm',
  'orders:cancel',
  'orders:delete',
  'pharmacies:view',
  'pharmacies:create',
  'pharmacies:edit',
  'pharmacies:delete',
  'clients:view',
  'analytics:view',
  'activations:view',
];

class _PermGroup {
  final String Function(AppL10n) title;
  final IconData icon;
  final List<String> permissions;

  const _PermGroup({
    required this.title,
    required this.icon,
    required this.permissions,
  });
}

final _permGroups = [
  _PermGroup(
    title: (l) => l.permSectionOrders,
    icon: Icons.receipt_long_outlined,
    permissions: [
      'orders:view',
      'orders:create',
      'orders:confirm',
      'orders:cancel',
      'orders:delete',
    ],
  ),
  _PermGroup(
    title: (l) => l.permSectionPharmacies,
    icon: Icons.store_outlined,
    permissions: [
      'pharmacies:view',
      'pharmacies:create',
      'pharmacies:edit',
      'pharmacies:delete',
    ],
  ),
  _PermGroup(
    title: (l) => l.permSectionClients,
    icon: Icons.people_outline,
    permissions: ['clients:view'],
  ),
  _PermGroup(
    title: (l) => l.permSectionAnalytics,
    icon: Icons.analytics_outlined,
    permissions: ['analytics:view'],
  ),
  _PermGroup(
    title: (l) => l.permSectionActivations,
    icon: Icons.how_to_reg_outlined,
    permissions: ['activations:view'],
  ),
];

// ─── Main screen ──────────────────────────────────────────────────────────────

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _lastTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.animation!.addListener(_onTabAnimChange);
  }

  void _onTabAnimChange() {
    final val = _tabController.animation!.value;
    final lo = val.floor().clamp(0, 1);
    final hi = val.ceil().clamp(0, 1);
    if (lo == hi && lo != _lastTabIndex) {
      _lastTabIndex = lo;
      HapticService.selection();
    }
  }

  @override
  void dispose() {
    _tabController.animation!.removeListener(_onTabAnimChange);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminRolesTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.adminRolesTab),
            Tab(text: l10n.adminUsersTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _RolesTab(),
          _UsersTab(),
        ],
      ),
    );
  }
}

// ─── Roles Tab ────────────────────────────────────────────────────────────────

class _RolesTab extends ConsumerWidget {
  const _RolesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(adminRolesProvider);

    if (state.isLoading && state.roles.isEmpty) return const CenteredLoader();
    if (state.error != null && state.roles.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(adminRolesProvider.notifier).load(),
      );
    }
    if (state.roles.isEmpty) {
      return EmptyState(
        icon: Icons.manage_accounts_outlined,
        title: l10n.adminNoRoles,
        subtitle: l10n.adminNoRolesSub,
        action: ElevatedButton.icon(
          onPressed: () {
            HapticService.light();
            pushRightPanel(context, const _RoleFormPage());
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.adminCreateRole),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          HapticService.medium();
          await ref.read(adminRolesProvider.notifier).load();
        },
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.roles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _RoleCard(role: state.roles[i]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticService.light();
          pushRightPanel(context, const _RoleFormPage());
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}

// ─── Role Card ────────────────────────────────────────────────────────────────

class _RoleCard extends ConsumerWidget {
  final AdminRole role;

  const _RoleCard({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '${role.usersCount} ${l10n.adminUsersTab.toLowerCase()} · '
                        '${role.permissions.length} ${l10n.adminPermissions.toLowerCase()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                  ),
                  onPressed: () {
                    HapticService.light();
                    pushRightPanel(context, _RoleFormPage(role: role));
                  },
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.error,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.08),
                    padding: const EdgeInsets.all(6),
                    minimumSize: const Size(32, 32),
                  ),
                  onPressed: () {
                    HapticService.light();
                    _delete(context, ref);
                  },
                ),
              ],
            ),
            if (role.permissions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: role.permissions
                    .map((p) => _PermChip(
                          permission: l10n.permissionLabel(p),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminDeleteRole),
        content: Text('"${role.name}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final success =
          await ref.read(adminRolesProvider.notifier).delete(role.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(success
                  ? context.l10n.adminRoleDeleted
                  : context.l10n.error)),
        );
      }
    }
  }
}

// ─── Permission chip ──────────────────────────────────────────────────────────

class _PermChip extends StatelessWidget {
  final String permission;

  const _PermChip({required this.permission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        permission,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Role Form Page ───────────────────────────────────────────────────────────

class _RoleFormPage extends ConsumerStatefulWidget {
  final AdminRole? role;

  const _RoleFormPage({this.role});

  @override
  ConsumerState<_RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends ConsumerState<_RoleFormPage> {
  late final TextEditingController _nameController;
  late final Set<String> _selected;
  bool _isLoading = false;

  bool get _isEdit => widget.role != null;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.role?.name ?? '');
    _selected = {...widget.role?.permissions ?? []};
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    bool success;
    if (_isEdit) {
      success = await ref.read(adminRolesProvider.notifier).update(
            widget.role!.id,
            name: _nameController.text.trim(),
            permissions: _selected.toList(),
          );
    } else {
      success = await ref.read(adminRolesProvider.notifier).create(
            _nameController.text.trim(),
            _selected.toList(),
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? l10n.adminRoleUpdated : l10n.adminRoleCreated),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error)),
        );
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
          title:
              Text(_isEdit ? l10n.adminEditRole : l10n.adminCreateRole),
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
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.adminRoleName,
                hintText: l10n.adminRoleNameHint,
                prefixIcon: const Icon(Icons.shield_outlined),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.adminPermissions,
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    HapticService.selection();
                    setState(() => _selected.addAll(_allPermissions));
                  },
                  child: Text(l10n.adminSelectAll,
                      style: const TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () {
                    HapticService.selection();
                    setState(() => _selected.clear());
                  },
                  child: Text(l10n.adminClearAll,
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._permGroups.map((group) => _PermSection(
                  group: group,
                  selected: _selected,
                  onToggle: (p, v) => setState(
                      () => v ? _selected.add(p) : _selected.remove(p)),
                  onToggleAll: (perms, selectAll) => setState(() =>
                      selectAll
                          ? _selected.addAll(perms)
                          : _selected.removeAll(perms)),
                )),
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
                    : Text(l10n.adminSaveRole),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Permission Section ───────────────────────────────────────────────────────

class _PermSection extends StatelessWidget {
  final _PermGroup group;
  final Set<String> selected;
  final void Function(String perm, bool value) onToggle;
  final void Function(List<String> perms, bool selectAll) onToggleAll;

  const _PermSection({
    required this.group,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final perms = group.permissions;
    final allSelected = perms.every(selected.contains);
    final anySelected = perms.any(selected.contains);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: anySelected
                ? AppColors.primary.withValues(alpha: 0.3)
                : theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                HapticService.selection();
                onToggleAll(perms, !allSelected);
              },
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(group.icon,
                        size: 16,
                        color: anySelected
                            ? AppColors.primary
                            : theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Text(
                      group.title(l10n),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: anySelected
                            ? AppColors.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Checkbox(
                      value: allSelected
                          ? true
                          : (anySelected ? null : false),
                      tristate: true,
                      onChanged: (_) {
                        HapticService.selection();
                        onToggleAll(perms, !allSelected);
                      },
                      activeColor: AppColors.primary,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, indent: 14, endIndent: 14),
            ...perms.map((p) {
              final isSelected = selected.contains(p);
              return InkWell(
                onTap: () {
                  HapticService.selection();
                  onToggle(p, !isSelected);
                },
                borderRadius: p == perms.last
                    ? const BorderRadius.vertical(
                        bottom: Radius.circular(12))
                    : BorderRadius.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.permissionLabel(p),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: isSelected,
                        onChanged: (v) {
                          HapticService.selection();
                          onToggle(p, v ?? false);
                        },
                        activeColor: AppColors.primary,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Users Tab ────────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(adminUsersProvider);
    final rolesState = ref.watch(adminRolesProvider);

    if (state.isLoading && state.users.isEmpty) return const CenteredLoader();
    if (state.error != null && state.users.isEmpty) {
      return AppErrorWidget(
        message: state.error!,
        onRetry: () => ref.read(adminUsersProvider.notifier).load(),
      );
    }
    if (state.users.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: l10n.adminNoUsers,
        action: ElevatedButton.icon(
          onPressed: () {
            HapticService.light();
            pushRightPanel(context, _UserFormPage(roles: rolesState.roles));
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.adminCreateUser),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          HapticService.medium();
          await ref.read(adminUsersProvider.notifier).load();
        },
        color: AppColors.primary,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _UserCard(
            user: state.users[i],
            roles: rolesState.roles,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticService.light();
          pushRightPanel(context, _UserFormPage(roles: rolesState.roles));
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}

// ─── User Card ────────────────────────────────────────────────────────────────

class _UserCard extends ConsumerWidget {
  final AdminUser user;
  final List<AdminRole> roles;

  const _UserCard({required this.user, required this.roles});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: user.isActive ? AppColors.primary : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(user.name,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: theme.textTheme.bodySmall),
            if (user.roles.isNotEmpty)
              Wrap(
                spacing: 4,
                children: user.roles
                    .map((r) => Chip(
                          label: Text(r.name,
                              style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          labelStyle:
                              const TextStyle(color: AppColors.primary),
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: user.isActive
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.isActive
                    ? l10n.adminUserActive
                    : l10n.adminUserInactive,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: user.isActive ? AppColors.success : AppColors.error,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () {
                HapticService.light();
                pushRightPanel(context, _UserFormPage(user: user, roles: roles));
              },
            ),
          ],
        ),
        isThreeLine: user.roles.isNotEmpty,
      ),
    );
  }
}

// ─── User Form Page ───────────────────────────────────────────────────────────

class _UserFormPage extends ConsumerStatefulWidget {
  final AdminUser? user;
  final List<AdminRole> roles;

  const _UserFormPage({this.user, required this.roles});

  @override
  ConsumerState<_UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends ConsumerState<_UserFormPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  late bool _isActive;
  late Set<String> _selectedRoleIds;
  bool _isLoading = false;
  bool _showPassword = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.user?.email ?? '');
    _isActive = widget.user?.isActive ?? true;
    _selectedRoleIds = {
      ...widget.user?.roles.map((r) => r.id).toList() ?? []
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (_nameCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty) {
      return;
    }
    if (!_isEdit && _passwordCtrl.text.trim().length < 6) return;

    setState(() => _isLoading = true);

    bool success;
    if (_isEdit) {
      success = await ref.read(adminUsersProvider.notifier).update(
            widget.user!.id,
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim().isEmpty
                ? null
                : _passwordCtrl.text.trim(),
            roleIds: _selectedRoleIds.toList(),
            isActive: _isActive,
          );
    } else {
      success = await ref.read(adminUsersProvider.notifier).create(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
            roleIds: _selectedRoleIds.toList(),
            isActive: _isActive,
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_isEdit
                  ? l10n.adminUserUpdated
                  : l10n.adminUserCreated)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error)),
        );
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
          title:
              Text(_isEdit ? l10n.adminEditUser : l10n.adminCreateUser),
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
                labelText: l10n.adminProfileName,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.adminUserEmail,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: _isEdit
                    ? '${l10n.passwordLbl} (${l10n.adminPasswordLeaveBlank})'
                    : l10n.passwordLbl,
                hintText: _isEdit ? '••••••' : l10n.adminPasswordMin,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(l10n.adminActiveAccount),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              activeTrackColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Text(l10n.adminUserRoles,
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (widget.roles.isEmpty)
              Text(l10n.adminNoAvailableRoles,
                  style: Theme.of(context).textTheme.bodySmall)
            else
              ...widget.roles.map((role) => CheckboxListTile(
                    title: Text(role.name),
                    subtitle: Text(
                      '${role.permissions.length} ${l10n.adminPermissions.toLowerCase()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: _selectedRoleIds.contains(role.id),
                    onChanged: (v) {
                      HapticService.selection();
                      setState(() => v == true
                          ? _selectedRoleIds.add(role.id)
                          : _selectedRoleIds.remove(role.id));
                    },
                    activeColor: AppColors.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  )),
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
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
