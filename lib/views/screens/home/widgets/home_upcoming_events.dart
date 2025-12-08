import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../meetings/meeting_detail_screen.dart';

class HomeUpcomingEvents extends ConsumerWidget {
  const HomeUpcomingEvents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final upcomingMeetings = ref.watch(upcomingMeetingsProvider);

    return SizedBox(
      height: 180,
      child: upcomingMeetings.when(
        data: (meetings) {
          if (meetings.isEmpty) {
            return _buildEmptyState(l10n);
          }
          return _buildMeetingsList(context, meetings);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (_, __) => Center(
          child: Text(
            'Failed to load meetings',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available, color: Colors.grey[400], size: 40),
              const SizedBox(height: 12),
              Text(
                l10n.translate('no_upcoming_meetings'),
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingsList(BuildContext context, List meetings) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MeetingDetailScreen(meeting: meeting),
            ),
          ),
          child: EventCard(
            title: meeting.title,
            subtitle: meeting.description ?? _getMeetingTypeLabel(meeting.type),
            date: DateFormat('MMM d').format(meeting.dateTime),
            time: DateFormat('h:mm a').format(meeting.dateTime),
            gradient: _getMeetingGradient(meeting.type),
            icon: _getMeetingIcon(meeting.type),
          ),
        );
      },
    );
  }

  List<Color> _getMeetingGradient(MeetingType type) {
    switch (type) {
      case MeetingType.countyAG:
        return const [AppColors.meetingCountyAG, Color(0xFF1E3A5F)];
      case MeetingType.bex:
        return const [AppColors.meetingBEX, Color(0xFFB91C1C)];
      case MeetingType.department:
        return const [AppColors.meetingDepartment, Color(0xFFB8962F)];
      case MeetingType.school:
        return const [AppColors.meetingSchool, Color(0xFF4B5563)];
    }
  }

  IconData _getMeetingIcon(MeetingType type) {
    switch (type) {
      case MeetingType.countyAG:
        return Icons.account_balance_rounded;
      case MeetingType.bex:
        return Icons.admin_panel_settings_rounded;
      case MeetingType.department:
        return Icons.groups_rounded;
      case MeetingType.school:
        return Icons.school_rounded;
    }
  }

  String _getMeetingTypeLabel(MeetingType type) {
    switch (type) {
      case MeetingType.countyAG:
        return 'County Assembly';
      case MeetingType.bex:
        return 'BEx Meeting';
      case MeetingType.department:
        return 'Department Meeting';
      case MeetingType.school:
        return 'School Meeting';
    }
  }
}

class EventCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String date;
  final String time;
  final List<Color> gradient;
  final IconData icon;

  const EventCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.time,
    required this.gradient,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth * 0.5).clamp(160.0, 220.0);

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '$date, $time',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
