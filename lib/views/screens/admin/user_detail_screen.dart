import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/admin/admin_controller.dart';
import '../../../controllers/auth/auth_controller.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import 'widgets/widgets.dart';

/// Screen to view and edit user details
class UserDetailScreen extends ConsumerWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final userAsync = ref.watch(adminUserProvider(userId));
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
          return _UserDetailContent(
            user: user,
            currentUser: currentUser,
            canChangeRoles: canChangeRoles,
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
        error: (_, __) => Scaffold(
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
}

class _UserDetailContent extends StatelessWidget {
  final UserModel user;
  final UserModel? currentUser;
  final bool canChangeRoles;

  const _UserDetailContent({
    required this.user,
    required this.currentUser,
    required this.canChangeRoles,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return CustomScrollView(
      slivers: [
        _buildAppBar(context),
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
                    _buildBadges(context),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, l10n.translate('user_information')),
                    const SizedBox(height: 12),
                    UserInfoCard(user: user),
                    const SizedBox(height: 24),
                    // SECURITY: Don't show role selector for Superadmin users (only Superadmin can modify)
                    // Also don't show for BEX users if current user is not Superadmin
                    if (canChangeRoles &&
                        user.id != currentUser?.id &&
                        user.role != UserRole.superadmin &&
                        !(user.role == UserRole.bex && currentUser?.role != UserRole.superadmin)) ...[
                      _buildSectionTitle(context, l10n.translate('change_role')),
                      const SizedBox(height: 12),
                      UserRoleSelector(user: user),
                      const SizedBox(height: 24),
                    ],
                    // SECURITY: Don't show status actions for Superadmin (only Superadmin can manage)
                    // Also don't show for BEX users if current user is not Superadmin
                    if (user.id != currentUser?.id &&
                        user.role != UserRole.superadmin &&
                        !(user.role == UserRole.bex && currentUser?.role != UserRole.superadmin)) ...[
                      _buildSectionTitle(context, l10n.translate('manage_status')),
                      const SizedBox(height: 12),
                      UserStatusActions(user: user),
                    ],
                    const SizedBox(height: 24),
                    if (canChangeRoles) ...[
                      _buildSectionTitle(context, l10n.translate('warnings')),
                      const SizedBox(height: 12),
                      UserWarningsSection(user: user),
                      const SizedBox(height: 24),
                    ],
                    if (canChangeRoles) ...[
                      _buildSectionTitle(context, l10n.translate('absences')),
                      const SizedBox(height: 12),
                      UserAbsencesSection(user: user),
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

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
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
        background: UserDetailHeader(user: user),
      ),
    );
  }

  Widget _buildBadges(BuildContext context) {
    return Row(
      children: [
        _Badge(
          label: _getLocalizedRoleName(context, user.role),
          backgroundColor: user.role.badgeBackgroundColor,
          textColor: user.role.badgeTextColor,
        ),
        const SizedBox(width: 8),
        _Badge(
          label: _getLocalizedStatusName(context, user.status),
          backgroundColor: user.status.color.withValues(alpha: 0.2),
          textColor: user.status.color,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: context.textPrimary,
      ),
    );
  }

  String _getLocalizedRoleName(BuildContext context, UserRole role) {
    final l10n = AppLocalizations.of(context);
    switch (role) {
      case UserRole.student:
        return l10n.translate('role_student');
      case UserRole.classRep:
        return l10n.translate('role_class_rep');
      case UserRole.schoolRep:
        return l10n.translate('role_school_rep');
      case UserRole.department:
        return l10n.translate('role_department');
      case UserRole.bex:
        return l10n.translate('role_bex');
      case UserRole.superadmin:
        return l10n.translate('role_superadmin');
    }
  }

  String _getLocalizedStatusName(BuildContext context, UserStatus status) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case UserStatus.active:
        return l10n.translate('active');
      case UserStatus.suspended:
        return l10n.translate('suspended');
      case UserStatus.pending:
        return l10n.translate('pending');
    }
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
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
}
