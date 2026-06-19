import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:english_writing_pro/models/writing_entry.dart';
import 'package:english_writing_pro/models/word_details.dart';

void main() {
  test('WordDetails parses the dictionary API response', () {
    final raw = jsonDecode('''
    [{"word":"vivid","phonetic":"/ˈvɪvɪd/",
      "phonetics":[{"text":"/ˈvɪvɪd/","audio":"https://x/vivid.mp3"}],
      "meanings":[{"partOfSpeech":"adjective",
        "definitions":[{"definition":"Bright and intense.","example":"a vivid red",
          "synonyms":["bright","intense"]}],
        "synonyms":["colourful"]}]}]
    ''') as List<dynamic>;

    final d = WordDetails.fromApi('vivid', raw);
    expect(d.word, 'vivid');
    expect(d.phonetic, '/ˈvɪvɪd/');
    expect(d.audioUrl, 'https://x/vivid.mp3');
    expect(d.senses.length, 1);
    expect(d.senses.first.partOfSpeech, 'adjective');
    expect(d.firstExample, 'a vivid red');
    expect(d.synonyms, containsAll(['bright', 'intense', 'colourful']));

    // Round-trips through the cache map.
    final restored = WordDetails.fromMap(d.toMap());
    expect(restored.word, 'vivid');
    expect(restored.senses.first.definition, 'Bright and intense.');
  });

  test('WritingEntry counts words and round-trips through JSON', () {
    final now = DateTime.now();
    final entry = WritingEntry(
      id: '1',
      title: 'Test',
      content: 'Hello world this is a test.',
      promptText: '',
      category: 'Free Writing',
      level: 'Any',
      createdAt: now,
      updatedAt: now,
    );

    expect(entry.wordCount, 6);
    expect(entry.sentenceCount, 1);

    final restored = WritingEntry.fromJson(entry.toJson());
    expect(restored.title, 'Test');
    expect(restored.wordCount, 6);
  });

  testWidgets('Empty content has zero words', (tester) async {
    final entry = WritingEntry(
      id: '2',
      title: '',
      content: '   ',
      promptText: '',
      category: 'x',
      level: 'Any',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    expect(entry.wordCount, 0);
    await tester.pumpWidget(const SizedBox());
  });
}
