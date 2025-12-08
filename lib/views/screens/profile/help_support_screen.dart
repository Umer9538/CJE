import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';

/// Help & Support screen with FAQ and contact options
class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  final List<int> _expandedFAQs = [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(l10n.translate('help_support')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Section
            _buildSectionTitle(l10n.translate('contact_us')),
            const SizedBox(height: 12),
            _buildContactSection(context, l10n),

            const SizedBox(height: 32),

            // FAQ Section
            _buildSectionTitle(l10n.translate('faq')),
            const SizedBox(height: 12),
            _buildFAQSection(context, l10n),

            const SizedBox(height: 32),

            // App Info Section
            _buildSectionTitle(l10n.translate('about_app')),
            const SizedBox(height: 12),
            _buildAppInfoSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.navy,
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, AppLocalizations l10n) {
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
      child: Column(
        children: [
          _ContactTile(
            icon: Icons.email_rounded,
            iconColor: const Color(0xFF3B82F6),
            title: l10n.translate('email_us'),
            subtitle: 'support@cje.ro',
            onTap: () => _launchEmail('support@cje.ro'),
          ),
          const Divider(height: 24),
          _ContactTile(
            icon: Icons.phone_rounded,
            iconColor: const Color(0xFF10B981),
            title: l10n.translate('call_us'),
            subtitle: '+40 123 456 789',
            onTap: () => _launchPhone('+40123456789'),
          ),
          const Divider(height: 24),
          _ContactTile(
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: l10n.translate('website'),
            subtitle: 'www.cje.ro',
            onTap: () => _launchUrl('https://www.cje.ro'),
          ),
          const Divider(height: 24),
          _ContactTile(
            icon: Icons.facebook_rounded,
            iconColor: const Color(0xFF1877F2),
            title: 'Facebook',
            subtitle: 'CJE Romania',
            onTap: () => _launchUrl('https://www.facebook.com/CJERomania'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context, AppLocalizations l10n) {
    final faqs = _getFAQs(l10n);

    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: faqs.asMap().entries.map((entry) {
            final index = entry.key;
            final faq = entry.value;
            final isExpanded = _expandedFAQs.contains(index);

            return Column(
              children: [
                if (index > 0)
                  Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedFAQs.remove(index);
                      } else {
                        _expandedFAQs.add(index);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                faq['question']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.navy,
                                ),
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Text(
                            faq['answer']!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context, AppLocalizations l10n) {
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.navy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.info_outline, color: AppColors.navy),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('app_name_full'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.translate('version')}: 1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoButton(
                  icon: Icons.description_rounded,
                  label: l10n.translate('terms_of_service'),
                  onTap: () => _launchUrl('https://www.cje.ro/terms'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoButton(
                  icon: Icons.privacy_tip_rounded,
                  label: l10n.translate('privacy_policy'),
                  onTap: () => _launchUrl('https://www.cje.ro/privacy'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getFAQs(AppLocalizations l10n) {
    return [
      {
        'question': l10n.translate('faq_q1'),
        'answer': l10n.translate('faq_a1'),
      },
      {
        'question': l10n.translate('faq_q2'),
        'answer': l10n.translate('faq_a2'),
      },
      {
        'question': l10n.translate('faq_q3'),
        'answer': l10n.translate('faq_a3'),
      },
      {
        'question': l10n.translate('faq_q4'),
        'answer': l10n.translate('faq_a4'),
      },
      {
        'question': l10n.translate('faq_q5'),
        'answer': l10n.translate('faq_a5'),
      },
    ];
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InfoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppColors.navy),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
