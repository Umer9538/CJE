import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/admin/admin_controller.dart';
import '../../../controllers/auth/auth_controller.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// Screen to view and edit user details
/// Allows changing role and status for authorized admins
class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(adminUserProvider(widget.userId));
    final currentUser = ref.watch(currentUserProvider);
    final canChangeRoles = ref.watch(canChangeRolesProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Scaffold(
              appBar: AppBar(title: Text(l10n.translate('user_not_found'))),
              body: Center(child: Text(l10n.translate('user_not_found'))),
            );
          }
          return _buildContent(context, user, currentUser, canChangeRoles);
        },
        loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(l10n.translate('error_loading')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserModel user,
    UserModel? currentUser,
    bool canChangeRoles,
  ) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return CustomScrollView(
      slivers: [
        // App Bar with user header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.navy,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.navy,
                    AppColors.navy.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: user.role.badgeBackgroundColor,
                      backgroundImage:
                          user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: user.role.badgeTextColor,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              decoration: BoxDecoration(
                color: context.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and Role badges
                    Row(
                      children: [
                        _buildBadge(
                          label: user.role.displayName,
                          backgroundColor: user.role.badgeBackgroundColor,
                          textColor: user.role.badgeTextColor,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          label: user.status.displayName,
                          backgroundColor: user.status.color.withValues(alpha: 0.2),
                          textColor: user.status.color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // User Info Section
                    _buildSectionTitle(l10n.translate('user_information')),
                    const SizedBox(height: 12),

                    _buildInfoCard([
                      _buildInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email,
                      ),
                      if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                        _buildInfoRow(
                          icon: Icons.phone_outlined,
                          label: l10n.translate('phone'),
                          value: user.phoneNumber!,
                        ),
                      if (user.schoolName != null)
                        _buildInfoRow(
                          icon: Icons.school_outlined,
                          label: l10n.translate('school'),
                          value: user.schoolName!,
                        ),
                      if (user.city != null)
                        _buildInfoRow(
                          icon: Icons.location_city_outlined,
                          label: l10n.translate('city'),
                          value: user.city!,
                        ),
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: l10n.translate('member_since'),
                        value: dateFormat.format(user.createdAt),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Role Management Section (only for bex/superadmin)
                    if (canChangeRoles && user.id != currentUser?.id) ...[
                      _buildSectionTitle(l10n.translate('change_role')),
                      const SizedBox(height: 12),
                      _buildRoleSelector(context, user),
                      const SizedBox(height: 24),
                    ],

                    // Status Management Section
                    if (user.id != currentUser?.id) ...[
                      _buildSectionTitle(l10n.translate('manage_status')),
                      const SizedBox(height: 12),
                      _buildStatusActions(context, user),
                    ],

                    const SizedBox(height: 24),

                    // Warnings Section
                    if (canChangeRoles) ...[
                      _buildSectionTitle(l10n.translate('warnings')),
                      const SizedBox(height: 12),
                      _buildWarningsSection(context, user),
                      const SizedBox(height: 24),
                    ],

                    // Absences Section
                    if (canChangeRoles) ...[
                      _buildSectionTitle(l10n.translate('absences')),
                      const SizedBox(height: 12),
                      _buildAbsencesSection(context, user),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.navy,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.navy, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('select_new_role'),
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserRole.values.map((role) {
              final isCurrentRole = user.role == role;
              return GestureDetector(
                onTap: isCurrentRole || _isLoading
                    ? null
                    : () => _changeRole(context, user, role),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentRole
                        ? role.badgeBackgroundColor
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: isCurrentRole
                        ? Border.all(color: role.badgeTextColor, width: 2)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCurrentRole)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check_circle,
                            size: 16,
                            color: role.badgeTextColor,
                          ),
                        ),
                      Text(
                        role.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrentRole ? FontWeight.bold : FontWeight.w500,
                          color: isCurrentRole ? role.badgeTextColor : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (user.status == UserStatus.pending)
            _buildActionButton(
              icon: Icons.check_circle_outline,
              label: l10n.translate('approve_user'),
              color: Colors.green,
              onTap: () => _approveUser(context, user),
            ),
          if (user.status == UserStatus.active)
            _buildActionButton(
              icon: Icons.block,
              label: l10n.translate('suspend_user'),
              color: Colors.orange,
              onTap: () => _suspendUser(context, user),
            ),
          if (user.status == UserStatus.suspended)
            _buildActionButton(
              icon: Icons.restore,
              label: l10n.translate('reactivate_user'),
              color: Colors.green,
              onTap: () => _reactivateUser(context, user),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            const Spacer(),
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRole(BuildContext context, UserModel user, UserRole newRole) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_role_change')),
        content: Text(
          '${l10n.translate('change_role_to')} ${newRole.displayName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
            child: Text(l10n.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final controller = ref.read(adminControllerProvider.notifier);
    final success = await controller.changeUserRole(user.id, newRole);

    setState(() => _isLoading = false);

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('role_changed')
              : l10n.translate('error_changing_role')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _approveUser(BuildContext context, UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    final controller = ref.read(adminControllerProvider.notifier);
    final success = await controller.approveUser(user.id);

    setState(() => _isLoading = false);

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('user_approved')
              : l10n.translate('error_approving_user')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _suspendUser(BuildContext context, UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_suspend')),
        content: Text(l10n.translate('suspend_user_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('suspend')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    final controller = ref.read(adminControllerProvider.notifier);
    final success = await controller.suspendUser(user.id);

    setState(() => _isLoading = false);

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('user_suspended')
              : l10n.translate('error_suspending_user')),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<void> _reactivateUser(BuildContext context, UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    final controller = ref.read(adminControllerProvider.notifier);
    final success = await controller.reactivateUser(user.id);

    setState(() => _isLoading = false);

    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('user_reactivated')
              : l10n.translate('error_reactivating_user')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // ==================== WARNINGS UI ====================

  Widget _buildWarningsSection(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${user.warningCount} ${l10n.translate('total')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showAddWarningDialog(context, user),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.translate('add')),
                style: TextButton.styleFrom(foregroundColor: Colors.orange),
              ),
            ],
          ),

          if (user.warnings.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.translate('no_warnings'),
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(),
            ...user.warnings.map((warning) => _buildWarningTile(
              context,
              user,
              warning,
              dateFormat,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningTile(
    BuildContext context,
    UserModel user,
    UserWarning warning,
    DateFormat dateFormat,
  ) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: warning.isActive ? Colors.orange : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warning.reason,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: warning.isActive ? AppColors.navy : Colors.grey,
                    decoration: warning.isActive ? null : TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.translate('issued_by')}: ${warning.issuedByName} • ${dateFormat.format(warning.issuedAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (!warning.isActive && warning.resolvedByName != null)
                  Text(
                    '${l10n.translate('resolved_by')}: ${warning.resolvedByName}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green[600],
                    ),
                  ),
              ],
            ),
          ),
          if (warning.isActive)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (value) {
                if (value == 'resolve') {
                  _showResolveWarningDialog(context, user, warning);
                } else if (value == 'remove') {
                  _removeWarning(context, user, warning);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'resolve',
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(l10n.translate('resolve')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.translate('remove')),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showAddWarningDialog(BuildContext context, UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('add_warning')),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: l10n.translate('reason'),
            hintText: l10n.translate('warning_reason_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('add_warning')),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final success = await ref.read(adminControllerProvider.notifier)
          .addWarning(user.id, result.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('warning_added')
                : l10n.translate('error_adding_warning')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showResolveWarningDialog(BuildContext context, UserModel user, UserWarning warning) async {
    final l10n = AppLocalizations.of(context);
    final noteController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('resolve_warning')),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: l10n.translate('resolution_note'),
            hintText: l10n.translate('resolution_note_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, noteController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('resolve')),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await ref.read(adminControllerProvider.notifier)
          .resolveWarning(user.id, warning.id, result.trim().isEmpty ? null : result.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('warning_resolved')
                : l10n.translate('error_resolving_warning')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeWarning(BuildContext context, UserModel user, UserWarning warning) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_remove_warning')),
        content: Text(l10n.translate('remove_warning_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('remove')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(adminControllerProvider.notifier)
          .removeWarning(user.id, warning.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('warning_removed')
                : l10n.translate('error_removing_warning')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  // ==================== ABSENCES UI ====================

  Widget _buildAbsencesSection(BuildContext context, UserModel user) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.event_busy_rounded, color: Colors.red, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${user.absenceCount} ${l10n.translate('total')}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _showAddAbsenceDialog(context, user),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.translate('add')),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),

          if (user.absences.isEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: Text(
                l10n.translate('no_absences'),
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(),
            ...user.absences.map((absence) => _buildAbsenceTile(
              context,
              user,
              absence,
              dateFormat,
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAbsenceTile(
    BuildContext context,
    UserModel user,
    UserAbsence absence,
    DateFormat dateFormat,
  ) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: absence.isExcused ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        absence.meetingTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (absence.isExcused)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.translate('excused'),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.translate('meeting_date')}: ${dateFormat.format(absence.meetingDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                if (absence.reason != null && absence.reason!.isNotEmpty)
                  Text(
                    '${l10n.translate('reason')}: ${absence.reason}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (!absence.isExcused)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (value) {
                if (value == 'excuse') {
                  _showExcuseAbsenceDialog(context, user, absence);
                } else if (value == 'remove') {
                  _removeAbsence(context, user, absence);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'excuse',
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(l10n.translate('excuse')),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(l10n.translate('remove')),
                    ],
                  ),
                ),
              ],
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              onPressed: () => _removeAbsence(context, user, absence),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddAbsenceDialog(BuildContext context, UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final meetingTitleController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.translate('add_absence')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: meetingTitleController,
                decoration: InputDecoration(
                  labelText: l10n.translate('meeting_title'),
                  hintText: l10n.translate('meeting_title_hint'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text(DateFormat('MMMM d, yyyy').format(selectedDate)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, {
                'title': meetingTitleController.text,
                'date': selectedDate,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.translate('add_absence')),
            ),
          ],
        ),
      ),
    );

    if (result != null && (result['title'] as String).trim().isNotEmpty) {
      final success = await ref.read(adminControllerProvider.notifier).addAbsence(
        user.id,
        'manual_${DateTime.now().millisecondsSinceEpoch}',
        (result['title'] as String).trim(),
        result['date'] as DateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('absence_added')
                : l10n.translate('error_adding_absence')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showExcuseAbsenceDialog(BuildContext context, UserModel user, UserAbsence absence) async {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('excuse_absence')),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            labelText: l10n.translate('reason'),
            hintText: l10n.translate('excuse_reason_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('excuse')),
          ),
        ],
      ),
    );

    if (result != null) {
      final success = await ref.read(adminControllerProvider.notifier)
          .excuseAbsence(user.id, absence.id, result.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('absence_excused')
                : l10n.translate('error_excusing_absence')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeAbsence(BuildContext context, UserModel user, UserAbsence absence) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('confirm_remove_absence')),
        content: Text(l10n.translate('remove_absence_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.translate('remove')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(adminControllerProvider.notifier)
          .removeAbsence(user.id, absence.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? l10n.translate('absence_removed')
                : l10n.translate('error_removing_absence')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
