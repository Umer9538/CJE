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
    final isSupportingAsync = ref.watch(
      isSupportingProvider(widget.initiative.id),
    );
    final commentsAsync = ref.watch(
      initiativeCommentsStreamProvider(widget.initiative.id),
    );
    // Permission checks
    final canComment = ref.watch(canCommentOnInitiativesProvider);
    final canSupport = ref.watch(canSupportInitiativesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canSupport)
          _SupportSection(
            initiative: widget.initiative,
            isSupportingAsync: isSupportingAsync,
          ),
        const SizedBox(height: 24),
        _buildCommentsHeader(context, l10n),
        const SizedBox(height: 12),
        if (canComment)
          _buildCommentInput(context, l10n),
        if (canComment)
          const SizedBox(height: 16),
        _buildCommentsList(context, commentsAsync, l10n),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCommentsHeader(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(Icons.comment_rounded, size: 20, color: isDark ? AppColors.gold : AppColors.navy),
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
            child: TextField(
              controller: _commentController,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.translate('write_comment'),
                hintStyle: TextStyle(color: context.textSecondary),
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
    );
  }

  Widget _buildCommentsList(
    BuildContext context,
    AsyncValue<List<InitiativeComment>> commentsAsync,
    AppLocalizations l10n,
  ) {
    return commentsAsync.when(
      data: (comments) => comments.isEmpty
          ? _buildEmptyComments(context, l10n)
          : Column(
              children: comments
                  .map((c) => InitiativeCommentCard(comment: c))
                  .toList(),
            ),
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => Center(
        child: Text(
          l10n.translate('error_loading_comments'),
          style: TextStyle(color: context.textSecondary),
        ),
      ),
    );
  }

  Widget _buildEmptyComments(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
      ),
    );
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

class _SupportSection extends ConsumerWidget {
  final InitiativeModel initiative;
  final AsyncValue<bool> isSupportingAsync;

  const _SupportSection({
    required this.initiative,
    required this.isSupportingAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

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
      child: Row(
        children: [
          _buildSupportIcon(),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSupportCount(context, l10n),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 0,
            child: _buildSupportButton(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.favorite_rounded,
        size: 24,
        color: AppColors.gold,
      ),
    );
  }

  Widget _buildSupportCount(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${initiative.supportCount}',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
          maxLines: 1,
        ),
        Text(
          l10n.translate('supporters'),
          style: TextStyle(fontSize: 14, color: context.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSupportButton(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isSupportingAsync.when(
      data: (isSupporting) => ElevatedButton.icon(
        onPressed: () => _toggleSupport(ref),
        icon: Icon(
          isSupporting ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
          size: 18,
        ),
        label: Text(
          isSupporting ? l10n.translate('supported') : l10n.translate('support'),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSupporting ? AppColors.gold : (isDark ? Colors.grey[800] : Colors.grey.shade200),
          foregroundColor: isSupporting ? AppColors.navy : context.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      loading: () => ElevatedButton.icon(
        onPressed: null, // Disabled while loading
        icon: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: Text(l10n.translate('support')),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey.shade200,
          foregroundColor: context.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // Show button on error too - user can still try to support
      error: (_, __) => ElevatedButton.icon(
        onPressed: () => _toggleSupport(ref),
        icon: const Icon(Icons.favorite_outline_rounded, size: 18),
        label: Text(l10n.translate('support')),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.grey[800] : Colors.grey.shade200,
          foregroundColor: context.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _toggleSupport(WidgetRef ref) {
    ref
        .read(initiativeControllerProvider.notifier)
        .toggleSupport(initiative.id);
  }
}
