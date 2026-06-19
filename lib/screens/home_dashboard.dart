import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/content_repository.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/playful.dart';
import 'editor_screen.dart';
import 'todays_words.dart';
import 'word_trainer_screen.dart';

/// The dashboard / home tab.
class HomeDashboard extends StatefulWidget {
  /// Switch to another bottom-nav tab (0=home,1=prompts,2=writings,3=learn,4=progress).
  final void Function(int index) onNavigate;
  const HomeDashboard({super.key, required this.onNavigate});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final _confetti = ConfettiController();
  bool? _wasGoalMet;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  String _greetingEmoji() {
    final h = DateTime.now().hour;
    if (h < 12) return '☀️';
    if (h < 18) return '🌤️';
    return '🌙';
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final content = context.watch<ContentRepository>();
    final scheme = Theme.of(context).colorScheme;

    // Fire confetti the moment the daily goal flips to "met".
    final met = state.goalMetToday;
    if (_wasGoalMet != null && _wasGoalMet == false && met) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
    _wasGoalMet = met;

    // Deterministic "prompt of the day".
    final dayIndex = DateTime.now().difference(DateTime(2020)).inDays;
    final prompt = content.prompts[dayIndex % content.prompts.length];

    return Scaffold(
      body: ConfettiOverlay(
        controller: _confetti,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            children: [
              PopIn(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_greeting()} ${_greetingEmoji()}',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              )),
                          const Text(
                            'Ready to write?',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StreakBadge(streak: state.currentStreak),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PopIn(
                delay: const Duration(milliseconds: 60),
                child: _DailyGoalCard(state: state),
              ),
              const SizedBox(height: 20),
              const PopIn(
                delay: Duration(milliseconds: 120),
                child: TodaysWords(),
              ),
              const SizedBox(height: 8),
              Center(
                child: BouncyTap(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const WordTrainerScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🃏', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          'Practise words with flashcards',
                          style: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SectionHeader('✨ Prompt of the day'),
              PopIn(
                delay: const Duration(milliseconds: 180),
                child: _PromptOfDay(
                  title: prompt.title,
                  text: prompt.text,
                  level: prompt.level,
                  category: prompt.category,
                  onStart: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => EditorScreen(prompt: prompt)),
                  ),
                  onBrowse: () => widget.onNavigate(1),
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader('🚀 Quick actions'),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _ActionTile(
                    icon: Icons.edit_note,
                    emoji: '✍️',
                    label: 'Free write',
                    color: const Color(0xFF6366F1),
                    delayMs: 200,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const EditorScreen()),
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.list_alt,
                    emoji: '💡',
                    label: 'Browse prompts',
                    color: const Color(0xFF06B6D4),
                    delayMs: 260,
                    onTap: () => widget.onNavigate(1),
                  ),
                  _ActionTile(
                    icon: Icons.school_outlined,
                    emoji: '📚',
                    label: 'Lessons',
                    color: const Color(0xFFA855F7),
                    delayMs: 320,
                    onTap: () => widget.onNavigate(3),
                  ),
                  _ActionTile(
                    icon: Icons.insights,
                    emoji: '🏆',
                    label: 'My progress',
                    color: const Color(0xFFFF8A3D),
                    delayMs: 380,
                    onTap: () => widget.onNavigate(4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    return BouncyTap(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.streak, AppTheme.gold],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppTheme.softShadow(AppTheme.streak, opacity: 0.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StreakFlame(size: 20),
            const SizedBox(width: 5),
            Text(
              '$streak',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final AppState state;
  const _DailyGoalCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final done = state.goalMetToday;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: done
              ? const [Color(0xFF22C55E), Color(0xFF2DD4BF)]
              : [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.softShadow(
          done ? const Color(0xFF22C55E) : scheme.primary,
          opacity: 0.35,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(done ? '🎉' : '🎯', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                done ? 'Goal smashed today!' : "Today's goal",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${state.wordsToday}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  )),
              Text(' / ${state.dailyGoal} words',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedBar(
            value: state.goalProgress,
            height: 12,
            background: Colors.white.withValues(alpha: 0.3),
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _PromptOfDay extends StatelessWidget {
  final String title;
  final String text;
  final String level;
  final String category;
  final VoidCallback onStart;
  final VoidCallback onBrowse;
  const _PromptOfDay({
    required this.title,
    required this.text,
    required this.level,
    required this.category,
    required this.onStart,
    required this.onBrowse,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catColor = AppTheme.categoryColor(category);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
            catColor.withValues(alpha: 0.07), scheme.surface),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: catColor.withValues(alpha: 0.30), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LevelChip(level, small: true),
              const SizedBox(width: 8),
              Text(category,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: catColor,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(text,
              style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w600),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Write now'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onBrowse,
                child: const Text('More'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String emoji;
  final String label;
  final Color color;
  final int delayMs;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.emoji,
    required this.label,
    required this.color,
    required this.delayMs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopIn(
      delay: Duration(milliseconds: delayMs),
      child: BouncyTap(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
                color.withValues(alpha: 0.10), scheme.surface),
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: color.withValues(alpha: 0.22), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(height: 10),
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14.5)),
            ],
          ),
        ),
      ),
    );
  }
}
