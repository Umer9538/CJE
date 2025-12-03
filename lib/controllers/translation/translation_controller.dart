import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/translation_service.dart';
import '../theme/theme_controller.dart';
import '../language/language_controller.dart';

/// Translation settings storage keys
const String _translationEnabledKey = 'translation_enabled';
const String _translationProviderKey = 'translation_provider';
const String _translationApiKeyKey = 'translation_api_key';
const String _autoTranslateKey = 'auto_translate';

/// Translation settings state
class TranslationSettings {
  final bool isEnabled;
  final TranslationProvider provider;
  final String? apiKey;
  final bool autoTranslate;

  const TranslationSettings({
    this.isEnabled = false,
    this.provider = TranslationProvider.none,
    this.apiKey,
    this.autoTranslate = true,
  });

  TranslationSettings copyWith({
    bool? isEnabled,
    TranslationProvider? provider,
    String? apiKey,
    bool? autoTranslate,
  }) {
    return TranslationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      autoTranslate: autoTranslate ?? this.autoTranslate,
    );
  }
}

/// Translation settings notifier
class TranslationSettingsNotifier extends StateNotifier<TranslationSettings> {
  final SharedPreferences _prefs;

  TranslationSettingsNotifier(this._prefs) : super(_loadSettings(_prefs));

  static TranslationSettings _loadSettings(SharedPreferences prefs) {
    return TranslationSettings(
      isEnabled: prefs.getBool(_translationEnabledKey) ?? false,
      provider: TranslationProvider.values[
          prefs.getInt(_translationProviderKey) ?? TranslationProvider.none.index],
      apiKey: prefs.getString(_translationApiKeyKey),
      autoTranslate: prefs.getBool(_autoTranslateKey) ?? true,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(isEnabled: enabled);
    await _prefs.setBool(_translationEnabledKey, enabled);
  }

  Future<void> setProvider(TranslationProvider provider) async {
    state = state.copyWith(provider: provider);
    await _prefs.setInt(_translationProviderKey, provider.index);
  }

  Future<void> setApiKey(String? apiKey) async {
    state = state.copyWith(apiKey: apiKey);
    if (apiKey != null) {
      await _prefs.setString(_translationApiKeyKey, apiKey);
    } else {
      await _prefs.remove(_translationApiKeyKey);
    }
  }

  Future<void> setAutoTranslate(bool autoTranslate) async {
    state = state.copyWith(autoTranslate: autoTranslate);
    await _prefs.setBool(_autoTranslateKey, autoTranslate);
  }

  Future<void> configure({
    required TranslationProvider provider,
    required String apiKey,
    bool enabled = true,
    bool autoTranslate = true,
  }) async {
    state = TranslationSettings(
      isEnabled: enabled,
      provider: provider,
      apiKey: apiKey,
      autoTranslate: autoTranslate,
    );
    await _prefs.setBool(_translationEnabledKey, enabled);
    await _prefs.setInt(_translationProviderKey, provider.index);
    await _prefs.setString(_translationApiKeyKey, apiKey);
    await _prefs.setBool(_autoTranslateKey, autoTranslate);
  }
}

/// Translation settings provider
final translationSettingsProvider =
    StateNotifierProvider<TranslationSettingsNotifier, TranslationSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TranslationSettingsNotifier(prefs);
});

/// Translation service provider
final translationServiceProvider = Provider<TranslationService>((ref) {
  final settings = ref.watch(translationSettingsProvider);

  if (!settings.isEnabled || settings.apiKey == null) {
    return NoOpTranslationService();
  }

  switch (settings.provider) {
    case TranslationProvider.google:
      return GoogleTranslationService(apiKey: settings.apiKey!);
    case TranslationProvider.deepL:
      return DeepLTranslationService(apiKey: settings.apiKey!);
    case TranslationProvider.libre:
      return LibreTranslationService(apiKey: settings.apiKey);
    case TranslationProvider.none:
      return NoOpTranslationService();
  }
});

/// Translation cache provider
final translationCacheProvider = Provider<TranslationCache>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TranslationCache(prefs);
});

/// Translation controller for handling translations
class TranslationController {
  final TranslationService service;
  final TranslationCache cache;
  final String targetLanguage;
  final bool isEnabled;

  TranslationController({
    required this.service,
    required this.cache,
    required this.targetLanguage,
    required this.isEnabled,
  });

