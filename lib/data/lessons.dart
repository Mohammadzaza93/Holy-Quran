import '../models/lesson.dart';

/// سلسلة شرح كتاب التجويد المصور — الدكتور أيمن رشدي سويد
/// المصدر: قائمة التشغيل الرسمية على يوتيوب
/// https://www.youtube.com/playlist?list=PLJi21Zen45zQ-p3e38-Wb94LhDKIZ7sac
final List<Lesson> tajweedLessons = [
  Lesson(id: 'ep-01', order: 1, title: 'مقدمة في علم التجويد (1)', summary: 'الحلقة 1 — مقدمة', youtubeVideoId: 'H6WTnSZ6G-0'),
  Lesson(id: 'ep-02', order: 2, title: 'مقدمة في علم التجويد (2)', summary: 'الحلقة 2 — تتمة المقدمة', youtubeVideoId: 'ChtM254qsdU'),
  Lesson(id: 'ep-03', order: 3, title: 'مخارج الحروف — الجوف', summary: 'الحلقة 3 — باب المخارج', youtubeVideoId: 'Es_a0IGHofc', relatedCategory: 'makharij'),
  Lesson(id: 'ep-04', order: 4, title: 'مخارج الحروف — الحلق', summary: 'الحلقة 4 — باب المخارج', youtubeVideoId: '2BFpfzbBBVo', relatedCategory: 'makharij'),
  Lesson(id: 'ep-05', order: 5, title: 'مخارج الحروف — اللسان (1)', summary: 'الحلقة 5 — باب المخارج', youtubeVideoId: 'vwaWWcV0Z5M', relatedCategory: 'makharij'),
  Lesson(id: 'ep-06', order: 6, title: 'مخارج الحروف — اللسان (2)', summary: 'الحلقة 6 — باب المخارج', youtubeVideoId: '8zIZQkaySyQ', relatedCategory: 'makharij'),
  Lesson(id: 'ep-07', order: 7, title: 'صفات الحروف (مقدمة)', summary: 'الحلقة 7 — باب الصفات', youtubeVideoId: 'aYO2mrrHqPo', relatedCategory: 'sifat'),
  Lesson(id: 'ep-08', order: 8, title: 'الشدة والرخاوة والبينية', summary: 'الحلقة 8 — باب الصفات', youtubeVideoId: '5q5rI3qBLx0', relatedCategory: 'sifat'),
  Lesson(id: 'ep-09', order: 9, title: 'قياس أزمنة الحروف', summary: 'الحلقة 9 — السواكن والمتحركة', youtubeVideoId: 'AZSlZoUfS9Y', relatedCategory: 'sifat'),
  Lesson(id: 'ep-10', order: 10, title: 'الاستعلاء والاستفال', summary: 'الحلقة 10 — باب الصفات', youtubeVideoId: 'xh_MHe1YOdA', relatedCategory: 'sifat'),
  Lesson(id: 'ep-11', order: 11, title: 'حكم الألف واللام والراء', summary: 'الحلقة 11 — التفخيم والترقيق', youtubeVideoId: 'MTkmsbjK0Tc', relatedCategory: 'misc'),
  Lesson(id: 'ep-12', order: 12, title: 'صفات الحروف (تتمة)', summary: 'الحلقة 12 — باب الصفات', youtubeVideoId: 'Ydo53V1V1V8', relatedCategory: 'sifat'),
  Lesson(id: 'ep-13', order: 13, title: 'القلقلة', summary: 'الحلقة 13 — باب الصفات', youtubeVideoId: 'KgotHP9a7-o', relatedCategory: 'misc'),
  Lesson(id: 'ep-14', order: 14, title: 'نصائح لأهل القرآن', summary: 'الحلقة 14 — توجيهات', youtubeVideoId: 'Y7Y7g3GIl7Y'),
  Lesson(id: 'ep-15', order: 15, title: 'اللين', summary: 'الحلقة 15 — باب الصفات', youtubeVideoId: 'OJDGrpOFyw8', relatedCategory: 'sifat'),
  Lesson(id: 'ep-16', order: 16, title: 'الغنة صفةً', summary: 'الحلقة 16 — باب الصفات', youtubeVideoId: 'I3-IOD49WgE', relatedCategory: 'noon'),
  Lesson(id: 'ep-17', order: 17, title: 'أبرز أخطاء نطق حروف الهجاء', summary: 'الحلقة 17 — تنبيهات', youtubeVideoId: '_2RZIEq0t6s', relatedCategory: 'makharij'),
  Lesson(id: 'ep-18', order: 18, title: 'إتمام الحركات', summary: 'الحلقة 18', youtubeVideoId: '-LxbHpJs9bw'),
  Lesson(id: 'ep-19', order: 19, title: 'الوقف والابتداء', summary: 'الحلقة 19', youtubeVideoId: 'tOW9ZVAI0eU', relatedCategory: 'misc'),
  Lesson(id: 'ep-20', order: 20, title: 'الوقف والابتداء — تنبيهات', summary: 'الحلقة 20', youtubeVideoId: 'bteuCHz-mRM', relatedCategory: 'misc'),
  Lesson(id: 'ep-21', order: 21, title: 'مقدمة القسم الثاني', summary: 'الحلقة 21', youtubeVideoId: 'KvIwlbpMWIs'),
  Lesson(id: 'ep-22', order: 22, title: 'الحرفان الملتقيان', summary: 'الحلقة 22', youtubeVideoId: 'Z9hDuv7DYMQ', relatedCategory: 'misc'),
  Lesson(id: 'ep-23', order: 23, title: 'الحرفان المتقاربان', summary: 'الحلقة 23', youtubeVideoId: 'LMtDtKjEAzI', relatedCategory: 'misc'),
  Lesson(id: 'ep-24', order: 24, title: 'أحكام الميم الساكنة', summary: 'الحلقة 24 — إدغام وإخفاء وإظهار', youtubeVideoId: 'gyrtmirqn_M', relatedCategory: 'meem'),
  Lesson(id: 'ep-25', order: 25, title: 'أحكام النون الساكنة والتنوين', summary: 'الحلقة 25', youtubeVideoId: 'LYOO-6f3s0U', relatedCategory: 'noon'),
  Lesson(id: 'ep-26', order: 26, title: 'النون الساكنة — الإخفاء', summary: 'الحلقة 26', youtubeVideoId: '1mydlMCh9eg', relatedCategory: 'noon'),
  Lesson(id: 'ep-27', order: 27, title: 'المدود — تعريف المد', summary: 'الحلقة 27', youtubeVideoId: '3tL5YYdjnTw', relatedCategory: 'madd'),
  Lesson(id: 'ep-28', order: 28, title: 'قياس أزمنة المدود', summary: 'الحلقة 28', youtubeVideoId: 'bfbB-YxuDpw', relatedCategory: 'madd'),
  Lesson(id: 'ep-29', order: 29, title: 'المد الطبيعي', summary: 'الحلقة 29', youtubeVideoId: 'd_W1cbLbwM0', relatedCategory: 'madd'),
  Lesson(id: 'ep-30', order: 30, title: 'المد الجائز المنفصل', summary: 'الحلقة 30', youtubeVideoId: 'VVoZxsr8uiQ', relatedCategory: 'madd'),
  Lesson(id: 'ep-31', order: 31, title: 'الحروف المقطعة (1)', summary: 'الحلقة 31', youtubeVideoId: '5za4w-bg6-U', relatedCategory: 'madd'),
  Lesson(id: 'ep-32', order: 32, title: 'الحروف المقطعة (2)', summary: 'الحلقة 32', youtubeVideoId: 'JWjyU5irlF4', relatedCategory: 'madd'),
  Lesson(id: 'ep-33', order: 33, title: 'المد العارض للسكون ومد اللين', summary: 'الحلقة 33', youtubeVideoId: 'lbDV5QSj_vY', relatedCategory: 'madd'),
  Lesson(id: 'ep-34', order: 34, title: 'قاعدة أقوى السببين', summary: 'الحلقة 34', youtubeVideoId: '1P32Jelgu0A', relatedCategory: 'madd'),
  Lesson(id: 'ep-35', order: 35, title: 'التقاء الساكنين', summary: 'الحلقة 35', youtubeVideoId: 'MEuYX35zBEc'),
  Lesson(id: 'ep-36', order: 36, title: 'مواضيع متفرقة (إمالة وغيرها)', summary: 'الحلقة 36', youtubeVideoId: 'hLbqfHzw_kI', relatedCategory: 'hafs'),
  Lesson(id: 'ep-37', order: 37, title: 'كلمات خاصة على رواية حفص', summary: 'الحلقة 37', youtubeVideoId: 'qBWCZZWsz7I', relatedCategory: 'hafs'),
  Lesson(id: 'ep-38', order: 38, title: 'الرَّوم والإشمام', summary: 'الحلقة 38', youtubeVideoId: '9MS2pHBYU_s', relatedCategory: 'hafs'),
  Lesson(id: 'ep-39', order: 39, title: 'ما لا يدخله الروم ولا الإشمام', summary: 'الحلقة 39', youtubeVideoId: 'QBa2UXeN-TE', relatedCategory: 'hafs'),
  Lesson(id: 'ep-40', order: 40, title: 'الألفات السبعة', summary: 'الحلقة 40', youtubeVideoId: 'WqudUBqqlZQ', relatedCategory: 'hafs'),
  Lesson(id: 'ep-41', order: 41, title: 'همزة القطع', summary: 'الحلقة 41', youtubeVideoId: 'rySLUV_lcgU'),
  Lesson(id: 'ep-42', order: 42, title: 'مراحل تطور كتابة المصحف (1)', summary: 'الحلقة 42', youtubeVideoId: 'cHDr7oV02nc'),
  Lesson(id: 'ep-43', order: 43, title: 'مراحل تطور كتابة المصحف (2)', summary: 'الحلقة 43', youtubeVideoId: 'PiIsjbNVlS8'),
  Lesson(id: 'ep-44', order: 44, title: 'مراحل تطور كتابة المصحف (3)', summary: 'الحلقة 44', youtubeVideoId: 'X920piSRPgs'),
  Lesson(id: 'ep-45', order: 45, title: 'حفظ القرآن الكريم', summary: 'الحلقة 45 — خاتمة السلسلة', youtubeVideoId: '0pVF5wcFOJ8'),
];

Lesson? getLessonByOrder(int order) {
  try {
    return tajweedLessons.firstWhere((l) => l.order == order);
  } catch (_) {
    return null;
  }
}

Lesson? getLessonById(String id) {
  try {
    return tajweedLessons.firstWhere((l) => l.id == id);
  } catch (_) {
    return null;
  }
}
