import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/prompt.dart';
import '../models/writing_entry.dart';
import '../state/app_state.dart';
import '../widgets/common_widgets.dart';

/// The writing editor. Used both for new prompt-based writing and editing
/// an existing entry.
class EditorScreen extends StatefulWidget {
  final WritingPrompt? prompt;
  final WritingEntry? existing;

  const EditorScreen({super.key, this.prompt, this.existing});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  Timer? _timer;
  int _seconds = 0;
  bool _dirty = false;
  bool _tipsExpanded = false;

  WritingPrompt? get _prompt => widget.prompt;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleCtrl = TextEditingController(
      text: existing?.title ?? _prompt?.title ?? '',
    );
    _bodyCtrl = TextEditingController(text: existing?.content ?? '');
    _bodyCtrl.addListener(_onChanged);
    _titleCtrl.addListener(_onChanged);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _onChanged() {
    if (!_dirty) setState(() => _dirty = true);
    setState(() {}); // refresh live counters
  }

  @override
  void dispose() {
    _timer?.cancel();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  int get _wordCount {
    final t = _bodyCtrl.text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  String get _timeLabel {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _save() async {
    final body = _bodyCtrl.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before saving 🙂')),
      );
      return;
    }
    final state = context.read<AppState>();
    final now = DateTime.now();
    final existing = widget.existing;
    final title = _titleCtrl.text.trim().isEmpty
        ? (_prompt?.title ?? 'Untitled')
        : _titleCtrl.text.trim();

    final entry = existing != null
        ? existing.copyWith(
            title: title,
            content: _bodyCtrl.text,
            updatedAt: now,
          )
        : WritingEntry(
            id: now.microsecondsSinceEpoch.toString(),
            title: title,
            content: _bodyCtrl.text,
            promptId: _prompt?.id,
            promptText: _prompt?.text ?? '',
            category: _prompt?.category ?? 'Free Writing',
            level: _prompt?.level ?? 'Any',
            createdAt: now,
            updatedAt: now,
          );

    await state.saveEntry(entry);
    if (!mounted) return;
    setState(() => _dirty = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved · ${entry.wordCount} words 🎉')),
    );
    Navigator.of(context).pop(true);
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved writing. Leave without saving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep writing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prompt = _prompt;
    final target = prompt?.suggestedWords ?? 0;
    final progress =
        target == 0 ? null : (_wordCount / target).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final canLeave = await _confirmLeave();
        if (!mounted) return;
        if (canLeave) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing != null ? 'Edit' : 'Write'),
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        size: 16, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(_timeLabel,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontFeatures: const [])),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            if (prompt != null) _PromptBanner(
              prompt: prompt,
              expanded: _tipsExpanded,
              onToggle: () => setState(() => _tipsExpanded = !_tipsExpanded),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const Divider(),
                    TextField(
                      controller: _bodyCtrl,
                      maxLines: null,
                      minLines: 12,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      decoration: const InputDecoration(
                        hintText: 'Start writing in English here...',
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomBar(
              wordCount: _wordCount,
              target: target,
              progress: progress,
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptBanner extends StatelessWidget {
  final WritingPrompt prompt;
  final bool expanded;
  final VoidCallback onToggle;
  const _PromptBanner({
    required this.prompt,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.primaryContainer.withValues(alpha: 0.4),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LevelChip(prompt.level, small: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  prompt.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(prompt.text, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 4),
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    expanded ? Icons.expand_less : Icons.lightbulb_outline,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    expanded ? 'Hide tips' : 'Show writing tips',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            ...prompt.tips.map(
              (t) => Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(
                        child: Text(t,
                            style: const TextStyle(fontSize: 13, height: 1.3))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int wordCount;
  final int target;
  final double? progress;
  final VoidCallback onSave;
  const _BottomBar({
    required this.wordCount,
    required this.target,
    required this.progress,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$wordCount words',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
                if (target > 0)
                  Text(
                    'Goal: $target',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            if (progress != null)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
