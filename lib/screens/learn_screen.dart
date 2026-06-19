import 'package:flutter/material.dart';

import 'dictionary_screen.dart';
import 'lessons_screen.dart';
import 'vocab_screen.dart';

/// Tabbed container for Lessons, Vocabulary and the full Dictionary.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Learn'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: '📖 Lessons', icon: Icon(Icons.school_outlined)),
              Tab(text: '🔤 Vocabulary', icon: Icon(Icons.translate)),
              Tab(text: '📚 Dictionary', icon: Icon(Icons.menu_book_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            LessonsScreen(),
            VocabScreen(),
            DictionaryScreen(),
          ],
        ),
      ),
    );
  }
}
