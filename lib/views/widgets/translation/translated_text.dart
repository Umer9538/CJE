import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../controllers/controllers.dart';
import '../../../core/core.dart';

/// A text widget that automatically translates content to user's language
class TranslatedText extends ConsumerWidget {
  /// The original text to translate
  final String text;

  /// Original language of the text (auto-detect if null)
  final String? sourceLanguage;

  /// Text style to apply
  final TextStyle? style;

  /// Text alignment
  final TextAlign? textAlign;

  /// Maximum lines
  final int? maxLines;

  /// Text overflow behavior
  final TextOverflow? overflow;

  /// Whether to show loading indicator while translating
  final bool showLoading;

  /// Whether to show original text on error
  final bool showOriginalOnError;

  /// Custom loading widget
  final Widget? loadingWidget;

  /// Callback when translation completes
  final void Function(TranslationResult)? onTranslated;

  const TranslatedText(
    this.text, {
    super.key,
    this.sourceLanguage,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.showLoading = true,
    this.showOriginalOnError = true,
    this.loadingWidget,
    this.onTranslated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(translationSettingsProvider);
    final targetLocale = ref.watch(languageProvider);

    // If translation is disabled or same language, just show original text
    if (!settings.isEnabled ||
        sourceLanguage?.toLowerCase() == targetLocale.languageCode.toLowerCase()) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Watch the translation
    final translationAsync = ref.watch(translateTextProvider(text));

    return translationAsync.when(
      data: (result) {
        onTranslated?.call(result);
        return Text(
          result.translatedText,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
      loading: () {
        if (!showLoading) {
          return Text(
            text,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          );
        }
        return loadingWidget ??
            Shimmer.fromColors(
              baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              highlightColor: Theme.of(context).colorScheme.surface,
              child: Container(
                height: (style?.fontSize ?? 14) * 1.5,
                width: text.length * (style?.fontSize ?? 14) * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
      },
      error: (error, stack) {
        if (showOriginalOnError) {
          return Text(
            text,
            style: style,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          );
        }
        return Text(
          '[Translation Error]',
          style: style?.copyWith(color: Theme.of(context).colorScheme.error) ??
              TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}

/// A rich text widget with automatic translation
class TranslatedRichText extends ConsumerWidget {
  final String text;
  final String? sourceLanguage;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool showLoading;

  const TranslatedRichText(
    this.text, {
    super.key,
    this.sourceLanguage,
    this.style,
    this.textAlign = TextAlign.start,
    this.showLoading = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(translationSettingsProvider);
    final targetLocale = ref.watch(languageProvider);

    if (!settings.isEnabled ||
        sourceLanguage?.toLowerCase() == targetLocale.languageCode.toLowerCase()) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
      );
    }

    final translationAsync = ref.watch(translateTextProvider(text));

    return translationAsync.when(
      data: (result) => Text(
        result.translatedText,
        style: style,
        textAlign: textAlign,
      ),
      loading: () => Text(
        text,
        style: style?.copyWith(
          color: style?.color?.withValues(alpha: 0.5),
        ),
        textAlign: textAlign,
      ),
      error: (_, __) => Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }
}

/// A card/container with translated content
class TranslatedContentCard extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final String? sourceLanguage;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const TranslatedContentCard({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.sourceLanguage,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusCard),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppSizes.paddingMD),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSizes.spacing12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      title,
                      sourceLanguage: sourceLanguage,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSizes.spacing4),
                      TranslatedText(
                        subtitle!,
                        sourceLanguage: sourceLanguage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (description != null) ...[
                      const SizedBox(height: AppSizes.spacing8),
                      TranslatedText(
                        description!,
                        sourceLanguage: sourceLanguage,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSizes.spacing12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Translation toggle button (shows when viewing translated content)
class TranslationToggle extends ConsumerWidget {
  final String originalText;
  final String translatedText;
  final String? sourceLanguage;

  const TranslationToggle({
    super.key,
    required this.originalText,
    required this.translatedText,
    this.sourceLanguage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isShowingOriginal = useState(false);

    if (originalText == translatedText) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () {
        isShowingOriginal.value = !isShowingOriginal.value;
      },
      icon: Icon(
        isShowingOriginal.value ? Icons.translate : Icons.text_fields,
        size: 16,
      ),
      label: Text(
        isShowingOriginal.value ? l10n.translate('see_translation') : l10n.translate('see_original'),
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

/// Helper function to use useState in ConsumerWidget
ValueNotifier<T> useState<T>(T initialValue) {
  return ValueNotifier<T>(initialValue);
}

/// Translation status indicator
class TranslationIndicator extends ConsumerWidget {
  final String? sourceLanguage;
  final bool isTranslated;

  const TranslationIndicator({
    super.key,
    this.sourceLanguage,
    this.isTranslated = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(translationSettingsProvider);

    if (!settings.isEnabled || !isTranslated) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: AppSizes.paddingXS,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppSizes.radiusSM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.translate,
            size: 12,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'Tradus',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }
}

/// Translation settings tile for settings screen
class TranslationSettingsTile extends ConsumerWidget {
  const TranslationSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(translationSettingsProvider);

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Traducere automată'),
          subtitle: const Text('Traduce automat conținutul în limba ta'),
          secondary: const Icon(Icons.translate),
          value: settings.isEnabled,
          onChanged: (value) {
            ref.read(translationSettingsProvider.notifier).setEnabled(value);
          },
        ),
        if (settings.isEnabled) ...[
          ListTile(
            title: const Text('Furnizor traducere'),
            subtitle: Text(_getProviderName(settings.provider)),
            leading: const Icon(Icons.cloud),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showProviderDialog(context, ref),
          ),
          if (settings.provider != TranslationProvider.none)
            ListTile(
              title: const Text('Cheie API'),
              subtitle: Text(
                settings.apiKey != null ? '••••••••' : 'Nu este configurată',
              ),
              leading: const Icon(Icons.key),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showApiKeyDialog(context, ref),
            ),
        ],
      ],
    );
  }

  String _getProviderName(TranslationProvider provider) {
    switch (provider) {
      case TranslationProvider.google:
        return 'Google Cloud Translation';
      case TranslationProvider.deepL:
        return 'DeepL';
      case TranslationProvider.libre:
        return 'LibreTranslate (Gratuit)';
      case TranslationProvider.none:
        return 'Dezactivat';
    }
  }

  void _showProviderDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Consumer(
          builder: (context, ref, child) {
            final settings = ref.watch(translationSettingsProvider);

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.paddingMD),
                    child: Text(
                      'Selectează furnizorul',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  ...TranslationProvider.values.map((provider) {
                    final isSelected = provider == settings.provider;
                    return ListTile(
                      leading: Icon(
                        provider == TranslationProvider.google
                            ? Icons.g_mobiledata
                            : provider == TranslationProvider.deepL
                                ? Icons.translate
                                : provider == TranslationProvider.libre
                                    ? Icons.public
                                    : Icons.block,
                      ),
                      title: Text(_getProviderName(provider)),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary)
                          : const Icon(Icons.circle_outlined),
                      onTap: () {
                        ref.read(translationSettingsProvider.notifier).setProvider(provider);
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

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(translationSettingsProvider);
    final controller = TextEditingController(text: settings.apiKey ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cheie API'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Introdu cheia API',
            hintText: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
          ),
          obscureText: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anulează'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(translationSettingsProvider.notifier)
                  .setApiKey(controller.text.isNotEmpty ? controller.text : null);
              Navigator.pop(context);
            },
            child: const Text('Salvează'),
          ),
        ],
      ),
    );
  }
}
