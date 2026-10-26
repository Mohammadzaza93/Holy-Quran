import '../models/question.dart';

/// مثال قرآني يرد في الدرس (اختياري الموضع).
class LessonExample {
  const LessonExample(this.phrase, this.note, {this.surah, this.ayah});

  final String phrase;
  final String note;
  final int? surah;
  final int? ayah;
}

/// فقرة داخل الدرس: عنوان + نص + نقاط + أمثلة + اقتباس (من متن الجزرية مثلاً).
class LessonSection {
  const LessonSection({
    required this.heading,
    this.body = const [],
    this.points = const [],
    this.examples = const [],
    this.quote,
    this.quoteSource,
  });

  final String heading;
  final List<String> body;
  final List<String> points;
  final List<LessonExample> examples;
  final String? quote;
  final String? quoteSource;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.part,
    required this.title,
    required this.summary,
    required this.pages,
    required this.sections,
    this.category,
  });

  final String id;

  /// اسم الباب الذي يندرج تحته الدرس في قائمة الدروس
  final String part;
  final String title;
  final String summary;

  /// أرقام صفحات الكتاب المطبوع التي أُخذ منها الدرس، مثل: ٤٣–٤٦
  final String pages;
  final List<LessonSection> sections;

  /// قسم الأسئلة المرتبط بالدرس (لزر «اختبرني في هذا الدرس»)
  final QuizCategory? category;
}
