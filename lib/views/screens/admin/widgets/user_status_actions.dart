import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/admin/admin_controller.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// Status action buttons for user management
class UserStatusActions extends ConsumerStatefulWidget {
  final UserModel user;

  const UserStatusActions({super.key, required this.user});

  @override
  ConsumerState<UserStatusActions> createState() => _UserStatusActionsState();
}

class _UserStatusActionsState extends ConsumerState<UserStatusActions> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
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
          if (widget.user.status == UserStatus.pending)
            _ActionButton(
              icon: Icons.check_circle_outline,
              label: l10n.translate('approve_user'),
              color: Colors.green,
              isLoading: _isLoading,
              onTap: _approveUser,
            ),
          if (widget.user.status == UserStatus.active)
            _ActionButton(
              icon: Icons.block,
              label: l10n.translate('suspend_user'),
              color: Colors.orange,
              isLoading: _isLoading,
              onTap: _suspendUser,
            ),
          if (widget.user.status == UserStatus.suspended)
            _ActionButton(
              icon: Icons.restore,
              label: l10n.translate('reactivate_user'),
              color: Colors.green,
              isLoading: _isLoading,
              onTap: _reactivateUser,
            ),
        ],
      ),
    );
  }

  Future<void> _approveUser() async {
    final l10n = AppLocalizations.of(context);

    setState(() => _isLoading = true);

    final success = await ref
        .read(adminControllerProvider.notifier)
        .approveUser(widget.user.id);

    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(adminUserProvider(widget.user.id));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('user_approved')
              : l10n.translate('error_approving_user')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _suspendUser() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('confirm_suspend')),
        content: Text(l10n.translate('suspend_user_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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

    final success = await ref
        .read(adminControllerProvider.notifier)
        .suspendUser(widget.user.id);

    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(adminUserProvider(widget.user.id));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('user_suspended')
              : l10n.translate('error_suspending_user')),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<void> _reactivateUser() async {
    final l10n = AppLocalizations.of(context);

    setState(() => _isLoading = true);

    final success = await ref
        .read(adminControllerProvider.notifier)
        .reactivateUser(widget.user.id);

    setState(() => _isLoading = false);

    if (success) {
      ref.invalidate(adminUserProvider(widget.user.id));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? l10n.translate('user_reactivated')
              : l10n.translate('error_reactivating_user')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
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
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
