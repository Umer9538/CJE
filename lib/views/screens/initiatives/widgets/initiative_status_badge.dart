import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Status badge widget for initiatives
class InitiativeStatusBadge extends StatelessWidget {
  final InitiativeStatus status;

  const InitiativeStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusLabel(status, l10n),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(InitiativeStatus status) {
    switch (status) {
      case InitiativeStatus.draft:
        return Colors.grey;
      case InitiativeStatus.submitted:
        return Colors.blue;
      case InitiativeStatus.review:
        return Colors.orange;
      case InitiativeStatus.debate:
        return Colors.purple;
      case InitiativeStatus.voting:
        return Colors.green;
      case InitiativeStatus.adopted:
        return AppColors.gold;
      case InitiativeStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusLabel(InitiativeStatus status, AppLocalizations l10n) {
    switch (status) {
      case InitiativeStatus.draft:
        return l10n.translate('draft');
      case InitiativeStatus.submitted:
        return l10n.translate('submitted');
      case InitiativeStatus.review:
        return l10n.translate('review');
      case InitiativeStatus.debate:
        return l10n.translate('in_debate');
      case InitiativeStatus.voting:
        return l10n.translate('voting');
      case InitiativeStatus.adopted:
        return l10n.translate('adopted');
      case InitiativeStatus.rejected:
        return l10n.translate('rejected');
    }
  }
}
