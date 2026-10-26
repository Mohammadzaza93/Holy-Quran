/// درس من سلسلة شروح التجويد المصور للشيخ أيمن رشدي سويد (روابط يوتيوب).
class Lesson {
  const Lesson({
    required this.id,
    required this.order,
    required this.title,
    required this.summary,
    required this.youtubeVideoId,
    this.relatedCategory,
  });

  /// معرّف فريد للدرس
  final String id;

  /// ترتيب الحلقة في السلسلة (يبدأ من 1)
  final int order;

  /// عنوان الحلقة
  final String title;

  /// ملخص قصير يظهر في القائمة
  final String summary;

  /// معرّف فيديو يوتيوب (بدون الرابط الكامل)
  final String youtubeVideoId;

  /// قسم الاختبار المرتبط (اختياري)
  final String? relatedCategory;

  /// رابط المشاهدة على يوتيوب
  String get youtubeUrl => 'https://www.youtube.com/watch?v=$youtubeVideoId';

  /// رابط التطبيق إن وُجد
  String get youtubeAppUrl => 'youtube://watch?v=$youtubeVideoId';

  static const String playlistUrl =
      'https://www.youtube.com/playlist?list=PLJi21Zen45zQ-p3e38-Wb94LhDKIZ7sac';

  static const String attribution =
      'شرح كتاب التجويد المصور — فضيلة الدكتور الشيخ أيمن رشدي سويد (قائمة تشغيل رسمية على يوتيوب)';
}
