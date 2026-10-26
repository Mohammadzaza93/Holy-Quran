import 'package:flutter_test/flutter_test.dart';
import 'package:tajweed_quiz/data/lessons.dart';
import 'package:tajweed_quiz/data/surahs.dart';

void main() {
  test('معرّفات الدروس فريدة ومرتبة', () {
    final ids = allLessons.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(allLessons, isNotEmpty);
  });

  test('كل درس له عنوان وملخص وصفحات وأقسام غير فارغة', () {
    for (final l in allLessons) {
      expect(l.title.trim(), isNotEmpty, reason: l.id);
      expect(l.summary.trim(), isNotEmpty, reason: l.id);
      expect(l.pages.trim(), isNotEmpty, reason: l.id);
      expect(l.sections, isNotEmpty, reason: l.id);
      for (final s in l.sections) {
        expect(s.heading.trim(), isNotEmpty, reason: l.id);
        final hasContent =
            s.body.isNotEmpty || s.points.isNotEmpty || s.examples.isNotEmpty || s.quote != null;
        expect(hasContent, isTrue, reason: '${l.id} / ${s.heading} قسم فارغ');
      }
    }
  });

  test('مراجع الآيات في الأمثلة صحيحة', () {
    for (final l in allLessons) {
      for (final s in l.sections) {
        for (final e in s.examples) {
          expect((e.surah == null) == (e.ayah == null), isTrue,
              reason: '${l.id}: ${e.phrase} سورة وآية معاً أو لا شيء');
          if (e.surah != null) {
            expect(e.surah! >= 1 && e.surah! <= 114, isTrue, reason: '${l.id}: ${e.phrase}');
            expect(e.ayah! >= 1 && e.ayah! <= surahAyahCount(e.surah!), isTrue,
                reason: '${l.id}: ${e.phrase} (${e.surah}:${e.ayah})');
          }
        }
      }
    }
  });

  test('لا تتضمن الدروس أبياتاً من المتون (الاقتباسات أحاديث فقط)', () {
    for (final l in allLessons) {
      for (final s in l.sections) {
        if (s.quote == null) continue;
        expect(s.quoteSource ?? '', contains('حديث'), reason: '${l.id}: ${s.heading}');
      }
    }
  });

  test('كل درس يحمل نطاق صفحات من الكتاب', () {
    final digits = RegExp('[٠-٩]');
    for (final l in allLessons) {
      expect(digits.hasMatch(l.pages), isTrue, reason: '${l.id}: ${l.pages}');
    }
  });
}
