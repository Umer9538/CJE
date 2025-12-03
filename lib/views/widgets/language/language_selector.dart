import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';

/// A toggle button for switching between languages
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final flag = AppLocales.getFlagEmoji(locale);

    return IconButton(
      icon: Text(
        flag,
        style: const TextStyle(fontSize: 24),
      ),
      onPressed: () {
        ref.read(languageProvider.notifier).toggleLanguage();
      },
      tooltip: AppLocalizations.of(context).selectLanguage,
    );
  }
}

/// A dropdown for selecting language
class LanguageDropdown extends ConsumerWidget {
  const LanguageDropdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return DropdownButton<String>(
      value: locale.languageCode,
      underline: const SizedBox(),
      items: AppLocales.supportedLocales.map((Locale supportedLocale) {
        return DropdownMenuItem<String>(
          value: supportedLocale.languageCode,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocales.getFlagEmoji(supportedLocale),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(AppLocales.getLanguageName(supportedLocale)),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? languageCode) {
        if (languageCode != null) {
          ref.read(languageProvider.notifier).setLanguageByCode(languageCode);
        }
      },
    );
  }
}

/// A list tile for language selection in settings
class LanguageSettingsTile extends ConsumerWidget {
  const LanguageSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context);
    final languageName = AppLocales.getLanguageName(locale);
    final flag = AppLocales.getFlagEmoji(locale);

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(l10n.language),
      subtitle: Text('$flag $languageName'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showLanguageBottomSheet(context, ref);
      },
    );
  }

  void _showLanguageBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final currentLocale = ref.watch(languageProvider);
            final l10n = AppLocalizations.of(context);

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Text(
                      l10n.selectLanguage,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ...AppLocales.supportedLocales.map((locale) {
                    final isSelected = locale.languageCode == currentLocale.languageCode;
                    final languageName = AppLocales.getLanguageName(locale);
                    final nativeName = AppLocales.getNativeLanguageName(locale.languageCode);
                    final flag = AppLocales.getFlagEmoji(locale);

                    return ListTile(
                      leading: Text(
                        flag,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(languageName),
                      subtitle: languageName != nativeName ? Text(nativeName) : null,
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : const Icon(Icons.circle_outlined),
                      onTap: () {
                        ref.read(languageProvider.notifier).setLocale(locale);
                        Navigator.pop(bottomSheetContext);
                      },
                    );
                  }),
                  const SizedBox(height: AppSizes.spacing16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// A segmented button for language selection
class LanguageSegmentedButton extends ConsumerWidget {
  const LanguageSegmentedButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return SegmentedButton<String>(
      segments: AppLocales.supportedLocales.map((Locale supportedLocale) {
        return ButtonSegment<String>(
          value: supportedLocale.languageCode,
          icon: Text(
            AppLocales.getFlagEmoji(supportedLocale),
            style: const TextStyle(fontSize: 18),
          ),
          label: Text(AppLocales.getLanguageName(supportedLocale)),
        );
      }).toList(),
      selected: {locale.languageCode},
      onSelectionChanged: (Set<String> selection) {
        ref.read(languageProvider.notifier).setLanguageByCode(selection.first);
      },
      showSelectedIcon: false,
    );
  }
}

/// A compact language switcher chip
class LanguageSwitcherChip extends ConsumerWidget {
  const LanguageSwitcherChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final flag = AppLocales.getFlagEmoji(locale);
    final languageCode = locale.languageCode.toUpperCase();

    return ActionChip(
      avatar: Text(flag),
      label: Text(languageCode),
      onPressed: () {
        ref.read(languageProvider.notifier).toggleLanguage();
      },
    );
  }
}

/// A popup menu for language selection
class LanguagePopupMenu extends ConsumerWidget {
  const LanguagePopupMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final flag = AppLocales.getFlagEmoji(locale);

    return PopupMenuButton<String>(
      icon: Text(
        flag,
        style: const TextStyle(fontSize: 24),
      ),
      tooltip: AppLocalizations.of(context).selectLanguage,
      onSelected: (String languageCode) {
        ref.read(languageProvider.notifier).setLanguageByCode(languageCode);
      },
      itemBuilder: (BuildContext context) {
        return AppLocales.supportedLocales.map((Locale supportedLocale) {
          final isSelected = supportedLocale.languageCode == locale.languageCode;

          return PopupMenuItem<String>(
            value: supportedLocale.languageCode,
            child: Row(
              children: [
                Text(
                  AppLocales.getFlagEmoji(supportedLocale),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(AppLocales.getLanguageName(supportedLocale)),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
