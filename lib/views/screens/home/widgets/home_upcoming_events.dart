import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../../../models/models.dart';
import '../../../../routes/route_names.dart';

/// Unified event type for home screen
enum UpcomingEventType { meeting, poll, initiative }

/// Unified event model for combining different event types
class UpcomingEvent {
  final String id;
  final String title;
  final String subtitle;
  final DateTime date;
  final UpcomingEventType type;
  final dynamic originalData;

  const UpcomingEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    required this.originalData,
  });
}

class HomeUpcomingEvents extends ConsumerWidget {
  const HomeUpcomingEvents({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Watch all three data sources
    final meetingsAsync = ref.watch(upcomingMeetingsStreamProvider);
    final pollsAsync = ref.watch(activePollsStreamProvider);
    final initiativesAsync = ref.watch(recentInitiativesStreamProvider);

    // Combine loading states
    final isLoading = meetingsAsync.isLoading || pollsAsync.isLoading || initiativesAsync.isLoading;
    final hasError = meetingsAsync.hasError && pollsAsync.hasError && initiativesAsync.hasError;

    if (isLoading && !meetingsAsync.hasValue && !pollsAsync.hasValue && !initiativesAsync.hasValue) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (hasError) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            l10n.translate('error_loading_data'),
            style: TextStyle(color: context.textSecondary),
          ),
        ),
      );
    }

    // Combine all events
    final events = _combineEvents(
      meetings: meetingsAsync.valueOrNull ?? [],
      polls: pollsAsync.valueOrNull ?? [],
      initiatives: initiativesAsync.valueOrNull ?? [],
    );

    if (events.isEmpty) {
      return SizedBox(
        height: 180,
        child: _buildEmptyState(context, l10n),
      );
    }

    return SizedBox(
      height: 180,
      child: _buildEventsList(context, l10n, events),
    );
  }

  List<UpcomingEvent> _combineEvents({
    required List<MeetingModel> meetings,
    required List<PollModel> polls,
    required List<InitiativeModel> initiatives,
  }) {
    final List<UpcomingEvent> events = [];
    final now = DateTime.now();

    // Add upcoming meetings
    for (final meeting in meetings) {
      if (meeting.dateTime.isAfter(now)) {
        events.add(UpcomingEvent(
          id: meeting.id,
          title: meeting.title,
          subtitle: _getMeetingTypeLabel(meeting.type),
          date: meeting.dateTime,
          type: UpcomingEventType.meeting,
          originalData: meeting,
        ));
      }
    }

    // Add active polls (ending soon)
    for (final poll in polls) {
      if (poll.isActive && poll.endDate.isAfter(now)) {
        events.add(UpcomingEvent(
          id: poll.id,
          title: poll.question,
          subtitle: _getPollTypeLabel(poll),
          date: poll.endDate,
          type: UpcomingEventType.poll,
          originalData: poll,
        ));
      }
    }

    // Add initiatives in voting phase
    for (final initiative in initiatives) {
      if (initiative.status == InitiativeStatus.voting && initiative.votingEndedAt != null) {
        if (initiative.votingEndedAt!.isAfter(now)) {
          events.add(UpcomingEvent(
            id: initiative.id,
            title: initiative.title,
            subtitle: _getInitiativeLabel(),
            date: initiative.votingEndedAt!,
            type: UpcomingEventType.initiative,
            originalData: initiative,
          ));
        }
      }
    }

    // Sort by date (soonest first)
    events.sort((a, b) => a.date.compareTo(b.date));

    // Limit to 10 events
    return events.take(10).toList();
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available, color: context.textSecondary, size: 40),
              const SizedBox(height: 12),
              Text(
                l10n.translate('no_upcoming_events'),
                style: TextStyle(color: context.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, AppLocalizations l10n, List<UpcomingEvent> events) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return GestureDetector(
          onTap: () => _navigateToDetail(context, event),
          child: EventCard(
            title: event.title,
            subtitle: event.subtitle,
            date: DateFormat('MMM d').format(event.date),
            time: _getTimeLabel(event, l10n),
            gradient: _getGradient(event),
            icon: _getIcon(event),
          ),
        );
      },
    );
  }

  void _navigateToDetail(BuildContext context, UpcomingEvent event) {
    switch (event.type) {
      case UpcomingEventType.meeting:
        context.push(RouteNames.meetingDetailPath(event.id));
        break;
      case UpcomingEventType.poll:
        context.push(RouteNames.pollDetailPath(event.id));
        break;
      case UpcomingEventType.initiative:
        context.push(RouteNames.initiativeDetailPath(event.id));
        break;
    }
  }

  String _getTimeLabel(UpcomingEvent event, AppLocalizations l10n) {
    switch (event.type) {
      case UpcomingEventType.meeting:
        return DateFormat('h:mm a').format(event.date);
      case UpcomingEventType.poll:
        return l10n.translate('ends');
      case UpcomingEventType.initiative:
        return l10n.translate('vote_ends');
    }
  }

  List<Color> _getGradient(UpcomingEvent event) {
    switch (event.type) {
      case UpcomingEventType.meeting:
        final meeting = event.originalData as MeetingModel;
        return _getMeetingGradient(meeting.type);
      case UpcomingEventType.poll:
        return const [Color(0xFF7C3AED), Color(0xFF5B21B6)]; // Purple for polls
      case UpcomingEventType.initiative:
        return const [Color(0xFF059669), Color(0xFF047857)]; // Green for initiatives
    }
  }

  IconData _getIcon(UpcomingEvent event) {
    switch (event.type) {
      case UpcomingEventType.meeting:
        final meeting = event.originalData as MeetingModel;
        return _getMeetingIcon(meeting.type);
      case UpcomingEventType.poll:
        return Icons.how_to_vote_rounded;
      case UpcomingEventType.initiative:
        return Icons.lightbulb_rounded;
    }
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

  String _getPollTypeLabel(PollModel poll) {
    // If schoolId is null, it's a county-wide poll
    if (poll.schoolId == null || poll.schoolId!.isEmpty) {
      return 'County Poll';
    }
    return 'School Poll';
  }

  String _getInitiativeLabel() {
    return 'Initiative Vote';
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
