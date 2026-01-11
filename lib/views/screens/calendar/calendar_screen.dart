import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../meetings/meeting_detail_screen.dart';
import '../announcements/announcement_detail_screen.dart';
import '../polls/poll_detail_screen.dart';

/// Calendar event wrapper for displaying different event types
class CalendarEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final CalendarEventType type;
  final dynamic data; // Original model (MeetingModel, AnnouncementModel, or PollModel)

  CalendarEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.type,
    required this.data,
  });
}

enum CalendarEventType { meeting, announcement, poll }

/// Calendar screen showing meetings, announcements, and polls
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  // MVP: Only monthly view - no format switching
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Fetch all event types
    final meetingsAsync = ref.watch(
      meetingsProvider(const MeetingFilter(upcomingOnly: false, limit: 100)),
    );
    final announcementsAsync = ref.watch(
      announcementsProvider(const AnnouncementFilter()),
    );
    final pollsAsync = ref.watch(
      pollsProvider(const PollFilter()),
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('calendar'),
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: meetingsAsync.when(
        data: (meetings) {
          return announcementsAsync.when(
            data: (announcements) {
              return pollsAsync.when(
                data: (polls) => _buildContent(meetings, announcements, polls, l10n),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
                error: (_, __) => Center(child: Text(l10n.translate('error_loading'))),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            error: (_, __) => Center(child: Text(l10n.translate('error_loading'))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        error: (_, __) => Center(child: Text(l10n.translate('error_loading'))),
      ),
    );
  }

  Widget _buildContent(
    List<MeetingModel> meetings,
    List<AnnouncementModel> announcements,
    List<PollModel> polls,
    AppLocalizations l10n,
  ) {
    // Convert all events to CalendarEvent
    final allEvents = _convertToCalendarEvents(meetings, announcements, polls);
    final eventsByDay = _groupEventsByDay(allEvents);
    final selectedEvents = _getSelectedDayEvents(allEvents);

    return Column(
      children: [
        _buildCalendar(eventsByDay, l10n),
        const Divider(height: 1),
        Expanded(
          child: _buildEventsList(selectedEvents, l10n),
        ),
      ],
    );
  }

  List<CalendarEvent> _convertToCalendarEvents(
    List<MeetingModel> meetings,
    List<AnnouncementModel> announcements,
    List<PollModel> polls,
  ) {
    final events = <CalendarEvent>[];

    // Add meetings
    for (final meeting in meetings) {
      events.add(CalendarEvent(
        id: meeting.id,
        title: meeting.title,
        dateTime: meeting.dateTime,
        type: CalendarEventType.meeting,
        data: meeting,
      ));
    }

    // Add announcements
    for (final announcement in announcements) {
      events.add(CalendarEvent(
        id: announcement.id,
        title: announcement.title,
        dateTime: announcement.createdAt,
        type: CalendarEventType.announcement,
        data: announcement,
      ));
    }

    // Add polls
    for (final poll in polls) {
      events.add(CalendarEvent(
        id: poll.id,
        title: poll.question,
        dateTime: poll.createdAt,
        type: CalendarEventType.poll,
        data: poll,
      ));
    }

    return events..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Map<DateTime, List<CalendarEvent>> _groupEventsByDay(List<CalendarEvent> events) {
    final Map<DateTime, List<CalendarEvent>> grouped = {};
    for (final event in events) {
      final day = DateTime(
        event.dateTime.year,
        event.dateTime.month,
        event.dateTime.day,
      );
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(event);
    }
    return grouped;
  }

  List<CalendarEvent> _getSelectedDayEvents(List<CalendarEvent> events) {
    if (_selectedDay == null) return [];
    return events.where((e) {
      return e.dateTime.year == _selectedDay!.year &&
             e.dateTime.month == _selectedDay!.month &&
             e.dateTime.day == _selectedDay!.day;
    }).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  Widget _buildCalendar(Map<DateTime, List<CalendarEvent>> eventsByDay, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: TableCalendar<CalendarEvent>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          return eventsByDay[normalizedDay] ?? [];
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        // MVP: Disabled format changing - monthly view only
        availableCalendarFormats: const {CalendarFormat.month: 'Month'},
        onFormatChanged: null,
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle: TextStyle(color: context.textPrimary),
          weekendTextStyle: TextStyle(color: context.textPrimary),
          holidayTextStyle: TextStyle(color: context.textPrimary),
          todayDecoration: BoxDecoration(
            color: context.goldColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: context.goldColor,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: BoxDecoration(
            color: context.goldColor,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          markerSize: 6,
          markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        ),
        headerStyle: HeaderStyle(
          // MVP: Hide format button - monthly view only
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: context.textPrimary),
          rightChevronIcon: Icon(Icons.chevron_right, color: context.textPrimary),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: context.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: context.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events, AppLocalizations l10n) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 48, color: context.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.translate('no_events_on_date'),
              style: TextStyle(color: context.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('h:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(
          event: event,
          timeFormat: dateFormat,
          onTap: () => _navigateToEventDetail(context, event),
        );
      },
    );
  }

  void _navigateToEventDetail(BuildContext context, CalendarEvent event) {
    switch (event.type) {
      case CalendarEventType.meeting:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MeetingDetailScreen(meeting: event.data as MeetingModel),
          ),
        );
        break;
      case CalendarEventType.announcement:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnnouncementDetailScreen(announcement: event.data as AnnouncementModel),
          ),
        );
        break;
      case CalendarEventType.poll:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PollDetailScreen(poll: event.data as PollModel),
          ),
        );
        break;
    }
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final DateFormat timeFormat;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.timeFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _getEventColor();
    final icon = _getEventIcon();
    final typeLabel = _getEventTypeLabel(l10n);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 10, color: color),
                            const SizedBox(width: 4),
                            Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeFormat.format(event.dateTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.textSecondary),
          ],
        ),
      ),
    );
  }

  Color _getEventColor() {
    switch (event.type) {
      case CalendarEventType.meeting:
        return AppColors.meetingBEX;
      case CalendarEventType.announcement:
        return AppColors.gold;
      case CalendarEventType.poll:
        return const Color(0xFF8B5CF6);
    }
  }

  IconData _getEventIcon() {
    switch (event.type) {
      case CalendarEventType.meeting:
        return Icons.event_rounded;
      case CalendarEventType.announcement:
        return Icons.campaign_rounded;
      case CalendarEventType.poll:
        return Icons.poll_rounded;
    }
  }

  String _getEventTypeLabel(AppLocalizations l10n) {
    switch (event.type) {
      case CalendarEventType.meeting:
        return l10n.translate('meeting');
      case CalendarEventType.announcement:
        return l10n.translate('announcement');
      case CalendarEventType.poll:
        return l10n.translate('poll');
    }
  }
}
