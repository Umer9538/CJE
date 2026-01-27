import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../models/warning_model.dart';

/// Screen for users to view their own warnings and absences
class MyWarningsScreen extends ConsumerStatefulWidget {
  const MyWarningsScreen({super.key});

  @override
  ConsumerState<MyWarningsScreen> createState() => _MyWarningsScreenState();
}

class _MyWarningsScreenState extends ConsumerState<MyWarningsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final size = MediaQuery.of(context).size;

    if (user == null) {
      return Scaffold(
        backgroundColor: context.scaffoldBackgroundColor,
        body: Center(
          child: Text(l10n.translate('not_logged_in')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background gradient
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.navy.withValues(alpha: 0.15),
                    AppColors.navy.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.3,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.1),
                    AppColors.gold.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(context, l10n),
                  _buildSummaryCards(context, l10n, user.id),
                  _buildTabBar(context, l10n),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _WarningsTab(userId: user.id),
                        _AbsencesTab(userId: user.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
              child: Icon(Icons.arrow_back_rounded, color: context.iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              l10n.translate('my_warnings_absences'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, AppLocalizations l10n, String userId) {
    // Use stream providers for real-time updates
    final warningCountAsync = ref.watch(warningCountStreamProvider(userId));
    final absenceCountAsync = ref.watch(absenceCountStreamProvider(userId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: warningCountAsync.when(
              data: (count) => _SummaryCard(
                icon: Icons.warning_rounded,
                color: Colors.orange,
                value: count.toString(),
                label: l10n.translate('active_warnings'),
              ),
              loading: () => _SummaryCard(
                icon: Icons.warning_rounded,
                color: Colors.orange,
                value: '-',
                label: l10n.translate('active_warnings'),
              ),
              error: (_, __) => _SummaryCard(
                icon: Icons.warning_rounded,
                color: Colors.orange,
                value: '0',
                label: l10n.translate('active_warnings'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: absenceCountAsync.when(
              data: (counts) => _SummaryCard(
                icon: Icons.event_busy_rounded,
                color: Colors.red,
                value: (counts['unexcused'] ?? 0).toString(),
                label: l10n.translate('unexcused_absences'),
              ),
              loading: () => _SummaryCard(
                icon: Icons.event_busy_rounded,
                color: Colors.red,
                value: '-',
                label: l10n.translate('unexcused_absences'),
              ),
              error: (_, __) => _SummaryCard(
                icon: Icons.event_busy_rounded,
                color: Colors.red,
                value: '0',
                label: l10n.translate('unexcused_absences'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
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
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.navy,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: context.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        indicatorPadding: const EdgeInsets.all(4),
        tabs: [
          Tab(text: l10n.translate('warnings')),
          Tab(text: l10n.translate('absences')),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _WarningsTab extends ConsumerWidget {
  final String userId;

  const _WarningsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Use stream provider for real-time updates
    final warningsAsync = ref.watch(userWarningsStreamProvider(userId));

    return warningsAsync.when(
      data: (warnings) {
        if (warnings.isEmpty) {
          return _EmptyState(
            icon: Icons.verified_rounded,
            title: l10n.translate('no_warnings'),
            subtitle: l10n.translate('no_warnings_desc'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          itemCount: warnings.length,
          itemBuilder: (context, index) {
            return _WarningCard(warning: warnings[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          l10n.translate('error_loading_warnings'),
          style: TextStyle(color: context.textSecondary),
        ),
      ),
    );
  }
}

class _AbsencesTab extends ConsumerWidget {
  final String userId;

  const _AbsencesTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Use stream provider for real-time updates
    final absencesAsync = ref.watch(userAbsencesStreamProvider(userId));

    return absencesAsync.when(
      data: (absences) {
        if (absences.isEmpty) {
          return _EmptyState(
            icon: Icons.event_available_rounded,
            title: l10n.translate('no_absences'),
            subtitle: l10n.translate('no_absences_desc'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          itemCount: absences.length,
          itemBuilder: (context, index) {
            return _AbsenceCard(absence: absences[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          l10n.translate('error_loading_absences'),
          style: TextStyle(color: context.textSecondary),
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final WarningModel warning;

  const _WarningCard({required this.warning});

  Color _getWarningColor(WarningType type) {
    switch (type) {
      case WarningType.verbal:
        return Colors.amber;
      case WarningType.written:
        return Colors.orange;
      case WarningType.suspension:
        return Colors.deepOrange;
      case WarningType.removal:
        return Colors.red;
    }
  }

  IconData _getWarningIcon(WarningType type) {
    switch (type) {
      case WarningType.verbal:
        return Icons.record_voice_over_rounded;
      case WarningType.written:
        return Icons.description_rounded;
      case WarningType.suspension:
        return Icons.pause_circle_rounded;
      case WarningType.removal:
        return Icons.remove_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = _getWarningColor(warning.type);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final isRomanian = Localizations.localeOf(context).languageCode == 'ro';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
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
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getWarningIcon(warning.type), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRomanian ? warning.type.displayNameRo : warning.type.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    Text(
                      dateFormat.format(warning.issuedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!warning.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.translate('resolved'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            warning.reason,
            style: TextStyle(
              fontSize: 14,
              color: context.textPrimary,
            ),
          ),
          if (warning.details != null && warning.details!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              warning.details!,
              style: TextStyle(
                fontSize: 13,
                color: context.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: context.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${l10n.translate('issued_by')}: ${warning.issuedByName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (warning.expiresAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 14, color: context.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${l10n.translate('expires')}: ${dateFormat.format(warning.expiresAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AbsenceCard extends StatelessWidget {
  final AbsenceModel absence;

  const _AbsenceCard({required this.absence});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isExcused = absence.type == AbsenceType.excused;
    final color = isExcused ? Colors.green : Colors.red;
    final dateFormat = DateFormat('dd MMM yyyy');
    final isRomanian = Localizations.localeOf(context).languageCode == 'ro';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
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
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isExcused ? Icons.event_available_rounded : Icons.event_busy_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      absence.meetingTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      dateFormat.format(absence.meetingDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isRomanian ? absence.type.displayNameRo : absence.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (absence.reason != null && absence.reason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded, size: 14, color: context.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    absence.reason!,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: context.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${l10n.translate('recorded_by')}: ${absence.recordedByName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
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
}
