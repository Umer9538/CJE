import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../announcements/announcement_detail_screen.dart';
import '../../initiatives/initiative_detail_screen.dart';

class HomeActivityFeed extends ConsumerWidget {
  const HomeActivityFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAnnouncements = ref.watch(recentAnnouncementsProvider);
    final recentInitiatives = ref.watch(recentInitiativesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildAnnouncements(context, recentAnnouncements),
          _buildInitiatives(context, recentInitiatives),
          _buildEmptyState(recentAnnouncements, recentInitiatives),
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    AnnouncementDetailScreen(announcement: announcement),
              ),
            ),
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
      BuildContext context, AsyncValue<List<dynamic>> initiatives) {
    return initiatives.when(
      data: (list) => Column(
        children: list.take(2).map((initiative) {
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InitiativeDetailScreen(initiative: initiative),
              ),
            ),
            child: ActivityCard(
              avatarColor: const Color(0xFF8B5CF6),
              title: initiative.title,
              subtitle:
                  '${initiative.supportCount} supporters • ${_getStatusLabel(initiative.status)}',
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

  Widget _buildEmptyState(AsyncValue<List<dynamic>> announcements,
      AsyncValue<List<dynamic>> initiatives) {
    if (announcements.valueOrNull?.isEmpty == true &&
        initiatives.valueOrNull?.isEmpty == true) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, color: Colors.grey[400], size: 40),
            const SizedBox(height: 12),
            Text(
              'No recent activity',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
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

  String _getStatusLabel(InitiativeStatus status) {
    switch (status) {
      case InitiativeStatus.draft:
        return 'Draft';
      case InitiativeStatus.submitted:
        return 'Submitted';
      case InitiativeStatus.review:
        return 'In Review';
      case InitiativeStatus.debate:
        return 'In Debate';
      case InitiativeStatus.voting:
        return 'Voting';
      case InitiativeStatus.adopted:
        return 'Adopted';
      case InitiativeStatus.rejected:
        return 'Rejected';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isUrgent
            ? Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    if (isUrgent) _buildUrgentBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Urgent',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFFEF4444),
        ),
      ),
    );
  }
}
