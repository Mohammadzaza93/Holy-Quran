import 'package:flutter_test/flutter_test.dart';
import 'package:tajweed_quiz/services/advanced_check.dart';

void main() {
  test('تحليل ردّ ناجح فيه خطأ حركة', () {
    const body = '''
{"uthmani_text":"قُلْ هُوَ","predicted_phonemes":"x","reference_phonemes":"y",
 "errors":[{"uthmani_pos":[0,1],"ph_pos":[0,1],"error_type":"tashkeel",
 "speech_error_type":"replace","expected_ph":"قُ","preditected_ph":"قِ",
 "expected_len":null,"predicted_len":null,
 "ref_tajweed_rules":[{"name":{"ar":"مد","en":"madd"},"golden_len":2,"correctness_type":"count"}]}]}''';
    final r = AdvancedCheckResult.parse(200, body);
    expect(r.matched, isTrue);
    expect(r.errors.single.typeLabel, 'حركة (تشكيل)');
    expect(r.errors.single.actionLabel, 'إبدال');
    expect(r.errors.single.ruleNames, ['مد']);
  });

  test('عدم وجود مطابقة (404)', () {
    final r = AdvancedCheckResult.parse(404, '{"predicted_phonemes":"x","message":"لا نتائج"}');
    expect(r.matched, isFalse);
    expect(r.message, 'لا نتائج');
  });

  test('تطبيع عنوان الخادم', () {
    expect(AdvancedCheck.normalizeUrl(' 192.168.1.5:8001/ '), 'http://192.168.1.5:8001');
  });
}
