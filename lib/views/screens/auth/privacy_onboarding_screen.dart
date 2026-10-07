import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../widgets/common/registration_privacy_section.dart';
import '../../widgets/common/account_privacy_action.dart';

/// Mandatory first-login step for CSV-imported and legacy accounts.
class PrivacyOnboardingScreen extends ConsumerStatefulWidget {
  const PrivacyOnboardingScreen({super.key});

  @override
  ConsumerState<PrivacyOnboardingScreen> createState() =>
      _PrivacyOnboardingScreenState();
}

class _PrivacyOnboardingScreenState
    extends ConsumerState<PrivacyOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool? _isUnder16;
  bool _privacyNoticeAcknowledged = false;
  bool _termsAccepted = false;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final (success, errorMessage) = await ref
        .read(authControllerProvider.notifier)
        .completePrivacyOnboarding(
          isUnder16: _isUnder16!,
          privacyNoticeAcknowledged: _privacyNoticeAcknowledged,
          termsAccepted: _termsAccepted,
        );

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _errorMessage = success ? null : errorMessage;
    });
    // The user-document listener changes the auth state and the router moves
    // to pending approval or the appropriate dashboard after a successful save.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.translate('privacy_onboarding_title')),
          actions: [
            const AccountPrivacyAction(),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () => ref.read(authControllerProvider.notifier).signOut(),
              child: Text(l10n.translate('logout')),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLG),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  Text(
                    l10n.translate('privacy_onboarding_heading'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing8),
                  Text(
                    l10n.translate('privacy_onboarding_description'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing24),
                  RegistrationPrivacySection(
                    isUnder16: _isUnder16,
                    privacyNoticeAcknowledged: _privacyNoticeAcknowledged,
                    termsAccepted: _termsAccepted,
                    onTermsAcceptedChanged: (value) =>
                        setState(() => _termsAccepted = value),
                    enabled: !_isSaving,
                    onAgeGroupChanged: (value) =>
                        setState(() => _isUnder16 = value),
                    onPrivacyNoticeAcknowledgedChanged: (value) =>
                        setState(() => _privacyNoticeAcknowledged = value),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSizes.spacing12),
                    Text(
                      _errorMessage!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppSizes.spacing24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _submit,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(l10n.translate('privacy_onboarding_continue')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
