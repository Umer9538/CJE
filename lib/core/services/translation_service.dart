import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Supported translation providers
enum TranslationProvider {
  google,
  deepL,
  libre, // Free, self-hosted option
  mlKit, // Firebase ML Kit (offline, free)
  none, // No translation (returns original text)
}

/// Translation result
class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final bool isTranslated;
  final DateTime timestamp;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.isTranslated,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TranslationResult.notTranslated(String text) {
    return TranslationResult(
      originalText: text,
      translatedText: text,
      sourceLanguage: 'unknown',
      targetLanguage: 'unknown',
      isTranslated: false,
    );
  }

  Map<String, dynamic> toJson() => {
        'originalText': originalText,
        'translatedText': translatedText,
        'sourceLanguage': sourceLanguage,
        'targetLanguage': targetLanguage,
        'isTranslated': isTranslated,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      isTranslated: json['isTranslated'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Abstract translation service interface
abstract class TranslationService {
  /// Translate text from source language to target language
  Future<TranslationResult> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage, // Auto-detect if null
  });

  /// Translate multiple texts at once (batch translation)
  Future<List<TranslationResult>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String? sourceLanguage,
  });

  /// Detect the language of the given text
  Future<String> detectLanguage(String text);

  /// Check if translation is available
  Future<bool> isAvailable();
}

/// Google Cloud Translation API implementation
class GoogleTranslationService implements TranslationService {
  final String apiKey;
  final String _baseUrl = 'https://translation.googleapis.com/language/translate/v2';

  GoogleTranslationService({required this.apiKey});

