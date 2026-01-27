import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../announcements/create_announcement_screen.dart';
import '../../calendar/calendar_screen.dart';
import '../../documents/documents_screen.dart';
import '../../initiatives/create_initiative_screen.dart';
import '../../meetings/create_meeting_screen.dart';

class HomeQuickStats extends ConsumerWidget {
  const HomeQuickStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final hasAdminAccess = ref.watch(hasAdminAccessProvider);
    final canCreateAnnouncements = ref.watch(canCreateAnnouncementsProvider);
    final canDraftInitiatives = ref.watch(canDraftInitiativesProvider);
    final canCreateMeetings = user != null &&
        (user.role == UserRole.schoolRep ||
         user.role == UserRole.department ||
         user.role == UserRole.bex ||
         user.role == UserRole.superadmin);

    // Show quick actions for users with elevated permissions
    if (hasAdminAccess || canCreateAnnouncements || canDraftInitiatives || canCreateMeetings) {
      return _buildQuickActions(context, l10n,
        canCreateAnnouncements: canCreateAnnouncements,
        canDraftInitiatives: canDraftInitiatives,
        canCreateMeetings: canCreateMeetings,
      );
    }

    // For regular users, show minimal quick actions
    return _buildMinimalQuickActions(context, l10n);
  }

  Widget _buildQuickActions(
    BuildContext context,
    AppLocalizations l10n, {
    required bool canCreateAnnouncements,
    required bool canDraftInitiatives,
    required bool canCreateMeetings,
  }) {
    final actions = <_QuickActionData>[];
    // Use theme-aware icon color (gold in dark mode, navy in light mode)
    final secondaryColor = context.iconColor;

    // Add actions based on permissions - using brand colors (Navy/Gold)
    if (canCreateAnnouncements) {
      actions.add(_QuickActionData(
        icon: Icons.campaign_rounded,
        label: l10n.translate('new_announcement'),
        color: AppColors.gold,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
        ),
      ));
    }

    if (canDraftInitiatives) {
      actions.add(_QuickActionData(
        icon: Icons.lightbulb_rounded,
        label: l10n.translate('new_initiative'),
        color: secondaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateInitiativeScreen()),
        ),
      ));
    }

    if (canCreateMeetings) {
      actions.add(_QuickActionData(
        icon: Icons.groups_rounded,
        label: l10n.translate('new_meeting'),
        color: AppColors.gold,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateMeetingScreen()),
        ),
      ));
    }

    // Documents is always available
    actions.add(_QuickActionData(
      icon: Icons.folder_rounded,
      label: l10n.translate('documents'),
      color: secondaryColor,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DocumentsScreen()),
      ),
    ));

    // Ensure we have exactly 4 actions (or less)
    final displayActions = actions.take(4).toList();
    final responsive = Responsive(context);

    // Responsive grid columns: 2 on mobile, 4 on tablet/desktop
    final columns = responsive.value(mobile: 2, tablet: 4, desktop: 4);
    final horizontalPadding = responsive.value(mobile: 24.0, tablet: 32.0, desktop: 48.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('quick_actions'),
            style: TextStyle(
              fontSize: responsive.value(mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: responsive.value(mobile: 2.2, tablet: 2.5, desktop: 2.8),
            ),
            itemCount: displayActions.length,
            itemBuilder: (context, index) => _QuickActionButton(data: displayActions[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalQuickActions(BuildContext context, AppLocalizations l10n) {
    final secondaryColor = context.iconColor;
    final responsive = Responsive(context);
    final horizontalPadding = responsive.value(mobile: 24.0, tablet: 32.0, desktop: 48.0);

    final actions = [
      _QuickActionData(
        icon: Icons.folder_rounded,
        label: l10n.translate('documents'),
        color: secondaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DocumentsScreen()),
        ),
      ),
      _QuickActionData(
        icon: Icons.calendar_month_rounded,
        label: l10n.translate('calendar'),
        color: AppColors.gold,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CalendarScreen()),
        ),
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('quick_actions'),
            style: TextStyle(
              fontSize: responsive.value(mobile: 18.0, tablet: 20.0, desktop: 22.0),
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: responsive.value(mobile: 2, tablet: 4, desktop: 4),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: responsive.value(mobile: 2.2, tablet: 2.5, desktop: 2.8),
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) => _QuickActionButton(data: actions[index]),
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _QuickActionButton extends StatelessWidget {
  final _QuickActionData data;

  const _QuickActionButton({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
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

// Keep this for backwards compatibility if needed elsewhere
class QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const QuickStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 100;
        final iconContainerSize = isSmall ? 32.0 : 40.0;
        final iconSize = isSmall ? 16.0 : 20.0;
        final valueFontSize = isSmall ? 18.0 : 24.0;
        final titleFontSize = isSmall ? 9.0 : 11.0;
        final padding = isSmall ? 12.0 : 16.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                SizedBox(height: isSmall ? 8 : 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
