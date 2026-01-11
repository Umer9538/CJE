import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../../../routes/route_names.dart';
import 'announcement_detail_screen.dart';
import 'create_announcement_screen.dart';

/// Main announcements list screen
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AnnouncementType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedFilter = null; // All
            break;
          case 1:
            _selectedFilter = AnnouncementType.county; // CJE
            break;
          case 2:
            _selectedFilter = AnnouncementType.school; // School
            break;
        }
      });
    });
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
    final announcementsAsync = ref.watch(
      announcementsProvider(AnnouncementFilter(type: _selectedFilter)),
    );

    // Check if user can create announcements
    final canCreate = user != null &&
        (user.role == UserRole.schoolRep ||
            user.role == UserRole.bex ||
            user.role == UserRole.superadmin);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, l10n),

            // Tabs
            _buildTabs(context, l10n),

            // Content
            Expanded(
              child: announcementsAsync.when(
                data: (announcements) => announcements.isEmpty
                    ? _buildEmptyState(context, l10n)
                    : _buildAnnouncementsList(announcements),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (error, _) => _buildErrorState(context, l10n, error),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canCreate
          ? Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: FloatingActionButton.extended(
                heroTag: 'fab_announcements',
                onPressed: () => _navigateToCreate(context),
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
                icon: const Icon(Icons.add_rounded),
                label: Text(l10n.translate('create')),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final currentUser = ref.watch(currentUserProvider);
    final String backRoute = currentUser?.role == UserRole.bex
        ? RouteNames.bexDashboard
        : RouteNames.home;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(backRoute);
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: context.shadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(Icons.arrow_back_rounded, color: context.iconColor, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            l10n.translate('announcements'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.goldColor,
            ),
          ),
          const Spacer(),
          _buildIconButton(
            context: context,
            icon: Icons.search_rounded,
            onTap: () => context.push(RouteNames.search),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({required BuildContext context, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: context.iconColor, size: 22),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
      child: TabBar(
        controller: _tabController,
        labelColor: context.textPrimary,
        unselectedLabelColor: context.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: context.goldColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: [
          Tab(text: l10n.translate('all')),
          Tab(text: l10n.translate('county')),
          Tab(text: l10n.translate('school')),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList(List<AnnouncementModel> announcements) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(announcementsProvider);
      },
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: announcements.length,
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          return _AnnouncementCard(
            announcement: announcement,
            onTap: () => _navigateToDetail(context, announcement),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: context.goldColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.campaign_outlined,
              size: 48,
              color: context.goldColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.translate('no_announcements'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.translate('check_back_later'),
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: context.errorColor),
          const SizedBox(height: 16),
          Text(
            l10n.translate('failed_to_load_announcements'),
            style: TextStyle(color: context.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(announcementsProvider),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.translate('retry')),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.goldColor,
              foregroundColor: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, AnnouncementModel announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnnouncementDetailScreen(announcement: announcement),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateAnnouncementScreen(),
      ),
    );
  }
}

/// Announcement card widget
class _AnnouncementCard extends StatelessWidget {
  final AnnouncementModel announcement;
  final VoidCallback onTap;

  const _AnnouncementCard({
    required this.announcement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final isCounty = announcement.type == AnnouncementType.county;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (announcement.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  announcement.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: context.textSecondary.withValues(alpha: 0.1),
                    child: Center(
                      child: Icon(Icons.image_not_supported_outlined, size: 40, color: context.textSecondary),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge and date
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCounty
                                ? context.goldColor.withValues(alpha: 0.15)
                                : context.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCounty ? l10n.translate('county') : announcement.schoolName ?? l10n.translate('school'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isCounty ? context.goldColor : context.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (announcement.isPinned) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.push_pin_rounded, size: 14, color: context.textSecondary),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        dateFormat.format(announcement.publishedAt ?? announcement.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title (with translation support)
                  Text(
                    announcement.getTitle(Localizations.localeOf(context).languageCode),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Preview text (with translation support)
                  Text(
                    _getPreviewText(announcement, Localizations.localeOf(context).languageCode),
                    style: TextStyle(
                      fontSize: 14,
                      color: context.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),

                  // Author and views
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: context.goldColor.withValues(alpha: 0.1),
                        backgroundImage: announcement.authorPhotoUrl != null
                            ? NetworkImage(announcement.authorPhotoUrl!)
                            : null,
                        child: announcement.authorPhotoUrl == null
                            ? Text(
                                announcement.authorName.isNotEmpty
                                    ? announcement.authorName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: context.goldColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          announcement.authorName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.visibility_outlined, size: 14, color: context.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${announcement.viewCount}',
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

  /// Get preview text in the specified language
  String _getPreviewText(AnnouncementModel announcement, String languageCode) {
    final summary = announcement.getSummary(languageCode);
    if (summary != null && summary.isNotEmpty) return summary;

    final content = announcement.getContent(languageCode);
    if (content.length <= 150) return content;
    return '${content.substring(0, 150)}...';
  }
}
