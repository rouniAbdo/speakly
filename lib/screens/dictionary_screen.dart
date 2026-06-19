import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/dictionary_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'word_detail_screen.dart';

/// Browse and search thousands of English words. Tap one to see its full
/// dictionary entry (meaning, example sentence, synonyms, pronunciation).
class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _dict = DictionaryService();
  final _search = TextEditingController();
  late Future<List<String>> _wordsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _wordsFuture = _dict.loadWords();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> _filter(List<String> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    final starts = <String>[];
    final contains = <String>[];
    for (final w in all) {
      if (w.startsWith(q)) {
        starts.add(w);
      } else if (w.contains(q)) {
        contains.add(w);
      }
    }
    return [...starts, ...contains];
  }

  void _open(String word) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WordDetailScreen(word: word)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = context.watch<AppState>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: (v) {
              final w = v.trim();
              if (w.isNotEmpty) _open(w);
            },
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search any English word...',
              isDense: true,
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _search.clear()),
                    ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<String>>(
            future: _wordsFuture,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = _filter(snap.data!);
              final q = _query.trim().toLowerCase();
              final exactExists = q.isNotEmpty && snap.data!.contains(q);

              return ListView.builder(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: 24),
                // +1 row to offer looking up an off-list word.
                itemCount: list.length + (q.isNotEmpty && !exactExists ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == list.length) {
                    // "Look up exactly what I typed" row.
                    return ListTile(
                      leading: Icon(Icons.travel_explore,
                          color: scheme.primary),
                      title: Text('Look up "${_search.text.trim()}"'),
                      subtitle: const Text('Search the full dictionary'),
                      onTap: () => _open(_search.text.trim()),
                    );
                  }
                  final word = list[i];
                  final learned = state.isLearned(word);
                  final color = AppTheme.wordColor(word);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.18),
                      foregroundColor: color,
                      child: Text(
                        word[0].toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(
                      word,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    trailing: learned
                        ? const Icon(Icons.check_circle,
                            size: 22, color: Color(0xFF22C55E))
                        : Icon(Icons.chevron_right, color: scheme.outline),
                    onTap: () => _open(word),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
