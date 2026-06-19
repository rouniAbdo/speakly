import 'dart:convert';

/// A single piece of writing the user has produced.
class WritingEntry {
  final String id;
  final String title;
  final String content;
  final String? promptId;
  final String promptText;
  final String category;
  final String level;
  final DateTime createdAt;
  final DateTime updatedAt;

  WritingEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.promptText,
    required this.category,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
    this.promptId,
  });

  int get wordCount {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).length;
  }

  int get charCount => content.length;

  int get sentenceCount {
    final matches = RegExp(r'[.!?]+').allMatches(content.trim());
    final c = matches.length;
    return c == 0 && content.trim().isNotEmpty ? 1 : c;
  }

  WritingEntry copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
  }) {
    return WritingEntry(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      promptId: promptId,
      promptText: promptText,
      category: category,
      level: level,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'promptId': promptId,
        'promptText': promptText,
        'category': category,
        'level': level,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory WritingEntry.fromMap(Map<String, dynamic> map) => WritingEntry(
        id: map['id'] as String,
        title: map['title'] as String? ?? 'Untitled',
        content: map['content'] as String? ?? '',
        promptId: map['promptId'] as String?,
        promptText: map['promptText'] as String? ?? '',
        category: map['category'] as String? ?? 'Free Writing',
        level: map['level'] as String? ?? 'Any',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
            DateTime.now(),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );

  String toJson() => jsonEncode(toMap());

  factory WritingEntry.fromJson(String source) =>
      WritingEntry.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
