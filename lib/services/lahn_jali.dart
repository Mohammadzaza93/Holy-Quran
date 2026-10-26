/// تصنيف «اللحن الجلي» في التلاوة: الخطأ الظاهر الذي يغيّر اللفظ فيخلّ بالمعنى أو الإعراب.
///
/// أنواعه ثلاثة: في الحروف (إبدال، نقص، زيادة)، وفي الكلمات (إبدال، نقص، زيادة)،
/// وفي الحركات (إبدال حركة بحركة أو بسكون أو العكس).
///
/// حدّ مهم: التعرف الصوتي يعيد كلمات **بلا تشكيل**، فيمكن رصد اللحن في الحروف والكلمات
/// ولا يمكن رصد اللحن في الحركات آلياً. ثم إن الرصد هنا **اشتباه** يُعاد التحقق منه بالاستماع
/// للقارئ، لأن المحرك قد يخطئ هو نفسه في السماع.
library;

import 'recitation_checker.dart';

enum LahnCategory { letters, words }

enum LahnKind {
  letterSubstitution,
  letterOmission,
  letterAddition,
  wordSubstitution,
  wordOmission,
  wordAddition,
}

class LahnFinding {
  const LahnFinding({
    required this.kind,
    required this.expected,
    this.heard,
    this.expectedLetter,
    this.heardLetter,
    this.hint,
  });

  final LahnKind kind;

  /// الكلمة كما في المصحف (أو الكلمة المسموعة الزائدة في حالة الزيادة)
  final String expected;
  final String? heard;
  final String? expectedLetter;
  final String? heardLetter;

  /// تنبيه تعليمي إن كان الإبدال من الأخطاء الشائعة
  final String? hint;

  LahnCategory get category => switch (kind) {
        LahnKind.letterSubstitution ||
        LahnKind.letterOmission ||
        LahnKind.letterAddition =>
          LahnCategory.letters,
        _ => LahnCategory.words,
      };

  String get title => switch (kind) {
        LahnKind.letterSubstitution => 'إبدال حرف بحرف',
        LahnKind.letterOmission => 'نقص حرف',
        LahnKind.letterAddition => 'زيادة حرف',
        LahnKind.wordSubstitution => 'إبدال كلمة بكلمة',
        LahnKind.wordOmission => 'نقص كلمة',
        LahnKind.wordAddition => 'زيادة كلمة',
      };

  String get description {
    switch (kind) {
      case LahnKind.letterSubstitution:
        return 'في «$expected» سُمع «$heardLetter» بدل «$expectedLetter» (سُمعت «$heard»).';
      case LahnKind.letterOmission:
        return 'في «$expected» سقط حرف «$expectedLetter» (سُمعت «$heard»).';
      case LahnKind.letterAddition:
        return 'في «$expected» زِيد حرف «$heardLetter» (سُمعت «$heard»).';
      case LahnKind.wordSubstitution:
        return 'نُطقت «$heard» بدل «$expected».';
      case LahnKind.wordOmission:
        return 'تُركت كلمة «$expected».';
      case LahnKind.wordAddition:
        return 'زِيدت كلمة «$expected».';
    }
  }
}

class LahnJali {
  LahnJali._();

  /// إبدالات شائعة بين الحروف المتقاربة، مع ما يُنبَّه عليه (على الرسم الموحَّد).
  static const Map<String, String> _commonSwaps = {
    'ث>س': 'الثاء تخرج من طرف اللسان مع أطراف الثنايا العليا، لا كالسين.',
    'ذ>ز': 'الذال تخرج من طرف اللسان مع أطراف الثنايا العليا، لا كالزاي.',
    'ظ>ز': 'الظاء مطبقة مستعلية ومخرجها كالذال، لا كالزاي.',
    'ظ>ذ': 'الظاء مطبقة مستعلية، وتفخيمها يميزها عن الذال.',
    'ط>د': 'الطاء مطبقة مستعلية مفخمة، لا كالدال.',
    'ط>ت': 'الطاء مطبقة مستعلية مفخمة، لا كالتاء.',
    'ض>د': 'الضاد تخرج من حافة اللسان مع الأضراس، وفيها إطباق واستطالة.',
    'ض>ظ': 'الضاد من حافة اللسان لا من طرفه، وتختلف عن الظاء.',
    'ص>س': 'الصاد مطبقة مستعلية مفخمة، لا كالسين.',
    'ح>ه': 'الحاء من وسط الحلق، والهاء من أقصاه.',
    'ع>ا': 'العين من وسط الحلق، وليست كالهمزة.',
    'ق>ك': 'القاف أقصى اللسان مفخمة، والكاف أدنى منها مرققة.',
    'ق>ا': 'القاف مستعلية من أقصى اللسان، وليست كالهمزة.',
    'غ>خ': 'الغين مجهورة والخاء مهموسة، وكلاهما من أدنى الحلق.',
  };

