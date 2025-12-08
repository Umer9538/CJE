import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../meetings/create_meeting_screen.dart';
import '../meetings/meeting_detail_screen.dart';
import 'department_dashboard_screen.dart';

/// Department Meetings Screen - Shows all department meetings
class DepartmentMeetingsScreen extends ConsumerStatefulWidget {
  const DepartmentMeetingsScreen({super.key});

  @override
  ConsumerState<DepartmentMeetingsScreen> createState() => _DepartmentMeetingsScreenState();
}

class _DepartmentMeetingsScreenState extends ConsumerState<DepartmentMeetingsScreen> {
  bool _showUpcomingOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final meetingsAsync = ref.watch(departmentMeetingsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF92400E),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        body: Column(
          children: [
            // Header
            _buildHeader(context, l10n, user),

            // Filter toggle
            _buildFilterToggle(context, l10n),

            // Meetings list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(departmentMeetingsProvider);
                },
                child: meetingsAsync.when(
                  data: (meetings) {
                    final filteredMeetings = _showUpcomingOnly
                        ? meetings.where((m) => m.dateTime.isAfter(DateTime.now())).toList()
                        : meetings;

                    if (filteredMeetings.isEmpty) {
                      return _buildEmptyState(l10n);
                    }

                    // Sort meetings
                    final sortedMeetings = List<MeetingModel>.from(filteredMeetings);
                    if (_showUpcomingOnly) {
                      sortedMeetings.sort((a, b) => a.dateTime.compareTo(b.dateTime));
                    } else {
                      sortedMeetings.sort((a, b) => b.dateTime.compareTo(a.dateTime));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedMeetings.length,
                      itemBuilder: (context, index) {
                        final meeting = sortedMeetings[index];
                        return _MeetingListItem(
                          meeting: meeting,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MeetingDetailScreen(meeting: meeting),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.badgeDepartmentText),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          l10n.translate('error_loading'),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => ref.invalidate(departmentMeetingsProvider),
                          child: Text(l10n.translate('retry')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateMeetingScreen(
                preselectedType: MeetingType.department,
              ),
            ),
          ),
          backgroundColor: const Color(0xFF92400E),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            l10n.translate('new_meeting'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, UserModel? user) {
    return Container(
      color: const Color(0xFF92400E),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('meetings'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.department?.displayName ?? l10n.translate('department'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterToggle(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.translate('all'),
            isSelected: !_showUpcomingOnly,
            onTap: () => setState(() => _showUpcomingOnly = false),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: l10n.translate('upcoming'),
            isSelected: _showUpcomingOnly,
            onTap: () => setState(() => _showUpcomingOnly = true),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _showUpcomingOnly
                ? l10n.translate('no_upcoming_meetings')
                : l10n.translate('no_meetings'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('create_first_meeting'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.badgeDepartmentBg : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.badgeDepartmentText : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.badgeDepartmentText : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _MeetingListItem extends StatelessWidget {
  final MeetingModel meeting;
  final VoidCallback onTap;

  const _MeetingListItem({
    required this.meeting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPast = meeting.dateTime.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Date badge
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isPast
                    ? Colors.grey[100]
                    : AppColors.badgeDepartmentBg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    DateFormat('dd').format(meeting.dateTime),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isPast ? Colors.grey[500] : const Color(0xFF92400E),
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(meeting.dateTime).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPast ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Meeting info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isPast ? Colors.grey[500] : AppColors.navy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(meeting.dateTime),
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        meeting.isOnline ? Icons.videocam : Icons.location_on,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          meeting.isOnline
                              ? 'Online'
                              : (meeting.location ?? 'TBD'),
                          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (isPast) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meeting.isCompleted ? 'Completed' : 'Past',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
