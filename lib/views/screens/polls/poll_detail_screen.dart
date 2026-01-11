import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// Poll detail screen with voting capability
/// ALL users (including students) can vote if poll is active
class PollDetailScreen extends ConsumerStatefulWidget {
  final PollModel poll;

  const PollDetailScreen({
    super.key,
    required this.poll,
  });

  @override
  ConsumerState<PollDetailScreen> createState() => _PollDetailScreenState();
}

class _PollDetailScreenState extends ConsumerState<PollDetailScreen> {
  String? _selectedOptionId; // For single vote
  final Set<String> _selectedOptionIds = {}; // For multiple votes
  bool _isVoting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final hasVotedAsync = ref.watch(hasVotedProvider(widget.poll.id));
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    final isActive = widget.poll.isActive;
    final hasEnded = widget.poll.hasEnded;

    // Check if user can manage (delete) poll
    final canManage = user != null &&
        (user.id == widget.poll.createdById ||
            user.role == UserRole.bex ||
            user.role == UserRole.superadmin);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.arrow_back, color: context.iconColor, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.shadowColor,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.more_vert, color: context.iconColor, size: 20),
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _handleDelete(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        l10n.translate('delete'),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badges
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? l10n.translate('active') : (hasEnded ? l10n.translate('ended') : l10n.translate('upcoming')),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.goldColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.translate(widget.poll.type.translationKey),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                if (widget.poll.isAnonymous) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_off_rounded,
                          size: 12,
                          color: Colors.purple[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.translate('anonymous'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Question (with translation support)
            Text(
              widget.poll.getQuestion(Localizations.localeOf(context).languageCode),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.goldColor,
                height: 1.3,
              ),
            ),
            if (widget.poll.description != null &&
                widget.poll.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.poll.getDescription(Localizations.localeOf(context).languageCode) ?? '',
                style: TextStyle(
                  fontSize: 15,
                  color: context.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Date info
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('start_date'),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(widget.poll.startDate),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.textSecondary.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.translate('end_date'),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(widget.poll.endDate),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Voting section
            Text(
              hasEnded ? l10n.translate('results') : l10n.translate('options'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.goldColor,
              ),
            ),
            const SizedBox(height: 16),

            // Options
            hasVotedAsync.when(
              data: (hasVoted) => _buildOptions(context, hasVoted || hasEnded, l10n),
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
              error: (_, __) => _buildOptions(context, hasEnded, l10n),
            ),

            const SizedBox(height: 24),

            // Vote stats
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    context,
                    l10n,
                    icon: Icons.how_to_vote_rounded,
                    value: '${widget.poll.totalVotes}',
                    label: l10n.translate('total_votes'),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.textSecondary.withValues(alpha: 0.2),
                  ),
                  _buildStatItem(
                    context,
                    l10n,
                    icon: Icons.people_rounded,
                    value: '${widget.poll.voterIds.length}',
                    label: l10n.translate('participants'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Created by
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: context.goldColor.withValues(alpha: 0.1),
                    child: Text(
                      widget.poll.createdByName.isNotEmpty
                          ? widget.poll.createdByName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.goldColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('created_by'),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                        Text(
                          widget.poll.createdByName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Voter details for non-anonymous polls (admin only)
            if (!widget.poll.isAnonymous && canManage) ...[
              const SizedBox(height: 24),
              _PollVoterSection(pollId: widget.poll.id),
            ],

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: hasVotedAsync.when(
        data: (hasVoted) {
          if (hasVoted || hasEnded || !isActive) return null;
          final hasSelection = widget.poll.allowMultipleVotes
              ? _selectedOptionIds.isNotEmpty
              : _selectedOptionId != null;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: hasSelection && !_isVoting
                    ? () => _handleVote(context)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: _isVoting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.navy,
                        ),
                      )
                    : Text(
                        l10n.translate('submit_vote'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildOptions(BuildContext context, bool showResults, AppLocalizations l10n) {
    final allowMultiple = widget.poll.allowMultipleVotes;

    return Column(
      children: widget.poll.options.map((option) {
        final percentage = option.getPercentage(widget.poll.totalVotes);
        final isSelected = allowMultiple
            ? _selectedOptionIds.contains(option.id)
            : _selectedOptionId == option.id;
        final isWinner = showResults &&
            widget.poll.winningOptions.any((o) => o.id == option.id);

        return GestureDetector(
          onTap: showResults
              ? null
              : () => setState(() {
                  if (allowMultiple) {
                    if (_selectedOptionIds.contains(option.id)) {
                      _selectedOptionIds.remove(option.id);
                    } else {
                      _selectedOptionIds.add(option.id);
                    }
                  } else {
                    _selectedOptionId = option.id;
                  }
                }),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? context.goldColor
                    : (isWinner
                        ? Colors.green.withValues(alpha: 0.5)
                        : Colors.transparent),
                width: 2,
              ),
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
                Row(
                  children: [
                    if (!showResults)
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: allowMultiple ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: allowMultiple ? BorderRadius.circular(4) : null,
                          border: Border.all(
                            color: isSelected ? context.goldColor : context.textSecondary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          color: isSelected ? context.goldColor : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    Expanded(
                      child: Text(
                        option.getText(Localizations.localeOf(context).languageCode),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    if (showResults)
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isWinner ? Colors.green : context.textPrimary,
                        ),
                      ),
                  ],
                ),
                if (showResults) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: context.textSecondary.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isWinner ? Colors.green : context.goldColor,
                      ),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${option.voteCount} ${l10n.translate('votes')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    AppLocalizations l10n, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: context.goldColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }

  Future<void> _handleVote(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final controller = ref.read(pollControllerProvider.notifier);

    // Determine which options to vote for
    final optionsToVote = widget.poll.allowMultipleVotes
        ? _selectedOptionIds.toList()
        : (_selectedOptionId != null ? [_selectedOptionId!] : <String>[]);

    if (optionsToVote.isEmpty) return;

    setState(() => _isVoting = true);

    // Vote for all selected options at once
    final success = await controller.voteMultiple(widget.poll.id, optionsToVote);

    setState(() => _isVoting = false);

    if (mounted) {
      if (success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.translate('vote_submitted')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.translate('vote_failed')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.translate('delete_poll')),
        content: Text(l10n.translate('delete_poll_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final controller = ref.read(pollControllerProvider.notifier);
              final success = await controller.deletePoll(widget.poll.id);
              if (success && mounted) {
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.translate('poll_deleted'))),
                );
              }
            },
            child: Text(
              l10n.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Voter section for non-anonymous polls (admin visibility)
class _PollVoterSection extends ConsumerStatefulWidget {
  final String pollId;

  const _PollVoterSection({required this.pollId});

  @override
  ConsumerState<_PollVoterSection> createState() => _PollVoterSectionState();
}

class _PollVoterSectionState extends ConsumerState<_PollVoterSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final votesAsync = ref.watch(pollVotesStreamProvider(widget.pollId));

    return Container(
      padding: const EdgeInsets.all(16),
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
          // Header with expand/collapse
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_rounded,
                  size: 20,
                  color: context.goldColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.translate('voter_details'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.goldColor,
                    ),
                  ),
                ),
                votesAsync.when(
                  data: (votes) => Text(
                    '${votes.length} ${l10n.translate('votes').toLowerCase()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: context.textSecondary,
                ),
              ],
            ),
          ),

          // Voter list
          if (_isExpanded) ...[
            const SizedBox(height: 16),
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
                      children: votes.map((vote) => _PollVoterTile(vote: vote)).toList(),
                    ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.gold),
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
        ],
      ),
    );
  }
}

/// Individual voter tile for poll
class _PollVoterTile extends StatelessWidget {
  final PollVote vote;

  const _PollVoterTile({required this.vote});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: context.goldColor.withValues(alpha: 0.15),
            child: Text(
              vote.voterName.isNotEmpty ? vote.voterName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.goldColor,
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
                // Show voted options
                if (vote.optionTexts.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: vote.optionTexts.map((text) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
