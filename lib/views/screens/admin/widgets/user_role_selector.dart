import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/admin/admin_controller.dart';
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
    // Use local selected role for display, fallback to widget.user.role
    final currentRole = _selectedRole ?? widget.user.role;

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
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: UserRole.values
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('confirm_role_change')),
        content: Text('${l10n.translate('change_role_to')} $roleName?'),
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
        .changeUserRole(widget.user.id, newRole);

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

    return GestureDetector(
      onTap: isSelected || isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? role.badgeBackgroundColor : Colors.grey[100],
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
                color: isSelected ? role.badgeTextColor : Colors.grey[700],
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
