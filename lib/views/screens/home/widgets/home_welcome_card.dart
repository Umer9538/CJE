import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';

class HomeWelcomeCard extends ConsumerWidget {
  final dynamic user;

  const HomeWelcomeCard({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF0D2847)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _buildContent(context, ref),
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -30,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoleBadge(context),
        const SizedBox(height: 20),
        Text(
          l10n.translate('your_impact_this_month'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        _ImpactStats(),
      ],
    );
  }

  String _getRoleTranslationKey(UserRole? role) {
    switch (role) {
      case UserRole.student:
        return 'role_student';
      case UserRole.classRep:
        return 'role_class_rep';
      case UserRole.schoolRep:
        return 'role_school_rep';
      case UserRole.department:
        return 'role_department';
      case UserRole.bex:
        return 'role_bex';
      case UserRole.superadmin:
        return 'role_superadmin';
      default:
        return 'member';
    }
  }

  Widget _buildRoleBadge(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: AppColors.navy, size: 14),
          const SizedBox(width: 4),
          Text(
            l10n.translate(_getRoleTranslationKey(user?.role)),
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactStats extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePolls = ref.watch(activePollsProvider);
    final recentInitiatives = ref.watch(recentInitiativesProvider);
    final upcomingMeetings = ref.watch(upcomingMeetingsProvider);

    return Row(
      children: [
        Expanded(
          child: _ImpactStat(
            value: activePolls.when(
              data: (polls) => polls.length.toString(),
              loading: () => '-',
              error: (_, __) => '0',
            ),
            label: 'Active Polls',
          ),
        ),
        Expanded(
          child: _ImpactStat(
            value: recentInitiatives.when(
              data: (initiatives) => initiatives.length.toString(),
              loading: () => '-',
              error: (_, __) => '0',
            ),
            label: 'Initiatives',
          ),
        ),
        Expanded(
          child: _ImpactStat(
            value: upcomingMeetings.when(
              data: (meetings) => meetings.length.toString(),
              loading: () => '-',
              error: (_, __) => '0',
            ),
            label: 'Meetings',
          ),
        ),
      ],
    );
  }
}

class _ImpactStat extends StatelessWidget {
  final String value;
  final String label;

  const _ImpactStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 70;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: isSmall ? 22 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: isSmall ? 10 : 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