  /// Translate text with caching
  Future<TranslationResult> translate(
    String text, {
    String? sourceLanguage,
    bool useCache = true,
  }) async {
    if (!isEnabled || text.trim().isEmpty) {
      return TranslationResult.notTranslated(text);
    }

    // Check cache first
    if (useCache) {
      final cached = cache.get(text, targetLanguage);
      if (cached != null) {
        return cached;
      }
    }

    // Perform translation
    final result = await service.translate(
      text: text,
      targetLanguage: targetLanguage,
      sourceLanguage: sourceLanguage,
    );

    // Cache the result if translation was successful
    if (result.isTranslated && useCache) {
      await cache.set(result);
    }

    return result;
  }

  /// Translate multiple texts with caching
  Future<List<TranslationResult>> translateBatch(
    List<String> texts, {
    String? sourceLanguage,
    bool useCache = true,
  }) async {
    if (!isEnabled || texts.isEmpty) {
      return texts.map((t) => TranslationResult.notTranslated(t)).toList();
    }

    final results = <TranslationResult>[];
    final textsToTranslate = <String>[];
    final textsIndices = <int>[];

    // Check cache first
    for (int i = 0; i < texts.length; i++) {
      if (useCache) {
        final cached = cache.get(texts[i], targetLanguage);
        if (cached != null) {
          results.add(cached);
          continue;
        }
      }
      textsToTranslate.add(texts[i]);
      textsIndices.add(i);
    }

    // Translate uncached texts
    if (textsToTranslate.isNotEmpty) {
      final translated = await service.translateBatch(
        texts: textsToTranslate,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      );

      // Cache results and add to list
      for (int i = 0; i < translated.length; i++) {
        if (translated[i].isTranslated && useCache) {
          await cache.set(translated[i]);
        }
        results.insert(textsIndices[i], translated[i]);
      }
    }

    return results;
  }

  /// Detect language of text
  Future<String> detectLanguage(String text) async {
    return service.detectLanguage(text);
  }

  /// Clear translation cache
  Future<void> clearCache() async {
    await cache.clear();
  }
}

/// Translation controller provider
final translationControllerProvider = Provider<TranslationController>((ref) {
  final service = ref.watch(translationServiceProvider);
  final cache = ref.watch(translationCacheProvider);
  final locale = ref.watch(languageProvider);
  final settings = ref.watch(translationSettingsProvider);

  return TranslationController(
    service: service,
    cache: cache,
    targetLanguage: locale.languageCode,
    isEnabled: settings.isEnabled,
  );
});

/// Single text translation provider (for use in widgets)
final translateTextProvider =
    FutureProvider.family<TranslationResult, String>((ref, text) async {
  final controller = ref.watch(translationControllerProvider);
  return controller.translate(text);
});

/// Batch text translation provider
final translateBatchProvider =
    FutureProvider.family<List<TranslationResult>, List<String>>((ref, texts) async {
  final controller = ref.watch(translationControllerProvider);
  return controller.translateBatch(texts);
});

/// Extension for easy translation access
extension TranslationExtension on String {
  /// Check if text needs translation (different from target language)
  bool needsTranslation(String targetLanguage, String? sourceLanguage) {
    if (sourceLanguage == null) return true;
    return sourceLanguage.toLowerCase() != targetLanguage.toLowerCase();
  }
}

/// Translatable content mixin for models
mixin TranslatableContent {
  /// Original language of the content
  String? get originalLanguage;

  /// Get translatable fields
  Map<String, String> get translatableFields;

  /// Store translated fields
  final Map<String, Map<String, String>> _translations = {};

  /// Get translated value for a field
  String getTranslatedField(String fieldName, String targetLanguage) {
    // Return cached translation if available
    if (_translations[targetLanguage]?.containsKey(fieldName) == true) {
      return _translations[targetLanguage]![fieldName]!;
    }
    // Return original value
    return translatableFields[fieldName] ?? '';
  }

  /// Store translated value for a field
  void setTranslatedField(String fieldName, String targetLanguage, String value) {
    _translations[targetLanguage] ??= {};
    _translations[targetLanguage]![fieldName] = value;
  }

  /// Check if content needs translation
  bool needsTranslation(String targetLanguage) {
    if (originalLanguage == null) return false;
    return originalLanguage!.toLowerCase() != targetLanguage.toLowerCase();
  }
}
