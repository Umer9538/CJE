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
import '../announcements/create_announcement_screen.dart';
import '../polls/create_poll_screen.dart';
import '../meetings/create_meeting_screen.dart';
import '../documents/upload_document_screen.dart';
import '../profile/profile_screen.dart';

/// Admin Dashboard - Main screen for superadmin
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);

    // Show loading if user is not yet loaded
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, user, l10n),
              const SizedBox(height: 24),

              // Statistics Cards
              _buildStatisticsSection(context, ref, l10n),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActionsSection(context, l10n),
              const SizedBox(height: 24),

              // Pending Approvals
              _buildPendingApprovalsSection(context, ref, l10n),
              const SizedBox(height: 24),

              // Recent Activity
              _buildRecentActivitySection(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user, AppLocalizations l10n) {
    final greeting = _getGreeting();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.fullName.isNotEmpty ? user.fullName : 'Admin',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Super Admin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Profile Avatar
        GestureDetector(
          onTap: () => _showProfileMenu(context),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.navy,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('statistics'),
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
    return Column(
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
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: 48, color: Colors.green[300]),
                      const SizedBox(height: 12),
                      Text(
                        l10n.translate('no_pending_approvals'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
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

  Widget _buildRecentActivitySection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('recent_activity'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _ActivityItem(
                icon: Icons.person_add,
                color: Colors.green,
                title: 'New user registered',
                subtitle: 'John Doe joined as student',
                time: '2 min ago',
              ),
              const Divider(height: 24),
              _ActivityItem(
                icon: Icons.campaign,
                color: Colors.purple,
                title: 'Announcement published',
                subtitle: 'Meeting reminder for Friday',
                time: '1 hour ago',
              ),
              const Divider(height: 24),
              _ActivityItem(
                icon: Icons.how_to_vote,
                color: Colors.orange,
                title: 'Poll ended',
                subtitle: 'School event preferences',
                time: '3 hours ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showProfileMenu(BuildContext context) {
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
                title: const Text('Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to profile
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
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
    // Navigate to users screen with option to add
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
    );
  }

  void _showCreateAnnouncementDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAnnouncementScreen()),
    );
  }

  void _showCreatePollDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePollScreen()),
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
      MaterialPageRoute(builder: (_) => const CreateMeetingScreen()),
    );
  }

  void _showUploadDocumentDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UploadDocumentScreen()),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _approveUser(BuildContext context, WidgetRef ref, UserModel user) async {
    final controller = ref.read(adminControllerProvider.notifier);
    final success = await controller.approveUser(user.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User approved' : 'Error approving user'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectUser(BuildContext context, WidgetRef ref, UserModel user) async {
    final controller = ref.read(adminControllerProvider.notifier);
    final success = await controller.suspendUser(user.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'User rejected' : 'Error rejecting user'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          if (valueProvider != null)
            valueProvider!.when(
              data: (users) => Text(
                valueBuilder!(users),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const Text('-'),
            )
          else
            Text(
              value ?? '-',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          valueProvider.when(
            data: (data) => Text(
              valueBuilder(data),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            loading: () => const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const Text('0'),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.navy,
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
            backgroundColor: AppColors.navy.withValues(alpha: 0.1),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  '${user.email} • ${dateFormat.format(user.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}
