import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/admin/admin_controller.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// Warnings section widget for user details
class UserWarningsSection extends ConsumerWidget {
  final UserModel user;

  const UserWarningsSection({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _buildHeader(context, ref, l10n),
          if (user.warnings.isEmpty)
            _buildEmpty(l10n)
          else
            _buildWarningsList(context, ref, dateFormat, l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Row(
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
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () => _showAddWarningDialog(context, ref, l10n),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.translate('add')),
          style: TextButton.styleFrom(foregroundColor: Colors.orange),
        ),
      ],
    );
  }

  Widget _buildEmpty(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          l10n.translate('no_warnings'),
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildWarningsList(
    BuildContext context,
    WidgetRef ref,
    DateFormat dateFormat,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Divider(),
        ...user.warnings.map((w) => _WarningTile(
              user: user,
              warning: w,
              dateFormat: dateFormat,
            )),
      ],
    );
  }

  Future<void> _showAddWarningDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
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
      final success = await ref
          .read(adminControllerProvider.notifier)
          .addWarning(user.id, result.trim());

      if (context.mounted) {
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
}

class _WarningTile extends ConsumerWidget {
  final UserModel user;
  final UserWarning warning;
  final DateFormat dateFormat;

  const _WarningTile({
    required this.user,
    required this.warning,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          Expanded(child: _buildContent(l10n)),
          if (warning.isActive) _buildMenu(context, ref, l10n),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    return Column(
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
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        if (!warning.isActive && warning.resolvedByName != null)
          Text(
            '${l10n.translate('resolved_by')}: ${warning.resolvedByName}',
            style: TextStyle(fontSize: 11, color: Colors.green[600]),
          ),
      ],
    );
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 18),
      onSelected: (value) {
        if (value == 'resolve') {
          _showResolveDialog(context, ref, l10n);
        } else if (value == 'remove') {
          _removeWarning(context, ref, l10n);
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
    );
  }

  Future<void> _showResolveDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final noteController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, noteController.text),
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
      final note = result.trim().isEmpty ? null : result.trim();
      final success = await ref
          .read(adminControllerProvider.notifier)
          .resolveWarning(user.id, warning.id, note);

      if (context.mounted) {
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

  Future<void> _removeWarning(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('confirm_remove_warning')),
        content: Text(l10n.translate('remove_warning_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
      final success = await ref
          .read(adminControllerProvider.notifier)
          .removeWarning(user.id, warning.id);

      if (context.mounted) {
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
}
