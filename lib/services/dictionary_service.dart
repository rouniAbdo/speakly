import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_details.dart';

enum LookupStatus { ok, notFound, offline, error }

/// Result of a dictionary lookup.
class LookupResult {
  final LookupStatus status;
  final WordDetails? details;
  final bool fromCache;
  const LookupResult(this.status, {this.details, this.fromCache = false});
}

/// Loads the bundled common-word list and looks words up against the free
/// dictionary API (dictionaryapi.dev), caching every result on-device.
class DictionaryService {
  static const _cachePrefix = 'dict_v1_';
  static const _assetPath = 'assets/words/common_words.txt';
  static const _endpoint =
      'https://api.dictionaryapi.dev/api/v2/entries/en/';

  List<String>? _words;

  /// The full bundled word list (loaded once, cached in memory).
  Future<List<String>> loadWords() async {
    if (_words != null) return _words!;
    final raw = await rootBundle.loadString(_assetPath);
    _words = raw
        .split('\n')
        .map((w) => w.trim())
        .where((w) => w.isNotEmpty)
        .toList();
    return _words!;
  }

  /// The integer day-number for [date] (days since the Unix epoch, local time).
  /// Used to seed a selection that is stable for a day and changes daily.
  static int dayNumber([DateTime? date]) {
    final d = date ?? DateTime.now();
    return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  List<String>? _studyPoolCache;

  /// The pool of words worth studying: mid-frequency words (skip the most
  /// trivial like "the"/"of" and the very rare tail) of a useful length.
  Future<List<String>> studyPool() async {
    if (_studyPoolCache != null) return _studyPoolCache!;
    final all = await loadWords();
    final pool = <String>[];
    for (var i = 0; i < all.length; i++) {
      if (i >= 120 && i < 6000 && all[i].length >= 4) {
        pool.add(all[i]);
      }
    }
    _studyPoolCache = pool.isEmpty ? all : pool;
    return _studyPoolCache!;
  }

  /// A fresh set of words to study today. The selection is deterministic for
  /// a given calendar day and automatically rotates to new words each day.
  Future<List<String>> dailyWords({int count = 12, DateTime? date}) async {
    final pool = await studyPool();
    final rng = Random(dayNumber(date));
    final shuffled = List<String>.from(pool)..shuffle(rng);
    return shuffled.take(count).toList();
  }

  /// A random batch of study words, excluding any in [exclude] (e.g. words
  /// already learned or already shown). A new call returns different words, so
  /// the user never has to see the same list twice.
  Future<List<String>> pickWords({
    int count = 12,
    Set<String> exclude = const {},
    int? seed,
  }) async {
    final pool = await studyPool();
    final ex = exclude.map((e) => e.toLowerCase()).toSet();
    final candidates =
        pool.where((w) => !ex.contains(w.toLowerCase())).toList();
    if (candidates.isEmpty) return [];
    candidates.shuffle(seed == null ? Random() : Random(seed));
    return candidates.take(count).toList();
  }

  Future<bool> isCached(String word) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_cachePrefix + word.toLowerCase());
  }

  Future<WordDetails?> _readCache(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachePrefix + word.toLowerCase());
    if (raw == null) return null;
    try {
      return WordDetails.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(WordDetails d) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _cachePrefix + d.word.toLowerCase(), jsonEncode(d.toMap()));
  }

  /// Look up a word: returns cached data instantly if present, otherwise
  /// fetches from the API and caches the result.
  Future<LookupResult> lookup(String word, {bool forceRefresh = false}) async {
    final clean = word.trim().toLowerCase();
    if (clean.isEmpty) return const LookupResult(LookupStatus.notFound);

    if (!forceRefresh) {
      final cached = await _readCache(clean);
      if (cached != null) {
        return LookupResult(LookupStatus.ok,
            details: cached, fromCache: true);
      }
    }

    try {
      final resp = await http
          .get(Uri.parse('$_endpoint${Uri.encodeComponent(clean)}'))
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 404) {
        return const LookupResult(LookupStatus.notFound);
      }
      if (resp.statusCode != 200) {
        return const LookupResult(LookupStatus.error);
      }

      final data = jsonDecode(resp.body);
      if (data is! List || data.isEmpty) {
        return const LookupResult(LookupStatus.notFound);
      }

      final details = WordDetails.fromApi(clean, data);
      if (details.senses.isEmpty) {
        return const LookupResult(LookupStatus.notFound);
      }
      await _writeCache(details);
      return LookupResult(LookupStatus.ok, details: details);
    } catch (_) {
      // No connection / timeout / parse failure.
      return const LookupResult(LookupStatus.offline);
    }
  }
}
