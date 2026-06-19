import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/writing_entry.dart';

/// Handles persistence of entries, streak data, and learned words.
class StorageService {
  static const _kEntries = 'entries_v1';
  static const _kStreakDates = 'streak_dates_v1';
  static const _kLearnedWords = 'learned_words_v1';
  static const _kDailyGoal = 'daily_goal_v1';
  static const _kReadLessons = 'read_lessons_v1';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ---------------- Entries ----------------
  Future<List<WritingEntry>> loadEntries() async {
    final prefs = await _prefs;
    final raw = prefs.getStringList(_kEntries) ?? [];
    final entries = <WritingEntry>[];
    for (final s in raw) {
      try {
        entries.add(WritingEntry.fromJson(s));
      } catch (_) {
        // skip corrupt entry
      }
    }
    entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries;
  }

  Future<void> saveEntries(List<WritingEntry> entries) async {
    final prefs = await _prefs;
    final raw = entries.map((e) => e.toJson()).toList();
    await prefs.setStringList(_kEntries, raw);
  }

  // ---------------- Streak ----------------
  Future<Set<String>> loadStreakDates() async {
    final prefs = await _prefs;
    return (prefs.getStringList(_kStreakDates) ?? []).toSet();
  }

  Future<void> saveStreakDates(Set<String> dates) async {
    final prefs = await _prefs;
    await prefs.setStringList(_kStreakDates, dates.toList());
  }

  // ---------------- Learned words ----------------
  Future<Set<String>> loadLearnedWords() async {
    final prefs = await _prefs;
    return (prefs.getStringList(_kLearnedWords) ?? []).toSet();
  }

  Future<void> saveLearnedWords(Set<String> words) async {
    final prefs = await _prefs;
    await prefs.setStringList(_kLearnedWords, words.toList());
  }

  // ---------------- Read lessons ----------------
  Future<Set<String>> loadReadLessons() async {
    final prefs = await _prefs;
    return (prefs.getStringList(_kReadLessons) ?? []).toSet();
  }

  Future<void> saveReadLessons(Set<String> ids) async {
    final prefs = await _prefs;
    await prefs.setStringList(_kReadLessons, ids.toList());
  }

  // ---------------- Daily goal ----------------
  Future<int> loadDailyGoal() async {
    final prefs = await _prefs;
    return prefs.getInt(_kDailyGoal) ?? 150;
  }

  Future<void> saveDailyGoal(int goal) async {
    final prefs = await _prefs;
    await prefs.setInt(_kDailyGoal, goal);
  }

  // Helper used by tests / debugging.
  String encode(Object value) => jsonEncode(value);
}
