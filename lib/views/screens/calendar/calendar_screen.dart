import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../meetings/meeting_detail_screen.dart';

/// Calendar screen showing meetings in a calendar view
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
    final meetingsAsync = ref.watch(
      meetingsProvider(const MeetingFilter(upcomingOnly: false, limit: 100)),
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('calendar'),
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: meetingsAsync.when(
        data: (meetings) => _buildContent(meetings, l10n),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
        error: (_, __) => Center(
          child: Text(l10n.translate('error_loading')),
        ),
      ),
    );
  }

  Widget _buildContent(List<MeetingModel> meetings, AppLocalizations l10n) {
    final meetingsByDay = _groupMeetingsByDay(meetings);
    final selectedMeetings = _getSelectedDayMeetings(meetings);

    return Column(
      children: [
        _buildCalendar(meetingsByDay, l10n),
        const Divider(height: 1),
        Expanded(
          child: _buildMeetingsList(selectedMeetings, l10n),
        ),
      ],
    );
  }

  Map<DateTime, List<MeetingModel>> _groupMeetingsByDay(List<MeetingModel> meetings) {
    final Map<DateTime, List<MeetingModel>> grouped = {};
    for (final meeting in meetings) {
      final day = DateTime(
        meeting.dateTime.year,
        meeting.dateTime.month,
        meeting.dateTime.day,
      );
      grouped.putIfAbsent(day, () => []);
      grouped[day]!.add(meeting);
    }
    return grouped;
  }

  List<MeetingModel> _getSelectedDayMeetings(List<MeetingModel> meetings) {
    if (_selectedDay == null) return [];
    return meetings.where((m) {
      return m.dateTime.year == _selectedDay!.year &&
             m.dateTime.month == _selectedDay!.month &&
             m.dateTime.day == _selectedDay!.day;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  Widget _buildCalendar(Map<DateTime, List<MeetingModel>> meetingsByDay, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
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
      child: TableCalendar<MeetingModel>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) {
          final normalizedDay = DateTime(day.year, day.month, day.day);
          return meetingsByDay[normalizedDay] ?? [];
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
          weekendTextStyle: const TextStyle(color: AppColors.navy),
          holidayTextStyle: const TextStyle(color: AppColors.navy),
          todayDecoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.gold,
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
          titleTextStyle: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.navy),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.navy),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingsList(List<MeetingModel> meetings, AppLocalizations l10n) {
    if (meetings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              l10n.translate('no_meetings_on_date'),
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('h:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meetings.length,
      itemBuilder: (context, index) {
        final meeting = meetings[index];
        return _MeetingCard(
          meeting: meeting,
          timeFormat: dateFormat,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MeetingDetailScreen(meeting: meeting),
            ),
          ),
        );
      },
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final DateFormat timeFormat;
  final VoidCallback onTap;

  const _MeetingCard({
    required this.meeting,
    required this.timeFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getTypeColor(meeting.type).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                color: _getTypeColor(meeting.type),
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
                          color: _getTypeColor(meeting.type).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTypeLabel(meeting.type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getTypeColor(meeting.type),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeFormat.format(meeting.dateTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (meeting.isOnline) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.videocam_rounded, size: 14, color: Colors.green[600]),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    meeting.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (meeting.location != null && !meeting.isOnline) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            meeting.location!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(MeetingType type) {
    switch (type) {
      case MeetingType.countyAG:
        return AppColors.meetingCountyAG;
      case MeetingType.bex:
        return AppColors.meetingBEX;
      case MeetingType.department:
        return AppColors.meetingDepartment;
      case MeetingType.school:
        return AppColors.meetingSchool;
    }
  }

  String _getTypeLabel(MeetingType type) {
    switch (type) {
      case MeetingType.countyAG:
        return 'AG Județean';
      case MeetingType.bex:
        return 'BEx';
      case MeetingType.department:
        return 'Departament';
      case MeetingType.school:
        return 'Școală';
    }
  }
}
