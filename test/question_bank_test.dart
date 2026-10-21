import 'package:flutter_test/flutter_test.dart';
import 'package:tajweed_quiz/data/question_bank.dart';

void main() {
  test('معرّفات الأسئلة فريدة', () {
    final ids = builtInQuestions.map((q) => q.id).toSet();
    expect(ids.length, builtInQuestions.length);
  });

  test('كل سؤال له ثلاثة مشتتات مختلفة ولا تحتوي الصحيحة', () {
    for (final q in builtInQuestions) {
      expect(q.wrong.length, 3, reason: q.id);
      expect(q.wrong.toSet().length, q.wrong.length, reason: q.id);
      expect(q.wrong.contains(q.correct), isFalse, reason: q.id);
    }
  });

  test('مراجع الآيات صحيحة', () {
    for (final q in builtInQuestions.where((q) => q.hasAyahRef)) {
      expect(q.surah! >= 1 && q.surah! <= 114, isTrue, reason: q.id);
      expect(q.ayah! >= 1, isTrue, reason: q.id);
    }
  });
}
