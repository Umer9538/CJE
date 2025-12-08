import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../controllers/controllers.dart';
import '../../../../core/core.dart';
import '../../../../routes/route_names.dart';

class HomeQuickStats extends ConsumerWidget {
  const HomeQuickStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final activePolls = ref.watch(activePollsProvider);
    final documents = ref.watch(documentsProvider(const DocumentFilter()));
    final userCount = ref.watch(userCountProvider); // Use count provider instead of fetching all users

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: QuickStatCard(
              icon: Icons.how_to_vote_rounded,
              title: l10n.translate('active_polls'),
              value: activePolls.when(
                data: (polls) => polls.length.toString(),
                loading: () => '-',
                error: (_, __) => '0',
              ),
              color: const Color(0xFF8B5CF6),
              onTap: () => context.go(RouteNames.polls),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: QuickStatCard(
              icon: Icons.description_rounded,
              title: l10n.translate('documents'),
              value: documents.when(
                data: (docs) => docs.length.toString(),
                loading: () => '-',
                error: (_, __) => '0',
              ),
              color: const Color(0xFF3B82F6),
              onTap: () => context.go(RouteNames.documents),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: QuickStatCard(
              icon: Icons.group_rounded,
              title: l10n.translate('members'),
              value: userCount.when(
                data: (count) => count.toString(),
                loading: () => '-',
                error: (_, __) => '0',
              ),
              color: const Color(0xFF10B981),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const QuickStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 100;
        final iconContainerSize = isSmall ? 32.0 : 40.0;
        final iconSize = isSmall ? 16.0 : 20.0;
        final valueFontSize = isSmall ? 18.0 : 24.0;
        final titleFontSize = isSmall ? 9.0 : 11.0;
        final padding = isSmall ? 12.0 : 16.0;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(padding),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: iconContainerSize,
                  height: iconContainerSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                SizedBox(height: isSmall ? 8 : 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
