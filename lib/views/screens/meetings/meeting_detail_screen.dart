import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import 'edit_meeting_screen.dart';

/// Detail screen for viewing a single meeting with tabs for Agenda, Documents, Participants
class MeetingDetailScreen extends ConsumerStatefulWidget {
  final MeetingModel meeting;

  const MeetingDetailScreen({
    super.key,
    required this.meeting,
  });

  @override
  ConsumerState<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends ConsumerState<MeetingDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Check if user can edit/delete
    final isCountyLevelMeeting = widget.meeting.type == MeetingType.countyAG ||
        widget.meeting.type == MeetingType.bex;
    final canEdit = user != null &&
        (user.role == UserRole.bex ||
            user.role == UserRole.superadmin ||
            (!isCountyLevelMeeting && user.id == widget.meeting.createdById));

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            // App Bar with meeting header
            SliverAppBar(
              expandedHeight: 260,
              pinned: true,
              backgroundColor: AppColors.navy,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                if (canEdit)
                  PopupMenuButton<String>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _handleEdit(context);
                      } else if (value == 'delete') {
                        _handleDelete(context, ref);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.translate('edit')),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                            const SizedBox(width: 12),
                            Text(
                              l10n.translate('delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.navy,
                        AppColors.navy.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 60, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meeting type badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeLabel(widget.meeting.type),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Title (with translation support)
                          Text(
                            widget.meeting.getTitle(Localizations.localeOf(context).languageCode),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          // Date & Time row - responsive layout
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    dateFormat.format(widget.meeting.dateTime),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${timeFormat.format(widget.meeting.dateTime)} (${widget.meeting.durationMinutes} min)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                widget.meeting.isOnline
                                    ? Icons.videocam_rounded
                                    : Icons.location_on_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.meeting.isOnline
                                      ? l10n.translate('online')
                                      : (widget.meeting.location ?? l10n.translate('location_tbd')),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.9),
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
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: AppColors.navy,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.gold,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(text: l10n.translate('agenda')),
                      Tab(text: l10n.translate('documents')),
                      Tab(text: l10n.translate('participants')),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Agenda Tab
            _buildAgendaTab(context, l10n),
            // Documents Tab
            _buildDocumentsTab(context, l10n),
            // Participants Tab
            _buildParticipantsTab(context, l10n),
          ],
        ),
      ),
      bottomNavigationBar: widget.meeting.isOnline && widget.meeting.onlineLink != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: () => _joinMeeting(context),
                  icon: const Icon(Icons.videocam_rounded),
                  label: Text(l10n.translate('join_meeting')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAgendaTab(BuildContext context, AppLocalizations l10n) {
    if (widget.meeting.agendaItems.isEmpty) {
      return _buildEmptyState(
        icon: Icons.list_alt_rounded,
        title: l10n.translate('no_agenda'),
        subtitle: l10n.translate('no_agenda_description'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.meeting.agendaItems.length,
      itemBuilder: (context, index) {
        final item = widget.meeting.agendaItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocumentsTab(BuildContext context, AppLocalizations l10n) {
    if (widget.meeting.documents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.folder_open_rounded,
        title: l10n.translate('no_documents'),
        subtitle: l10n.translate('no_documents_description'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.meeting.documents.length,
      itemBuilder: (context, index) {
        final doc = widget.meeting.documents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getDocumentColor(doc.fileType).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getDocumentIcon(doc.fileType),
                color: _getDocumentColor(doc.fileType),
                size: 24,
              ),
            ),
            title: Text(
              doc.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            subtitle: Text(
              doc.fileType?.toUpperCase() ?? 'FILE',
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: context.textSecondary,
              ),
              onPressed: () => _openDocument(context, doc),
            ),
            onTap: () => _openDocument(context, doc),
          ),
        );
      },
    );
  }

  Widget _buildParticipantsTab(BuildContext context, AppLocalizations l10n) {
    final canManageAttendance = ref.watch(canManageAttendanceProvider);
    final attendanceAsync = ref.watch(meetingAttendanceProvider(widget.meeting.id));
    final invitedUsersAsync = ref.watch(usersByIdsProvider(widget.meeting.attendeeIds));

    return Column(
      children: [
        // Add participant button for authorized users
        if (canManageAttendance)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAddParticipantDialog(context, l10n),
                icon: const Icon(Icons.person_add_rounded),
                label: Text(l10n.translate('add_participant')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        // Participants list
        Expanded(
          child: attendanceAsync.when(
            data: (attendees) {
              // Create a combined list: attendance records + invited users without attendance
              final attendeeUserIds = attendees.map((a) => a.userId).toSet();

              return invitedUsersAsync.when(
                data: (invitedUsers) {
                  // Filter invited users who don't have attendance records yet
                  final pendingInvites = invitedUsers
                      .where((u) => !attendeeUserIds.contains(u.id))
                      .toList();

                  if (attendees.isEmpty && pendingInvites.isEmpty) {
                    return _buildEmptyState(
                      icon: Icons.people_outline_rounded,
                      title: l10n.translate('no_participants'),
                      subtitle: l10n.translate('no_participants_description'),
                    );
                  }

                  return ListView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: canManageAttendance ? 0 : 16,
                      bottom: 16,
                    ),
                    children: [
                      // Attendance records (present/absent)
                      if (attendees.isNotEmpty) ...[
                        _buildSectionLabel(context, l10n.translate('attendance_recorded')),
                        const SizedBox(height: 8),
                        ...attendees.map((attendee) => _buildParticipantCard(context, attendee, canManageAttendance)),
                      ],
                      // Pending invites (no attendance yet)
                      if (pendingInvites.isNotEmpty) ...[
                        if (attendees.isNotEmpty) const SizedBox(height: 16),
                        _buildSectionLabel(context, l10n.translate('invited_pending')),
                        const SizedBox(height: 8),
                        ...pendingInvites.map((user) => _buildInvitedUserCard(context, user, canManageAttendance, l10n)),
                      ],
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: l10n.translate('error'),
                  subtitle: l10n.translate('error_loading_participants'),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildEmptyState(
              icon: Icons.error_outline_rounded,
              title: l10n.translate('error'),
              subtitle: l10n.translate('error_loading_participants'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.textSecondary,
      ),
    );
  }

  Widget _buildInvitedUserCard(BuildContext context, UserModel user, bool canManage, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.gold.withValues(alpha: 0.15),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 16,
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  user.schoolName ?? user.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (canManage) ...[
            // Mark as present button
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              tooltip: l10n.translate('mark_present'),
              onPressed: () => _markAttendance(user, AttendanceStatus.present),
            ),
            // Mark as absent button
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: Colors.red),
              tooltip: l10n.translate('mark_absent'),
              onPressed: () => _markAttendance(user, AttendanceStatus.absent),
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.translate('pending'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _markAttendance(UserModel user, AttendanceStatus status) async {
    final l10n = AppLocalizations.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await ref.read(meetingControllerProvider.notifier).addParticipant(
      meetingId: widget.meeting.id,
      oderId: user.id,
      userName: user.fullName,
      status: status,
    );

    // Close loading dialog
    if (mounted) Navigator.of(context).pop();

    if (mounted) {
      if (success) {
        ref.invalidate(meetingAttendanceProvider(widget.meeting.id));
        ref.invalidate(usersByIdsProvider(widget.meeting.attendeeIds));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == AttendanceStatus.present
              ? l10n.translate('marked_present')
              : l10n.translate('marked_absent')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('error_updating_attendance')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddParticipantDialog(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddParticipantSheet(
        meetingId: widget.meeting.id,
        existingParticipantIds: widget.meeting.attendeeIds,
        onParticipantAdded: () {
          ref.invalidate(meetingAttendanceProvider(widget.meeting.id));
          ref.invalidate(usersByIdsProvider(widget.meeting.attendeeIds));
        },
      ),
    );
  }

  Widget _buildParticipantCard(BuildContext context, MeetingAttendance attendee, bool canManage) {
    final statusColor = attendee.status.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.gold.withValues(alpha: 0.15),
            child: Text(
              attendee.userName.isNotEmpty ? attendee.userName[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 16,
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
                  attendee.userName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                if (attendee.checkInTime != null)
                  Text(
                    'Checked in at ${DateFormat('h:mm a').format(attendee.checkInTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              attendee.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.textSecondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  Color _getDocumentColor(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(MeetingType type) {
    switch (type) {
      case MeetingType.countyAG:
        return 'AG Judetean';
      case MeetingType.department:
        return 'Departament';
      case MeetingType.school:
        return 'Scoala';
      case MeetingType.bex:
        return 'BEx';
    }
  }

  Future<void> _joinMeeting(BuildContext context) async {
    final link = widget.meeting.onlineLink;
    if (link == null || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('no_meeting_link'))),
      );
      return;
    }

    final uri = Uri.parse(link);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final launchedInApp = await launchUrl(uri, mode: LaunchMode.inAppWebView);
        if (!launchedInApp && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_link'))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_link'))),
        );
      }
    }
  }

  Future<void> _openDocument(BuildContext context, MeetingDocument doc) async {
    final uri = Uri.parse(doc.url);
    try {
      // Try to launch the URL directly - Firebase Storage URLs work in browser
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback: try with inAppWebView mode
        final launchedInApp = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
        if (!launchedInApp && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_file'))),
          );
        }
      }
    } catch (e) {
      // If launching fails, try opening in app web view as fallback
      try {
        final launchedInApp = await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
        if (!launchedInApp && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_file'))),
          );
        }
      } catch (e2) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('cannot_open_file'))),
          );
        }
      }
    }
  }

  void _handleEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMeetingScreen(meeting: widget.meeting),
      ),
    );
  }

  void _handleDelete(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('delete_meeting')),
        content: Text(l10n.translate('delete_meeting_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final controller = ref.read(meetingControllerProvider.notifier);
              final success = await controller.deleteMeeting(widget.meeting.id);
              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.translate('meeting_deleted'))),
                );
              }
            },
            child: Text(
              l10n.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adding participants to a meeting
class _AddParticipantSheet extends ConsumerStatefulWidget {
  final String meetingId;
  final List<String> existingParticipantIds;
  final VoidCallback onParticipantAdded;

  const _AddParticipantSheet({
    required this.meetingId,
    required this.existingParticipantIds,
    required this.onParticipantAdded,
  });

  @override
  ConsumerState<_AddParticipantSheet> createState() => _AddParticipantSheetState();
}

class _AddParticipantSheetState extends ConsumerState<_AddParticipantSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isAdding = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final searchResults = ref.watch(searchUsersProvider(_searchQuery));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.translate('add_participant'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.translate('search_users'),
                hintStyle: TextStyle(color: context.textSecondary),
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                filled: true,
                fillColor: context.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Search results or county users
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildCountyUsersList(l10n)
                : searchResults.when(
                    data: (users) {
                      // Filter out existing participants
                      final availableUsers = users
                          .where((u) => !widget.existingParticipantIds.contains(u.id))
                          .toList();

                      if (availableUsers.isEmpty) {
                        return Center(
                          child: Text(
                            l10n.translate('no_users_found'),
                            style: TextStyle(color: context.textSecondary),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: availableUsers.length,
                        itemBuilder: (context, index) {
                          final user = availableUsers[index];
                          return _buildUserTile(user, l10n);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Text(
                        l10n.translate('error_searching_users'),
                        style: TextStyle(color: context.textSecondary),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountyUsersList(AppLocalizations l10n) {
    final countyUsers = ref.watch(countyUsersProvider);

    return countyUsers.when(
      data: (users) {
        // Filter out existing participants
        final availableUsers = users
            .where((u) => !widget.existingParticipantIds.contains(u.id))
            .toList();

        if (availableUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 48,
                  color: context.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.translate('no_available_users'),
                  style: TextStyle(color: context.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translate('all_users_already_added'),
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                l10n.translate('available_participants'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableUsers.length,
                itemBuilder: (context, index) {
                  final user = availableUsers[index];
                  return _buildUserTile(user, l10n);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: context.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('error_loading_users'),
              style: TextStyle(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(UserModel user, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.gold.withValues(alpha: 0.15),
          child: Text(
            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
        ),
        title: Text(
          user.fullName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        subtitle: Text(
          user.schoolName ?? user.email,
          style: TextStyle(color: context.textSecondary),
        ),
        trailing: _isAdding
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.gold),
                onPressed: () => _addParticipant(user, l10n),
              ),
      ),
    );
  }

  Future<void> _addParticipant(UserModel user, AppLocalizations l10n) async {
    setState(() => _isAdding = true);

    final success = await ref.read(meetingControllerProvider.notifier).addParticipant(
      meetingId: widget.meetingId,
      oderId: user.id,
      userName: user.fullName,
      status: AttendanceStatus.present,
    );

    setState(() => _isAdding = false);

    if (success && mounted) {
      widget.onParticipantAdded();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.fullName} ${l10n.translate('added_as_participant')}'),
          backgroundColor: Colors.green,
        ),
      );
      // Clear search
      _searchController.clear();
      setState(() => _searchQuery = '');
    }
  }
}