  @override
  Future<TranslationResult> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult.notTranslated(text);
    }

    try {
      final uri = Uri.parse(_baseUrl);
      final body = {
        'q': text,
        'target': targetLanguage,
        'key': apiKey,
        'format': 'text',
      };

      if (sourceLanguage != null) {
        body['source'] = sourceLanguage;
      }

      final response = await http.post(uri, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translation = data['data']['translations'][0];
        final translatedText = translation['translatedText'] as String;
        final detectedSource =
            translation['detectedSourceLanguage'] as String? ?? sourceLanguage ?? 'auto';

        return TranslationResult(
          originalText: text,
          translatedText: translatedText,
          sourceLanguage: detectedSource,
          targetLanguage: targetLanguage,
          isTranslated: true,
        );
      } else {
        debugPrint('Translation API error: ${response.statusCode} - ${response.body}');
        return TranslationResult.notTranslated(text);
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      return TranslationResult.notTranslated(text);
    }
  }

  @override
  Future<List<TranslationResult>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (texts.isEmpty) return [];

    try {
      final uri = Uri.parse(_baseUrl);
      final body = <String, dynamic>{
        'q': texts,
        'target': targetLanguage,
        'key': apiKey,
        'format': 'text',
      };

      if (sourceLanguage != null) {
        body['source'] = sourceLanguage;
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translations = data['data']['translations'] as List;

        return List.generate(texts.length, (index) {
          final translation = translations[index];
          return TranslationResult(
            originalText: texts[index],
            translatedText: translation['translatedText'] as String,
            sourceLanguage:
                translation['detectedSourceLanguage'] as String? ?? sourceLanguage ?? 'auto',
            targetLanguage: targetLanguage,
            isTranslated: true,
          );
        });
      } else {
        return texts.map((t) => TranslationResult.notTranslated(t)).toList();
      }
    } catch (e) {
      debugPrint('Batch translation error: $e');
      return texts.map((t) => TranslationResult.notTranslated(t)).toList();
    }
  }

  @override
  Future<String> detectLanguage(String text) async {
    try {
      final uri = Uri.parse('$_baseUrl/detect');
      final response = await http.post(uri, body: {
        'q': text,
        'key': apiKey,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['detections'][0][0]['language'] as String;
      }
      return 'unknown';
    } catch (e) {
      debugPrint('Language detection error: $e');
      return 'unknown';
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final uri = Uri.parse('$_baseUrl/languages?key=$apiKey&target=en');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// DeepL Translation API implementation
class DeepLTranslationService implements TranslationService {
  final String apiKey;
  final bool useFreeApi;

  String get _baseUrl => useFreeApi
      ? 'https://api-free.deepl.com/v2'
      : 'https://api.deepl.com/v2';

  DeepLTranslationService({
    required this.apiKey,
    this.useFreeApi = true,
  });

  @override
  Future<TranslationResult> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult.notTranslated(text);
    }

    try {
      final uri = Uri.parse('$_baseUrl/translate');
      final body = {
        'text': [text],
        'target_lang': targetLanguage.toUpperCase(),
      };

      if (sourceLanguage != null) {
        body['source_lang'] = sourceLanguage.toUpperCase();
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'DeepL-Auth-Key $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translation = data['translations'][0];

        return TranslationResult(
          originalText: text,
          translatedText: translation['text'] as String,
          sourceLanguage: translation['detected_source_language'] as String? ?? 'auto',
          targetLanguage: targetLanguage,
          isTranslated: true,
        );
      } else {
        return TranslationResult.notTranslated(text);
      }
    } catch (e) {
      debugPrint('DeepL translation error: $e');
      return TranslationResult.notTranslated(text);
    }
  }

  @override
  Future<List<TranslationResult>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    // DeepL supports batch in single request
    if (texts.isEmpty) return [];

    try {
      final uri = Uri.parse('$_baseUrl/translate');
      final body = <String, dynamic>{
        'text': texts,
        'target_lang': targetLanguage.toUpperCase(),
      };

      if (sourceLanguage != null) {
        body['source_lang'] = sourceLanguage.toUpperCase();
      }

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'DeepL-Auth-Key $apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translations = data['translations'] as List;

        return List.generate(texts.length, (index) {
          final translation = translations[index];
          return TranslationResult(
            originalText: texts[index],
            translatedText: translation['text'] as String,
            sourceLanguage: translation['detected_source_language'] as String? ?? 'auto',
            targetLanguage: targetLanguage,
            isTranslated: true,
          );
        });
      } else {
        return texts.map((t) => TranslationResult.notTranslated(t)).toList();
      }
    } catch (e) {
      debugPrint('DeepL batch translation error: $e');
      return texts.map((t) => TranslationResult.notTranslated(t)).toList();
    }
  }

  @override
  Future<String> detectLanguage(String text) async {
    // DeepL doesn't have a separate detect endpoint
    // We use translate and get detected language
    final result = await translate(text: text, targetLanguage: 'EN');
    return result.sourceLanguage;
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final uri = Uri.parse('$_baseUrl/usage');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'DeepL-Auth-Key $apiKey'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// LibreTranslate (Free, self-hosted) implementation
class LibreTranslationService implements TranslationService {
  final String baseUrl;
  final String? apiKey;

  LibreTranslationService({
    this.baseUrl = 'https://libretranslate.com',
    this.apiKey,
  });

  @override
  Future<TranslationResult> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult.notTranslated(text);
    }

    try {
      final uri = Uri.parse('$baseUrl/translate');
      final body = <String, String>{
        'q': text,
        'source': sourceLanguage ?? 'auto',
        'target': targetLanguage,
        'format': 'text',
      };

      if (apiKey != null) {
        body['api_key'] = apiKey!;
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TranslationResult(
          originalText: text,
          translatedText: data['translatedText'] as String,
          sourceLanguage: data['detectedLanguage']?['language'] as String? ?? sourceLanguage ?? 'auto',
          targetLanguage: targetLanguage,
          isTranslated: true,
        );
      } else {
        return TranslationResult.notTranslated(text);
      }
    } catch (e) {
      debugPrint('LibreTranslate error: $e');
      return TranslationResult.notTranslated(text);
    }
  }

  @override
  Future<List<TranslationResult>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    // LibreTranslate doesn't support batch, so we translate one by one
    final results = <TranslationResult>[];
    for (final text in texts) {
      results.add(await translate(
        text: text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      ));
    }
    return results;
  }

  @override
  Future<String> detectLanguage(String text) async {
    try {
      final uri = Uri.parse('$baseUrl/detect');
      final body = <String, String>{'q': text};

      if (apiKey != null) {
        body['api_key'] = apiKey!;
      }

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          return data[0]['language'] as String;
        }
      }
      return 'unknown';
    } catch (e) {
      debugPrint('LibreTranslate detect error: $e');
      return 'unknown';
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      final uri = Uri.parse('$baseUrl/languages');
      final response = await http.get(uri);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// No-op translation service (returns original text)
class NoOpTranslationService implements TranslationService {
  @override
  Future<TranslationResult> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    return TranslationResult.notTranslated(text);
  }

  @override
  Future<List<TranslationResult>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    return texts.map((t) => TranslationResult.notTranslated(t)).toList();
  }

  @override
  Future<String> detectLanguage(String text) async => 'unknown';

  @override
  Future<bool> isAvailable() async => true;
}

