import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../screens/profile/privacy_security_screen.dart';

/// Account erasure remains accessible before approval or privacy onboarding.
/// This opens account settings only; it does not bypass content access gates.
class AccountPrivacyAction extends StatelessWidget {
  const AccountPrivacyAction({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppLocalizations.of(context).translate('privacy_security'),
    icon: const Icon(Icons.privacy_tip_outlined),
    onPressed: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PrivacySecurityScreen()),
    ),
  );
}
