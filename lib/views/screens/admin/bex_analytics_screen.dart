import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/models.dart';

/// BEX Analytics Dashboard for viewing initiative and poll statistics
class BexAnalyticsScreen extends ConsumerWidget {
  const BexAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('analytics'),
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Initiative Stats Section
          _buildSectionHeader(l10n.translate('initiative_statistics'), Icons.lightbulb_outline, context),
          const SizedBox(height: 16),
          const _InitiativeStatsCard(),
          const SizedBox(height: 24),

          // Initiative Status Breakdown
          _buildSectionHeader(l10n.translate('status_breakdown'), Icons.pie_chart_outline, context),
          const SizedBox(height: 16),
          const _InitiativeStatusBreakdown(),
          const SizedBox(height: 24),

          // Poll Stats Section
          _buildSectionHeader(l10n.translate('poll_statistics'), Icons.poll_outlined, context),
          const SizedBox(height: 16),
          const _PollStatsCard(),
          const SizedBox(height: 24),

          // Recent Activity
          _buildSectionHeader(l10n.translate('recent_activity'), Icons.history, context),
          const SizedBox(height: 16),
          const _RecentActivityCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.textPrimary, size: 22),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _InitiativeStatsCard extends ConsumerWidget {
  const _InitiativeStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final initiativesAsync = ref.watch(
      initiativesProvider(const InitiativeFilter(limit: 100)),
    );

    return initiativesAsync.when(
      data: (initiatives) {
        final total = initiatives.length;
        final adopted = initiatives.where((i) => i.status == InitiativeStatus.adopted).length;
        final rejected = initiatives.where((i) => i.status == InitiativeStatus.rejected).length;
        final inProgress = initiatives.where((i) =>
          i.status == InitiativeStatus.submitted ||
          i.status == InitiativeStatus.review ||
          i.status == InitiativeStatus.debate ||
          i.status == InitiativeStatus.voting
        ).length;
        final drafts = initiatives.where((i) => i.status == InitiativeStatus.draft).length;

        return Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Row(
                children: [
                  _StatItem(
                    value: total.toString(),
                    label: l10n.translate('total'),
                    color: context.textPrimary,
                  ),
                  _StatItem(
                    value: adopted.toString(),
                    label: l10n.translate('adopted'),
                    color: Colors.green,
                  ),
                  _StatItem(
                    value: rejected.toString(),
                    label: l10n.translate('rejected'),
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatItem(
                    value: inProgress.toString(),
                    label: l10n.translate('in_progress'),
                    color: Colors.orange,
                  ),
                  _StatItem(
                    value: drafts.toString(),
                    label: l10n.translate('drafts'),
                    color: Colors.grey,
                  ),
                  _StatItem(
                    value: total > 0 ? '${((adopted / total) * 100).toStringAsFixed(0)}%' : '0%',
                    label: l10n.translate('adoption_rate'),
                    color: AppColors.gold,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingCard(context),
      error: (_, __) => _buildErrorCard(l10n, context),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );
  }

  Widget _buildErrorCard(AppLocalizations l10n, BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(child: Text(l10n.translate('error_loading'))),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Builder(
            builder: (context) => Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _InitiativeStatusBreakdown extends ConsumerWidget {
  const _InitiativeStatusBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final initiativesAsync = ref.watch(
      initiativesProvider(const InitiativeFilter(limit: 100)),
    );

    return initiativesAsync.when(
      data: (initiatives) {
        final statusCounts = <InitiativeStatus, int>{};
        for (final i in initiatives) {
          statusCounts[i.status] = (statusCounts[i.status] ?? 0) + 1;
        }
        final total = initiatives.length;

        return Container(
          padding: const EdgeInsets.all(20),
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
            children: InitiativeStatus.values.map((status) {
              final count = statusCounts[status] ?? 0;
              final percentage = total > 0 ? count / total : 0.0;
              return _StatusBar(
                label: _getStatusLabel(status, l10n),
                count: count,
                percentage: percentage,
                color: _getStatusColor(status),
              );
            }).toList(),
          ),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Text(l10n.translate('error_loading'))),
      ),
    );
  }

  String _getStatusLabel(InitiativeStatus status, AppLocalizations l10n) {
    switch (status) {
      case InitiativeStatus.draft:
        return l10n.translate('draft');
      case InitiativeStatus.submitted:
        return l10n.translate('submitted');
      case InitiativeStatus.review:
        return l10n.translate('review');
      case InitiativeStatus.debate:
        return l10n.translate('debate');
      case InitiativeStatus.voting:
        return l10n.translate('voting');
      case InitiativeStatus.adopted:
        return l10n.translate('adopted');
      case InitiativeStatus.rejected:
        return l10n.translate('rejected');
    }
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
        return AppColors.gold;
      case InitiativeStatus.adopted:
        return Colors.green;
      case InitiativeStatus.rejected:
        return Colors.red;
    }
  }
}

class _StatusBar extends StatelessWidget {
  final String label;
  final int count;
  final double percentage;
  final Color color;

  const _StatusBar({
    required this.label,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.textSecondary,
                  ),
                ),
              ),
              Text(
                '$count (${(percentage * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: context.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PollStatsCard extends ConsumerWidget {
  const _PollStatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pollsAsync = ref.watch(
      pollsProvider(const PollFilter(limit: 100)),
    );

    return pollsAsync.when(
      data: (polls) {
        final total = polls.length;
        final active = polls.where((p) => p.isActive).length;
        final ended = polls.where((p) => p.hasEnded).length;
        final countyPolls = polls.where((p) => p.type == PollType.county).length;
        final schoolPolls = polls.where((p) => p.type == PollType.school).length;
        final totalVotes = polls.fold<int>(0, (sum, p) => sum + p.totalVotes);

        return Container(
          padding: const EdgeInsets.all(20),
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
            children: [
              Row(
                children: [
                  _StatItem(
                    value: total.toString(),
                    label: l10n.translate('total_polls'),
                    color: context.textPrimary,
                  ),
                  _StatItem(
                    value: active.toString(),
                    label: l10n.translate('active'),
                    color: Colors.green,
                  ),
                  _StatItem(
                    value: ended.toString(),
                    label: l10n.translate('ended'),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatItem(
                    value: countyPolls.toString(),
                    label: l10n.translate('county_polls'),
                    color: Colors.blue,
                  ),
                  _StatItem(
                    value: schoolPolls.toString(),
                    label: l10n.translate('school_polls'),
                    color: Colors.orange,
                  ),
                  _StatItem(
                    value: totalVotes.toString(),
                    label: l10n.translate('total_votes'),
                    color: AppColors.gold,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 150,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Text(l10n.translate('error_loading'))),
      ),
    );
  }
}

class _RecentActivityCard extends ConsumerWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activitiesAsync = ref.watch(recentActivitiesProvider);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return activitiesAsync.when(
      data: (activities) {
        if (activities.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                l10n.translate('no_recent_activity'),
                style: TextStyle(color: context.textSecondary),
              ),
            ),
          );
        }

        return Container(
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
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length > 10 ? 10 : activities.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getActivityColor(activity.type).withValues(alpha: 0.15),
                  child: Icon(
                    _getActivityIcon(activity.type),
                    color: _getActivityColor(activity.type),
                    size: 20,
                  ),
                ),
                title: Text(
                  activity.title,
                  style: const TextStyle(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Builder(
                  builder: (context) => Text(
                    dateFormat.format(activity.createdAt),
                    style: TextStyle(fontSize: 12, color: context.textSecondary),
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => Container(
        height: 200,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      ),
      error: (_, __) => Container(
        height: 100,
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(child: Text(l10n.translate('error_loading'))),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.initiativeSubmitted:
        return Icons.lightbulb_outline;
      case ActivityType.initiativeStatusChanged:
        return Icons.update_outlined;
      case ActivityType.pollCreated:
        return Icons.poll_outlined;
      case ActivityType.pollEnded:
        return Icons.how_to_vote_outlined;
      case ActivityType.announcementPublished:
        return Icons.campaign_outlined;
      case ActivityType.userRegistered:
        return Icons.person_add_outlined;
      case ActivityType.userApproved:
        return Icons.how_to_reg_outlined;
      case ActivityType.meetingCreated:
        return Icons.event_outlined;
      case ActivityType.documentUploaded:
        return Icons.upload_file_outlined;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.initiativeSubmitted:
        return Colors.purple;
      case ActivityType.initiativeStatusChanged:
        return Colors.teal;
      case ActivityType.pollCreated:
        return Colors.blue;
      case ActivityType.pollEnded:
        return Colors.deepOrange;
      case ActivityType.announcementPublished:
        return Colors.orange;
      case ActivityType.userRegistered:
        return Colors.green;
      case ActivityType.userApproved:
        return AppColors.navy;
      case ActivityType.meetingCreated:
        return AppColors.gold;
      case ActivityType.documentUploaded:
        return Colors.red;
    }
  }
}
