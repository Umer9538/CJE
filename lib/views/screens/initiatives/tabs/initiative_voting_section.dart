import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';
import '../widgets/widgets.dart';

/// Provider for current user's vote on an initiative
final currentUserVoteProvider = FutureProvider.family<String?, String>((ref, initiativeId) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return null;
  final repository = ref.read(initiativeRepositoryProvider);
  return repository.getUserVote(initiativeId, user.id);
});

/// Voting section for initiatives in voting status
class InitiativeVotingSection extends ConsumerStatefulWidget {
  final InitiativeModel initiative;

  const InitiativeVotingSection({super.key, required this.initiative});

  @override
  ConsumerState<InitiativeVotingSection> createState() => _InitiativeVotingSectionState();
}

class _InitiativeVotingSectionState extends ConsumerState<InitiativeVotingSection> {
  bool _isVoting = false;
  String? _votingFor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    // Check if user can vote based on initiative's minimum voting role
    final canVote = user != null &&
        user.role.hasPermissionOver(widget.initiative.minimumVotingRole);

    final canViewVoters = user != null &&
        (user.role == UserRole.bex || user.role == UserRole.superadmin);

    // Watch user's current vote
    final userVoteAsync = ref.watch(currentUserVoteProvider(widget.initiative.id));

    // Watch the initiative stream for real-time vote count updates
    final initiativeAsync = ref.watch(initiativeProvider(widget.initiative.id));

    // Use stream data if available, otherwise fall back to passed initiative
    final currentInitiative = initiativeAsync.valueOrNull ?? widget.initiative;

