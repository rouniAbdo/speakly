import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/playful.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final scheme = Theme.of(context).colorScheme;
    // Every word marked learned anywhere in the app (dictionary, trainer, …).
    final learnedVocab = state.learnedWords.length;

    // Milestone for words written.
    final milestones = [100, 500, 1000, 5000, 10000, 25000];
    final next = milestones.firstWhere(
      (m) => m > state.totalWords,
      orElse: () => milestones.last,
    );
    final prev = milestones.lastWhere(
      (m) => m <= state.totalWords,
      orElse: () => 0,
    );
    final milestoneProgress = next == prev
        ? 1.0
        : ((state.totalWords - prev) / (next - prev)).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              StatCard(
                icon: Icons.local_fire_department,
                value: '${state.currentStreak}',
                label: 'Day streak',
                color: const Color(0xFFEA580C),
              ),
              StatCard(
                icon: Icons.emoji_events_outlined,
                value: '${state.longestStreak}',
                label: 'Longest streak',
                color: const Color(0xFFCA8A04),
              ),
              StatCard(
                icon: Icons.notes,
                value: '${state.totalWords}',
                label: 'Words written',
                color: scheme.primary,
              ),
              StatCard(
                icon: Icons.menu_book_outlined,
                value: '${state.totalEntries}',
                label: 'Entries',
                color: const Color(0xFF0891B2),
              ),
              StatCard(
                icon: Icons.school_outlined,
                value: '$learnedVocab',
                label: 'Words learned',
                color: const Color(0xFF7C3AED),
              ),
              StatCard(
                icon: Icons.today_outlined,
                value: '${state.wordsToday}',
                label: 'Words today',
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader('🏅 Next milestone'),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.06), scheme.surface),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.18), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('${state.totalWords}',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: scheme.primary,
                        )),
                    Text(' / $next words',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBar(
                  value: milestoneProgress,
                  height: 12,
                  background: scheme.surfaceContainerHighest,
                  gradient: const [AppTheme.seed, AppTheme.accent],
                ),
                const SizedBox(height: 10),
                Text(
                  state.totalWords >= milestones.last
                      ? 'Incredible — you have passed every milestone! 🏆'
                      : '${next - state.totalWords} words to reach the next milestone.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('🎯 Daily goal'),
          _GoalEditor(state: state),
          const SizedBox(height: 24),
          const SectionHeader('📊 Last 7 days'),
          _WeekChart(state: state),
        ],
      ),
    );
  }
}

class _GoalEditor extends StatelessWidget {
  final AppState state;
  const _GoalEditor({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final goal = state.dailyGoal;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$goal words / day',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              if (state.goalMetToday)
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 4),
                    Text('Done today',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
            ],
          ),
          Slider(
            value: goal.toDouble(),
            min: 50,
            max: 500,
            divisions: 18,
            label: '$goal',
            onChanged: (v) => state.setDailyGoal(v.round()),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.goalProgress,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text('${state.wordsToday} / $goal words written today',
              style: TextStyle(
                  color: scheme.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  final AppState state;
  const _WeekChart({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    // Build word counts per day for the last 7 days.
    final days = List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final key = day.toIso8601String().substring(0, 10);
      final words = state.entries
          .where((e) =>
              e.updatedAt.toIso8601String().substring(0, 10) == key)
          .fold<int>(0, (s, e) => s + e.wordCount);
      return MapEntry(day, words);
    });
    final maxWords =
        days.map((e) => e.value).fold<int>(1, (m, v) => v > m ? v : m);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: days.map((entry) {
            final ratio = entry.value / maxWords;
            final hit = entry.value >= state.dailyGoal;
            return Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    entry.value > 0 ? '${entry.value}' : '',
                    style: TextStyle(
                        fontSize: 10, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      height: 90 * v + 6,
                      decoration: BoxDecoration(
                        gradient: hit
                            ? const LinearGradient(
                                colors: [AppTheme.streak, AppTheme.gold],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              )
                            : LinearGradient(
                                colors: [
                                  scheme.primary.withValues(alpha: 0.45),
                                  scheme.primary.withValues(alpha: 0.25),
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[entry.key.weekday - 1],
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
