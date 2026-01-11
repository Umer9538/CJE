import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/admin/admin_controller.dart';
import '../../../controllers/auth/auth_controller.dart';
import '../../../controllers/schools/school_controller.dart';
import '../../../controllers/announcements/announcement_controller.dart';
import '../../../controllers/polls/poll_controller.dart';
import '../../../controllers/meetings/meeting_controller.dart';
import '../../../controllers/gds/gds_controller.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import 'admin_users_screen.dart';
import 'admin_schools_screen.dart';
import 'admin_gds_screen.dart';
import 'admin_warnings_screen.dart';
import 'bex_analytics_screen.dart';
import 'send_notification_screen.dart';
import 'widgets/add_user_dialog.dart';
import '../announcements/announcements_screen.dart';
import '../polls/polls_screen.dart';
import '../meetings/meetings_screen.dart';
import '../documents/documents_screen.dart';
import '../profile/profile_screen.dart';
import '../calendar/calendar_screen.dart';

/// Admin Dashboard - Main screen for admin users (superadmin and BEX)
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);

    // Show loading if user is not yet loaded
    if (user == null) {
      return Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Navy header section with status bar
          Container(
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  children: [
                    _buildHeader(context, user, l10n),
                    // County Switcher for Superadmin
                    if (user.role == UserRole.superadmin) ...[
                      const SizedBox(height: 16),
                      _buildCountySwitcher(context, ref, l10n),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Content with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Invalidate all data providers to refresh dashboard data
                ref.invalidate(allUsersProvider);
                ref.invalidate(pendingUsersProvider);
                ref.invalidate(activeSchoolsProvider);
                ref.invalidate(announcementsProvider);
                ref.invalidate(pollsProvider);
                ref.invalidate(upcomingMeetingsProvider);
                ref.invalidate(activeGDSProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Actions (moved to top for better UX)
                    _buildQuickActionsSection(context, l10n),
                    const SizedBox(height: 24),

                    // Statistics Cards
                    _buildStatisticsSection(context, ref, l10n),
                    const SizedBox(height: 24),

                    // Pending Approvals
                    _buildPendingApprovalsSection(context, ref, l10n),
                    const SizedBox(height: 24),

                    // Recent Activity
                    _buildRecentActivitySection(context, ref, l10n),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user, AppLocalizations l10n) {
    final greeting = _getGreeting(l10n);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.fullName.isNotEmpty ? user.fullName : 'Admin',
                style: TextStyle(
                  fontSize: isSmallScreen ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 12,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.translate('super_admin'),
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Calendar Button
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CalendarScreen()),
          ),
          child: Container(
            width: isSmallScreen ? 40 : 48,
            height: isSmallScreen ? 40 : 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Profile Avatar
        GestureDetector(
          onTap: () => _showProfileMenu(context),
          child: Container(
            width: isSmallScreen ? 48 : 56,
            height: isSmallScreen ? 48 : 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: isSmallScreen ? 2 : 3),
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : 'A',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// County Switcher dropdown for Superadmin to filter content by county
  Widget _buildCountySwitcher(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final selectedCounty = ref.watch(selectedCountyProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_city_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedCounty,
                isExpanded: true,
                dropdownColor: AppColors.navy,
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                hint: Text(
                  l10n.translate('all_counties'),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Row(
                      children: [
                        const Icon(Icons.public, color: AppColors.gold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          l10n.translate('all_counties'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  ...romanianCounties.map((county) => DropdownMenuItem<String?>(
                    value: county,
                    child: Text(county, style: const TextStyle(color: Colors.white)),
                  )),
                ],
                onChanged: (value) {
                  ref.read(selectedCountyProvider.notifier).state = value;
                  // Invalidate all data providers to refresh with new county filter
                  ref.invalidate(allUsersProvider);
                  ref.invalidate(pendingUsersProvider);
                  ref.invalidate(activeSchoolsProvider);
                  ref.invalidate(announcementsProvider);
                  ref.invalidate(pollsProvider);
                  ref.invalidate(upcomingMeetingsProvider);
                  ref.invalidate(activeGDSProvider);
                  ref.invalidate(recentActivitiesProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('statistics'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.people_rounded,
                iconColor: Colors.blue,
                title: l10n.translate('total_users'),
                valueProvider: ref.watch(allUsersProvider),
                valueBuilder: (users) => users.length.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.pending_actions_rounded,
                iconColor: Colors.orange,
                title: l10n.translate('pending'),
                valueProvider: ref.watch(pendingUsersProvider),
                valueBuilder: (users) => users.length.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCardGeneric<List<SchoolModel>>(
                icon: Icons.school_rounded,
                iconColor: Colors.green,
                title: l10n.translate('schools'),
                valueProvider: ref.watch(activeSchoolsProvider),
                valueBuilder: (schools) => schools.length.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCardGeneric<List<AnnouncementModel>>(
                icon: Icons.campaign_rounded,
                iconColor: Colors.purple,
                title: l10n.translate('announcements'),
                valueProvider: ref.watch(announcementsProvider(const AnnouncementFilter())),
                valueBuilder: (announcements) => announcements.length.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCardGeneric<List<PollModel>>(
                icon: Icons.poll_rounded,
                iconColor: Colors.orange,
                title: l10n.translate('active_polls'),
                valueProvider: ref.watch(pollsProvider(const PollFilter(activeOnly: true))),
                valueBuilder: (polls) => polls.length.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCardGeneric<List<MeetingModel>>(
                icon: Icons.event_rounded,
                iconColor: Colors.indigo,
                title: l10n.translate('upcoming_meetings'),
                valueProvider: ref.watch(upcomingMeetingsProvider),
                valueBuilder: (meetings) => meetings.length.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCardGeneric<List<GDSModel>>(
                icon: Icons.groups_rounded,
                iconColor: Colors.cyan,
                title: l10n.translate('support_groups'),
                valueProvider: ref.watch(activeGDSProvider),
                valueBuilder: (gds) => gds.length.toString(),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()), // Placeholder for balance
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, AppLocalizations l10n) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate columns based on screen width - minimum 4, max 5 for tablets
    final crossAxisCount = screenWidth > 600 ? 5 : 4;
    // Calculate aspect ratio based on available width
    final itemWidth = (screenWidth - 40 - (crossAxisCount - 1) * 12) / crossAxisCount;
    final aspectRatio = itemWidth / (itemWidth + 16); // More height for text

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('quick_actions'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            _QuickActionButton(
              icon: Icons.people_rounded,
              label: l10n.translate('users'),
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.person_add_rounded,
              label: l10n.translate('add_user'),
              color: Colors.green,
              onTap: () => _showAddUserDialog(context),
            ),
            _QuickActionButton(
              icon: Icons.campaign_rounded,
              label: l10n.translate('announce'),
              color: Colors.purple,
              onTap: () => _showCreateAnnouncementDialog(context),
            ),
            _QuickActionButton(
              icon: Icons.poll_rounded,
              label: l10n.translate('poll'),
              color: Colors.orange,
              onTap: () => _showCreatePollDialog(context),
            ),
            _QuickActionButton(
              icon: Icons.school_rounded,
              label: l10n.translate('schools'),
              color: Colors.teal,
              onTap: () => _showSchoolsManagement(context),
            ),
            _QuickActionButton(
              icon: Icons.groups_rounded,
              label: 'GDS',
              color: Colors.cyan,
              onTap: () => _showGDSManagement(context),
            ),
            _QuickActionButton(
              icon: Icons.warning_amber_rounded,
              label: l10n.translate('warnings'),
              color: Colors.deepOrange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminWarningsScreen()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.event_rounded,
              label: l10n.translate('meeting'),
              color: Colors.indigo,
              onTap: () => _showCreateMeetingDialog(context),
            ),
            _QuickActionButton(
              icon: Icons.upload_file_rounded,
              label: l10n.translate('document'),
              color: Colors.red,
              onTap: () => _showUploadDocumentDialog(context),
            ),
            _QuickActionButton(
              icon: Icons.analytics_rounded,
              label: l10n.translate('analytics'),
              color: Colors.teal,
              onTap: () => _showAnalytics(context),
            ),
            _QuickActionButton(
              icon: Icons.notifications_active_rounded,
              label: l10n.translate('notify'),
              color: Colors.amber,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SendNotificationScreen()),
              ),
            ),
            _QuickActionButton(
              icon: Icons.settings_rounded,
              label: l10n.translate('settings'),
              color: Colors.grey,
              onTap: () => _showSettingsDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPendingApprovalsSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final pendingUsersAsync = ref.watch(pendingUsersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.translate('pending_approvals'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              ),
              child: Text(l10n.translate('view_all')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        pendingUsersAsync.when(
          data: (users) {
            if (users.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green[300]),
                      const SizedBox(height: 12),
                      Text(
                        l10n.translate('no_pending_approvals'),
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: users.take(5).length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _PendingUserTile(
                    user: user,
                    onApprove: () => _approveUser(context, ref, user),
                    onReject: () => _rejectUser(context, ref, user),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l10n.translate('error_loading'))),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final activitiesAsync = ref.watch(recentActivitiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('recent_activity'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: activitiesAsync.when(
            data: (activities) {
              if (activities.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('no_recent_activity'),
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: activities.asMap().entries.map((entry) {
                  final index = entry.key;
                  final activity = entry.value;
                  return Column(
                    children: [
                      _ActivityItem(
                        icon: _getActivityIcon(activity.type),
                        color: _getActivityColor(activity.type),
                        title: activity.title,
                        subtitle: activity.subtitle,
                        time: _formatTimeAgo(activity.createdAt, l10n),
                      ),
                      if (index < activities.length - 1)
                        const Divider(height: 24),
                    ],
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.translate('error_loading'),
                  style: TextStyle(color: context.textSecondary),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistered:
        return Icons.person_add;
      case ActivityType.userApproved:
        return Icons.how_to_reg;
      case ActivityType.announcementPublished:
        return Icons.campaign;
      case ActivityType.pollCreated:
        return Icons.poll;
      case ActivityType.pollEnded:
        return Icons.how_to_vote;
      case ActivityType.meetingCreated:
        return Icons.event;
      case ActivityType.initiativeSubmitted:
        return Icons.lightbulb;
      case ActivityType.initiativeStatusChanged:
        return Icons.update;
      case ActivityType.documentUploaded:
        return Icons.upload_file;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistered:
        return Colors.green;
      case ActivityType.userApproved:
        return Colors.blue;
      case ActivityType.announcementPublished:
        return Colors.purple;
      case ActivityType.pollCreated:
        return Colors.orange;
      case ActivityType.pollEnded:
        return Colors.deepOrange;
      case ActivityType.meetingCreated:
        return Colors.indigo;
      case ActivityType.initiativeSubmitted:
        return Colors.amber;
      case ActivityType.initiativeStatusChanged:
        return Colors.teal;
      case ActivityType.documentUploaded:
        return Colors.red;
    }
  }

  String _formatTimeAgo(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return l10n.translate('just_now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${l10n.translate('min_ago')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${difference.inHours > 1 ? l10n.translate('hours_ago') : l10n.translate('hour_ago')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${difference.inDays > 1 ? l10n.translate('days_ago') : l10n.translate('day_ago')}';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.translate('good_morning');
    if (hour < 17) return l10n.translate('good_afternoon');
    return l10n.translate('good_evening');
  }

  void _showProfileMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(l10n.translate('profile')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(l10n.translate('logout'), style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    // Show add user dialog directly
    showDialog(
      context: context,
      builder: (context) => const AddUserDialog(),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
    );
  }

  void _showCreatePollDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PollsScreen()),
    );
  }

  void _showSchoolsManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminSchoolsScreen()),
    );
  }

  void _showGDSManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminGDSScreen()),
    );
  }

  void _showCreateMeetingDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MeetingsScreen()),
    );
  }

  void _showUploadDocumentDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DocumentsScreen()),
    );
  }

  void _showAnalytics(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BexAnalyticsScreen()),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _approveUser(BuildContext context, WidgetRef ref, UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(adminControllerProvider.notifier);
    final success = await controller.approveUser(user.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.translate('user_approved') : l10n.translate('error_approving_user')),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectUser(BuildContext context, WidgetRef ref, UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(adminControllerProvider.notifier);
    final success = await controller.suspendUser(user.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.translate('user_rejected') : l10n.translate('error_rejecting_user')),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final AsyncValue<List<UserModel>>? valueProvider;
  final String Function(List<UserModel>)? valueBuilder;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    this.valueProvider,
    this.valueBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 140;
        final iconContainerSize = isSmallScreen ? 32.0 : 36.0;
        final iconSize = isSmallScreen ? 16.0 : 20.0;
        final valueFontSize = isSmallScreen ? 20.0 : 24.0;
        final titleFontSize = isSmallScreen ? 10.0 : 12.0;
        final padding = isSmallScreen ? 12.0 : 16.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: iconSize),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              if (valueProvider != null)
                valueProvider!.when(
                  data: (users) => FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      valueBuilder!(users),
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  loading: () => SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Text('-'),
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value ?? '-',
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    color: context.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Generic stat card for different types
class _StatCardGeneric<T> extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final AsyncValue<T> valueProvider;
  final String Function(T) valueBuilder;

  const _StatCardGeneric({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.valueProvider,
    required this.valueBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 140;
        final iconSize = isSmallScreen ? 16.0 : 20.0;
        final valueFontSize = isSmallScreen ? 20.0 : 24.0;
        final titleFontSize = isSmallScreen ? 10.0 : 12.0;
        final padding = isSmallScreen ? 12.0 : 16.0;

        return Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: iconSize),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              valueProvider.when(
                data: (data) => FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    valueBuilder(data),
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                loading: () => SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text('0'),
              ),
              SizedBox(height: isSmallScreen ? 2 : 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    color: context.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate sizes based on available space
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final iconContainerSize = (availableWidth * 0.55).clamp(32.0, 48.0);
        final iconSize = (iconContainerSize * 0.5).clamp(14.0, 22.0);
        final fontSize = (availableWidth * 0.14).clamp(9.0, 12.0);
        final padding = (availableWidth * 0.1).clamp(6.0, 12.0);
        final spacing = (availableHeight * 0.05).clamp(2.0, 8.0);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: context.shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                SizedBox(height: spacing),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                        color: context.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _PendingUserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingUserTile({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.gold.withValues(alpha: 0.15),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '${user.email} • ${dateFormat.format(user.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onApprove,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.green, size: 18),
            ),
          ),
          IconButton(
            onPressed: onReject,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.red, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}
