import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/auth/auth_controller.dart';
import '../../../core/core.dart';
import '../../../core/services/content_moderation_service.dart';

/// Uses a bounded reason selector instead of collecting additional personal data.
class ContentReportButton extends ConsumerWidget {
  final String type;
  final String contentId;
  final String authorId;
  final String? countyId;
  final Color? color;
  final VoidCallback? onBlocked;
  const ContentReportButton({
    super.key,
    required this.type,
    required this.contentId,
    required this.authorId,
    required this.countyId,
    this.color,
    this.onBlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || !user.isActive || user.id == authorId) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<bool>(
      tooltip: l10n.translate('report_title'),
      icon: Icon(Icons.flag_outlined, color: color),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: false,
          child: Text(l10n.translate('report_title')),
        ),
        PopupMenuItem(value: true, child: Text(l10n.translate('block_user'))),
      ],
      onSelected: (blockAuthor) async {
        final reason = await showDialog<String>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: Text(
              l10n.translate(
                blockAuthor ? 'block_user_confirm' : 'report_reason_label',
              ),
            ),
            children:
                [
                      'report_inappropriate',
                      'report_harassment',
                      'report_spam',
                      'report_other',
                    ]
                    .map(
                      (key) => SimpleDialogOption(
                        onPressed: () =>
                            Navigator.pop(dialogContext, l10n.translate(key)),
                        child: Text(l10n.translate(key)),
                      ),
                    )
                    .toList(),
          ),
        );
        if (reason == null || !context.mounted) return;
        try {
          await ContentModerationService().reportContent(
            user,
            type: type,
            contentId: contentId,
            countyId: countyId,
            authorId: authorId,
            reason: reason,
            blockAuthor: blockAuthor,
          );
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.translate(
                  blockAuthor ? 'user_blocked' : 'report_submitted',
                ),
              ),
            ),
          );
          if (blockAuthor) onBlocked?.call();
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.translate('report_failed'))),
            );
          }
        }
      },
    );
  }
}
