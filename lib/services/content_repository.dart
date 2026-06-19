import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/lesson.dart';
import '../models/prompt.dart';

/// Loads app content (prompts, lessons) from JSON assets at runtime. Nothing is
/// hardcoded in Dart — the content lives in `assets/data/*.json` and can be
/// edited without touching the code. (Vocabulary is drawn live from the full
/// dictionary, so it has no static list.)
class ContentRepository {
  final List<WritingPrompt> prompts;
  final List<Lesson> lessons;

  const ContentRepository({
    required this.prompts,
    required this.lessons,
  });

  static Future<ContentRepository> load() async {
    final prompts = await _loadList('assets/data/prompts.json');
    final lessons = await _loadList('assets/data/lessons.json');

    return ContentRepository(
      prompts: prompts.map(WritingPrompt.fromMap).toList(),
      lessons: lessons.map(Lesson.fromMap).toList(),
    );
  }

  static Future<List<Map<String, dynamic>>> _loadList(String path) async {
    final raw = await rootBundle.loadString(path);
    final data = jsonDecode(raw) as List<dynamic>;
    return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
  }

  /// Distinct prompt categories, derived from the loaded data.
  List<String> get promptCategories {
    final set = <String>{};
    for (final p in prompts) {
      set.add(p.category);
    }
    return set.toList();
  }

  /// Distinct levels, ordered by difficulty. The order is derived from the
  /// data itself (by the average suggested word count per level), so it stays
  /// correct without any hardcoded list.
  List<String> get levels {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final p in prompts) {
      totals[p.level] = (totals[p.level] ?? 0) + p.suggestedWords;
      counts[p.level] = (counts[p.level] ?? 0) + 1;
    }
    final list = totals.keys.toList();
    double avg(String l) => totals[l]! / counts[l]!;
    list.sort((a, b) => avg(a).compareTo(avg(b)));
    return list;
  }
}
