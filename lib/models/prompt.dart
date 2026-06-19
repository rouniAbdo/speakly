/// A writing prompt the user can practice with.
class WritingPrompt {
  final String id;
  final String category;
  final String level; // Beginner, Intermediate, Advanced
  final String title;
  final String text;
  final List<String> tips;
  final int suggestedWords;

  const WritingPrompt({
    required this.id,
    required this.category,
    required this.level,
    required this.title,
    required this.text,
    required this.tips,
    required this.suggestedWords,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'level': level,
        'title': title,
        'text': text,
        'tips': tips,
        'suggestedWords': suggestedWords,
      };

  factory WritingPrompt.fromMap(Map<String, dynamic> m) => WritingPrompt(
        id: m['id'] as String,
        category: m['category'] as String,
        level: m['level'] as String,
        title: m['title'] as String,
        text: m['text'] as String,
        tips: (m['tips'] as List? ?? []).map((e) => e.toString()).toList(),
        suggestedWords: (m['suggestedWords'] as num? ?? 0).toInt(),
      );
}
