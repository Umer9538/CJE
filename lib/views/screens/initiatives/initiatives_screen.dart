import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import 'initiative_detail_screen.dart';
import 'create_initiative_screen.dart';

/// Main initiatives list screen
class InitiativesScreen extends ConsumerStatefulWidget {
  const InitiativesScreen({super.key});

  @override
  ConsumerState<InitiativesScreen> createState() => _InitiativesScreenState();
}

class _InitiativesScreenState extends ConsumerState<InitiativesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  InitiativeStatus? _selectedStatus;
  bool _showOnlyMine = false;
  String? _selectedSchoolId;
  bool _showAllSchools = false; // Toggle to see all schools' initiatives
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedStatus = null; // All
            break;
          case 1:
            _selectedStatus = InitiativeStatus.submitted;
            break;
          case 2:
            _selectedStatus = InitiativeStatus.review;
            break;
          case 3:
            _selectedStatus = InitiativeStatus.debate;
            break;
          case 4:
            _selectedStatus = InitiativeStatus.voting;
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
    final currentUser = ref.watch(currentUserProvider);

    // Auto-set school filter on first build for school-level users
    // Students, classReps, and schoolReps see their school's initiatives by default
    if (!_initialized && currentUser != null) {
      _initialized = true;
      if (currentUser.schoolId != null &&
          currentUser.role != UserRole.bex &&
          currentUser.role != UserRole.superadmin &&
          currentUser.role != UserRole.department) {
        _selectedSchoolId = currentUser.schoolId;
      }
    }

    // Determine the effective school filter
    final effectiveSchoolId = _showAllSchools ? null : _selectedSchoolId;

    final initiativesAsync = ref.watch(
      initiativesProvider(InitiativeFilter(
        status: _selectedStatus,
        authorId: _showOnlyMine ? currentUser?.id : null,
        schoolId: effectiveSchoolId,
      )),
    );

    // Use the provider for permission check
    final canCreate = ref.watch(canDraftInitiativesProvider);
    final hasActiveFilters = _showOnlyMine || (_selectedSchoolId != null && !_showAllSchools);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, l10n, hasActiveFilters),

            // Tabs
            _buildTabs(context, l10n),

            // Content
            Expanded(
              child: initiativesAsync.when(
                data: (initiatives) => initiatives.isEmpty
                    ? _buildEmptyState(context, l10n)
                    : _buildInitiativesList(initiatives),
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
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.extended(
                heroTag: 'fab_initiatives',
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

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, bool hasActiveFilters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            l10n.translate('initiatives'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const Spacer(),
          _buildFilterButton(hasActiveFilters),
        ],
      ),
    );
  }

  Widget _buildFilterButton(bool hasActiveFilters) {
    return GestureDetector(
      onTap: _showFilterBottomSheet,
      child: Stack(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.filter_list_rounded, color: AppColors.navy, size: 22),
          ),
          if (hasActiveFilters)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.gold,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('filter'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy,
                  ),
                ),
                if (_showOnlyMine || (_selectedSchoolId != null && !_showAllSchools))
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showOnlyMine = false;
                        _showAllSchools = true;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      l10n.translate('clear_all'),
                      style: const TextStyle(color: AppColors.gold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Show only my initiatives
            _FilterOption(
              icon: Icons.person_outline_rounded,
              title: l10n.translate('my_initiatives'),
              subtitle: l10n.translate('show_only_my_initiatives'),
              isSelected: _showOnlyMine,
              onTap: () {
                setState(() => _showOnlyMine = !_showOnlyMine);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),

            // My School filter (for users with schoolId)
            Consumer(
              builder: (context, ref, _) {
                final user = ref.watch(currentUserProvider);
                if (user?.schoolId == null) return const SizedBox.shrink();

                return _FilterOption(
                  icon: Icons.school_outlined,
                  title: l10n.translate('my_school'),
                  subtitle: user?.schoolName ?? l10n.translate('show_school_initiatives'),
                  isSelected: _selectedSchoolId == user?.schoolId && !_showAllSchools,
                  onTap: () {
                    setState(() {
                      if (_selectedSchoolId == user?.schoolId && !_showAllSchools) {
                        // If already filtered by my school, show all
                        _showAllSchools = true;
                      } else {
                        // Filter by my school
                        _selectedSchoolId = user?.schoolId;
                        _showAllSchools = false;
                      }
                    });
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Show all schools option (only if user has school filter applied)
            Consumer(
              builder: (context, ref, _) {
                final user = ref.watch(currentUserProvider);
                if (user?.schoolId == null) return const SizedBox.shrink();

                return _FilterOption(
                  icon: Icons.public_rounded,
                  title: l10n.translate('all_schools'),
                  subtitle: l10n.translate('show_all_initiatives'),
                  isSelected: _showAllSchools,
                  onTap: () {
                    setState(() => _showAllSchools = !_showAllSchools);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.navy,
        unselectedLabelColor: Colors.grey[400],
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: [
          Tab(text: l10n.translate('all')),
          Tab(text: l10n.translate('submitted')),
          Tab(text: l10n.translate('review')),
          Tab(text: l10n.translate('debate')),
          Tab(text: l10n.translate('voting')),
        ],
      ),
    );
  }

  Widget _buildInitiativesList(List<InitiativeModel> initiatives) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(initiativesProvider);
      },
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: initiatives.length,
        itemBuilder: (context, index) {
          final initiative = initiatives[index];
          return _InitiativeCard(
            initiative: initiative,
            onTap: () => _navigateToDetail(context, initiative),
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
              color: AppColors.gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 48,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.translate('no_initiatives'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to propose an initiative!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load initiatives',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(initiativesProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, InitiativeModel initiative) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InitiativeDetailScreen(initiative: initiative),
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateInitiativeScreen(),
      ),
    );
  }
}

/// Initiative card widget
class _InitiativeCard extends StatelessWidget {
  final InitiativeModel initiative;
  final VoidCallback onTap;

  const _InitiativeCard({
    required this.initiative,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge and date
              Row(
                children: [
                  _StatusBadge(status: initiative.status),
                  const Spacer(),
                  Text(
                    dateFormat.format(initiative.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                initiative.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description preview
              Text(
                initiative.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Tags
              if (initiative.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: initiative.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.navy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.navy,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Author and support count
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                    child: Text(
                      initiative.authorName.isNotEmpty
                          ? initiative.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          initiative.authorName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (initiative.schoolName != null)
                          Text(
                            initiative.schoolName!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${initiative.supportCount}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status badge widget
class _StatusBadge extends StatelessWidget {
  final InitiativeStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(status),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _getStatusColor(status),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(InitiativeStatus status) {
    switch (status) {
      case InitiativeStatus.draft:
        return Colors.grey;
      case InitiativeStatus.submitted:
        return Colors.blue;
      case InitiativeStatus.review:
        return Colors.orange;
      case InitiativeStatus.debate:
        return Colors.purple;
      case InitiativeStatus.voting:
        return Colors.green;
      case InitiativeStatus.adopted:
        return AppColors.gold;
      case InitiativeStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusLabel(InitiativeStatus status) {
    switch (status) {
      case InitiativeStatus.draft:
        return 'Draft';
      case InitiativeStatus.submitted:
        return 'Submitted';
      case InitiativeStatus.review:
        return 'In Review';
      case InitiativeStatus.debate:
        return 'In Debate';
      case InitiativeStatus.voting:
        return 'Voting';
      case InitiativeStatus.adopted:
        return 'Adopted';
      case InitiativeStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Filter option widget for bottom sheet
class _FilterOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.gold : Colors.grey[600],
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.navy : Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.gold,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
