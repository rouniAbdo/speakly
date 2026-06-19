import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word_details.dart';
import '../services/dictionary_service.dart';
import '../state/app_state.dart';

/// Shows the full dictionary entry for a word: pronunciation, meanings,
/// examples and synonyms, plus a practice field.
class WordDetailScreen extends StatefulWidget {
  final String word;
  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final _dict = DictionaryService();
  final _audio = AudioPlayer();
  late Future<LookupResult> _future;
  final _sentence = TextEditingController();
  String? _feedback;
  bool _feedbackGood = false;

  @override
  void initState() {
    super.initState();
    _future = _dict.lookup(widget.word);
  }

  @override
  void dispose() {
    _audio.dispose();
    _sentence.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _future = _dict.lookup(widget.word, forceRefresh: true);
    });
  }

  Future<void> _play(String url) async {
    try {
      await _audio.stop();
      await _audio.play(UrlSource(url));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play audio.')),
        );
      }
    }
  }

  void _check(String word) {
    final text = _sentence.text.trim();
    final lower = text.toLowerCase();
    final used =
        RegExp(r'\b' + RegExp.escape(word.toLowerCase()) + r'\w*\b')
            .hasMatch(lower);
    final wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    setState(() {
      if (text.isEmpty) {
        _feedback = 'Write a sentence first 🙂';
        _feedbackGood = false;
      } else if (!used) {
        _feedback = 'Try to actually use the word "$word".';
        _feedbackGood = false;
      } else if (wordCount < 4) {
        _feedback = 'Good — now make it a fuller sentence (4+ words).';
        _feedbackGood = false;
      } else {
        _feedback = 'Nice! You used "$word" correctly. 🎉';
        _feedbackGood = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final learned = state.isLearned(widget.word);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.word),
        actions: [
          IconButton(
            tooltip: learned ? 'Learned' : 'Mark as learned',
            icon: Icon(learned ? Icons.check_circle : Icons.circle_outlined,
                color: learned ? const Color(0xFF22C55E) : null),
            onPressed: () =>
                context.read<AppState>().toggleLearned(widget.word),
          ),
        ],
      ),
      body: FutureBuilder<LookupResult>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snap.data!;
          switch (result.status) {
            case LookupStatus.notFound:
              return _Message(
                icon: Icons.search_off,
                title: 'No definition found',
                message:
                    '"${widget.word}" was not found in the dictionary.',
                onRetry: _retry,
              );
            case LookupStatus.offline:
              return _Message(
                icon: Icons.wifi_off,
                title: 'You are offline',
                message:
                    'Connect to the internet to look up this word. '
                    'Words you have viewed before work offline.',
                onRetry: _retry,
              );
            case LookupStatus.error:
              return _Message(
                icon: Icons.error_outline,
                title: 'Something went wrong',
                message: 'Could not load this word. Try again.',
                onRetry: _retry,
              );
            case LookupStatus.ok:
              return _Content(
                details: result.details!,
                fromCache: result.fromCache,
                onPlay: _play,
                sentence: _sentence,
                feedback: _feedback,
                feedbackGood: _feedbackGood,
                onCheck: () => _check(result.details!.word),
                onChanged: () {
                  if (_feedback != null) setState(() => _feedback = null);
                },
              );
          }
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final WordDetails details;
  final bool fromCache;
  final void Function(String url) onPlay;
  final TextEditingController sentence;
  final String? feedback;
  final bool feedbackGood;
  final VoidCallback onCheck;
  final VoidCallback onChanged;

  const _Content({
    required this.details,
    required this.fromCache,
    required this.onPlay,
    required this.sentence,
    required this.feedback,
    required this.feedbackGood,
    required this.onCheck,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(details.word,
                      style: const TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w800)),
                  if (details.phonetic != null &&
                      details.phonetic!.isNotEmpty)
                    Text(details.phonetic!,
                        style: TextStyle(
                            fontSize: 16,
                            color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (details.audioUrl != null)
              IconButton.filledTonal(
                iconSize: 28,
                onPressed: () => onPlay(details.audioUrl!),
                icon: const Icon(Icons.volume_up),
                tooltip: 'Play pronunciation',
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Meanings grouped by part of speech.
        ..._groupByPos(details.senses).entries.map((group) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Text(
                  group.key,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: scheme.primary,
                  ),
                ),
              ),
              ...group.value.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. ${s.definition}',
                          style: const TextStyle(fontSize: 15, height: 1.4)),
                      if (s.example != null && s.example!.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.format_quote,
                                size: 16, color: scheme.outline),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s.example!,
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: scheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          );
        }),

        if (details.synonyms.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Synonyms',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: details.synonyms
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            scheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s),
                    ))
                .toList(),
          ),
        ],

        const SizedBox(height: 24),
        Text('Your turn — use it in a sentence',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: scheme.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: sentence,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => onChanged(),
          decoration: InputDecoration(
            hintText: 'Use "${details.word}" in a sentence...',
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onCheck,
          icon: const Icon(Icons.spellcheck),
          label: const Text('Check my sentence'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        if (feedback != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (feedbackGood ? const Color(0xFF16A34A) : scheme.error)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  feedbackGood ? Icons.check_circle : Icons.info_outline,
                  color: feedbackGood ? const Color(0xFF16A34A) : scheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(feedback!)),
              ],
            ),
          ),
        ],
        if (fromCache) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.offline_pin_outlined,
                  size: 15, color: scheme.outline),
              const SizedBox(width: 6),
              Text('Saved offline',
                  style: TextStyle(fontSize: 12, color: scheme.outline)),
            ],
          ),
        ],
      ],
    );
  }

  Map<String, List<WordSense>> _groupByPos(List<WordSense> senses) {
    final map = <String, List<WordSense>>{};
    for (final s in senses) {
      final key = s.partOfSpeech.isEmpty ? 'other' : s.partOfSpeech;
      map.putIfAbsent(key, () => []).add(s);
    }
    return map;
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: scheme.outline),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
