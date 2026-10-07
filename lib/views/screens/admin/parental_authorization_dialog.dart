import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../models/models.dart';

/// Returns true immediately for users who are not declared under 16. For a
/// minor it records an administrator's explicit confirmation before approval.
Future<bool> confirmParentalAuthorizationIfRequired(
  BuildContext context,
  UserModel user,
) async {
  if (user.isUnder16 != true) return true;

  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.translate('verify_parental_authorization_title')),
      content: Text(l10n.translate('verify_parental_authorization_message')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.translate('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.translate('verify_and_approve')),
        ),
      ],
    ),
  );

  return confirmed == true;
}
