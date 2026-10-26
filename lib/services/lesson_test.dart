import 'dart:math';

import '../models/question.dart';

/// نتيجة اختبار قصير (قبلي أو بعدي) لدرس.
class LessonTestResult {
  const LessonTestResult(this.score, this.total);

  final int score;
  final int total;

  /// الصيغة المخزَّنة: «نتيجة/عدد»
  String encode() => '$score/$total';

  static LessonTestResult? decode(String? s) {
    if (s == null) return null;
    final p = s.split('/');
    if (p.length != 2) return null;
    final a = int.tryParse(p[0]);
    final b = int.tryParse(p[1]);
    if (a == null || b == null || b <= 0 || a < 0 || a > b) return null;
    return LessonTestResult(a, b);
  }

  double get ratio => total == 0 ? 0 : score / total;

  /// الفرق بين البعدي والقبلي بالنقاط المئوية (قد يكون سالباً).
  static int improvementPercent(LessonTestResult pre, LessonTestResult post) =>
      ((post.ratio - pre.ratio) * 100).round();
}

class LessonTest {
  LessonTest._();

  static const int defaultCount = 5;

  /// يختار [count] سؤالاً من [pool] مستبعداً [exclude] (أسئلة الاختبار القبلي) كي لا يحفظ
  /// المتعلم الإجابات؛ فإن لم يكفِ الباقي تُكمَّل من المستبعَدة.
  static List<Question> pick(List<Question> pool, int count, Set<String> exclude, Random rng) {
    final fresh = pool.where((q) => !exclude.contains(q.id)).toList()..shuffle(rng);
    final out = fresh.take(count).toList();
    if (out.length < count) {
      final rest = pool.where((q) => exclude.contains(q.id)).toList()..shuffle(rng);
      out.addAll(rest.take(count - out.length));
    }
    return out;
  }
}
