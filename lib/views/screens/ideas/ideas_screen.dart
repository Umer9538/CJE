import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../initiatives/initiative_detail_screen.dart';
import '../initiatives/create_initiative_screen.dart';
import '../polls/poll_detail_screen.dart';
import '../polls/create_poll_screen.dart';

/// Provider to track selected idea type (initiatives or polls)
final selectedIdeaTypeProvider = StateProvider<IdeaType>((ref) => IdeaType.initiatives);

enum IdeaType { initiatives, polls }

/// Combined Ideas screen with Initiatives and Polls
class IdeasScreen extends ConsumerStatefulWidget {
  const IdeasScreen({super.key});

  @override
  ConsumerState<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends ConsumerState<IdeasScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Initiative filters
  InitiativeStatus? _selectedInitiativeStatus;
  bool _showOnlyMyInitiatives = false;
  String? _selectedSchoolId;
  bool _showAllSchools = false;
  bool _initiativeFilterInitialized = false;

  // Poll filters
  bool _pollActiveOnly = false;
  PollType? _selectedPollType;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedType = ref.watch(selectedIdeaTypeProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Initialize school filter for initiatives
    if (!_initiativeFilterInitialized && currentUser != null) {
      _initiativeFilterInitialized = true;
      if (currentUser.schoolId != null &&
          currentUser.role != UserRole.bex &&
          currentUser.role != UserRole.superadmin &&
          currentUser.role != UserRole.department) {
        _selectedSchoolId = currentUser.schoolId;
      }
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              _buildHeader(context, l10n),

              // Type Selector (Initiatives / Polls)
              _buildTypeSelector(context, l10n, selectedType),

              // Content based on selected type
              Expanded(
                child: selectedType == IdeaType.initiatives
                    ? _buildInitiativesContent(context, l10n, currentUser)
                    : _buildPollsContent(context, l10n),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context, l10n, selectedType),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final selectedType = ref.watch(selectedIdeaTypeProvider);
    final hasActiveFilters = selectedType == IdeaType.initiatives
        ? (_showOnlyMyInitiatives || (_selectedSchoolId != null && !_showAllSchools))
        : _pollActiveOnly;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Text(
            l10n.translate('ideas'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.goldColor,
            ),
          ),
          const Spacer(),
          _buildFilterButton(context, hasActiveFilters, selectedType),
        ],
      ),
    );
  }

  Widget _buildFilterButton(BuildContext context, bool hasActiveFilters, IdeaType selectedType) {
    return GestureDetector(
      onTap: () => selectedType == IdeaType.initiatives
          ? _showInitiativeFilterSheet()
          : _showPollFilterSheet(),
      child: Stack(
        children: [
          Container(
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
            child: Icon(Icons.filter_list_rounded, color: context.iconColor, size: 22),
          ),
          if (hasActiveFilters)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.goldColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(BuildContext context, AppLocalizations l10n, IdeaType selectedType) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      padding: const EdgeInsets.all(6),
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
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              icon: Icons.lightbulb_rounded,
              label: l10n.translate('initiatives'),
              isSelected: selectedType == IdeaType.initiatives,
              onTap: () => ref.read(selectedIdeaTypeProvider.notifier).state = IdeaType.initiatives,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TypeButton(
              icon: Icons.poll_rounded,
              label: l10n.translate('polls'),
              isSelected: selectedType == IdeaType.polls,
              onTap: () => ref.read(selectedIdeaTypeProvider.notifier).state = IdeaType.polls,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // INITIATIVES CONTENT
  // ============================================

  Widget _buildInitiativesContent(BuildContext context, AppLocalizations l10n, dynamic currentUser) {
    final effectiveSchoolId = _showAllSchools ? null : _selectedSchoolId;

    final initiativesAsync = ref.watch(
      initiativesProvider(InitiativeFilter(
        status: _selectedInitiativeStatus,
        authorId: _showOnlyMyInitiatives ? currentUser?.id : null,
        schoolId: effectiveSchoolId,
      )),
    );

    return Column(
      children: [
        // Status tabs
        _buildInitiativeStatusTabs(context, l10n),

        // List
        Expanded(
          child: initiativesAsync.when(
            data: (initiatives) => initiatives.isEmpty
                ? _buildEmptyState(
                    context,
                    l10n,
                    Icons.lightbulb_outline_rounded,
                    l10n.translate('no_initiatives'),
                    l10n.translate('no_initiatives_desc'),
                  )
                : _buildInitiativesList(initiatives),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
            error: (error, _) => _buildErrorState(context, l10n, () => ref.invalidate(initiativesProvider)),
          ),
        ),
      ],
    );
  }

  Widget _buildInitiativeStatusTabs(BuildContext context, AppLocalizations l10n) {
    final statuses = [
      (null, l10n.translate('all')),
      (InitiativeStatus.submitted, l10n.translate('submitted')),
      (InitiativeStatus.review, l10n.translate('review')),
      (InitiativeStatus.debate, l10n.translate('debate')),
      (InitiativeStatus.voting, l10n.translate('voting')),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final (status, label) = statuses[index];
          final isSelected = _selectedInitiativeStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedInitiativeStatus = status),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.goldColor.withValues(alpha: 0.2)
                      : context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: context.goldColor, width: 1.5)
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? context.goldColor : context.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInitiativesList(List<InitiativeModel> initiatives) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(initiativesProvider),
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: initiatives.length,
        itemBuilder: (context, index) {
          final initiative = initiatives[index];
          return _InitiativeCard(
            initiative: initiative,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InitiativeDetailScreen(initiative: initiative),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInitiativeFilterSheet() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ctx.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.translate('filter'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ctx.textPrimary,
                  ),
                ),
                if (_showOnlyMyInitiatives || (_selectedSchoolId != null && !_showAllSchools))
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showOnlyMyInitiatives = false;
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
            _FilterOption(
              icon: Icons.person_outline_rounded,
              title: l10n.translate('my_initiatives'),
              subtitle: l10n.translate('show_only_my_initiatives'),
              isSelected: _showOnlyMyInitiatives,
              onTap: () {
                setState(() => _showOnlyMyInitiatives = !_showOnlyMyInitiatives);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
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
                        _showAllSchools = true;
                      } else {
                        _selectedSchoolId = user?.schoolId;
                        _showAllSchools = false;
                      }
                    });
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

  // ============================================
  // POLLS CONTENT
  // ============================================

  Widget _buildPollsContent(BuildContext context, AppLocalizations l10n) {
    final pollsAsync = ref.watch(
      pollsProvider(PollFilter(type: _selectedPollType, activeOnly: _pollActiveOnly)),
    );

    return Column(
      children: [
        // Type tabs
        _buildPollTypeTabs(context, l10n),

        // Active only toggle
        _buildPollActiveToggle(context, l10n),

        // List
        Expanded(
          child: pollsAsync.when(
            data: (polls) => polls.isEmpty
                ? _buildEmptyState(
                    context,
                    l10n,
                    Icons.poll_outlined,
                    l10n.translate('no_polls'),
                    l10n.translate('no_polls_desc'),
                  )
                : _buildPollsList(polls),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
            error: (error, _) => _buildErrorState(context, l10n, () => ref.invalidate(pollsProvider)),
          ),
        ),
      ],
    );
  }

  Widget _buildPollTypeTabs(BuildContext context, AppLocalizations l10n) {
    final types = [
      (null, l10n.translate('all')),
      (PollType.county, l10n.translate('county')),
      (PollType.school, l10n.translate('school')),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final (type, label) = types[index];
          final isSelected = _selectedPollType == type;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPollType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.goldColor.withValues(alpha: 0.2)
                      : context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: context.goldColor, width: 1.5)
                      : null,
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? context.goldColor : context.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPollActiveToggle(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          Text(
            l10n.translate('active_only'),
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _pollActiveOnly = !_pollActiveOnly),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _pollActiveOnly ? AppColors.navy : Colors.grey.withValues(alpha: 0.3),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _pollActiveOnly ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _pollActiveOnly ? AppColors.gold : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollsList(List<PollModel> polls) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(pollsProvider),
      color: AppColors.gold,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: polls.length,
        itemBuilder: (context, index) {
          final poll = polls[index];
          return _PollCard(
            poll: poll,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PollDetailScreen(poll: poll),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPollFilterSheet() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ctx.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.translate('filter'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ctx.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _FilterOption(
              icon: Icons.check_circle_outline_rounded,
              title: l10n.translate('active_only'),
              subtitle: l10n.translate('show_active_polls_only'),
              isSelected: _pollActiveOnly,
              onTap: () {
                setState(() => _pollActiveOnly = !_pollActiveOnly);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SHARED WIDGETS
  // ============================================

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    IconData icon,
    String title,
    String subtitle,
  ) {
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
            child: Icon(icon, size: 48, color: context.goldColor),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.goldColor,
            ),
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
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: context.errorColor),
          const SizedBox(height: 16),
          Text(
            l10n.translate('error_loading'),
            style: TextStyle(color: context.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
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

  Widget? _buildFAB(BuildContext context, AppLocalizations l10n, IdeaType selectedType) {
    final canCreateInitiative = ref.watch(canDraftInitiativesProvider);
    final canCreatePoll = ref.watch(canCreatePollsProvider);

    final canCreate = selectedType == IdeaType.initiatives ? canCreateInitiative : canCreatePoll;

    if (!canCreate) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 100),
      child: FloatingActionButton.extended(
        heroTag: 'fab_ideas',
        onPressed: () {
          if (selectedType == IdeaType.initiatives) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateInitiativeScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreatePollScreen()),
            );
          }
        },
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.navy,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.translate('create')),
      ),
    );
  }
}

// ============================================
// HELPER WIDGETS
// ============================================

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.navy : context.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.navy : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
          color: isSelected
              ? context.goldColor.withValues(alpha: 0.1)
              : context.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? context.goldColor : context.textSecondary.withValues(alpha: 0.3),
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
                    ? context.goldColor.withValues(alpha: 0.2)
                    : context.textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? context.goldColor : context.textSecondary,
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
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: context.goldColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// INITIATIVE CARD
// ============================================

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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _InitiativeStatusBadge(status: initiative.status),
                  const Spacer(),
                  Text(
                    dateFormat.format(initiative.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                initiative.title,
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
              Text(
                initiative.description,
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondary,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: context.goldColor.withValues(alpha: 0.1),
                    child: Text(
                      initiative.authorName.isNotEmpty
                          ? initiative.authorName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: context.goldColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      initiative.authorName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.goldColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_rounded, size: 14, color: context.goldColor),
                        const SizedBox(width: 4),
                        Text(
                          '${initiative.supportCount}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.goldColor,
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

class _InitiativeStatusBadge extends StatelessWidget {
  final InitiativeStatus status;

  const _InitiativeStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
            _getStatusLabel(status, l10n),
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

  String _getStatusLabel(InitiativeStatus status, AppLocalizations l10n) {
    switch (status) {
      case InitiativeStatus.draft:
        return l10n.translate('draft');
      case InitiativeStatus.submitted:
        return l10n.translate('submitted');
      case InitiativeStatus.review:
        return l10n.translate('in_review');
      case InitiativeStatus.debate:
        return l10n.translate('in_debate');
      case InitiativeStatus.voting:
        return l10n.translate('voting');
      case InitiativeStatus.adopted:
        return l10n.translate('adopted');
      case InitiativeStatus.rejected:
        return l10n.translate('rejected');
    }
  }
}

// ============================================
// POLL CARD
// ============================================

class _PollCard extends StatelessWidget {
  final PollModel poll;
  final VoidCallback onTap;

  const _PollCard({
    required this.poll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');
    final isActive = poll.isActive;
    final hasEnded = poll.hasEnded;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: context.goldColor.withValues(alpha: 0.5), width: 2)
              : null,
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
            Row(
              children: [
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : context.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive
                              ? l10n.translate('active')
                              : (hasEnded ? l10n.translate('ended') : l10n.translate('upcoming')),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.green : context.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.goldColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l10n.translate(poll.type.translationKey),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: context.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              poll.question,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.how_to_vote_rounded, size: 16, color: context.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${poll.totalVotes} ${l10n.translate('votes')}',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.format_list_bulleted_rounded, size: 16, color: context.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${poll.options.length} ${l10n.translate('options')}',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
                Text(
                  hasEnded
                      ? '${l10n.translate('ended')} ${dateFormat.format(poll.endDate)}'
                      : '${l10n.translate('ends')} ${dateFormat.format(poll.endDate)}',
                  style: TextStyle(fontSize: 11, color: context.textSecondary),
                ),
              ],
            ),
            if (isActive && poll.totalVotes > 0) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _getLeadingPercentage(),
                  backgroundColor: context.textSecondary.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(context.goldColor),
                  minHeight: 4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double _getLeadingPercentage() {
    if (poll.options.isEmpty || poll.totalVotes == 0) return 0;
    final maxVotes = poll.options.map((o) => o.voteCount).reduce((a, b) => a > b ? a : b);
    return maxVotes / poll.totalVotes;
  }
}
