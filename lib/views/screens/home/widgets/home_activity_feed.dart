import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../../../routes/route_names.dart';

class HomeActivityFeed extends ConsumerWidget {
  const HomeActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Use StreamProviders for real-time updates
    final recentAnnouncements = ref.watch(recentAnnouncementsStreamProvider);
    final recentInitiatives = ref.watch(recentInitiativesStreamProvider);
    final activePolls = ref.watch(activePollsStreamProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildAnnouncements(context, recentAnnouncements),
          _buildInitiatives(context, recentInitiatives, l10n),
          _buildPolls(context, activePolls, l10n),
          _buildEmptyState(context, recentAnnouncements, recentInitiatives, activePolls),
        ],
      ),
    );
  }

  Widget _buildAnnouncements(
      BuildContext context, AsyncValue<List<dynamic>> announcements) {
    return announcements.when(
      data: (list) => Column(
        children: list.take(2).map((announcement) {
          return GestureDetector(
            onTap: () => context.push(RouteNames.announcementDetailPath(announcement.id)),
            child: ActivityCard(
              avatarColor: announcement.type == AnnouncementType.county
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF10B981),
              title: announcement.title,
              subtitle: announcement.previewText,
              time: _formatTimeAgo(announcement.createdAt),
              icon: Icons.campaign_rounded,
            ),
          );
        }).toList(),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildInitiatives(
      BuildContext context, AsyncValue<List<dynamic>> initiatives, AppLocalizations l10n) {
    return initiatives.when(
      data: (list) => Column(
        children: list.take(2).map((initiative) {
          return GestureDetector(
            onTap: () => context.push(RouteNames.initiativeDetailPath(initiative.id)),
            child: ActivityCard(
              avatarColor: const Color(0xFF8B5CF6),
              title: initiative.title,
              subtitle:
                  '${initiative.supportCount} ${l10n.translate('supporters')} • ${_getStatusLabel(initiative.status, l10n)}',
              time: _formatTimeAgo(initiative.createdAt),
              icon: Icons.lightbulb_rounded,
              isUrgent: initiative.status == InitiativeStatus.voting,
            ),
          );
        }).toList(),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildPolls(
      BuildContext context, AsyncValue<List<dynamic>> polls, AppLocalizations l10n) {
    return polls.when(
      data: (list) => Column(
        children: list.take(2).map((poll) {
          final isEnding = poll.endDate.difference(DateTime.now()).inDays <= 1;
          return GestureDetector(
            onTap: () => context.push(RouteNames.pollDetailPath(poll.id)),
            child: ActivityCard(
              avatarColor: AppColors.gold,
              title: poll.question,
              subtitle: '${poll.totalVotes} ${l10n.translate('votes')} • ${_getPollTypeLabel(poll, l10n)}',
              time: _formatPollEndTime(poll.endDate, l10n),
              icon: Icons.how_to_vote_rounded,
              isUrgent: isEnding,
            ),
          );
        }).toList(),
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }

  String _getPollTypeLabel(dynamic poll, AppLocalizations l10n) {
    if (poll.schoolId == null || poll.schoolId.isEmpty) {
      return l10n.translate('poll_county');
    }
    return l10n.translate('poll_school');
  }

  String _formatPollEndTime(DateTime endDate, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) {
      return l10n.translate('ended');
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ${l10n.translate('left')}';
    } else if (difference.inDays == 1) {
      return '1 ${l10n.translate('day_left')}';
    } else {
      return '${difference.inDays} ${l10n.translate('days_left')}';
    }
  }

  Widget _buildEmptyState(BuildContext context, AsyncValue<List<dynamic>> announcements,
      AsyncValue<List<dynamic>> initiatives, AsyncValue<List<dynamic>> polls) {
    if (announcements.valueOrNull?.isEmpty == true &&
        initiatives.valueOrNull?.isEmpty == true &&
        polls.valueOrNull?.isEmpty == true) {
      return Container(
        padding: const EdgeInsets.all(24),
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
          children: [
            Icon(Icons.inbox_rounded, color: context.textSecondary, size: 40),
            const SizedBox(height: 12),
            Text(
              'No recent activity',
              style: TextStyle(color: context.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  String _getStatusLabel(InitiativeStatus status, AppLocalizations l10n) {
    switch (status) {
      case InitiativeStatus.draft:
        return l10n.translate('draft');
      case InitiativeStatus.submitted:
        return l10n.translate('submitted');
      case InitiativeStatus.review:
        return l10n.translate('review');
      case InitiativeStatus.debate:
        return l10n.translate('in_debate');
      case InitiativeStatus.voting:
        return l10n.translate('voting');
      case InitiativeStatus.adopted:
        return l10n.translate('adopted');
      case InitiativeStatus.rejected:
        return l10n.translate('rejected');
    }
  }
}

class ActivityCard extends StatelessWidget {
  final Color avatarColor;
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final bool isUrgent;

  const ActivityCard({
    super.key,
    required this.avatarColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    this.isUrgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isUrgent
            ? Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                width: 1.5)
            : null,
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: avatarColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: avatarColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                    if (isUrgent) _buildUrgentBadge(context),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        l10n.translate('urgent'),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }
}
