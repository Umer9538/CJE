import 'package:flutter/material.dart';

import '../../../../core/core.dart';

/// Status badge widget for initiatives
class InitiativeStatusBadge extends StatelessWidget {
  final InitiativeStatus status;

  const InitiativeStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusLabel(status),
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

  String _getStatusLabel(InitiativeStatus status) {
    switch (status) {
      case InitiativeStatus.draft:
        return 'Draft';
      case InitiativeStatus.submitted:
        return 'Submitted';
      case InitiativeStatus.review:
        return 'In Review';
      case InitiativeStatus.debate:
        return 'In Debate';
      case InitiativeStatus.voting:
        return 'Voting';
      case InitiativeStatus.adopted:
        return 'Adopted';
      case InitiativeStatus.rejected:
        return 'Rejected';
    }
  }
}
