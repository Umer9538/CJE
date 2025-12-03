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
        context.go(RouteNames.meetings);
        break;
      case 3:
        context.go(RouteNames.initiatives);
        break;
      case 4:
        context.go(RouteNames.profile);
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
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.campaign_rounded,
                  label: 'News',
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _CenterNavItem(
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.lightbulb_rounded,
                  label: 'Ideas',
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
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
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.5),
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterNavItem extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CenterNavItem({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [AppColors.gold, const Color(0xFFE5C158)]
                : [AppColors.gold.withValues(alpha: 0.8), AppColors.gold],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.event_rounded,
          color: AppColors.navy,
          size: isSelected ? 28 : 26,
        ),
      ),
    );
  }
}

/// Helper to get index from route
int getIndexFromRoute(String location) {
  if (location.startsWith(RouteNames.home)) return 0;
  if (location.startsWith(RouteNames.announcements)) return 1;
  if (location.startsWith(RouteNames.meetings)) return 2;
  if (location.startsWith(RouteNames.initiatives)) return 3;
  if (location.startsWith(RouteNames.profile)) return 4;
  return 0;
}
