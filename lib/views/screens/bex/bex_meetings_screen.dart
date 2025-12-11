import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../meetings/create_meeting_screen.dart';
import '../meetings/meeting_detail_screen.dart';

/// BEX Meetings Screen - Manage County AG and BEX meetings
class BexMeetingsScreen extends ConsumerWidget {
  const BexMeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          title: Text(l10n.translate('meetings')),
          elevation: 0,
          automaticallyImplyLeading: false,
          bottom: TabBar(
            indicatorColor: AppColors.gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: l10n.translate('upcoming')),
              Tab(text: l10n.translate('past')),
              Tab(text: l10n.translate('all')),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MeetingsTab(filter: _MeetingTabFilter.upcoming),
            _MeetingsTab(filter: _MeetingTabFilter.past),
            _MeetingsTab(filter: _MeetingTabFilter.all),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateMeetingScreen()),
            ),
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
            icon: const Icon(Icons.add),
            label: Text(l10n.translate('new_meeting')),
          ),
        ),
      ),
    );
  }
}

enum _MeetingTabFilter { upcoming, past, all }

class _MeetingsTab extends ConsumerWidget {
  final _MeetingTabFilter filter;

  const _MeetingsTab({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Get meetings based on filter - only county-level meetings for BEX
    final meetingsAsync = ref.watch(
      meetingsProvider(MeetingFilter(
        upcomingOnly: filter == _MeetingTabFilter.upcoming,
        limit: 50,
      )),
    );

    return meetingsAsync.when(
      data: (allMeetings) {
        // Filter for County AG and BEX meetings only
        List<MeetingModel> meetings = allMeetings.where((m) =>
          m.type == MeetingType.countyAG || m.type == MeetingType.bex
        ).toList();

        // Apply past filter
        if (filter == _MeetingTabFilter.past) {
          meetings = meetings.where((m) => !m.isUpcoming).toList();
        }

        if (meetings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64, color: context.textSecondary),
                const SizedBox(height: 16),
                Text(
                  l10n.translate('no_meetings'),
                  style: TextStyle(fontSize: 16, color: context.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(meetingsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: meetings.length,
            itemBuilder: (context, index) {
              return _MeetingCard(
                meeting: meetings[index],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeetingDetailScreen(meeting: meetings[index]),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback onTap;

  const _MeetingCard({
    required this.meeting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPast = !meeting.isUpcoming;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getMeetingTypeColor(meeting.type).withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getMeetingTypeColor(meeting.type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      meeting.type.displayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isPast)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meeting.isCompleted
                            ? l10n.translate('completed')
                            : l10n.translate('past'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  if (meeting.minutesDocumentUrl != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.description, size: 18, color: Colors.green[600]),
                  ],
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                  if (meeting.description != null && meeting.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      meeting.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.calendar_today_rounded,
                        label: DateFormat('dd MMM yyyy').format(meeting.dateTime),
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.access_time_rounded,
                        label: DateFormat('HH:mm').format(meeting.dateTime),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _InfoChip(
                        icon: meeting.isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
                        label: meeting.isOnline
                            ? l10n.translate('online')
                            : (meeting.location ?? l10n.translate('location_tbd')),
                      ),
                      const Spacer(),
                      if (meeting.agendaItems.isNotEmpty)
                        Text(
                          '${meeting.agendaItems.length} ${l10n.translate('agenda_items')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMeetingTypeColor(MeetingType type) {
    switch (type) {
      case MeetingType.countyAG:
        return Colors.purple;
      case MeetingType.bex:
        return Colors.indigo;
      case MeetingType.school:
        return Colors.blue;
      case MeetingType.department:
        return Colors.teal;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: context.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}
