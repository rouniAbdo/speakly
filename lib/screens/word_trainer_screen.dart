import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word_details.dart';
import '../services/dictionary_service.dart';
import '../state/app_state.dart';

/// Flashcard trainer backed by the full dictionary. Every session draws a
/// fresh batch of words you haven't learned yet, so you never see the same
/// list twice. Reveal a card to fetch its meaning and an example sentence,
/// then write your own.
class WordTrainerScreen extends StatefulWidget {
  const WordTrainerScreen({super.key});

  @override
  State<WordTrainerScreen> createState() => _WordTrainerScreenState();
}

class _WordTrainerScreenState extends State<WordTrainerScreen> {
  final _dict = DictionaryService();
  final _seen = <String>{};
  List<String>? _deck;
  bool _loading = true;
  int _index = 0;
  int _learnedThisSession = 0;

  @override
  void initState() {
    super.initState();
    _loadDeck();
  }

  Future<void> _loadDeck() async {
    setState(() => _loading = true);
    final learned = context.read<AppState>().learnedWords;
    final words = await _dict.pickWords(
      count: 10,
      exclude: {...learned, ..._seen},
    );
    _seen.addAll(words);
    if (!mounted) return;
    setState(() {
      _deck = words;
      _index = 0;
      _learnedThisSession = 0;
      _loading = false;
    });
  }

  void _next() {
    final deck = _deck!;
    if (_index < deck.length - 1) {
      setState(() => _index++);
    } else {
      setState(() => _index = deck.length); // -> completion view
    }
  }

  Future<void> _gotIt(String word) async {
    if (!context.read<AppState>().isLearned(word)) {
      _learnedThisSession++;
    }
    await context.read<AppState>().markLearned(word);
    _next();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        bottom: (_deck != null && _index < _deck!.length)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: LinearProgressIndicator(
                  value: (_index + 1) / _deck!.length,
                  minHeight: 6,
                ),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final deck = _deck!;
    if (deck.isEmpty) {
      return _CompletionView(
        learned: _learnedThisSession,
        title: 'No more new words',
        message: 'You have learned everything in the study pool. Amazing! 🏆',
        onNewSet: _loadDeck,
      );
    }
    if (_index >= deck.length) {
      return _CompletionView(
        learned: _learnedThisSession,
        title: 'Session complete!',
        message: _learnedThisSession == 0
            ? 'Tap below for a fresh set of new words.'
            : 'You learned $_learnedThisSession new word'
                  '${_learnedThisSession == 1 ? '' : 's'}. Keep going!',
        onNewSet: _loadDeck,
      );
    }

    final word = deck[_index];
    return _FlashCard(
      key: ValueKey(word),
      word: word,
      dict: _dict,
      position: _index + 1,
      total: deck.length,
      onSkip: _next,
      onGotIt: () => _gotIt(word),
    );
  }
}

class _FlashCard extends StatefulWidget {
  final String word;
  final DictionaryService dict;
  final int position;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onGotIt;

  const _FlashCard({
    super.key,
    required this.word,
    required this.dict,
    required this.position,
    required this.total,
    required this.onSkip,
    required this.onGotIt,
  });

  @override
  State<_FlashCard> createState() => _FlashCardState();
}

class _FlashCardState extends State<_FlashCard> {
  final _audio = AudioPlayer();
  final _sentence = TextEditingController();
  Future<LookupResult>? _lookup;
  String? _feedback;
  bool _feedbackGood = false;

  @override
  void dispose() {
    _audio.dispose();
    _sentence.dispose();
    super.dispose();
  }

  void _reveal() {
    setState(() {
      _lookup = widget.dict.lookup(widget.word);
    });
  }

  Future<void> _play(String url) async {
    try {
      await _audio.stop();
      await _audio.play(UrlSource(url));
    } catch (_) {}
  }

  void _check() {
    final text = _sentence.text.trim();
    final word = widget.word.toLowerCase();
    final used = RegExp(
      r'\b' + RegExp.escape(word) + r'\w*\b',
    ).hasMatch(text.toLowerCase());
    final wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    setState(() {
      if (text.isEmpty) {
        _feedback = 'Write a sentence first 🙂';
        _feedbackGood = false;
      } else if (!used) {
        _feedback = 'Try to actually use the word "${widget.word}".';
        _feedbackGood = false;
      } else if (wordCount < 4) {
        _feedback = 'Good — now make it a fuller sentence (4+ words).';
        _feedbackGood = false;
      } else {
        _feedback = 'Nice! You used "${widget.word}" correctly. 🎉';
        _feedbackGood = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          'Card ${widget.position} of ${widget.total}',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Text(
              widget.word,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_lookup == null)
          FilledButton.icon(
            onPressed: _reveal,
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Show meaning & sentence'),
          )
        else
          FutureBuilder<LookupResult>(
            future: _lookup,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final res = snap.data!;
              if (res.status != LookupStatus.ok) {
                return _RevealError(status: res.status, onRetry: _reveal);
              }
              return _Revealed(
                details: res.details!,
                onPlay: _play,
                sentence: _sentence,
                feedback: _feedback,
                feedbackGood: _feedbackGood,
                onCheck: _check,
                onChanged: () {
                  if (_feedback != null) setState(() => _feedback = null);
                },
              );
            },
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onSkip,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Skip'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: widget.onGotIt,
                icon: const Icon(Icons.check, size: 20),
                label: const Text("I've got it"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Revealed extends StatelessWidget {
  final WordDetails details;
  final void Function(String url) onPlay;
  final TextEditingController sentence;
  final String? feedback;
  final bool feedbackGood;
  final VoidCallback onCheck;
  final VoidCallback onChanged;

  const _Revealed({
    required this.details,
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
    final example = details.firstExample;
    final sense = details.senses.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (details.phonetic != null && details.phonetic!.isNotEmpty)
              Expanded(
                child: Text(
                  details.phonetic!,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 15,
                  ),
                ),
              )
            else
              const Spacer(),
            if (details.audioUrl != null)
              IconButton.filledTonal(
                onPressed: () => onPlay(details.audioUrl!),
                icon: const Icon(Icons.volume_up),
                tooltip: 'Play pronunciation',
              ),
          ],
        ),
        const SizedBox(height: 8),
        _Block(
          icon: Icons.lightbulb_outline,
          title: 'Meaning (${sense.partOfSpeech})',
          child: Text(
            sense.definition,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),
        ),
        if (example != null) ...[
          const SizedBox(height: 12),
          _Block(
            icon: Icons.format_quote,
            title: 'How to use it',
            child: Text(
              example,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
        if (details.synonyms.isNotEmpty) ...[
          const SizedBox(height: 12),
          _Block(
            icon: Icons.swap_horiz,
            title: 'Synonyms',
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: details.synonyms
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(s),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text(
          'Your turn — write your own sentence',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: scheme.onSurface,
          ),
        ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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
      ],
    );
  }
}

class _RevealError extends StatelessWidget {
  final LookupStatus status;
  final VoidCallback onRetry;
  const _RevealError({required this.status, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final offline = status == LookupStatus.offline;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            offline ? Icons.wifi_off : Icons.search_off,
            color: scheme.outline,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            offline
                ? 'Connect to the internet to load this word.'
                : 'No definition found — skip to the next word.',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Block({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CompletionView extends StatelessWidget {
  final int learned;
  final String title;
  final String message;
  final VoidCallback onNewSet;
  const _CompletionView({
    required this.learned,
    required this.title,
    required this.message,
    required this.onNewSet,
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
            Icon(Icons.emoji_events, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onNewSet,
              icon: const Icon(Icons.refresh),
              label: const Text('New set of words'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
