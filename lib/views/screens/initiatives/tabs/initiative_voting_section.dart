import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';
import '../widgets/widgets.dart';

/// Voting section for initiatives in voting status
class InitiativeVotingSection extends ConsumerWidget {
  final InitiativeModel initiative;

  const InitiativeVotingSection({super.key, required this.initiative});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final canVote = ref.watch(canVoteOnInitiativesProvider);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(l10n),
          const SizedBox(height: 16),
          _buildVoteCounts(l10n),
          if (canVote) ...[
            const SizedBox(height: 16),
            _buildVoteButtons(ref, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(Icons.how_to_vote_rounded, size: 20, color: AppColors.navy),
        const SizedBox(width: 8),
        Text(
          l10n.translate('voting'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteCounts(AppLocalizations l10n) {
    return Row(
      children: [
        _VoteCounter(
          label: l10n.translate('vote_for'),
          count: initiative.votesFor ?? 0,
          color: Colors.green,
        ),
        _VoteCounter(
          label: l10n.translate('vote_against'),
          count: initiative.votesAgainst ?? 0,
          color: Colors.red,
        ),
        _VoteCounter(
          label: l10n.translate('abstain'),
          count: initiative.votesAbstain ?? 0,
          color: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildVoteButtons(WidgetRef ref, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: InitiativeVoteButton(
            label: l10n.translate('for'),
            icon: Icons.thumb_up_rounded,
            color: Colors.green,
            onTap: () => _vote(ref, 'for'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InitiativeVoteButton(
            label: l10n.translate('against'),
            icon: Icons.thumb_down_rounded,
            color: Colors.red,
            onTap: () => _vote(ref, 'against'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InitiativeVoteButton(
            label: l10n.translate('abstain'),
            icon: Icons.remove_circle_outline_rounded,
            color: Colors.grey,
            onTap: () => _vote(ref, 'abstain'),
          ),
        ),
      ],
    );
  }

  void _vote(WidgetRef ref, String vote) {
    ref
        .read(initiativeControllerProvider.notifier)
        .vote(initiative.id, vote);
  }
}

class _VoteCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _VoteCounter({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 80;
          return Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: isSmall ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 10 : 12,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
