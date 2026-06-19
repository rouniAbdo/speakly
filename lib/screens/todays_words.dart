import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/dictionary_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'word_detail_screen.dart';

/// A colourful card showing a fresh set of words to learn today. The set
/// rotates automatically every day. Words you've learned show a check.
class TodaysWords extends StatefulWidget {
  const TodaysWords({super.key});

  @override
  State<TodaysWords> createState() => _TodaysWordsState();
}

class _TodaysWordsState extends State<TodaysWords> {
  final _dict = DictionaryService();
  late Future<List<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = _dict.dailyWords(count: 12);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFF97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(19),
        ),
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<String>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final words = snap.data!;
            final learned =
                words.where((w) => state.isLearned(w)).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🌅 ', style: TextStyle(fontSize: 20)),
                    const Text("Today's words",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text(
                      DateFormat('EEE d MMM').format(DateTime.now()),
                      style: TextStyle(
                          fontSize: 12.5, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'A fresh set every day · $learned / ${words.length} learned',
                  style: TextStyle(
                      fontSize: 12.5, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      words.map((w) => _WordChip(word: w)).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  const _WordChip({required this.word});

  @override
  Widget build(BuildContext context) {
    final learned = context.select<AppState, bool>((s) => s.isLearned(word));
    final color = AppTheme.wordColor(word);

    return Material(
      color: learned ? color : color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WordDetailScreen(word: word)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                learned ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: learned ? Colors.white : color,
              ),
              const SizedBox(width: 6),
              Text(
                word,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: learned ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
