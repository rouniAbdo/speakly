import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/writing_entry.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/playful.dart';
import 'editor_screen.dart';

class MyWritingsScreen extends StatelessWidget {
  const MyWritingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.entries;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Writings'),
        actions: [
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${entries.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: entries.isEmpty
          ? EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'No writings yet',
              message:
                  'Pick a prompt or free-write to create your first entry. '
                  'Everything you write is saved here.',
              action: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditorScreen()),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Start writing'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _EntryTile(entry: entries[i]),
            ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final WritingEntry entry;
  const _EntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = entry.level != 'Any'
        ? AppTheme.levelColor(entry.level, scheme)
        : AppTheme.wordColor(entry.title);
    return BouncyTap(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => EntryDetailScreen(entryId: entry.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
              accent.withValues(alpha: 0.06), scheme.surface),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: accent.withValues(alpha: 0.20), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (entry.level != 'Any') LevelChip(entry.level, small: true),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.content.replaceAll('\n', ' '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.notes, size: 14, color: scheme.outline),
                const SizedBox(width: 4),
                Text('${entry.wordCount} words',
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
                const SizedBox(width: 12),
                Icon(Icons.schedule, size: 14, color: scheme.outline),
                const SizedBox(width: 4),
                Text(
                  DateFormat('d MMM, HH:mm').format(entry.updatedAt),
                  style: TextStyle(fontSize: 12, color: scheme.outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EntryDetailScreen extends StatelessWidget {
  final String entryId;
  const EntryDetailScreen({super.key, required this.entryId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entry = state.entryById(entryId);
    final scheme = Theme.of(context).colorScheme;

    if (entry == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.delete_outline,
          title: 'Entry not found',
          message: 'This writing has been deleted.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EditorScreen(existing: entry),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete writing?'),
                  content: const Text('This cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<AppState>().deleteEntry(entry.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (entry.level != 'Any') LevelChip(entry.level, small: true),
                Text(
                  entry.category,
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12.5),
                ),
                Text('•', style: TextStyle(color: scheme.outline)),
                Text(
                  DateFormat('d MMM yyyy').format(entry.createdAt),
                  style: TextStyle(
                      color: scheme.onSurfaceVariant, fontSize: 12.5),
                ),
              ],
            ),
            if (entry.promptText.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.promptText,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Text(
              entry.content,
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MiniStat(label: 'Words', value: '${entry.wordCount}'),
                _MiniStat(label: 'Sentences', value: '${entry.sentenceCount}'),
                _MiniStat(label: 'Characters', value: '${entry.charCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
