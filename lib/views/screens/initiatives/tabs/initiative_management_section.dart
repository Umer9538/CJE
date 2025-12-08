import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';

/// Management section for admin actions on initiatives
class InitiativeManagementSection extends ConsumerWidget {
  final InitiativeModel initiative;

  const InitiativeManagementSection({super.key, required this.initiative});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
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
          _buildHeader(l10n),
          const SizedBox(height: 12),
          Text(
            _getManagementDescription(initiative.status),
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          _StatusActionButtons(initiative: initiative),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(Icons.admin_panel_settings_rounded,
            size: 20, color: AppColors.navy),
        const SizedBox(width: 8),
        Text(
          l10n.translate('manage_initiative'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  String _getManagementDescription(InitiativeStatus status) {
    switch (status) {
      case InitiativeStatus.submitted:
        return 'This initiative has been submitted and is waiting for review.';
      case InitiativeStatus.review:
        return 'This initiative is under review.';
      case InitiativeStatus.debate:
        return 'This initiative is in the debate stage.';
      case InitiativeStatus.voting:
        return 'This initiative is in the voting stage.';
      default:
        return 'Manage this initiative\'s status.';
    }
  }
}

class _StatusActionButtons extends ConsumerWidget {
  final InitiativeModel initiative;

  const _StatusActionButtons({required this.initiative});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    switch (initiative.status) {
      case InitiativeStatus.submitted:
        return _buildSubmittedButtons(context, ref, l10n);
      case InitiativeStatus.review:
        return _buildReviewButtons(context, ref, l10n);
      case InitiativeStatus.debate:
        return _buildDebateButtons(context, ref, l10n);
      case InitiativeStatus.voting:
        return _buildVotingButtons(context, ref, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSubmittedButtons(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: l10n.translate('approve'),
            icon: Icons.check_circle_outline,
            color: Colors.green,
            onPressed: () => _approve(context, ref),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RejectButton(initiative: initiative),
        ),
      ],
    );
  }

  Widget _buildReviewButtons(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: l10n.translate('move_to_debate'),
            icon: Icons.forum_outlined,
            color: Colors.purple,
            onPressed: () => _moveToDebate(context, ref),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _RejectButton(initiative: initiative)),
      ],
    );
  }

  Widget _buildDebateButtons(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: l10n.translate('move_to_voting'),
            icon: Icons.how_to_vote_outlined,
            color: Colors.green,
            onPressed: () => _moveToVoting(context, ref),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _RejectButton(initiative: initiative)),
      ],
    );
  }

  Widget _buildVotingButtons(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: l10n.translate('adopt'),
            icon: Icons.check_circle,
            color: AppColors.gold,
            foregroundColor: AppColors.navy,
            onPressed: () => _adopt(context, ref),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _RejectButton(initiative: initiative)),
      ],
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(initiativeControllerProvider.notifier)
        .approveInitiative(initiative.id);
    _showResult(context, success, 'Initiative approved');
  }

  Future<void> _moveToDebate(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(initiativeControllerProvider.notifier)
        .moveToDebate(initiative.id);
    _showResult(context, success, 'Moved to debate');
  }

  Future<void> _moveToVoting(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(initiativeControllerProvider.notifier)
        .moveToVoting(initiative.id);
    _showResult(context, success, 'Moved to voting');
  }

  Future<void> _adopt(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(initiativeControllerProvider.notifier)
        .adoptInitiative(initiative.id);
    _showResult(context, success, 'Initiative adopted');
  }

  void _showResult(BuildContext context, bool success, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? message : 'Action failed'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color? foregroundColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.foregroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foregroundColor ?? Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _RejectButton extends ConsumerWidget {
  final InitiativeModel initiative;

  const _RejectButton({required this.initiative});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return OutlinedButton.icon(
      onPressed: () => _showRejectDialog(context, ref, l10n),
      icon: const Icon(Icons.cancel_outlined, size: 18),
      label: Text(l10n.translate('reject')),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.translate('reject_initiative')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.translate('reject_initiative_reason')),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.translate('enter_reason'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              final success = await ref
                  .read(initiativeControllerProvider.notifier)
                  .rejectInitiative(initiative.id, reason);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Rejected' : 'Failed'),
                    backgroundColor: success ? Colors.orange : Colors.red,
                  ),
                );
                if (success) Navigator.pop(context);
              }
            },
            child: Text(l10n.translate('reject'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
