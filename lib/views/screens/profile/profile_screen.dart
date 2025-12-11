import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../controllers/controllers.dart';
import '../../../controllers/admin/admin_controller.dart';
import '../../../core/core.dart';
import '../admin/admin_users_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
            top: size.height * 0.2,
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

                  // Profile card
                  SliverToBoxAdapter(
                    child: _buildProfileCard(context, l10n, user),
                  ),

                  // Stats
                  SliverToBoxAdapter(
                    child: _buildStats(context, l10n, ref),
                  ),

                  // Achievement badges
                  SliverToBoxAdapter(
                    child: _buildAchievements(context, l10n),
                  ),

                  // Settings sections
                  SliverToBoxAdapter(
                    child: _buildSettingsSection(context, l10n, ref),
                  ),

                  // Logout button
                  SliverToBoxAdapter(
                    child: _buildLogoutButton(context, ref, l10n),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.share_rounded,
                onTap: () => _shareApp(context),
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.settings_rounded,
                onTap: () => _showSettingsSheet(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
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
        child: Icon(icon, color: context.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, AppLocalizations l10n, dynamic user) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF0D2847)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative elements
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.1),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.gold, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(21),
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
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: context.textPrimary, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                l10n.translate(_getRoleTranslationKey(user?.role)),
                                style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Edit profile button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditProfileScreen(),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: statsAsync.when(
        data: (stats) => Row(
          children: [
            Expanded(child: _StatCard(value: '${stats.totalVotes}', label: l10n.translate('total_votes'), icon: Icons.how_to_vote_rounded, color: const Color(0xFF8B5CF6))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '${stats.initiativesCount}', label: l10n.translate('initiatives'), icon: Icons.lightbulb_rounded, color: AppColors.gold)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '${stats.meetingsAttended}', label: l10n.translate('meetings'), icon: Icons.groups_rounded, color: const Color(0xFF10B981))),
          ],
        ),
        loading: () => Row(
          children: [
            Expanded(child: _StatCard(value: '-', label: l10n.translate('total_votes'), icon: Icons.how_to_vote_rounded, color: const Color(0xFF8B5CF6))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '-', label: l10n.translate('initiatives'), icon: Icons.lightbulb_rounded, color: AppColors.gold)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '-', label: l10n.translate('meetings'), icon: Icons.groups_rounded, color: const Color(0xFF10B981))),
          ],
        ),
        error: (_, __) => Row(
          children: [
            Expanded(child: _StatCard(value: '0', label: l10n.translate('total_votes'), icon: Icons.how_to_vote_rounded, color: const Color(0xFF8B5CF6))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '0', label: l10n.translate('initiatives'), icon: Icons.lightbulb_rounded, color: AppColors.gold)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(value: '0', label: l10n.translate('meetings'), icon: Icons.groups_rounded, color: const Color(0xFF10B981))),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '8/12',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AchievementBadge(icon: Icons.emoji_events_rounded, color: AppColors.gold, isUnlocked: true),
              _AchievementBadge(icon: Icons.flash_on_rounded, color: const Color(0xFF3B82F6), isUnlocked: true),
              _AchievementBadge(icon: Icons.favorite_rounded, color: const Color(0xFFEF4444), isUnlocked: true),
              _AchievementBadge(icon: Icons.star_rounded, color: const Color(0xFF8B5CF6), isUnlocked: true),
              _AchievementBadge(icon: Icons.workspace_premium_rounded, color: const Color(0xFF10B981), isUnlocked: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final hasAdminAccess = ref.watch(hasAdminAccessProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
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
                // Admin Panel - only visible for schoolRep, bex, superadmin
                if (hasAdminAccess) ...[
                  _SettingsTile(
                    icon: Icons.admin_panel_settings_rounded,
                    iconColor: AppColors.navy,
                    title: l10n.translate('manage_users'),
                    subtitle: l10n.translate('manage_users_desc'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminUsersScreen(),
                      ),
                    ),
                  ),
                  _buildDivider(),
                ],
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: l10n.translate('notifications'),
                  subtitle: l10n.translate('notifications_subtitle'),
                  trailing: _buildToggle(
                    ref.watch(notificationsEnabledProvider),
                    onChanged: (value) {
                      ref.read(notificationsEnabledProvider.notifier).setEnabled(value);
                    },
                  ),
                  onTap: () {},
                ),
                _buildDivider(),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Language',
                  subtitle: ref.watch(languageProvider).languageCode == 'ro' ? 'Romana' : 'English',
                  onTap: () => _showLanguageSheet(context, ref, l10n),
                ),
                _buildDivider(),
                _SettingsTile(
                  icon: Icons.dark_mode_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Dark Mode',
                  subtitle: 'System default',
                  trailing: _buildToggle(ref.watch(themeModeProvider) == ThemeMode.dark, onChanged: (value) {
                    if (value) {
                      ref.read(themeModeProvider.notifier).setDarkTheme();
                    } else {
                      ref.read(themeModeProvider.notifier).setLightTheme();
                    }
                  }),
                  onTap: () {},
                ),
                _buildDivider(),
                _SettingsTile(
                  icon: Icons.security_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: l10n.translate('privacy_security'),
                  subtitle: l10n.translate('privacy_security_subtitle'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacySecurityScreen(),
                      ),
                    );
                  },
                ),
                _buildDivider(),
                _SettingsTile(
                  icon: Icons.help_rounded,
                  iconColor: AppColors.gold,
                  title: l10n.translate('help_support'),
                  subtitle: l10n.translate('help_support_subtitle'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HelpSupportScreen(),
                      ),
                    );
                  },
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

  Widget _buildToggle(bool value, {ValueChanged<bool>? onChanged}) {
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

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context, ref, l10n),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
              SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareApp(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shareText = l10n.translate('share_app_message');
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
          final currentLocale = ref.watch(languageProvider);

          return Container(
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
                  'Quick Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                // Dark Mode Toggle
                _buildQuickSettingTile(
                  icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  iconColor: isDarkMode ? Colors.indigo : Colors.amber,
                  title: l10n.translate('dark_mode'),
                  trailing: Switch.adaptive(
                    value: isDarkMode,
                    activeColor: AppColors.gold,
                    onChanged: (value) {
                      if (value) {
                        ref.read(themeModeProvider.notifier).setDarkTheme();
                      } else {
                        ref.read(themeModeProvider.notifier).setLightTheme();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Language Selection
                _buildQuickSettingTile(
                  icon: Icons.language_rounded,
                  iconColor: Colors.blue,
                  title: l10n.translate('language'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentLocale == 'ro' ? 'Română' : 'English',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLanguageSheet(context, ref, l10n);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Builder(
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.borderColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.textPrimary,
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
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
              flag: 'assets/flags/ro.png',
              name: 'Romana',
              isSelected: currentLocale.languageCode == 'ro',
              onTap: () {
                ref.read(languageProvider.notifier).setRomanian();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _LanguageOption(
              flag: 'assets/flags/en.png',
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 28),
              ),
              const SizedBox(height: 20),
              Text(
                'Log Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out?',
                style: TextStyle(
                  fontSize: 14,
                  color: context.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: context.borderColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await ref.read(authControllerProvider.notifier).signOut();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Log Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
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

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isUnlocked;

  const _AchievementBadge({
    required this.icon,
    required this.color,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isUnlocked ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(color: color.withValues(alpha: 0.3), width: 2)
            : null,
      ),
      child: Icon(
        icon,
        color: isUnlocked ? color : Colors.grey.withValues(alpha: 0.4),
        size: 24,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
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
