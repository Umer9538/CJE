import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';
import '../widgets/widgets.dart';

/// Comments & Support tab for initiative detail screen
class InitiativeCommentsTab extends ConsumerStatefulWidget {
  final InitiativeModel initiative;

  const InitiativeCommentsTab({super.key, required this.initiative});

  @override
  ConsumerState<InitiativeCommentsTab> createState() =>
      _InitiativeCommentsTabState();
}

class _InitiativeCommentsTabState extends ConsumerState<InitiativeCommentsTab> {
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
    final commentsAsync = ref.watch(initiativeCommentsStreamProvider(widget.initiative.id));
    final canComment = ref.watch(canCommentOnInitiativesProvider);
    final canSupport = ref.watch(canSupportInitiativesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Support section
        if (canSupport) _buildSupportSection(context, l10n),

        if (canSupport) const SizedBox(height: 24),

        // Comments header
        _buildCommentsHeader(context, l10n),

        const SizedBox(height: 12),

        // Comment input
        if (canComment) _buildCommentInput(context, l10n),

        if (canComment) const SizedBox(height: 16),

        // Comments list
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return _buildEmptyComments(context, l10n);
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: comments.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InitiativeCommentCard(comment: c),
              )).toList(),
            );
          },
          loading: () => Container(
            height: 100,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
          error: (_, __) => Container(
            height: 100,
            alignment: Alignment.center,
            child: Text(
              l10n.translate('error_loading_comments'),
              style: TextStyle(color: context.textSecondary),
            ),
          ),
        ),

        // Extra padding for bottom navigation bar
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSupportingAsync = ref.watch(isSupportingProvider(widget.initiative.id));

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.favorite_rounded, size: 24, color: AppColors.gold),
              ),
              const SizedBox(width: 16),
              // Count and label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.initiative.supportCount}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.translate('supporters'),
                      style: TextStyle(fontSize: 14, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Button - full width
          SizedBox(
            width: double.infinity,
            height: 44,
            child: isSupportingAsync.when(
              data: (isSupporting) => Material(
                color: isSupporting ? Colors.red.shade600 : AppColors.gold,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                child: InkWell(
                  onTap: _toggleSupport,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSupporting ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isSupporting ? l10n.translate('supported') : l10n.translate('support'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              loading: () => Material(
                color: AppColors.gold.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              error: (_, __) => Material(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                child: InkWell(
                  onTap: _toggleSupport,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_outline_rounded, size: 22, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          l10n.translate('support'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsHeader(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          Icons.comment_rounded,
          size: 20,
          color: isDark ? AppColors.gold : AppColors.navy,
        ),
        const SizedBox(width: 8),
        Text(
          l10n.translate('comments'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: TextField(
              controller: _commentController,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.translate('write_comment'),
                hintStyle: TextStyle(color: context.textSecondary),
                border: InputBorder.none,
              ),
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
    );
  }

  Widget _buildEmptyComments(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 48,
            color: context.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.translate('no_comments_yet'),
            style: TextStyle(color: context.textSecondary),
          ),
        ],
      ),
    );
  }

  void _toggleSupport() {
    ref.read(initiativeControllerProvider.notifier).toggleSupport(widget.initiative.id);
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
}