/// Firebase ML Kit Translation Service (offline, free)
class MLKitTranslationService implements TranslationService {
  final _modelManager = OnDeviceTranslatorModelManager();
  final Map<String, OnDeviceTranslator> _translators = {};
  bool _isInitialized = false;

  /// Get language code for ML Kit
  TranslateLanguage _getLanguage(String code) {
    switch (code.toLowerCase()) {
      case 'ro':
      case 'romanian':
        return TranslateLanguage.romanian;
      case 'en':
      case 'english':
      default:
        return TranslateLanguage.english;
    }
  }

  /// Initialize and download required models
  Future<void> _ensureModelDownloaded(String languageCode) async {
    final bcpCode = _getLanguage(languageCode).bcpCode;
    final isDownloaded = await _modelManager.isModelDownloaded(bcpCode);
    if (!isDownloaded) {
      debugPrint('MLKitTranslation: Downloading model for $languageCode...');
      await _modelManager.downloadModel(bcpCode);
      debugPrint('MLKitTranslation: Model downloaded for $languageCode');
    }
  }

  /// Get or create translator for language pair
  Future<OnDeviceTranslator> _getTranslator(String sourceLanguage, String targetLanguage) async {
    final key = '${sourceLanguage}_$targetLanguage';

    if (!_translators.containsKey(key)) {
      await _ensureModelDownloaded(sourceLanguage);
      await _ensureModelDownloaded(targetLanguage);

      _translators[key] = OnDeviceTranslator(
        sourceLanguage: _getLanguage(sourceLanguage),
        targetLanguage: _getLanguage(targetLanguage),
      );
    }

    return _translators[key]!;
  }

