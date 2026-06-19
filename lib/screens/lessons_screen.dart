import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/lesson.dart';
import '../services/content_repository.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  static int _todaySeed() {
    final d = DateTime.now();
    return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = context.watch<ContentRepository>().lessons;
    final state = context.watch<AppState>();

    if (all.isEmpty) {
      return const EmptyState(
        icon: Icons.school_outlined,
        title: 'No lessons',
        message: 'Lesson content could not be loaded.',
      );
    }

    // Reshuffle the order every day so you don't see the same list each time,
    // and float lessons you haven't read yet to the top.
    final shuffled = List<Lesson>.from(all)..shuffle(Random(_todaySeed()));
    final unread = shuffled.where((l) => !state.isLessonRead(l.id)).toList();
    final read = shuffled.where((l) => state.isLessonRead(l.id)).toList();
    final lessonOfDay = unread.isNotEmpty ? unread.first : shuffled.first;
    final rest = [...unread, ...read]
        .where((l) => l.id != lessonOfDay.id)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const SectionHeader('📖 Lesson of the day'),
        _LessonCard(lesson: lessonOfDay, featured: true),
        const SizedBox(height: 16),
        SectionHeader(
          'All lessons',
          trailing: Text(
            '${read.length}/${all.length} read',
            style: TextStyle(
                fontSize: 13, color: scheme.onSurfaceVariant),
          ),
        ),
        for (final lesson in rest) ...[
          _LessonCard(lesson: lesson),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool featured;
  const _LessonCard({required this.lesson, this.featured = false});

  static IconData _iconFor(String category) {
    switch (category) {
      case 'Grammar':
        return Icons.spellcheck;
      case 'Punctuation':
        return Icons.more_horiz;
      case 'Structure':
        return Icons.account_tree_outlined;
      case 'Style':
        return Icons.auto_awesome;
      default:
        return Icons.school_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final read = context.select<AppState, bool>(
        (s) => s.isLessonRead(lesson.id));
    final color = AppTheme.categoryColor(lesson.category);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LessonDetailScreen(lesson: lesson)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: featured
              ? color.withValues(alpha: 0.12)
              : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: featured
              ? Border.all(color: color.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconFor(lesson.category), color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      LevelChip(lesson.level, small: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.summary,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            read
                ? const Icon(Icons.check_circle,
                    color: Color(0xFF22C55E), size: 22)
                : Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonDetailScreen({super.key, required this.lesson});

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark this lesson as read so it gets a check and drops down the list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppState>().markLessonRead(widget.lesson.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(lesson.category)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            lesson.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.summary,
            style: TextStyle(
              fontSize: 15,
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          LevelChip(lesson.level, small: true),
          const SizedBox(height: 20),
          for (final section in lesson.sections) ...[
            _SectionView(section: section),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _SectionView extends StatelessWidget {
  final LessonSection section;
  const _SectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.heading,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(section.body,
            style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 12),
        for (final ex in section.examples) _ExampleView(ex: ex, scheme: scheme),
      ],
    );
  }
}

class _ExampleView extends StatelessWidget {
  final ExamplePair ex;
  final ColorScheme scheme;
  const _ExampleView({required this.ex, required this.scheme});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFDC2626);
    const green = Color(0xFF16A34A);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(Icons.close, red, ex.wrong, strike: true),
          const SizedBox(height: 6),
          _line(Icons.check, green, ex.right),
          if (ex.note != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 15, color: scheme.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ex.note!,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(IconData icon, Color color, String text,
      {bool strike = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              height: 1.35,
              decoration:
                  strike ? TextDecoration.lineThrough : TextDecoration.none,
              decorationColor: color,
            ),
          ),
        ),
      ],
    );
  }
}
