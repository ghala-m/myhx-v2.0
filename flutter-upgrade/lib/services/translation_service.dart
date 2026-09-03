import 'dart:convert';

import 'package:http/http.dart' as http;
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

  bool _looksArabic(String text) =>
      RegExp(r'[\u0600-\u06FF]').hasMatch(text);

  /// Translate [text] to Arabic. Returns the original text on any failure.
  Future<String> toArabic(String text) async {
    final source = text.trim();
    if (source.isEmpty || _looksArabic(source)) return text;
    await _ensureLoaded();
    final hit = _memory[source];
    if (hit != null) return hit;

    try {
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl': 'en',
        'tl': 'ar',
        'dt': 't',
        'q': source,
      });
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return text;
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! List || decoded.isEmpty) return text;
      final segments = decoded.first;
      if (segments is! List) return text;
      final buffer = StringBuffer();
      for (final seg in segments) {
        if (seg is List && seg.isNotEmpty && seg.first != null) {
          buffer.write(seg.first.toString());
        }
      }
      final result = buffer.toString().trim();
      if (result.isEmpty) return text;
      _memory[source] = result;
      await _save();
      return result;
    } catch (_) {
      return text;
    }
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
