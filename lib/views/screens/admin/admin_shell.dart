import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import '../announcements/announcements_screen.dart';
import '../meetings/meetings_screen.dart';
import '../polls/polls_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';

/// Admin Shell - Main navigation for superadmin users
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminUsersScreen(),
    AnnouncementsScreen(),
    MeetingsScreen(),
    PollsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: l10n.translate('dashboard'),
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: l10n.translate('users'),
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.campaign_rounded,
                  label: l10n.translate('announcements'),
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.event_rounded,
                  label: l10n.translate('meetings'),
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.poll_rounded,
                  label: l10n.translate('polls'),
                  isSelected: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.navy : Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.navy : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
