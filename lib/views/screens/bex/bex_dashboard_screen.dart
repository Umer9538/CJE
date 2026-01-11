import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../admin/admin_warnings_screen.dart';
import '../admin/admin_users_screen.dart';
import '../admin/bex_analytics_screen.dart';
import '../admin/send_notification_screen.dart';
import '../admin/widgets/add_user_dialog.dart';
import '../announcements/announcements_screen.dart';
import '../polls/polls_screen.dart';
import '../meetings/meetings_screen.dart';
import '../documents/documents_screen.dart';
import '../calendar/calendar_screen.dart';
import '../profile/profile_screen.dart';

/// BEX Dashboard Screen - Overview for County Executive Bureau
class BexDashboardScreen extends ConsumerWidget {
  const BexDashboardScreen({super.key});

  Future<bool> _onWillPop(BuildContext context) async {
    // Show exit confirmation dialog
    final l10n = AppLocalizations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.translate('exit_app'), style: TextStyle(color: context.textPrimary)),
        content: Text(l10n.translate('exit_app_confirm'), style: TextStyle(color: context.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.translate('exit')),
          ),
        ],
      ),
    );
    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(context);
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: AppColors.navy,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: context.scaffoldBackgroundColor,
          body: RefreshIndicator(
          onRefresh: () async {
            // Invalidate all data providers to refresh dashboard data in real-time
            ref.invalidate(upcomingMeetingsProvider);
            ref.invalidate(allUsersProvider);
            ref.invalidate(announcementsProvider);
            ref.invalidate(pollsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with navy background extending to status bar
                _buildHeader(context, ref, user, l10n),

                // Quick Actions (moved to top for better UX)
                _buildQuickActionsSection(context, l10n),

                // Stats Cards
                _buildStatsSection(context, ref, l10n),

                // Upcoming Meetings
                _buildUpcomingMeetingsSection(context, ref, l10n),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, UserModel? user, AppLocalizations l10n) {
    return Container(
      color: AppColors.navy,
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
                      user?.fullName ?? 'BEX',
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
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'BEX - ${user?.city ?? ""}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Calendar Button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                ),
                child: Container(
                  width: 48,
                  height: 48,
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
              const SizedBox(width: 12),
              // Profile Avatar
              GestureDetector(
                onTap: () => _showProfileMenu(context, ref),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName[0].toUpperCase()
                          : 'B',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final usersAsync = ref.watch(allUsersProvider);
    final meetingsAsync = ref.watch(upcomingMeetingsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('overview'),
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
                  label: l10n.translate('members'),
                  value: usersAsync.when(
                    data: (users) => users.length.toString(),
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
                  label: l10n.translate('upcoming'),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.warning_amber_rounded,
                  label: l10n.translate('warnings'),
                  value: '0',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.school_rounded,
                  label: l10n.translate('schools'),
                  value: usersAsync.when(
                    data: (users) {
                      final schools = users.map((u) => u.schoolId).whereType<String>().toSet();
                      return schools.length.toString();
                    },
                    loading: () => '...',
                    error: (_, __) => '0',
                  ),
                  color: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
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
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: [
              _QuickActionButton(
                icon: Icons.event_rounded,
                label: l10n.translate('meeting'),
                color: Colors.indigo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MeetingsScreen()),
                ),
              ),
              _QuickActionButton(
                icon: Icons.campaign_rounded,
                label: l10n.translate('announce'),
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnnouncementsScreen()),
                ),
              ),
              _QuickActionButton(
                icon: Icons.poll_rounded,
                label: l10n.translate('poll'),
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PollsScreen()),
                ),
              ),
              _QuickActionButton(
                icon: Icons.upload_file_rounded,
                label: l10n.translate('document'),
                color: Colors.red,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                ),
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
                icon: Icons.notifications_active_rounded,
                label: l10n.translate('notify'),
                color: Colors.amber,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendNotificationScreen()),
                ),
              ),
              _QuickActionButton(
                icon: Icons.analytics_rounded,
                label: l10n.translate('analytics'),
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BexAnalyticsScreen()),
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
      ),
    );
  }

  Widget _buildUpcomingMeetingsSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final meetingsAsync = ref.watch(upcomingMeetingsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('upcoming_meetings'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to meetings tab
                },
                child: Text(
                  l10n.translate('see_all'),
                  style: const TextStyle(color: AppColors.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          meetingsAsync.when(
            data: (meetings) {
              if (meetings.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_rounded, size: 48, color: context.borderColor),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('no_upcoming_meetings'),
                          style: TextStyle(color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: meetings.take(3).map((meeting) => _MeetingCard(meeting: meeting)).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
            error: (e, _) => Center(child: Text(AppLocalizations.of(context).translate('error_loading'))),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddUserDialog(),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).translate('settings'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(AppLocalizations.of(context).translate('language')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // Show language selector
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_rounded),
              title: Text(AppLocalizations.of(context).translate('theme')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(context);
                // Show theme selector
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(AppLocalizations.of(context).translate('profile')),
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
              title: Text(AppLocalizations.of(context).translate('logout'), style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ref.read(authControllerProvider.notifier).signOut();
              },
            ),
          ],
        ),
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
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
        padding: const EdgeInsets.all(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      child: Row(
        children: [
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(meeting.dateTime),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(meeting.dateTime).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textSecondary,
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
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: context.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(meeting.dateTime),
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getMeetingTypeColor(meeting.type).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        meeting.type.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getMeetingTypeColor(meeting.type),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.textSecondary),
        ],
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
