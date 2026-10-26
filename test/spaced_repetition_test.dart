import 'package:flutter_test/flutter_test.dart';
import 'package:tajweed_quiz/services/spaced_repetition.dart';

void main() {
  const q = 'q1';

  test('الخطأ يجدول المراجعة بعد يوم', () {
    final m = SpacedRepetition.update({}, q, false, 100);
    expect(m[q]!.box, 0);
    expect(m[q]!.due, 101);
    expect(SpacedRepetition.dueIds(m, 100), isEmpty);
    expect(SpacedRepetition.dueIds(m, 101), {q});
  });

  test('المراحل: يوم ثم ٣ أيام ثم أسبوع ثم إتقان', () {
    var m = SpacedRepetition.update({}, q, false, 100);
    m = SpacedRepetition.update(m, q, true, 101);
    expect(m[q]!.due, 104);
    m = SpacedRepetition.update(m, q, true, 104);
    expect(m[q]!.due, 111);
    m = SpacedRepetition.update(m, q, true, 111);
    expect(m.containsKey(q), isFalse);
  });

  test('خطأ أثناء المراجعة يعيد إلى المرحلة الأولى', () {
    var m = SpacedRepetition.update({}, q, false, 100);
    m = SpacedRepetition.update(m, q, true, 101);
    m = SpacedRepetition.update(m, q, false, 104);
    expect(m[q]!.box, 0);
    expect(m[q]!.due, 105);
  });

  test('إصابة سؤال لم يحن موعده أو غير مجدول لا تغيّر شيئاً', () {
    var m = SpacedRepetition.update({}, q, false, 100);
    final same = SpacedRepetition.update(m, q, true, 100);
    expect(same[q]!.due, 101);
    expect(SpacedRepetition.update({}, 'x', true, 100), isEmpty);
  });

  test('رقم اليوم', () {
    expect(SpacedRepetition.dayNumber(DateTime(1970, 1, 2, 23, 59)), 1);
    expect(SpacedRepetition.dayNumber(DateTime(2026, 10, 26, 8)),
        SpacedRepetition.dayNumber(DateTime(2026, 10, 26, 23)));
  });

  test('تحويل الإدخال من/إلى JSON', () {
    final e = SrsEntry.fromJson(const SrsEntry(box: 2, due: 5).toJson())!;
    expect(e.box, 2);
    expect(e.due, 5);
    expect(SrsEntry.fromJson('bad'), isNull);
  });
}