    return Container(
      padding: const EdgeInsets.all(20),
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
          _buildHeader(context, l10n),
          const SizedBox(height: 8),
          // Show minimum voting role requirement
          _buildVotingRequirement(context, l10n),
          const SizedBox(height: 16),
          _buildVoteCounts(context, l10n, currentInitiative),
          if (canVote) ...[
            const SizedBox(height: 16),
            userVoteAsync.when(
              data: (userVote) => _buildVoteButtons(ref, l10n, userVote),
              loading: () => _buildVoteButtons(ref, l10n, null, isLoadingVote: true),
              error: (_, __) => _buildVoteButtons(ref, l10n, null),
            ),
            // Show message if user has already voted
            userVoteAsync.when(
              data: (userVote) {
                if (userVote != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Colors.green.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.translate('you_have_voted'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
          // Show message if user cannot vote
          if (!canVote && user != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.translate('insufficient_role_to_vote'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Admin voter visibility section
          if (canViewVoters) ...[
            const SizedBox(height: 20),
            _VoterListSection(initiativeId: widget.initiative.id),
          ],
        ],
      ),
    );
  }

  Widget _buildVotingRequirement(BuildContext context, AppLocalizations l10n) {
    final minRole = widget.initiative.minimumVotingRole;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: minRole.badgeBackgroundColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_rounded,
            size: 14,
            color: context.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            '${l10n.translate('eligible_voters')}: ${minRole.displayName} ${l10n.translate('and_above')}',
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(Icons.how_to_vote_rounded, size: 20, color: isDark ? AppColors.gold : AppColors.navy),
        const SizedBox(width: 8),
        Text(
          l10n.translate('voting'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteCounts(BuildContext context, AppLocalizations l10n, InitiativeModel initiative) {
    return Row(
      children: [
        _VoteCounter(
          label: l10n.translate('vote_for'),
          count: initiative.votesFor ?? 0,
          color: Colors.green,
          textSecondary: context.textSecondary,
        ),
        _VoteCounter(
          label: l10n.translate('vote_against'),
          count: initiative.votesAgainst ?? 0,
          color: Colors.red,
          textSecondary: context.textSecondary,
        ),
        _VoteCounter(
          label: l10n.translate('abstain'),
          count: initiative.votesAbstain ?? 0,
          color: Colors.grey,
          textSecondary: context.textSecondary,
        ),
      ],
    );
  }

  Widget _buildVoteButtons(WidgetRef ref, AppLocalizations l10n, String? userVote, {bool isLoadingVote = false}) {
    return Row(
      children: [
        Expanded(
          child: InitiativeVoteButton(
            label: l10n.translate('for'),
            icon: Icons.thumb_up_rounded,
            color: Colors.green,
            isSelected: userVote == 'for',
            isLoading: _isVoting && _votingFor == 'for',
            isDisabled: isLoadingVote || (_isVoting && _votingFor != 'for'),
            onTap: () => _vote(ref, 'for'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InitiativeVoteButton(
            label: l10n.translate('against'),
            icon: Icons.thumb_down_rounded,
            color: Colors.red,
            isSelected: userVote == 'against',
            isLoading: _isVoting && _votingFor == 'against',
            isDisabled: isLoadingVote || (_isVoting && _votingFor != 'against'),
            onTap: () => _vote(ref, 'against'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InitiativeVoteButton(
            label: l10n.translate('abstain'),
            icon: Icons.remove_circle_outline_rounded,
            color: Colors.grey,
            isSelected: userVote == 'abstain',
            isLoading: _isVoting && _votingFor == 'abstain',
            isDisabled: isLoadingVote || (_isVoting && _votingFor != 'abstain'),
            onTap: () => _vote(ref, 'abstain'),
          ),
        ),
      ],
    );
  }

  Future<void> _vote(WidgetRef ref, String vote) async {
    if (_isVoting) return;

    setState(() {
      _isVoting = true;
      _votingFor = vote;
    });

    final success = await ref
        .read(initiativeControllerProvider.notifier)
        .vote(widget.initiative.id, vote);

    if (mounted) {
      setState(() {
        _isVoting = false;
        _votingFor = null;
      });

      if (success) {
        // Refresh the user's vote
        ref.invalidate(currentUserVoteProvider(widget.initiative.id));
        // Refresh the initiative to get updated counts
        ref.invalidate(initiativeProvider(widget.initiative.id));

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('vote_recorded')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).translate('vote_failed')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _VoteCounter extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color textSecondary;

  const _VoteCounter({
    required this.label,
    required this.count,
    required this.color,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 80;
          return Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: FittedBox(
                  key: ValueKey<int>(count),
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
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 10 : 12,
                    color: textSecondary,
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

/// Voter list section for BEX/Superadmin visibility
class _VoterListSection extends ConsumerStatefulWidget {
  final String initiativeId;

  const _VoterListSection({required this.initiativeId});

  @override
  ConsumerState<_VoterListSection> createState() => _VoterListSectionState();
}

class _VoterListSectionState extends ConsumerState<_VoterListSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final votesAsync = ref.watch(initiativeVotesStreamProvider(widget.initiativeId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Divider(color: context.borderColor),
        const SizedBox(height: 12),

        // Header with expand/collapse
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Row(
            children: [
              Icon(
                Icons.visibility_rounded,
                size: 18,
                color: context.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.translate('voter_details'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
              votesAsync.when(
                data: (votes) => Text(
                  '${votes.length} ${l10n.translate('votes').toLowerCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.expand_more,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Voter list
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 12),
              votesAsync.when(
                data: (votes) => votes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            l10n.translate('no_votes_yet'),
                            style: TextStyle(color: context.textSecondary),
                          ),
                        ),
                      )
                    : Column(
                        children: votes.map((vote) => _VoterTile(vote: vote)).toList(),
                      ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (_, __) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.translate('error_loading_votes'),
                      style: TextStyle(color: context.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}

/// Individual voter tile
class _VoterTile extends StatelessWidget {
  final InitiativeVote vote;

  const _VoterTile({required this.vote});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    Color voteColor;
    IconData voteIcon;
    String voteLabel;

    switch (vote.voteType) {
      case 'for':
        voteColor = Colors.green;
        voteIcon = Icons.thumb_up_rounded;
        voteLabel = l10n.translate('vote_for');
        break;
      case 'against':
        voteColor = Colors.red;
        voteIcon = Icons.thumb_down_rounded;
        voteLabel = l10n.translate('vote_against');
        break;
      case 'abstain':
        voteColor = Colors.grey;
        voteIcon = Icons.remove_circle_outline_rounded;
        voteLabel = l10n.translate('abstain');
        break;
      default:
        voteColor = Colors.grey;
        voteIcon = Icons.help_outline;
        voteLabel = vote.voteType;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: voteColor.withValues(alpha: 0.15),
            child: Text(
              vote.voterName.isNotEmpty ? vote.voterName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: voteColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name and school
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vote.voterName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                if (vote.voterSchoolName != null && vote.voterSchoolName!.isNotEmpty)
                  Text(
                    vote.voterSchoolName!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Vote indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: voteColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(voteIcon, size: 14, color: voteColor),
                const SizedBox(width: 4),
                Text(
                  voteLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: voteColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
