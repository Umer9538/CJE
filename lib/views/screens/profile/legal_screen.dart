import 'package:flutter/material.dart';

import '../../../core/core.dart';

/// Screen for displaying Terms of Service
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('terms_of_service')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              l10n.translate('terms_section_1_title'),
              l10n.translate('terms_section_1_content'),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              l10n.translate('terms_section_2_title'),
              l10n.translate('terms_section_2_content'),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              l10n.translate('terms_section_3_title'),
              l10n.translate('terms_section_3_content'),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              l10n.translate('terms_section_4_title'),
              l10n.translate('terms_section_4_content'),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              l10n.translate('terms_section_5_title'),
              l10n.translate('terms_section_5_content'),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.translate('last_updated'),
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: context.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

/// Screen for displaying Privacy Policy
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('privacy_policy')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              l10n.translate('privacy_section_1_title'),
              l10n.translate('privacy_section_1_content'),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              l10n.translate('privacy_section_2_title'),
              l10n.translate('privacy_section_2_content'),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              l10n.translate('privacy_section_3_title'),
              l10n.translate('privacy_section_3_content'),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              l10n.translate('privacy_section_4_title'),
              l10n.translate('privacy_section_4_content'),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              l10n.translate('privacy_section_5_title'),
              l10n.translate('privacy_section_5_content'),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.translate('last_updated'),
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: context.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