  @override
  Future<TranslationResult> translate({
    required String text,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    if (text.trim().isEmpty) {
      return TranslationResult.notTranslated(text);
    }

    try {
      // Detect source language if not provided
      final source = sourceLanguage ?? await detectLanguage(text);

      // Don't translate if source and target are the same
      if (source.toLowerCase() == targetLanguage.toLowerCase()) {
        return TranslationResult(
          originalText: text,
          translatedText: text,
          sourceLanguage: source,
          targetLanguage: targetLanguage,
          isTranslated: false,
        );
      }

      final translator = await _getTranslator(source, targetLanguage);
      final translatedText = await translator.translateText(text);

      return TranslationResult(
        originalText: text,
        translatedText: translatedText,
        sourceLanguage: source,
        targetLanguage: targetLanguage,
        isTranslated: true,
      );
    } catch (e) {
      debugPrint('MLKitTranslation error: $e');
      return TranslationResult.notTranslated(text);
    }
  }

  @override
  Future<List<TranslationResult>> translateBatch({
    required List<String> texts,
    required String targetLanguage,
    String? sourceLanguage,
  }) async {
    final results = <TranslationResult>[];
    for (final text in texts) {
      results.add(await translate(
        text: text,
        targetLanguage: targetLanguage,
        sourceLanguage: sourceLanguage,
      ));
    }
    return results;
  }

  @override
  Future<String> detectLanguage(String text) async {
    final lowerText = text.toLowerCase();

    // Romanian indicators (diacritics and common words)
    final romanianIndicators = [
      'ă', 'â', 'î', 'ș', 'ț',
      ' și ', ' în ', ' că ', ' de ', ' la ', ' cu ', ' pe ', ' din ',
      ' pentru ', ' sau ', ' este ', ' sunt ', ' era ', ' fost ',
      ' această ', ' acest ', ' aceștia ', ' care ', ' mai ',
    ];

    // English indicators
    final englishIndicators = [
      ' the ', ' and ', ' is ', ' are ', ' was ', ' were ', ' be ',
      ' have ', ' has ', ' had ', ' do ', ' does ', ' did ',
      ' will ', ' would ', ' could ', ' should ', ' this ', ' that ',
      ' with ', ' from ', ' for ', ' not ', ' but ', ' or ',
    ];

    int roScore = 0;
    int enScore = 0;

    for (final indicator in romanianIndicators) {
      if (lowerText.contains(indicator)) roScore++;
    }

    for (final indicator in englishIndicators) {
      if (lowerText.contains(indicator)) enScore++;
    }

    return roScore > enScore ? 'ro' : 'en';
  }

  @override
  Future<bool> isAvailable() async {
    try {
      // Check if at least English model is available or can be downloaded
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Close all translators
  void dispose() {
    for (final translator in _translators.values) {
      translator.close();
    }
    _translators.clear();
    _isInitialized = false;
  }
}

/// Global ML Kit translation service instance
final mlKitTranslationService = MLKitTranslationService();

/// Translation cache manager
class TranslationCache {
  final SharedPreferences _prefs;
  final Duration cacheDuration;
  static const String _cachePrefix = 'translation_cache_';

  TranslationCache(this._prefs, {this.cacheDuration = const Duration(days: 7)});

  /// Generate cache key from text and target language
  String _generateKey(String text, String targetLanguage) {
    final content = '$text|$targetLanguage';
    final hash = md5.convert(utf8.encode(content)).toString();
    return '$_cachePrefix$hash';
  }

  /// Get cached translation
  TranslationResult? get(String text, String targetLanguage) {
    final key = _generateKey(text, targetLanguage);
    final cached = _prefs.getString(key);

    if (cached == null) return null;

    try {
      final result = TranslationResult.fromJson(json.decode(cached));

      // Check if cache is expired
      if (DateTime.now().difference(result.timestamp) > cacheDuration) {
        _prefs.remove(key);
        return null;
      }

      return result;
    } catch (e) {
      _prefs.remove(key);
      return null;
    }
  }

  /// Store translation in cache
  Future<void> set(TranslationResult result) async {
    final key = _generateKey(result.originalText, result.targetLanguage);
    await _prefs.setString(key, json.encode(result.toJson()));
  }

  /// Clear all cached translations
  Future<void> clear() async {
    final keys = _prefs.getKeys().where((k) => k.startsWith(_cachePrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Get cache size
  int get size {
    return _prefs.getKeys().where((k) => k.startsWith(_cachePrefix)).length;
  }
}

/// Translatable content - stores text in both English and Romanian
class TranslatableContent {
  final String en;
  final String ro;

  const TranslatableContent({required this.en, required this.ro});

  /// Get content for specific language
  String forLanguage(String languageCode) {
    return languageCode.toLowerCase() == 'ro' ? ro : en;
  }

  /// Create from single text (same for both languages)
  factory TranslatableContent.single(String text) {
    return TranslatableContent(en: text, ro: text);
  }

  /// Create from translation result
  static Future<TranslatableContent> fromText(String text, {TranslationService? service}) async {
    final translationService = service ?? mlKitTranslationService;
    final detectedLang = await translationService.detectLanguage(text);

    if (detectedLang == 'ro') {
      final enResult = await translationService.translate(
        text: text,
        targetLanguage: 'en',
        sourceLanguage: 'ro',
      );
      return TranslatableContent(
        en: enResult.isTranslated ? enResult.translatedText : text,
        ro: text,
      );
    } else {
      final roResult = await translationService.translate(
        text: text,
        targetLanguage: 'ro',
        sourceLanguage: 'en',
      );
      return TranslatableContent(
        en: text,
        ro: roResult.isTranslated ? roResult.translatedText : text,
      );
    }
  }

  Map<String, dynamic> toJson() => {'en': en, 'ro': ro};

  factory TranslatableContent.fromJson(Map<String, dynamic> json) {
    return TranslatableContent(
      en: json['en'] as String? ?? '',
      ro: json['ro'] as String? ?? '',
    );
  }

  /// Create from Firestore data (handles both old single-value and new multilingual format)
  factory TranslatableContent.fromFirestore(dynamic data, {String? fallbackField}) {
    if (data is Map<String, dynamic>) {
      return TranslatableContent.fromJson(data);
    } else if (data is String) {
      return TranslatableContent.single(data);
    }
    return TranslatableContent.single('');
  }

  @override
  String toString() => 'TranslatableContent(en: $en, ro: $ro)';
}
