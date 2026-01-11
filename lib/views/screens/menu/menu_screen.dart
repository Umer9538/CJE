import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';
import '../../../routes/route_names.dart';
import '../admin/admin_users_screen.dart';
import '../admin/admin_schools_screen.dart';
import '../admin/admin_gds_screen.dart' show AdminGDSScreen;
import '../admin/bex_analytics_screen.dart';
import '../admin/county_settings_screen.dart';
import '../calendar/calendar_screen.dart';
import '../documents/documents_screen.dart';
import '../polls/polls_screen.dart';
import '../profile/profile_screen.dart';

/// Menu/More screen containing navigation to various app sections
class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final hasAdminAccess = ref.watch(hasAdminAccessProvider);
    final size = MediaQuery.of(context).size;

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
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: _buildHeader(context, l10n),
                  ),

                  // User profile card (mini version)
                  SliverToBoxAdapter(
                    child: _buildUserCard(context, user, l10n),
                  ),

                  // Main menu items
                  SliverToBoxAdapter(
                    child: _buildMainMenuSection(context, l10n),
                  ),

                  // Admin section (if has access)
                  if (hasAdminAccess)
                    SliverToBoxAdapter(
                      child: _buildAdminSection(context, l10n),
                    ),

                  // Settings section
                  SliverToBoxAdapter(
                    child: _buildSettingsSection(context, l10n, ref),
                  ),

                  // Bottom padding for floating nav
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
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
      child: Text(
        l10n.translate('menu'),
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: context.textPrimary,
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, dynamic user, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, Color(0xFF0D2847)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.gold, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: user?.photoUrl != null
                    ? Image.network(user.photoUrl!, fit: BoxFit.cover)
                    : Container(
                        color: context.textPrimary,
                        child: Center(
                          child: Text(
                            user?.fullName?.isNotEmpty == true
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.gold,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.fullName ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.translate('view_profile'),
                    style: TextStyle(
                      color: AppColors.gold.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainMenuSection(BuildContext context, AppLocalizations l10n) {
    final secondaryIconColor = context.iconColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('general'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(24),
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
                _MenuTile(
                  icon: Icons.folder_rounded,
                  iconColor: secondaryIconColor,
                  title: l10n.translate('documents'),
                  subtitle: l10n.translate('documents_subtitle'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                  ),
                ),
                _buildDivider(),
                _MenuTile(
                  icon: Icons.poll_rounded,
                  iconColor: AppColors.gold,
                  title: l10n.translate('polls'),
                  subtitle: l10n.translate('polls_subtitle'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PollsScreen()),
                  ),
                ),
                _buildDivider(),
                _MenuTile(
                  icon: Icons.calendar_month_rounded,
                  iconColor: secondaryIconColor,
                  title: l10n.translate('calendar'),
                  subtitle: l10n.translate('calendar_subtitle'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CalendarScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context, AppLocalizations l10n) {
    final secondaryIconColor = context.iconColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('administration'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(24),
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
                _MenuTile(
                  icon: Icons.people_rounded,
                  iconColor: secondaryIconColor,
                  title: l10n.translate('users'),
                  subtitle: l10n.translate('manage_users_desc'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  ),
                ),
                _buildDivider(),
                _MenuTile(
                  icon: Icons.school_rounded,
                  iconColor: AppColors.gold,
                  title: l10n.translate('schools'),
                  subtitle: l10n.translate('schools_subtitle'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminSchoolsScreen()),
                  ),
                ),
                _buildDivider(),
                _MenuTile(
                  icon: Icons.groups_3_rounded,
                  iconColor: secondaryIconColor,
                  title: 'GDS',
                  subtitle: l10n.translate('gds_subtitle'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminGDSScreen()),
                  ),
                ),
                _buildDivider(),
                _MenuTile(
                  icon: Icons.analytics_rounded,
                  iconColor: AppColors.gold,
                  title: l10n.translate('analytics'),
                  subtitle: l10n.translate('analytics_subtitle'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BexAnalyticsScreen()),
                  ),
                ),
                _buildDivider(),
                _MenuTile(
                  icon: Icons.settings_applications_rounded,
                  iconColor: secondaryIconColor,
                  title: l10n.translate('county_settings'),
                  subtitle: l10n.translate('county_settings_subtitle'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CountySettingsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final secondaryIconColor = context.iconColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('settings'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(24),
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
                _MenuTile(
                  icon: Icons.notifications_rounded,
                  iconColor: AppColors.gold,
                  title: l10n.translate('notifications'),
                  subtitle: l10n.translate('notifications_subtitle'),
                  trailing: _buildToggle(
                    context,
                    ref.watch(notificationsEnabledProvider),
                    onChanged: (value) {
                      ref.read(notificationsEnabledProvider.notifier).setEnabled(value);
                    },
                  ),
                  onTap: () {},
                  hasInteractiveTrailing: true,
                ),
                _buildDivider(),
                _MenuTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: secondaryIconColor,
                  title: l10n.translate('dark_mode'),
                  subtitle: ref.watch(themeModeProvider) == ThemeMode.dark
                      ? l10n.translate('enabled')
                      : l10n.translate('disabled'),
                  trailing: _buildToggle(
                    context,
                    ref.watch(themeModeProvider) == ThemeMode.dark,
                    onChanged: (value) {
                      if (value) {
                        ref.read(themeModeProvider.notifier).setDarkTheme();
                      } else {
                        ref.read(themeModeProvider.notifier).setLightTheme();
                      }
                    },
                  ),
                  onTap: () {},
                  hasInteractiveTrailing: true,
                ),
                _buildDivider(),
                _MenuTile(
                  icon: Icons.language_rounded,
                  iconColor: AppColors.gold,
                  title: l10n.translate('language'),
                  subtitle: ref.watch(languageProvider).languageCode == 'ro'
                      ? 'Română'
                      : 'English',
                  onTap: () => _showLanguageSheet(context, ref),
                ),
                _buildDivider(),
                _MenuTile(
                  icon: Icons.help_rounded,
                  iconColor: secondaryIconColor,
                  title: l10n.translate('help_support'),
                  subtitle: l10n.translate('help_support_subtitle'),
                  onTap: () => context.push(RouteNames.help),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 70),
      child: Divider(height: 1, color: context.dividerColor),
    );
  }

  Widget _buildToggle(BuildContext context, bool value, {ValueChanged<bool>? onChanged}) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value ? AppColors.navy : Colors.grey.withValues(alpha: 0.3),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.gold : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(languageProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Language',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            _LanguageOption(
              name: 'Română',
              isSelected: currentLocale.languageCode == 'ro',
              onTap: () {
                ref.read(languageProvider.notifier).setRomanian();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _LanguageOption(
              name: 'English',
              isSelected: currentLocale.languageCode == 'en',
              onTap: () {
                ref.read(languageProvider.notifier).setEnglish();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool hasInteractiveTrailing;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
    this.hasInteractiveTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: context.textSecondary),
        ],
      ),
    );

    // If there's an interactive trailing widget, don't use opaque behavior
    // so the trailing widget can receive tap events
    if (hasInteractiveTrailing) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: content,
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.navy : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.textPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  name == 'English' ? 'EN' : 'RO',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: context.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.gold, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
