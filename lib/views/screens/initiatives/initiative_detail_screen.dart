import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// Detail screen for viewing a single initiative
class InitiativeDetailScreen extends ConsumerStatefulWidget {
  final InitiativeModel initiative;

  const InitiativeDetailScreen({
    super.key,
    required this.initiative,
  });

  @override
  ConsumerState<InitiativeDetailScreen> createState() =>
      _InitiativeDetailScreenState();
}

class _InitiativeDetailScreenState
    extends ConsumerState<InitiativeDetailScreen> {
  final _commentController = TextEditingController();
  bool _isCommenting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    // Watch for support status
    final isSupportingAsync = ref.watch(
      isSupportingProvider(widget.initiative.id),
    );

    // Check if user can edit/manage
    final canManage = user != null &&
        (user.id == widget.initiative.authorId ||
            user.role == UserRole.bex ||
            user.role == UserRole.superadmin);

    // Check if user can vote
    final canVote = widget.initiative.status == InitiativeStatus.voting &&
        user != null &&
        (user.role == UserRole.schoolRep ||
            user.role == UserRole.department ||
            user.role == UserRole.bex ||
            user.role == UserRole.superadmin);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.navy,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (canManage)
                PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                  ),
                  onSelected: (value) => _handleMenuAction(value, context),
                  itemBuilder: (context) => [
                    if (widget.initiative.status == InitiativeStatus.draft)
                      PopupMenuItem(
                        value: 'submit',
                        child: Row(
                          children: [
                            const Icon(Icons.send_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.translate('submit')),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined, size: 20),
                          const SizedBox(width: 12),
                          Text(l10n.translate('edit')),
                        ],
                      ),
                    ),
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
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.navy,
                      AppColors.navy.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          size: 40,
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _StatusBadge(status: widget.initiative.status),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FE),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.initiative.title,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Author info
                      _buildAuthorCard(),
                      const SizedBox(height: 16),

                      // Support button and count
                      _buildSupportSection(isSupportingAsync),
                      const SizedBox(height: 24),

                      // Description
                      _buildSection(
                        title: l10n.translate('initiative_description'),
                        content: widget.initiative.description,
                      ),

                      // Problem
                      if (widget.initiative.problem != null &&
                          widget.initiative.problem!.isNotEmpty)
                        _buildSection(
                          title: l10n.translate('problem'),
                          content: widget.initiative.problem!,
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.orange,
                        ),

                      // Solution
                      if (widget.initiative.solution != null &&
                          widget.initiative.solution!.isNotEmpty)
                        _buildSection(
                          title: l10n.translate('solution'),
                          content: widget.initiative.solution!,
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: Colors.green,
                        ),

                      // Impact
                      if (widget.initiative.impact != null &&
                          widget.initiative.impact!.isNotEmpty)
                        _buildSection(
                          title: l10n.translate('impact'),
                          content: widget.initiative.impact!,
                          icon: Icons.trending_up_rounded,
                          iconColor: Colors.blue,
                        ),

                      // Tags
                      if (widget.initiative.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.initiative.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
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
                        const SizedBox(height: 24),
                      ],

                      // Voting section (if in voting status)
                      if (canVote) ...[
                        _buildVotingSection(l10n),
                        const SizedBox(height: 24),
                      ],

                      // Comments section
                      _buildCommentsSection(l10n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorCard() {
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.navy.withValues(alpha: 0.1),
            child: Text(
              widget.initiative.authorName.isNotEmpty
                  ? widget.initiative.authorName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.initiative.authorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                if (widget.initiative.schoolName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.initiative.schoolName!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                dateFormat.format(widget.initiative.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(AsyncValue<bool> isSupportingAsync) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 20,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.initiative.supportCount}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'supporters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          isSupportingAsync.when(
            data: (isSupporting) => ElevatedButton.icon(
              onPressed: () => _toggleSupport(),
              icon: Icon(
                isSupporting
                    ? Icons.favorite_rounded
                    : Icons.favorite_outline_rounded,
                size: 18,
              ),
              label: Text(isSupporting ? 'Supported' : 'Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSupporting ? AppColors.gold : Colors.grey.shade200,
                foregroundColor: isSupporting ? AppColors.navy : Colors.grey[700],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            loading: () => const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
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
            content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildVotingSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('voting'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: [
              // Vote counts
              Row(
                children: [
                  _buildVoteCounter(
                    label: l10n.translate('vote_for'),
                    count: widget.initiative.votesFor ?? 0,
                    color: Colors.green,
                  ),
                  _buildVoteCounter(
                    label: l10n.translate('vote_against'),
                    count: widget.initiative.votesAgainst ?? 0,
                    color: Colors.red,
                  ),
                  _buildVoteCounter(
                    label: l10n.translate('abstain'),
                    count: widget.initiative.votesAbstain ?? 0,
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Vote buttons
              Row(
                children: [
                  Expanded(
                    child: _VoteButton(
                      label: 'For',
                      icon: Icons.thumb_up_rounded,
                      color: Colors.green,
                      onTap: () => _vote('for'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _VoteButton(
                      label: 'Against',
                      icon: Icons.thumb_down_rounded,
                      color: Colors.red,
                      onTap: () => _vote('against'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _VoteButton(
                      label: 'Abstain',
                      icon: Icons.remove_circle_outline_rounded,
                      color: Colors.grey,
                      onTap: () => _vote('abstain'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoteCounter({
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(AppLocalizations l10n) {
    final commentsAsync = ref.watch(
      initiativeCommentsStreamProvider(widget.initiative.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('comments'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),

        // Add comment field
        Container(
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
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: l10n.translate('write_comment'),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                  ),
                  maxLines: null,
                ),
              ),
              IconButton(
                onPressed: _isCommenting ? null : _addComment,
                icon: _isCommenting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, color: AppColors.gold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comments list
        commentsAsync.when(
          data: (comments) => comments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                )
              : Column(
                  children: comments.map((comment) {
                    return _CommentCard(comment: comment);
                  }).toList(),
                ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (_, __) => Center(
            child: Text(
              'Failed to load comments',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _toggleSupport() {
    ref
        .read(initiativeControllerProvider.notifier)
        .toggleSupport(widget.initiative.id);
  }

  void _vote(String vote) {
    ref
        .read(initiativeControllerProvider.notifier)
        .vote(widget.initiative.id, vote);
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isCommenting = true);

    final id = await ref
        .read(initiativeControllerProvider.notifier)
        .addComment(widget.initiative.id, text);

    setState(() => _isCommenting = false);

    if (id != null) {
      _commentController.clear();
    }
  }

  void _handleMenuAction(String action, BuildContext context) {
    final l10n = AppLocalizations.of(context);

    switch (action) {
      case 'submit':
        _submitInitiative(context);
        break;
      case 'edit':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon')),
        );
        break;
      case 'delete':
        _deleteInitiative(context, l10n);
        break;
    }
  }

  void _submitInitiative(BuildContext context) async {
    final success = await ref
        .read(initiativeControllerProvider.notifier)
        .submitInitiative(widget.initiative.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initiative submitted for review'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteInitiative(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('delete_initiative')),
        content: Text(l10n.translate('delete_initiative_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(initiativeControllerProvider.notifier)
                  .deleteInitiative(widget.initiative.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('initiative_deleted'))),
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

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final InitiativeStatus status;

  const _StatusBadge({required this.status});

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

/// Vote button widget
class _VoteButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _VoteButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Comment card widget
class _CommentCard extends StatelessWidget {
  final InitiativeComment comment;

  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: comment.isOfficial
            ? AppColors.gold.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: comment.isOfficial
            ? Border.all(color: AppColors.gold.withValues(alpha: 0.3))
            : null,
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
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                backgroundImage: comment.authorPhotoUrl != null
                    ? NetworkImage(comment.authorPhotoUrl!)
                    : null,
                child: comment.authorPhotoUrl == null
                    ? Text(
                        comment.authorName.isNotEmpty
                            ? comment.authorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                          ),
                        ),
                        if (comment.isOfficial) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OFFICIAL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      dateFormat.format(comment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
