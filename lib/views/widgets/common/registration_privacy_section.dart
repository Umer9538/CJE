import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../screens/profile/legal_screen.dart';

/// Collects only the age band needed for the under-16 safeguard; no date of
/// birth is requested or stored.
class RegistrationPrivacySection extends StatelessWidget {
  final bool? isUnder16;
  final bool privacyNoticeAcknowledged;
  final bool termsAccepted;
  final bool enabled;
  final ValueChanged<bool?> onAgeGroupChanged;
  final ValueChanged<bool> onPrivacyNoticeAcknowledgedChanged;
  final ValueChanged<bool> onTermsAcceptedChanged;

  const RegistrationPrivacySection({
    super.key,
    required this.isUnder16,
    required this.privacyNoticeAcknowledged,
    required this.termsAccepted,
    required this.enabled,
    required this.onAgeGroupChanged,
    required this.onPrivacyNoticeAcknowledgedChanged,
    required this.onTermsAcceptedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormField<bool>(
          initialValue: termsAccepted,
          validator: (value) => value == true
              ? null
              : l10n.translate('terms_acceptance_required'),
          builder: (field) => Column(
            children: [
              CheckboxListTile(
                value: termsAccepted,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  l10n.translate('terms_acceptance_label'),
                  style: theme.textTheme.bodySmall,
                ),
                onChanged: enabled
                    ? (value) {
                        field.didChange(value ?? false);
                        onTermsAcceptedChanged(value ?? false);
                      }
                    : null,
              ),
              if (field.hasError)
                Text(
                  field.errorText!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              TextButton.icon(
                onPressed: enabled
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      )
                    : null,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l10n.translate('view_full_terms')),
              ),
            ],
          ),
        ),
        DropdownButtonFormField<bool>(
          isExpanded: true,
          initialValue: isUnder16,
          decoration: InputDecoration(
            labelText: l10n.translate('age_group_label'),
            prefixIcon: const Icon(Icons.cake_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            DropdownMenuItem(
              value: false,
              child: Text(
                l10n.translate('age_16_or_over'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: true,
              child: Text(
                l10n.translate('age_under_16_with_authorization'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: enabled ? onAgeGroupChanged : null,
          validator: (value) =>
              value == null ? l10n.translate('age_group_required') : null,
        ),
        if (isUnder16 == true) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.translate('under_16_activation_notice'),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: 8),
        FormField<bool>(
          initialValue: privacyNoticeAcknowledged,
          validator: (value) => value == true
              ? null
              : l10n.translate('privacy_acknowledgement_required'),
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                value: privacyNoticeAcknowledged,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  l10n.translate('privacy_acknowledgement'),
                  style: theme.textTheme.bodySmall,
                ),
                onChanged: enabled
                    ? (value) {
                        final acknowledged = value ?? false;
                        field.didChange(acknowledged);
                        onPrivacyNoticeAcknowledgedChanged(acknowledged);
                      }
                    : null,
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    field.errorText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: enabled
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PrivacyPolicyScreen(),
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l10n.translate('view_privacy_policy')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
