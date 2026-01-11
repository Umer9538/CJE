import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../routes/route_names.dart';

/// Search result type
enum SearchResultType {
  announcement,
  meeting,
  initiative,
  poll,
  document,
  user,
}

/// Search result model
class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final DateTime? date;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.date,
  });
}

/// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Helper function to check if any tag matches the query
bool _tagsMatch(List<String> tags, String query) {
  return tags.any((tag) => tag.toLowerCase().contains(query));
}

/// Search results provider - MVP: Title and Tags only
final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  if (query.isEmpty || query.length < 2) return [];

  final results = <SearchResult>[];

  // Search announcements by title and tags
  try {
    final announcementsAsync = await ref.read(
      announcementsProvider(const AnnouncementFilter(limit: 100)).future,
    );
    for (final announcement in announcementsAsync) {
      if (announcement.title.toLowerCase().contains(query) ||
          _tagsMatch(announcement.tags, query)) {
        results.add(SearchResult(
          id: announcement.id,
          title: announcement.title,
          subtitle: announcement.authorName,
          type: SearchResultType.announcement,
          date: announcement.createdAt,
        ));
      }
    }
  } catch (_) {}

  // Search meetings by title only (no tags field)
  try {
    final meetingsAsync = await ref.read(
      meetingsProvider(const MeetingFilter(limit: 100)).future,
    );
    for (final meeting in meetingsAsync) {
      if (meeting.title.toLowerCase().contains(query)) {
        results.add(SearchResult(
          id: meeting.id,
          title: meeting.title,
          subtitle: meeting.type.displayName,
          type: SearchResultType.meeting,
          date: meeting.dateTime,
        ));
      }
    }
  } catch (_) {}

  // Search initiatives by title and tags
  try {
    final initiativesAsync = await ref.read(
      initiativesProvider(const InitiativeFilter(limit: 100)).future,
    );
    for (final initiative in initiativesAsync) {
      if (initiative.title.toLowerCase().contains(query) ||
          _tagsMatch(initiative.tags, query)) {
        results.add(SearchResult(
          id: initiative.id,
          title: initiative.title,
          subtitle: initiative.authorName,
          type: SearchResultType.initiative,
          date: initiative.createdAt,
        ));
      }
    }
  } catch (_) {}

  // Search polls by title only (no tags field)
  try {
    final pollsAsync = await ref.read(
      pollsProvider(const PollFilter(limit: 100)).future,
    );
    for (final poll in pollsAsync) {
      if (poll.question.toLowerCase().contains(query)) {
        results.add(SearchResult(
          id: poll.id,
          title: poll.question,
          subtitle: poll.createdByName,
          type: SearchResultType.poll,
          date: poll.createdAt,
        ));
      }
    }
  } catch (_) {}

  // Search documents by title and tags
  try {
    final documentsAsync = await ref.read(
      documentsProvider(const DocumentFilter(limit: 100)).future,
    );
    for (final document in documentsAsync) {
      if (document.title.toLowerCase().contains(query) ||
          _tagsMatch(document.tags, query)) {
        results.add(SearchResult(
          id: document.id,
          title: document.title,
          subtitle: document.category.displayName,
          type: SearchResultType.document,
          date: document.createdAt,
        ));
      }
    }
  } catch (_) {}

  // Sort by date (most recent first)
  results.sort((a, b) {
    if (a.date == null && b.date == null) return 0;
    if (a.date == null) return 1;
    if (b.date == null) return -1;
    return b.date!.compareTo(a.date!);
  });

  return results;
});

