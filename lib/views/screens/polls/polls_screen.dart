import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';
import '../../../routes/route_names.dart';
import 'poll_detail_screen.dart';
import 'create_poll_screen.dart';

/// Main polls list screen
/// Students can VIEW and VOTE on polls but CANNOT create them
class PollsScreen extends ConsumerStatefulWidget {
  const PollsScreen({super.key});

  @override
  ConsumerState<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends ConsumerState<PollsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _activeOnly = false;

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

  PollType? get _selectedType {
    switch (_tabController.index) {
      case 0:
        return null; // All
      case 1:
        return PollType.county;
      case 2:
        return PollType.school;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pollsAsync = ref.watch(
      pollsProvider(PollFilter(type: _selectedType, activeOnly: _activeOnly)),
    );

    // Use the provider for permission check
    final canCreate = ref.watch(canCreatePollsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context, l10n),

            // Filter toggle
            _buildFilterToggle(context, l10n),

            // Tabs
            _buildTabs(context, l10n),

            // Content
            Expanded(
              child: pollsAsync.when(
                data: (polls) => polls.isEmpty
                    ? _buildEmptyState(context, l10n)
                    : _buildPollsList(polls),
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
                heroTag: 'fab_polls',
                onPressed: () => _navigateToCreatePoll(context),
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
          // Back button - navigate to home or BEX dashboard
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
            l10n.translate('polls'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.goldColor,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFilterToggle(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
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
          Switch(
            value: _activeOnly,
            onChanged: (value) => setState(() => _activeOnly = value),
            activeTrackColor: context.goldColor,
            thumbColor: WidgetStateProperty.all(Colors.white),
          ),
        ],
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
        onTap: (_) => setState(() {}),
        labelColor: context.textPrimary,
        unselectedLabelColor: context.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicator: BoxDecoration(
          color: context.goldColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        padding: const EdgeInsets.all(6),
        tabs: [
          Tab(text: l10n.translate('all')),
          Tab(text: l10n.translate('county')),
          Tab(text: l10n.translate('school')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                Icons.poll_outlined,
                size: 48,
                color: context.goldColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('no_polls'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('no_polls_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: context.errorColor),
            const SizedBox(height: 16),
            Text(
              l10n.translate('error_loading'),
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(pollsProvider),
              child: Text(l10n.translate('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollsList(List<PollModel> polls) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
    );
  }

  void _navigateToCreatePoll(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreatePollScreen()),
    );
  }
}

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
            // Header row
            Row(
              children: [
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : context.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? l10n.translate('active') : (hasEnded ? l10n.translate('ended') : l10n.translate('upcoming')),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.green : context.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
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

            // Question (with translation support)
            Text(
              poll.getQuestion(Localizations.localeOf(context).languageCode),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (poll.description != null && poll.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                poll.getDescription(Localizations.localeOf(context).languageCode) ?? '',
                style: TextStyle(
                  fontSize: 13,
                  color: context.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 14),

            // Stats row
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.how_to_vote_rounded,
                      size: 16,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${poll.totalVotes} ${l10n.translate('votes')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.format_list_bulleted_rounded,
                      size: 16,
                      color: context.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${poll.options.length} ${l10n.translate('options')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  hasEnded
                      ? '${l10n.translate('ended')} ${dateFormat.format(poll.endDate)}'
                      : '${l10n.translate('ends')} ${dateFormat.format(poll.endDate)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),

            // Progress bar showing voting progress (if active)
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
