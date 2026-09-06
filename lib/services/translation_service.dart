import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Translates user-entered English content to Arabic on the fly.
///
/// Data entry stays English-only; when the user switches the app to Arabic,
/// stored free text is machine-translated and cached locally so the same
/// string is never translated twice.
class TranslationService {
  TranslationService._();
  static final TranslationService instance = TranslationService._();

  static const _prefsKey = 'translation_cache_v1';

  final Map<String, String> _memory = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((k, v) => _memory[k.toString()] = v.toString());
        }
      }
    } catch (_) {}
    _loaded = true;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_memory));
    } catch (_) {}
  }

  /// Cached translation if we already have one (synchronous, for build()).
  String? cached(String text) => _memory[text.trim()];

  /// Translate [text] to Arabic. Returns the original text on any failure.
  ///
  /// ⚠️ DISABLED as of this audit: this used to call the *undocumented*
  /// Google Translate endpoint (translate.googleapis.com/translate_a/single
  /// — the one browser extensions use, not the official paid Cloud
  /// Translation API). That endpoint has no SLA, is against Google's ToS,
  /// and — critically — was sending potentially patient-derived clinical
  /// text (diagnoses, symptoms, free-text notes) to an undocumented
  /// third-party service on every patient-record view in Arabic mode, with
  /// no consent notice or data-processing agreement. That is not
  /// acceptable for a clinical app, so the network call has been removed.
  ///
  /// [TranslatedText] still calls this and will just display the original
  /// (English) text until this is replaced with either:
  ///   (a) the official Cloud Translation API behind a server-side proxy
  ///       that never receives an embedded client key, with a privacy
  ///       notice covering this data flow, or
  ///   (b) dropping machine translation entirely and relying only on the
  ///       static l10n/app_strings.dart table for UI copy.
  Future<String> toArabic(String text) async {
    // Network call intentionally removed — see doc comment above.
    return text;
  }

  /// Translate a batch of strings, preserving order.
  Future<List<String>> toArabicAll(Iterable<String> texts) async {
    final out = <String>[];
    for (final t in texts) {
      out.add(await toArabic(t));
    }
    return out;
  }

  /// Translate every string value of a map (keys untouched).
  Future<Map<String, dynamic>> translateValues(Map<String, dynamic> map) async {
    final out = <String, dynamic>{};
    for (final entry in map.entries) {
      final v = entry.value;
      out[entry.key] = v is String ? await toArabic(v) : v;
    }
    return out;
  }

  Future<void> clearCache() async {
    _memory.clear();
    await _save();
  }
}