/// Global search screen
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(searchQueryProvider);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            onChanged: (value) {
              ref.read(searchQueryProvider.notifier).state = value;
            },
            style: const TextStyle(color: AppColors.navy, fontSize: 16),
            cursorColor: AppColors.navy,
            decoration: InputDecoration(
              hintText: l10n.translate('search_placeholder'),
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            textInputAction: TextInputAction.search,
          ),
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? _buildInitialState(context, l10n)
          : query.length < 2
              ? _buildMinLengthState(context, l10n)
              : resultsAsync.when(
                  data: (results) => results.isEmpty
                      ? _buildEmptyState(context, l10n, query)
                      : _buildResultsList(context, l10n, results),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.gold),
                  ),
                  error: (error, _) => _buildErrorState(context, l10n),
                ),
    );
  }

  Widget _buildInitialState(BuildContext context, AppLocalizations l10n) {
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
                Icons.search_rounded,
                size: 48,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('search_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.translate('search_description'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),
            _buildSearchCategories(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCategories(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildCategoryChip(
          icon: Icons.campaign_rounded,
          label: l10n.translate('announcements'),
          color: const Color(0xFF10B981),
        ),
        _buildCategoryChip(
          icon: Icons.event_rounded,
          label: l10n.translate('meetings'),
          color: const Color(0xFF3B82F6),
        ),
        _buildCategoryChip(
          icon: Icons.lightbulb_rounded,
          label: l10n.translate('initiatives'),
          color: const Color(0xFFF59E0B),
        ),
        _buildCategoryChip(
          icon: Icons.poll_rounded,
          label: l10n.translate('polls'),
          color: const Color(0xFF8B5CF6),
        ),
        _buildCategoryChip(
          icon: Icons.folder_rounded,
          label: l10n.translate('documents'),
          color: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinLengthState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l10n.translate('search_min_length'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.goldColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.translate('no_results'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.translate('no_results_for')} "$query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              l10n.translate('error_loading'),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(BuildContext context, AppLocalizations l10n, List<SearchResult> results) {
    // Group results by type
    final grouped = <SearchResultType, List<SearchResult>>{};
    for (final result in results) {
      grouped.putIfAbsent(result.type, () => []).add(result);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            '${results.length} ${l10n.translate('results_found')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Results by type
        for (final type in grouped.keys) ...[
          _buildTypeHeader(context, l10n, type, grouped[type]!.length),
          ...grouped[type]!.map((result) => _SearchResultCard(
                result: result,
                onTap: () => _navigateToResult(result),
              )),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildTypeHeader(BuildContext context, AppLocalizations l10n, SearchResultType type, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            _getTypeIcon(type),
            size: 18,
            color: _getTypeColor(type),
          ),
          const SizedBox(width: 8),
          Text(
            _getTypeName(l10n, type),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getTypeColor(type),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getTypeColor(type).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getTypeColor(type),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToResult(SearchResult result) {
    switch (result.type) {
      case SearchResultType.announcement:
        context.push(RouteNames.announcementDetailPath(result.id));
        break;
      case SearchResultType.meeting:
        context.push(RouteNames.meetingDetailPath(result.id));
        break;
      case SearchResultType.initiative:
        context.push(RouteNames.initiativeDetailPath(result.id));
        break;
      case SearchResultType.poll:
        context.push(RouteNames.pollDetailPath(result.id));
        break;
      case SearchResultType.document:
        // Documents open directly, no detail route
        context.go(RouteNames.documents);
        break;
      case SearchResultType.user:
        // Users go to admin detail
        context.push(RouteNames.adminUserDetailPath(result.id));
        break;
    }
  }

  IconData _getTypeIcon(SearchResultType type) {
    switch (type) {
      case SearchResultType.announcement:
        return Icons.campaign_rounded;
      case SearchResultType.meeting:
        return Icons.event_rounded;
      case SearchResultType.initiative:
        return Icons.lightbulb_rounded;
      case SearchResultType.poll:
        return Icons.poll_rounded;
      case SearchResultType.document:
        return Icons.folder_rounded;
      case SearchResultType.user:
        return Icons.person_rounded;
    }
  }

  Color _getTypeColor(SearchResultType type) {
    switch (type) {
      case SearchResultType.announcement:
        return const Color(0xFF10B981);
      case SearchResultType.meeting:
        return const Color(0xFF3B82F6);
      case SearchResultType.initiative:
        return const Color(0xFFF59E0B);
      case SearchResultType.poll:
        return const Color(0xFF8B5CF6);
      case SearchResultType.document:
        return const Color(0xFFEF4444);
      case SearchResultType.user:
        return const Color(0xFF6B7280); // Grey for users - visible in both themes
    }
  }

  String _getTypeName(AppLocalizations l10n, SearchResultType type) {
    switch (type) {
      case SearchResultType.announcement:
        return l10n.translate('announcements');
      case SearchResultType.meeting:
        return l10n.translate('meetings');
      case SearchResultType.initiative:
        return l10n.translate('initiatives');
      case SearchResultType.poll:
        return l10n.translate('polls');
      case SearchResultType.document:
        return l10n.translate('documents');
      case SearchResultType.user:
        return l10n.translate('users');
    }
  }
}

class _SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const _SearchResultCard({
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
