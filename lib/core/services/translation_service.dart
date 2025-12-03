import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Supported translation providers
enum TranslationProvider {
  google,
  deepL,
  libre, // Free, self-hosted option
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
