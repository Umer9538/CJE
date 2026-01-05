import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/admin/admin_controller.dart';
import '../../../../controllers/auth/auth_controller.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// Role selector widget for changing user roles
class UserRoleSelector extends ConsumerStatefulWidget {
  final UserModel user;

  const UserRoleSelector({super.key, required this.user});

  @override
  ConsumerState<UserRoleSelector> createState() => _UserRoleSelectorState();
}

class _UserRoleSelectorState extends ConsumerState<UserRoleSelector> {
  bool _isLoading = false;
  UserRole? _selectedRole; // Track selected role locally for immediate UI update

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.user.role;
  }

  @override
  void didUpdateWidget(UserRoleSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected role when widget.user changes (e.g., from provider refresh)
    if (oldWidget.user.role != widget.user.role) {
      _selectedRole = widget.user.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider);

    // SECURITY: Don't show role selector at all for Superadmin accounts (unless current user is Superadmin)
    if (widget.user.role == UserRole.superadmin && currentUser?.role != UserRole.superadmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.lock, color: context.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate('superadmin_role_protected'),
                style: TextStyle(fontSize: 13, color: context.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    // SECURITY: Don't show role selector for BEX accounts (unless current user is Superadmin)
    if (widget.user.role == UserRole.bex && currentUser?.role != UserRole.superadmin) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.lock, color: context.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.translate('bex_role_protected'),
                style: TextStyle(fontSize: 13, color: context.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    // Use local selected role for display, fallback to widget.user.role
    final currentRole = _selectedRole ?? widget.user.role;

    // SECURITY: Filter available roles based on current user's permissions
    final availableRoles = UserRole.values.where((role) {
      // Never allow promoting to superadmin
      if (role == UserRole.superadmin) return false;
      // Only Superadmin can assign BEX role
      if (role == UserRole.bex && currentUser?.role != UserRole.superadmin) return false;
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
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
            style: TextStyle(fontSize: 13, color: context.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableRoles
                .map((role) => _RoleChip(
                      role: role,
                      isSelected: currentRole == role,
                      isLoading: _isLoading,
                      onTap: () => _changeRole(role),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole(UserRole newRole) async {
    final currentRole = _selectedRole ?? widget.user.role;
    if (currentRole == newRole || _isLoading) return;

    final l10n = AppLocalizations.of(context);
    final roleName = _getLocalizedRoleName(newRole);

    // If changing to department role, first ask which department
    DepartmentType? selectedDepartment;
    if (newRole == UserRole.department) {
      selectedDepartment = await _showDepartmentPicker(l10n);
      if (selectedDepartment == null) return; // User cancelled
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('confirm_role_change')),
        content: Text(newRole == UserRole.department
            ? '${l10n.translate('change_role_to')} $roleName (${selectedDepartment!.displayName})?'
            : '${l10n.translate('change_role_to')} $roleName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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

    final success = await ref
        .read(adminControllerProvider.notifier)
        .changeUserRole(widget.user.id, newRole, department: selectedDepartment);

    if (success) {
      // Update local state immediately for instant UI feedback
      setState(() {
        _selectedRole = newRole;
        _isLoading = false;
      });
      // Also invalidate providers to refresh data from server
      ref.invalidate(adminUserProvider(widget.user.id));
      ref.invalidate(allUsersProvider);
    } else {
      setState(() => _isLoading = false);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('role_changed')
              : l10n.translate('error_changing_role')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<DepartmentType?> _showDepartmentPicker(AppLocalizations l10n) async {
    return showModalBottomSheet<DepartmentType>(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('select_department'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ctx.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('select_department_description'),
              style: TextStyle(
                fontSize: 14,
                color: ctx.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...DepartmentType.values.map((dept) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.badgeDepartmentBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getDepartmentIcon(dept),
                      color: AppColors.badgeDepartmentText,
                      size: 20,
                    ),
                  ),
                  title: Text(dept.displayName),
                  onTap: () => Navigator.pop(context, dept),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getDepartmentIcon(DepartmentType dept) {
    switch (dept) {
      case DepartmentType.prCommunications:
        return Icons.campaign_rounded;
      case DepartmentType.volunteering:
        return Icons.volunteer_activism_rounded;
      case DepartmentType.schoolInclusion:
        return Icons.diversity_3_rounded;
    }
  }

  String _getLocalizedRoleName(UserRole role) {
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
}

class _RoleChip extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  const _RoleChip({
    required this.role,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final roleName = _getLocalizedRoleName(l10n, role);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isSelected || isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? role.badgeBackgroundColor : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: role.badgeTextColor, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle, size: 16, color: role.badgeTextColor),
              ),
            Text(
              roleName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? role.badgeTextColor : context.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedRoleName(AppLocalizations l10n, UserRole role) {
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
}
