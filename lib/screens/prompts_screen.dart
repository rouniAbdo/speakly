import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prompt.dart';
import '../services/content_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/playful.dart';
import 'editor_screen.dart';

class PromptsScreen extends StatefulWidget {
  const PromptsScreen({super.key});

  @override
  State<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends State<PromptsScreen> {
  String? _level; // null = all
  String? _category;

  List<WritingPrompt> _filtered(List<WritingPrompt> all) {
    return all.where((p) {
      final lvlOk = _level == null || p.level == _level;
      final catOk = _category == null || p.category == _category;
      return lvlOk && catOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = context.watch<ContentRepository>();
    final list = _filtered(content.prompts);
    return Scaffold(
      appBar: AppBar(title: const Text('Writing Prompts')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _Filter(
                  label: 'All levels',
                  selected: _level == null,
                  onTap: () => setState(() => _level = null),
                ),
                ...content.levels.map((l) => _Filter(
                      label: l,
                      selected: _level == l,
                      onTap: () => setState(
                          () => _level = _level == l ? null : l),
                    )),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _Filter(
                    label: 'All topics',
                    selected: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  ...content.promptCategories.map((c) => _Filter(
                        label: c,
                        selected: _category == c,
                        onTap: () => setState(
                            () => _category = _category == c ? null : c),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No prompts match',
                    message: 'Try removing a filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _PromptCard(prompt: list[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const EditorScreen()),
          );
        },
        icon: const Icon(Icons.edit_note),
        label: const Text('Free write'),
        backgroundColor: scheme.tertiaryContainer,
        foregroundColor: scheme.onTertiaryContainer,
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Filter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final WritingPrompt prompt;
  const _PromptCard({required this.prompt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final catColor = AppTheme.categoryColor(prompt.category);
    return BouncyTap(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => EditorScreen(prompt: prompt)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: catColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border(
            left: BorderSide(color: catColor, width: 6),
            top: BorderSide(color: catColor.withValues(alpha: 0.20)),
            right: BorderSide(color: catColor.withValues(alpha: 0.20)),
            bottom: BorderSide(color: catColor.withValues(alpha: 0.20)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LevelChip(prompt.level, small: true),
                const SizedBox(width: 8),
                Text(
                  prompt.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: catColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '~${prompt.suggestedWords}w',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              prompt.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              prompt.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                height: 1.4,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.edit_outlined, size: 16, color: catColor),
                const SizedBox(width: 6),
                Text(
                  'Start writing',
                  style: TextStyle(
                    color: catColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
