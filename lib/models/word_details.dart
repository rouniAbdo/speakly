/// One meaning of a word (part of speech + definition + optional example).
class WordSense {
  final String partOfSpeech;
  final String definition;
  final String? example;

  const WordSense({
    required this.partOfSpeech,
    required this.definition,
    this.example,
  });

  Map<String, dynamic> toMap() => {
        'pos': partOfSpeech,
        'def': definition,
        'ex': example,
      };

  factory WordSense.fromMap(Map<String, dynamic> m) => WordSense(
        partOfSpeech: m['pos'] as String? ?? '',
        definition: m['def'] as String? ?? '',
        example: m['ex'] as String?,
      );
}

/// Full dictionary entry for a word, built from the free dictionary API
/// and cacheable to local storage.
class WordDetails {
  final String word;
  final String? phonetic;
  final String? audioUrl;
  final List<WordSense> senses;
  final List<String> synonyms;

  const WordDetails({
    required this.word,
    required this.senses,
    required this.synonyms,
    this.phonetic,
    this.audioUrl,
  });

  /// A short example sentence pulled from the first sense that has one.
  String? get firstExample {
    for (final s in senses) {
      if (s.example != null && s.example!.trim().isNotEmpty) {
        return s.example;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'word': word,
        'phonetic': phonetic,
        'audioUrl': audioUrl,
        'senses': senses.map((s) => s.toMap()).toList(),
        'synonyms': synonyms,
      };

  factory WordDetails.fromMap(Map<String, dynamic> m) => WordDetails(
        word: m['word'] as String? ?? '',
        phonetic: m['phonetic'] as String?,
        audioUrl: m['audioUrl'] as String?,
        senses: (m['senses'] as List? ?? [])
            .map((e) => WordSense.fromMap(e as Map<String, dynamic>))
            .toList(),
        synonyms:
            (m['synonyms'] as List? ?? []).map((e) => e.toString()).toList(),
      );

  /// Parse the raw response of dictionaryapi.dev (a JSON array of entries).
  factory WordDetails.fromApi(String word, List<dynamic> data) {
    String? phonetic;
    String? audioUrl;
    final senses = <WordSense>[];
    final synonyms = <String>{};

    for (final entryRaw in data) {
      final entry = entryRaw as Map<String, dynamic>;
      phonetic ??= entry['phonetic'] as String?;

      // Find a phonetic text / audio from the phonetics list.
      for (final pRaw in (entry['phonetics'] as List? ?? [])) {
        final p = pRaw as Map<String, dynamic>;
        final text = p['text'] as String?;
        if (phonetic == null && text != null && text.isNotEmpty) {
          phonetic = text;
        }
        final audio = p['audio'] as String?;
        if (audioUrl == null && audio != null && audio.isNotEmpty) {
          audioUrl = audio;
        }
      }

      for (final mRaw in (entry['meanings'] as List? ?? [])) {
        final meaning = mRaw as Map<String, dynamic>;
        final pos = meaning['partOfSpeech'] as String? ?? '';
        for (final s in (meaning['synonyms'] as List? ?? [])) {
          synonyms.add(s.toString());
        }
        for (final dRaw in (meaning['definitions'] as List? ?? [])) {
          final d = dRaw as Map<String, dynamic>;
          final def = d['definition'] as String?;
          if (def == null || def.isEmpty) continue;
          senses.add(WordSense(
            partOfSpeech: pos,
            definition: def,
            example: d['example'] as String?,
          ));
          for (final s in (d['synonyms'] as List? ?? [])) {
            synonyms.add(s.toString());
          }
        }
      }
    }

    return WordDetails(
      word: word,
      phonetic: phonetic,
      audioUrl: audioUrl,
      senses: senses,
      synonyms: synonyms.take(12).toList(),
    );
  }
}
