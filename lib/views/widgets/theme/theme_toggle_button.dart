import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';

/// A toggle button for switching between light and dark themes
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode to rebuild on change
    ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: isDark ? AppColors.primaryDark : AppColors.textPrimaryLight,
      ),
      onPressed: () {
        ref.read(themeModeProvider.notifier).toggle();
      },
      tooltip: isDark ? 'Activează tema deschisă' : 'Activează tema întunecată',
    );
  }
}

/// A segmented button for choosing between system, light, and dark themes
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          icon: Icon(Icons.settings_suggest_rounded),
          label: Text('Sistem'),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          icon: Icon(Icons.light_mode_rounded),
          label: Text('Deschis'),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          icon: Icon(Icons.dark_mode_rounded),
          label: Text('Întunecat'),
        ),
      ],
      selected: {themeMode},
      onSelectionChanged: (Set<ThemeMode> selection) {
        ref.read(themeModeProvider.notifier).setThemeMode(selection.first);
      },
      showSelectedIcon: false,
    );
  }
}

/// A list tile for theme selection in settings
class ThemeSettingsTile extends ConsumerWidget {
  const ThemeSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    String themeName;
    IconData themeIcon;

    switch (themeMode) {
      case ThemeMode.system:
        themeName = 'Sistem';
        themeIcon = Icons.settings_suggest_rounded;
        break;
      case ThemeMode.light:
        themeName = 'Temă deschisă';
        themeIcon = Icons.light_mode_rounded;
        break;
      case ThemeMode.dark:
        themeName = 'Temă întunecată';
        themeIcon = Icons.dark_mode_rounded;
        break;
    }

    return ListTile(
      leading: Icon(themeIcon),
      title: const Text('Aspect'),
      subtitle: Text(themeName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showThemeBottomSheet(context, ref);
      },
    );
  }

  void _showThemeBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final themeMode = ref.watch(themeModeProvider);

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Text(
                      'Selectează aspectul',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _buildThemeOption(
                    context: context,
                    ref: ref,
                    title: 'Sistem',
                    subtitle: 'Urmează setările dispozitivului',
                    icon: Icons.settings_suggest_rounded,
                    mode: ThemeMode.system,
                    currentMode: themeMode,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setSystemTheme();
                      Navigator.pop(bottomSheetContext);
                    },
                  ),
                  _buildThemeOption(
                    context: context,
                    ref: ref,
                    title: 'Temă deschisă',
                    subtitle: 'Aspect luminos',
                    icon: Icons.light_mode_rounded,
                    mode: ThemeMode.light,
                    currentMode: themeMode,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setLightTheme();
                      Navigator.pop(bottomSheetContext);
                    },
                  ),
                  _buildThemeOption(
                    context: context,
                    ref: ref,
                    title: 'Temă întunecată',
                    subtitle: 'Aspect întunecat',
                    icon: Icons.dark_mode_rounded,
                    mode: ThemeMode.dark,
                    currentMode: themeMode,
                    onTap: () {
                      ref.read(themeModeProvider.notifier).setDarkTheme();
                      Navigator.pop(bottomSheetContext);
                    },
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
  }) {
    final isSelected = mode == currentMode;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}

/// A switch for quick theme toggle with label
class ThemeSwitch extends ConsumerWidget {
  final bool showLabel;

  const ThemeSwitch({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Icon(
            Icons.light_mode_rounded,
            size: AppSizes.iconSM,
            color: !isDark ? AppColors.primaryLight : AppColors.tertiaryDark,
          ),
          const SizedBox(width: AppSizes.spacing8),
        ],
        Switch(
          value: themeMode == ThemeMode.dark,
          onChanged: (isDarkMode) {
            if (isDarkMode) {
              ref.read(themeModeProvider.notifier).setDarkTheme();
            } else {
              ref.read(themeModeProvider.notifier).setLightTheme();
            }
          },
        ),
        if (showLabel) ...[
          const SizedBox(width: AppSizes.spacing8),
          Icon(
            Icons.dark_mode_rounded,
            size: AppSizes.iconSM,
            color: isDark ? AppColors.primaryDark : AppColors.tertiaryLight,
          ),
        ],
      ],
    );
  }
}
