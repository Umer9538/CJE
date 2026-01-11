import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../home/home_screen.dart';
import '../announcements/announcements_screen.dart';
import '../ideas/ideas_screen.dart';
import '../meetings/meetings_screen.dart';
import '../menu/menu_screen.dart';

/// BEX Shell - Main navigation for BEX (County Executive Bureau) users
/// Same navigation structure as main app:
/// - Home
/// - Announcements
/// - Ideas (Initiatives + Polls)
/// - Meetings
/// - Menu (contains Users, Schools, GDS, Analytics, Settings)
class BexShell extends ConsumerStatefulWidget {
  const BexShell({super.key});

  @override
  ConsumerState<BexShell> createState() => _BexShellState();
}

class _BexShellState extends ConsumerState<BexShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    AnnouncementsScreen(),
    IdeasScreen(),
    MeetingsScreen(),
    MenuScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Clamp index to valid range (safety for hot reload)
    final safeIndex = _currentIndex.clamp(0, _screens.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: safeIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: _FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        labels: [
          l10n.translate('home'),
          l10n.translate('announcements'),
          l10n.translate('ideas'),
          l10n.translate('meetings'),
          l10n.translate('menu'),
        ],
      ),
    );
  }
}

/// Floating Bottom Navigation Bar - Same style as main shell
class _FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<String> labels;

  const _FloatingBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.labels,
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
                  label: labels[0],
                  isSelected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.campaign_rounded,
                  label: labels[1],
                  isSelected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  icon: Icons.lightbulb_rounded,
                  label: labels[2],
                  isSelected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.groups_rounded,
                  label: labels[3],
                  isSelected: currentIndex == 3,
                  onTap: () => onTap(3),
                ),
                _NavItem(
                  icon: Icons.menu_rounded,
                  label: labels[4],
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
