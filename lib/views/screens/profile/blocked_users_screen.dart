import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/auth/auth_controller.dart';
import '../../../core/core.dart';
import '../../../core/services/content_moderation_service.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.translate('blocked_users'))),
      body: ListView(
        children: (user?.blockedUsers ?? const <String>[])
            .map(
              (id) => ListTile(
                title: Text(id),
                trailing: TextButton(
                  child: Text(l10n.translate('unblock_user')),
                  onPressed: () async {
                    if (user == null) return;
                    try {
                      await ContentModerationService().unblockAuthor(user, id);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.translate('error'))),
                        );
                      }
                    }
                  },
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
