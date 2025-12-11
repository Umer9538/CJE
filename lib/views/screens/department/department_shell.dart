import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/core.dart';
import 'department_dashboard_screen.dart';
import 'department_meetings_screen.dart';
import 'department_documents_screen.dart';
import 'department_members_screen.dart';
import 'department_more_screen.dart';

/// Department Shell - Main navigation for Department users
/// Department-specific features:
/// - Dashboard (overview, quick actions)
/// - Meetings (Department meetings only)
/// - Documents (Department documents)
/// - Members (View department members)
class DepartmentShell extends ConsumerStatefulWidget {
  const DepartmentShell({super.key});

  @override
  ConsumerState<DepartmentShell> createState() => _DepartmentShellState();
}

class _DepartmentShellState extends ConsumerState<DepartmentShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DepartmentDashboardScreen(),
    DepartmentMeetingsScreen(),
    DepartmentDocumentsScreen(),
    DepartmentMembersScreen(),
    DepartmentMoreScreen(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cardColor,
          boxShadow: [
            BoxShadow(
              color: context.shadowColor,
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
                  icon: Icons.event_rounded,
                  label: l10n.translate('meetings'),
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.folder_rounded,
                  label: l10n.translate('documents'),
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.people_rounded,
                  label: l10n.translate('members'),
                  isSelected: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.more_horiz_rounded,
                  label: l10n.translate('more'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.badgeDepartmentBg.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? context.textPrimary : context.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? context.textPrimary : context.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
