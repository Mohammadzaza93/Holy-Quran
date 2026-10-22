import 'package:flutter_test/flutter_test.dart';
import 'package:tajweed_quiz/services/recitation_checker.dart';

void main() {
  group('ArabicText.normalize', () {
    test('يحذف التشكيل ويوحّد الألفات', () {
      expect(ArabicText.normalize('ٱلْحَمْدُ لِلَّهِ'), 'الحمد لله');
      expect(ArabicText.normalize('إِيَّاكَ'), 'اياك');
    });

    test('يحذف الألف الخنجرية والتطويل', () {
      expect(ArabicText.normalize('ٱلرَّحْمَـٰنِ'), 'الرحمن');
    });

    test('يوحّد التاء المربوطة والألف المقصورة', () {
      expect(ArabicText.normalize('رَحْمَةً'), 'رحمه');
      expect(ArabicText.normalize('عَلَىٰ'), 'علي');
    });

    test('يتجاهل رموز الآيات', () {
      expect(ArabicText.displayWords('فَسَجَدُوا ۩ لَهُ').length, 2);
    });
  });

  group('RecitationChecker.compare', () {
    const ayah = 'قُلْ هُوَ ٱللَّهُ أَحَدٌ';

    test('تلاوة صحيحة تماماً', () {
      final r = RecitationChecker.compare(ayah, 'قل هو الله احد');
      expect(r.isPerfect, isTrue);
      expect(r.score, 1.0);
      expect(r.correct, 4);
    });

    test('كلمة متروكة', () {
      final r = RecitationChecker.compare(ayah, 'قل هو احد');
      expect(r.missing, 1);
      expect(r.words[2].status, WordStatus.missing);
      expect(r.correct, 3);
      expect(r.score, lessThan(1.0));
    });

    test('كلمة مبدّلة', () {
      final r = RecitationChecker.compare(ayah, 'قل هو الرحمن احد');
      expect(r.wrong, 1);
      expect(r.words[2].status, WordStatus.wrong);
      expect(r.words[2].heard, 'الرحمن');
    });

    test('كلمة زائدة', () {
      final r = RecitationChecker.compare(ayah, 'قل هو الله الله احد');
      expect(r.extras, ['الله']);
      expect(r.correct, 4);
      expect(r.score, lessThan(1.0));
    });

    test('كلمة قريبة النطق', () {
      final r = RecitationChecker.compare('ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ', 'الصراط المستقيم');
      expect(r.wrong, 0);
      expect(r.missing, 0);
    });

    test('لم يُسمع شيء', () {
      final r = RecitationChecker.compare(ayah, '');
      expect(r.nothingHeard, isTrue);
      expect(r.missing, 4);
      expect(r.score, 0.0);
    });
  });
}
