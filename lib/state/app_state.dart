import 'package:flutter/foundation.dart';

import '../models/writing_entry.dart';
import '../services/storage_service.dart';

/// Central app state: writings, streak, goals and learned vocabulary.
class AppState extends ChangeNotifier {
  final StorageService _storage;

  AppState(this._storage);

  bool _loaded = false;
  bool get loaded => _loaded;

  List<WritingEntry> _entries = [];
  List<WritingEntry> get entries => List.unmodifiable(_entries);

  Set<String> _streakDates = {};
  Set<String> _learnedWords = {};
  Set<String> _readLessons = {};
  int _dailyGoal = 150;
  int get dailyGoal => _dailyGoal;

  Future<void> init() async {
    _entries = await _storage.loadEntries();
    _streakDates = await _storage.loadStreakDates();
    _learnedWords = await _storage.loadLearnedWords();
    _readLessons = await _storage.loadReadLessons();
    _dailyGoal = await _storage.loadDailyGoal();
    _loaded = true;
    notifyListeners();
  }

  // ---------------- Stats ----------------
  int get totalEntries => _entries.length;

  int get totalWords =>
      _entries.fold(0, (sum, e) => sum + e.wordCount);

  int get wordsToday {
    final today = _dayKey(DateTime.now());
    return _entries
        .where((e) => _dayKey(e.updatedAt) == today)
        .fold(0, (sum, e) => sum + e.wordCount);
  }

  bool get goalMetToday => wordsToday >= _dailyGoal;

  double get goalProgress =>
      _dailyGoal == 0 ? 1 : (wordsToday / _dailyGoal).clamp(0, 1).toDouble();

  /// Consecutive-day streak ending today (or yesterday if not yet written today).
  int get currentStreak {
    if (_streakDates.isEmpty) return 0;
    int streak = 0;
    var day = DateTime.now();
    // Allow the streak to still count if user hasn't written today yet.
    if (!_streakDates.contains(_dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
      if (!_streakDates.contains(_dayKey(day))) return 0;
    }
    while (_streakDates.contains(_dayKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    if (_streakDates.isEmpty) return 0;
    final days = _streakDates
        .map((s) => DateTime.parse(s))
        .toList()
      ..sort();
    int best = 1;
    int run = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        run++;
        best = run > best ? run : best;
      } else if (diff > 1) {
        run = 1;
      }
    }
    return best;
  }

  // ---------------- Learned words ----------------
  Set<String> get learnedWords => Set.unmodifiable(_learnedWords);
  bool isLearned(String word) => _learnedWords.contains(word.toLowerCase());

  Future<void> toggleLearned(String word) async {
    final key = word.toLowerCase();
    if (_learnedWords.contains(key)) {
      _learnedWords.remove(key);
    } else {
      _learnedWords.add(key);
    }
    await _storage.saveLearnedWords(_learnedWords);
    notifyListeners();
  }

  /// Mark a word as learned without ever un-marking it (used by the trainer).
  Future<void> markLearned(String word) async {
    final key = word.toLowerCase();
    if (_learnedWords.add(key)) {
      await _storage.saveLearnedWords(_learnedWords);
      notifyListeners();
    }
  }

  // ---------------- Read lessons ----------------
  Set<String> get readLessons => Set.unmodifiable(_readLessons);
  bool isLessonRead(String id) => _readLessons.contains(id);
  int get readLessonCount => _readLessons.length;

  Future<void> markLessonRead(String id) async {
    if (_readLessons.add(id)) {
      await _storage.saveReadLessons(_readLessons);
      notifyListeners();
    }
  }

  // ---------------- Goal ----------------
  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal.clamp(20, 2000);
    await _storage.saveDailyGoal(_dailyGoal);
    notifyListeners();
  }

  // ---------------- Entries CRUD ----------------
  WritingEntry? entryById(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<WritingEntry> saveEntry(WritingEntry entry) async {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      _entries[idx] = entry;
    } else {
      _entries.add(entry);
    }
    _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _streakDates.add(_dayKey(DateTime.now()));
    await _storage.saveEntries(_entries);
    await _storage.saveStreakDates(_streakDates);
    notifyListeners();
    return entry;
  }

  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _storage.saveEntries(_entries);
    notifyListeners();
  }

  static String _dayKey(DateTime d) =>
      DateTime(d.year, d.month, d.day).toIso8601String().substring(0, 10);
}
