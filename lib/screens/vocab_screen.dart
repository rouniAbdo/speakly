import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/dictionary_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'word_detail_screen.dart';
import 'word_trainer_screen.dart';

/// Vocabulary tab: a rotating batch of new words to learn, drawn from the full
/// dictionary. Words you've already learned are excluded, and "New words"
/// always brings a fresh set — never the same list twice.
class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  final _dict = DictionaryService();
  final _seen = <String>{};
  List<String>? _batch;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final learned = context.read<AppState>().learnedWords;
    final words = await _dict.pickWords(
      count: 8,
      exclude: {...learned, ..._seen},
    );
    _seen.addAll(words);
    if (!mounted) return;
    setState(() {
      _batch = words;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WordTrainerScreen()),
                  ),
                  icon: const Icon(Icons.style),
                  label: const Text('Flashcards'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
                label: const Text('New words'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
            child: Text(
              'A fresh batch of words to learn — tap a word for details.',
              style: TextStyle(
                  fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _batch!.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _VocabBatchCard(word: _batch![i], dict: _dict),
                ),
        ),
      ],
    );
  }
}

class _VocabBatchCard extends StatefulWidget {
  final String word;
  final DictionaryService dict;
  const _VocabBatchCard({required this.word, required this.dict});

  @override
  State<_VocabBatchCard> createState() => _VocabBatchCardState();
}

class _VocabBatchCardState extends State<_VocabBatchCard> {
  final _audio = AudioPlayer();
  late Future<LookupResult> _lookup;

  @override
  void initState() {
    super.initState();
    _lookup = widget.dict.lookup(widget.word);
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  Future<void> _play(String url) async {
    try {
      await _audio.stop();
      await _audio.play(UrlSource(url));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final learned = context.select<AppState, bool>(
        (s) => s.isLearned(widget.word));
    final color = AppTheme.wordColor(widget.word);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => WordDetailScreen(word: widget.word)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: learned
              ? const Color(0xFF22C55E).withValues(alpha: 0.10)
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(widget.word,
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: color)),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: learned ? 'Learned' : 'Mark as learned',
                  icon: Icon(
                    learned ? Icons.check_circle : Icons.circle_outlined,
                    color:
                        learned ? const Color(0xFF22C55E) : scheme.outline,
                  ),
                  onPressed: () =>
                      context.read<AppState>().toggleLearned(widget.word),
                ),
              ],
            ),
            FutureBuilder<LookupResult>(
              future: _lookup,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Loading…',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                  );
                }
                final res = snap.data!;
                if (res.status != LookupStatus.ok) {
                  return Text(
                    res.status == LookupStatus.offline
                        ? 'Connect to load this word.'
                        : 'Tap to look this word up.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  );
                }
                final d = res.details!;
                final sense = d.senses.first;
                final example = d.firstExample;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${sense.partOfSpeech.isEmpty ? '' : '(${sense.partOfSpeech}) '}${sense.definition}',
                            style: const TextStyle(fontSize: 14.5, height: 1.4),
                          ),
                        ),
                        if (d.audioUrl != null)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Play pronunciation',
                            icon: const Icon(Icons.volume_up, size: 20),
                            onPressed: () => _play(d.audioUrl!),
                          ),
                      ],
                    ),
                    if (example != null) ...[
                      const SizedBox(height: 6),
                      Text('"$example"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          )),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
