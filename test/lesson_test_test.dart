import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tajweed_quiz/models/question.dart';
import 'package:tajweed_quiz/services/lesson_test.dart';

Question _q(int i) => Question(
      id: 'q$i',
      category: QuizCategory.madd,
      text: 'س$i',
      correct: 'ج',
      wrong: const ['أ', 'ب'],
      explanation: 'ش',
    );

void main() {
  final pool = [for (var i = 0; i < 12; i++) _q(i)];

  test('الاختبار البعدي لا يكرر أسئلة القبلي حين يتوفر غيرها', () {
    final pre = LessonTest.pick(pool, 5, {}, Random(1));
    expect(pre.length, 5);
    final post = LessonTest.pick(pool, 5, pre.map((q) => q.id).toSet(), Random(2));
    expect(post.length, 5);
    expect(post.map((q) => q.id).toSet().intersection(pre.map((q) => q.id).toSet()), isEmpty);
  });

  test('إكمال العدد من المستبعَدة عند قلة الأسئلة', () {
    final small = pool.take(6).toList();
    final ex = small.take(3).map((q) => q.id).toSet();
    final out = LessonTest.pick(small, 5, ex, Random(3));
    expect(out.length, 5);
    expect(out.map((q) => q.id).toSet().length, 5);
  });

  test('ترميز النتيجة وفكّها', () {
    expect(LessonTestResult.decode(const LessonTestResult(3, 5).encode())!.score, 3);
    expect(LessonTestResult.decode('x'), isNull);
    expect(LessonTestResult.decode('6/5'), isNull);
    expect(LessonTestResult.decode(null), isNull);
  });

  test('التحسن بالنقاط المئوية', () {
    expect(LessonTestResult.improvementPercent(
        const LessonTestResult(2, 5), const LessonTestResult(4, 5)), 40);
    expect(LessonTestResult.improvementPercent(
        const LessonTestResult(4, 5), const LessonTestResult(3, 5)), -20);
  });
}
