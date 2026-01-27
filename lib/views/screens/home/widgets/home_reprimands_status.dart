import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../warnings/my_warnings_screen.dart';

/// Home page widget showing user's reprimands and absences status
class HomeReprimandsStatus extends ConsumerWidget {
  const HomeReprimandsStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final responsive = Responsive(context);

    if (user == null) return const SizedBox.shrink();

    // Watch real-time streams for reprimands and absences
    final warningCountAsync = ref.watch(warningCountStreamProvider(user.id));
    final absenceCountAsync = ref.watch(absenceCountStreamProvider(user.id));

    final horizontalPadding = responsive.value(mobile: 24.0, tablet: 32.0, desktop: 48.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 8, horizontalPadding, 8),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyWarningsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getBorderColor(warningCountAsync, absenceCountAsync),
              width: 1.5,
            ),
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
              // Icon with colored background
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(warningCountAsync, absenceCountAsync),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getIcon(warningCountAsync, absenceCountAsync),
                  color: _getIconColor(warningCountAsync, absenceCountAsync),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              // Status text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translate('warnings_absences'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildStatusText(context, l10n, warningCountAsync, absenceCountAsync),
                  ],
                ),
              ),
              // Arrow indicator
              Icon(
                Icons.chevron_right_rounded,
                color: context.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBorderColor(
    AsyncValue<int> warningCount,
    AsyncValue<Map<String, int>> absenceCount,
  ) {
    final warnings = warningCount.valueOrNull ?? 0;
    final unexcused = absenceCount.valueOrNull?['unexcused'] ?? 0;

    if (warnings > 0) {
      return Colors.orange.withValues(alpha: 0.5);
    } else if (unexcused > 0) {
      return Colors.red.withValues(alpha: 0.4);
    }
    return Colors.green.withValues(alpha: 0.3);
  }

  Color _getIconBackgroundColor(
    AsyncValue<int> warningCount,
    AsyncValue<Map<String, int>> absenceCount,
  ) {
    final warnings = warningCount.valueOrNull ?? 0;
    final unexcused = absenceCount.valueOrNull?['unexcused'] ?? 0;

    if (warnings > 0) {
      return Colors.orange.withValues(alpha: 0.15);
    } else if (unexcused > 0) {
      return Colors.red.withValues(alpha: 0.12);
    }
    return Colors.green.withValues(alpha: 0.12);
  }

  Color _getIconColor(
    AsyncValue<int> warningCount,
    AsyncValue<Map<String, int>> absenceCount,
  ) {
    final warnings = warningCount.valueOrNull ?? 0;
    final unexcused = absenceCount.valueOrNull?['unexcused'] ?? 0;

    if (warnings > 0) {
      return Colors.orange;
    } else if (unexcused > 0) {
      return Colors.red;
    }
    return Colors.green;
  }

  IconData _getIcon(
    AsyncValue<int> warningCount,
    AsyncValue<Map<String, int>> absenceCount,
  ) {
    final warnings = warningCount.valueOrNull ?? 0;
    final unexcused = absenceCount.valueOrNull?['unexcused'] ?? 0;

    if (warnings > 0 || unexcused > 0) {
      return Icons.warning_amber_rounded;
    }
    return Icons.verified_rounded;
  }

  Widget _buildStatusText(
    BuildContext context,
    AppLocalizations l10n,
    AsyncValue<int> warningCountAsync,
    AsyncValue<Map<String, int>> absenceCountAsync,
  ) {
    // Handle loading state
    if (warningCountAsync.isLoading || absenceCountAsync.isLoading) {
      return Text(
        l10n.translate('loading'),
        style: TextStyle(
          fontSize: 13,
          color: context.textSecondary,
        ),
      );
    }

    // Handle error state
    if (warningCountAsync.hasError || absenceCountAsync.hasError) {
      return Text(
        l10n.translate('error'),
        style: TextStyle(
          fontSize: 13,
          color: Colors.red,
        ),
      );
    }

    final warnings = warningCountAsync.valueOrNull ?? 0;
    final unexcused = absenceCountAsync.valueOrNull?['unexcused'] ?? 0;

    // Build status parts
    final List<TextSpan> spans = [];

    if (warnings > 0) {
      spans.add(TextSpan(
        text: '$warnings ${warnings == 1 ? l10n.translate('active_reprimand_singular') : l10n.translate('active_reprimands_plural')}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.orange.shade700,
        ),
      ));
    }

    if (unexcused > 0) {
      if (spans.isNotEmpty) {
        spans.add(TextSpan(
          text: ' / ',
          style: TextStyle(
            fontSize: 13,
            color: context.textSecondary,
          ),
        ));
      }
      spans.add(TextSpan(
        text: '$unexcused ${unexcused == 1 ? l10n.translate('unexcused_absence_singular') : l10n.translate('unexcused_absences_plural')}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.red.shade600,
        ),
      ));
    }

    // No issues - show positive message
    if (spans.isEmpty) {
      return Text(
        l10n.translate('no_issues_status'),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.green.shade600,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
