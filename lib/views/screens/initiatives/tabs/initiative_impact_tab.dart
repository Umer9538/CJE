import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../../../models/models.dart';
import '../widgets/widgets.dart';

/// Impact tab for initiative detail screen
class InitiativeImpactTab extends StatelessWidget {
  final InitiativeModel initiative;

  const InitiativeImpactTab({super.key, required this.initiative});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasImpact =
        initiative.impact != null && initiative.impact!.isNotEmpty;

    if (!hasImpact) {
      return InitiativeEmptyState(
        icon: Icons.trending_up_rounded,
        title: l10n.translate('no_impact'),
        subtitle: l10n.translate('no_impact_description'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildImpactHeader(l10n),
        const SizedBox(height: 16),
        _buildImpactContent(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildImpactHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.green.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              size: 32,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.translate('expected_impact'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactContent() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Text(
        initiative.impact!,
        style: TextStyle(
          fontSize: 15,
          color: Colors.grey[700],
          height: 1.7,
        ),
      ),
    );
  }
}
