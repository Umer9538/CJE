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
        _buildCommentsHeader(l10n),
        const SizedBox(height: 12),
        if (canComment)
          _buildCommentInput(l10n),
        if (canComment)
          const SizedBox(height: 16),
        _buildCommentsList(commentsAsync, l10n),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCommentsHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(Icons.comment_rounded, size: 20, color: AppColors.navy),
        const SizedBox(width: 8),
        Text(
          l10n.translate('comments'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput(AppLocalizations l10n) {
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
    );
  }

  Widget _buildCommentsList(
    AsyncValue<List<InitiativeComment>> commentsAsync,
    AppLocalizations l10n,
  ) {
    return commentsAsync.when(
      data: (comments) => comments.isEmpty
          ? _buildEmptyComments(l10n)
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
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }

  Widget _buildEmptyComments(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.translate('no_comments_yet'),
              style: TextStyle(color: Colors.grey[500]),
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
          _buildSupportIcon(),
          const SizedBox(width: 16),
          Expanded(child: _buildSupportCount(l10n)),
          _buildSupportButton(ref, l10n),
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

  Widget _buildSupportCount(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${initiative.supportCount}',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        Text(
          l10n.translate('supporters'),
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSupportButton(WidgetRef ref, AppLocalizations l10n) {
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
          backgroundColor: isSupporting ? AppColors.gold : Colors.grey.shade200,
          foregroundColor: isSupporting ? AppColors.navy : Colors.grey[700],
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    );
  }

  void _toggleSupport(WidgetRef ref) {
    ref
        .read(initiativeControllerProvider.notifier)
        .toggleSupport(initiative.id);
  }
}