  /// يصنّف عدم التطابق بين كلمة متوقعة [expected] وما سُمع [heard] (كلاهما بعد توحيد الرسم).
  /// يعيد null إن لم يمكن الجزم بنوع (فرق متعدد الحروف أو تشابه شديد يرجّح خطأ السماع).
  static LahnFinding? classifyWord({
    required String display,
    required String expected,
    required String heard,
    required bool wrongStatus,
  }) {
    if (expected == heard) return null;

    // إبدال حرف واحد
    if (expected.length == heard.length) {
      final diffs = <int>[
        for (var i = 0; i < expected.length; i++)
          if (expected[i] != heard[i]) i,
      ];
      if (diffs.length == 1) {
        final e = expected[diffs.first];
        final h = heard[diffs.first];
        return LahnFinding(
          kind: LahnKind.letterSubstitution,
          expected: display,
          heard: heard,
          expectedLetter: e,
          heardLetter: h,
          hint: _commonSwaps['$e>$h'],
        );
      }
    }
    // نقص حرف واحد
    if (heard.length == expected.length - 1) {
      for (var i = 0; i < expected.length; i++) {
        if (expected.substring(0, i) + expected.substring(i + 1) == heard) {
          return LahnFinding(
            kind: LahnKind.letterOmission,
            expected: display,
            heard: heard,
            expectedLetter: expected[i],
          );
        }
      }
    }
    // زيادة حرف واحد
    if (heard.length == expected.length + 1) {
      for (var i = 0; i < heard.length; i++) {
        if (heard.substring(0, i) + heard.substring(i + 1) == expected) {
          return LahnFinding(
            kind: LahnKind.letterAddition,
            expected: display,
            heard: heard,
            heardLetter: heard[i],
          );
        }
      }
    }
    // كلمة مختلفة تماماً (لا فرق بحرف واحد)
    if (wrongStatus) {
      return LahnFinding(kind: LahnKind.wordSubstitution, expected: display, heard: heard);
    }
    return null;
  }

  /// يستخرج كل ما يُشتبه فيه من اللحن الجلي من كلمات نتيجة المقارنة والكلمات الزائدة.
  static List<LahnFinding> analyze(List<WordResult> words, List<String> extras) {
    final out = <LahnFinding>[];
    for (final w in words) {
      switch (w.status) {
        case WordStatus.missing:
          out.add(LahnFinding(kind: LahnKind.wordOmission, expected: w.display));
        case WordStatus.wrong || WordStatus.near:
          final h = w.heard;
          if (h == null) break;
          final f = classifyWord(
            display: w.display,
            expected: w.expected,
            heard: h,
            wrongStatus: w.status == WordStatus.wrong,
          );
          if (f != null) out.add(f);
        default:
          break;
      }
    }
    for (final e in extras) {
      out.add(LahnFinding(kind: LahnKind.wordAddition, expected: e));
    }
    return out;
  }

  /// نص تعريفي مختصر (صياغة التطبيق) يُعرض في شاشة النتيجة.
  static const String definition =
      'اللحن الجلي خطأ يطرأ على ألفاظ القرآن فيخلّ بالمعنى أو الإعراب إخلالاً ظاهراً، '
      'وسُمّي جلياً لوضوحه للقرّاء والمستمعين. وهو محرَّم، ويأثم القارئ به إن تعمّده أو قصّر في التعلّم، '
      'ويُعذر من في لسانه عجمة أو عيب خِلقي أو كبير تعسّر لسانه، ومن كان في مجلس تعلّم يصحَّح له.';

  static const List<String> forms = [
    'في الحروف: إبدال حرف بحرف (ثيّبات بالسين)، أو نقص حرف (واخشوني)، أو زيادة حرف (دعانِ).',
    'في الحركات: إبدال حركة بحركة (أنعمتُ بضم التاء)، أو بسكون (بيتيْ)، أو سكون بحركة (عهدِيَ).',
    'في الكلمات: إبدال كلمة بكلمة، أو نقصها، أو زيادتها.',
  ];

  static const String limit =
      'يرصد التطبيق اللحن في الحروف والكلمات اشتباهاً، أما اللحن في الحركات فلا يمكن رصده آلياً '
      'لأن التعرف الصوتي لا يعيد التشكيل؛ فاستمع لقارئ متقن وأعد الآية.';
}
