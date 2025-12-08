import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../meetings/create_meeting_screen.dart';
import '../documents/upload_document_screen.dart';

/// Department Dashboard Screen - Overview for Department members
class DepartmentDashboardScreen extends ConsumerWidget {
  const DepartmentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF92400E), // Amber-800
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(departmentMeetingsProvider);
            ref.invalidate(departmentMembersProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with department color
                _buildHeader(context, user, l10n),

                // Stats Cards
                _buildStatsSection(context, ref, l10n, user),

                // Quick Actions
                _buildQuickActionsSection(context, l10n, user),

                // Upcoming Meetings
                _buildUpcomingMeetingsSection(context, ref, l10n, user),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, AppLocalizations l10n) {
    final departmentName = user?.department?.displayName ?? l10n.translate('department');

    return Container(
      color: const Color(0xFF92400E), // Amber-800
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('welcome_back'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.fullName ?? 'Department',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.badgeDepartmentBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        departmentName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getDepartmentIcon(user?.department),
                  color: AppColors.badgeDepartmentBg,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDepartmentIcon(DepartmentType? department) {
    switch (department) {
      case DepartmentType.prCommunications:
        return Icons.campaign_rounded;
      case DepartmentType.volunteering:
        return Icons.volunteer_activism_rounded;
      case DepartmentType.schoolInclusion:
        return Icons.diversity_3_rounded;
      default:
        return Icons.work_rounded;
    }
  }

  Widget _buildStatsSection(BuildContext context, WidgetRef ref, AppLocalizations l10n, UserModel? user) {
    final meetingsAsync = ref.watch(departmentMeetingsProvider);
    final membersAsync = ref.watch(departmentMembersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('overview'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.people_rounded,
                  label: l10n.translate('members'),
                  value: membersAsync.when(
                    data: (members) => members.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.event_rounded,
                  label: l10n.translate('meetings'),
                  value: meetingsAsync.when(
                    data: (meetings) => meetings.length.toString(),
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, AppLocalizations l10n, UserModel? user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('quick_actions'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.event_rounded,
                  label: l10n.translate('new_meeting'),
                  color: Colors.indigo,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateMeetingScreen(
                        preselectedType: MeetingType.department,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.upload_file_rounded,
                  label: l10n.translate('upload_document'),
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UploadDocumentScreen(
                        isDepartmentDocument: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingMeetingsSection(BuildContext context, WidgetRef ref, AppLocalizations l10n, UserModel? user) {
    final meetingsAsync = ref.watch(departmentMeetingsProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('upcoming_meetings'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to meetings tab - handled by shell
                },
                child: Text(
                  l10n.translate('see_all'),
                  style: const TextStyle(color: AppColors.badgeDepartmentText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          meetingsAsync.when(
            data: (meetings) {
              final upcomingMeetings = meetings.where((m) => m.dateTime.isAfter(DateTime.now())).toList()
                ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

              if (upcomingMeetings.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('no_upcoming_meetings'),
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: upcomingMeetings.take(3).map((meeting) => _MeetingCard(meeting: meeting)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.badgeDepartmentText),
              ),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeetingCard extends StatelessWidget {
  final MeetingModel meeting;

  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.badgeDepartmentBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(meeting.dateTime),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                Text(
                  DateFormat('MMM').format(meeting.dateTime).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(meeting.dateTime),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                    if (meeting.location != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
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
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}

/// Provider for department meetings (filtered by current user's department)
final departmentMeetingsProvider = FutureProvider<List<MeetingModel>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.department == null) {
    return <MeetingModel>[];
  }

  final repository = ref.read(meetingRepositoryProvider);
  try {
    return await repository.getMeetings(
      type: MeetingType.department,
      department: user.department,
      limit: 20,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <MeetingModel>[],
    );
  } catch (e) {
    return <MeetingModel>[];
  }
});

/// Provider for department members
final departmentMembersProvider = FutureProvider<List<UserModel>>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.department == null) {
    return <UserModel>[];
  }

  final repository = ref.read(userRepositoryProvider);
  try {
    return await repository.getDepartmentMembers(user.department!).timeout(
      const Duration(seconds: 10),
      onTimeout: () => <UserModel>[],
    );
  } catch (e) {
    return <UserModel>[];
  }
});
