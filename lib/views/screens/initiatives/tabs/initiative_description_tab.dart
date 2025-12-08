import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';
import '../widgets/widgets.dart';
import 'initiative_management_section.dart';
import 'initiative_voting_section.dart';

/// Description tab for initiative detail screen
class InitiativeDescriptionTab extends ConsumerWidget {
  final InitiativeModel initiative;

  const InitiativeDescriptionTab({super.key, required this.initiative});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final canApprove = ref.watch(canApproveInitiativesProvider(initiative));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Management section for admins
        if (canApprove && !initiative.status.isFinal)
          InitiativeManagementSection(initiative: initiative),

        // Description
        InitiativeContentCard(
          title: l10n.translate('initiative_description'),
          content: initiative.description,
          icon: Icons.description_rounded,
          iconColor: AppColors.navy,
        ),

        // Problem
        if (initiative.problem != null && initiative.problem!.isNotEmpty)
          InitiativeContentCard(
            title: l10n.translate('problem'),
            content: initiative.problem!,
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.orange,
          ),

        // Solution
        if (initiative.solution != null && initiative.solution!.isNotEmpty)
          InitiativeContentCard(
            title: l10n.translate('solution'),
            content: initiative.solution!,
            icon: Icons.check_circle_outline_rounded,
            iconColor: Colors.green,
          ),

        // Tags
        if (initiative.tags.isNotEmpty) _buildTags(),

        // Voting section
        if (_canVote(user)) ...[
          const SizedBox(height: 16),
          InitiativeVotingSection(initiative: initiative),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: initiative.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tag,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _canVote(UserModel? user) {
    return initiative.status == InitiativeStatus.voting &&
        user != null &&
        (user.role == UserRole.classRep ||
            user.role == UserRole.schoolRep ||
            user.role == UserRole.department ||
            user.role == UserRole.bex ||
            user.role == UserRole.superadmin);
  }
}
