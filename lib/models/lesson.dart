/// A writing/grammar lesson made up of sections and examples.
class Lesson {
  final String id;
  final String category; // Grammar, Style, Structure, Punctuation
  final String level;
  final String title;
  final String summary;
  final List<LessonSection> sections;

  const Lesson({
    required this.id,
    required this.category,
    required this.level,
    required this.title,
    required this.summary,
    required this.sections,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'category': category,
        'level': level,
        'title': title,
        'summary': summary,
        'sections': sections.map((s) => s.toMap()).toList(),
      };

  factory Lesson.fromMap(Map<String, dynamic> m) => Lesson(
        id: m['id'] as String,
        category: m['category'] as String,
        level: m['level'] as String,
        title: m['title'] as String,
        summary: m['summary'] as String,
        sections: (m['sections'] as List? ?? [])
            .map((e) => LessonSection.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}

class LessonSection {
  final String heading;
  final String body;
  final List<ExamplePair> examples;

  const LessonSection({
    required this.heading,
    required this.body,
    this.examples = const [],
  });

  Map<String, dynamic> toMap() => {
        'heading': heading,
        'body': body,
        'examples': examples.map((e) => e.toMap()).toList(),
      };

  factory LessonSection.fromMap(Map<String, dynamic> m) => LessonSection(
        heading: m['heading'] as String,
        body: m['body'] as String,
        examples: (m['examples'] as List? ?? [])
            .map((e) => ExamplePair.fromMap(e as Map<String, dynamic>))
            .toList(),
      );
}

/// A wrong vs. right example pair used to teach a point.
class ExamplePair {
  final String wrong;
  final String right;
  final String? note;

  const ExamplePair({required this.wrong, required this.right, this.note});

  Map<String, dynamic> toMap() => {
        'wrong': wrong,
        'right': right,
        'note': note,
      };

  factory ExamplePair.fromMap(Map<String, dynamic> m) => ExamplePair(
        wrong: m['wrong'] as String,
        right: m['right'] as String,
        note: m['note'] as String?,
      );
}
