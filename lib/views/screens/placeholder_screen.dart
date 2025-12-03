import 'package:flutter/material.dart';

import '../../core/core.dart';

/// Placeholder screen for features under development
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Color? accentColor;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = accentColor ?? AppColors.gold;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.search,
                      color: AppColors.navy,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon container
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            size: 40,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      subtitle ?? l10n.translate('coming_soon'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'This feature is currently under development.\nCheck back soon!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_outlined, color: color, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Notify me when ready',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Announcements screen placeholder
class AnnouncementsScreen extends StatelessWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n.translate('announcements'),
      icon: Icons.campaign_rounded,
      subtitle: 'Announcements',
      accentColor: AppColors.gold,
    );
  }
}

/// Meetings screen placeholder
class MeetingsScreen extends StatelessWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n.translate('meetings'),
      icon: Icons.event_rounded,
      subtitle: 'Meetings',
      accentColor: const Color(0xFF3B82F6),
    );
  }
}

/// Initiatives screen placeholder
class InitiativesScreen extends StatelessWidget {
  const InitiativesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PlaceholderScreen(
      title: l10n.translate('initiatives'),
      icon: Icons.lightbulb_rounded,
      subtitle: 'Initiatives',
      accentColor: const Color(0xFF10B981),
    );
  }
}
