/// نموذج الدرس في سلسلة شروح التجويد.
/// المحتوى أصلي ومستوحى من منهج الشيخ أيمن رشدي سويد مع الإسناد الواضح.
class Lesson {
  const Lesson({
    required this.id,
    required this.order,
    required this.title,
    required this.summary,
    required this.content,
    this.relatedCategory,
  });

  /// معرّف فريد للدرس
  final String id;

  /// ترتيب الدرس في السلسلة (يبدأ من 1)
  final int order;

  /// عنوان الدرس
  final String title;

  /// ملخص قصير يظهر في قائمة الدروس
  final String summary;

  /// نص الشرح الكامل (يدعم أسطر متعددة)
  final String content;

  /// قسم الاختبار المرتبط (اختياري) لربطه لاحقاً بالأسئلة
  final String? relatedCategory;

  /// نص الإسناد الثابت
  static const String attribution =
      'مستند إلى محاضرات الشيخ أيمن رشدي سويد – كتاب النور المبين في تجويد القرآن الكريم';
}
