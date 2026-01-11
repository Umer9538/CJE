import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/core.dart';
import '../../../routes/route_names.dart';

/// Provider for current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Main shell with floating bottom navigation
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return Scaffold(
      body: child,
      extendBody: true,
      bottomNavigationBar: _FloatingBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          _navigateToIndex(context, index);
        },
      ),
    );
  }

  void _navigateToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(RouteNames.home);
        break;
      case 1:
        context.go(RouteNames.announcements);
        break;
      case 2:
        context.go(RouteNames.initiatives);
        break;
      case 3:
        context.go(RouteNames.meetings);
        break;
      case 4:
        context.go(RouteNames.menu);
        break;
    }
  }
}

/// Floating Bottom Navigation Bar
class _FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const _FloatingBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDarkMode;
    final navBgColor = isDark ? AppColors.cardDark : AppColors.navy;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: navBgColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: navBgColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: l10n.translate('home'),
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.campaign_rounded,
                  label: l10n.translate('announcements'),
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.lightbulb_rounded,
                  label: l10n.translate('ideas'),
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.groups_rounded,
                  label: l10n.translate('meetings'),
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
                _NavItem(
                  icon: Icons.menu_rounded,
                  label: l10n.translate('menu'),
                  isSelected: currentIndex == 4,
                  onTap: () => onTap(4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.5),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.5),
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to get index from route
int getIndexFromRoute(String location) {
  if (location.startsWith(RouteNames.home)) return 0;
  if (location.startsWith(RouteNames.announcements)) return 1;
  if (location.startsWith(RouteNames.initiatives)) return 2;
  if (location.startsWith(RouteNames.meetings)) return 3;
  if (location.startsWith(RouteNames.menu)) return 4;
  if (location.startsWith(RouteNames.profile)) return 4; // Profile is now under Menu
  if (location.startsWith(RouteNames.documents)) return 4; // Documents is now under Menu
  if (location.startsWith(RouteNames.polls)) return 4; // Polls is now under Menu
  return 0;
}
