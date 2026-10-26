/// منطق مقارنة ما نطقه القارئ (نص ناتج عن التعرف الصوتي) بنص الآية المتوقع.
///
/// مهم: التعرف الصوتي الجاهز يعيد كلمات عربية بلا تشكيل غالباً، لذلك تتم المقارنة
/// على مستوى **الكلمات** بعد توحيد الرسم (حذف التشكيل، توحيد الألفات والتاء المربوطة...).
/// هذا يكشف: كلمة مبدّلة، كلمة متروكة، كلمة زائدة. ولا يكشف أحكام التجويد
/// (المدود، الغنة، الإخفاء، مخارج الحروف الدقيقة) فهذه تحتاج مقرئاً.
library;

import 'lahn_jali.dart';

class ArabicText {
  ArabicText._();

  static final RegExp _marks = RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ​-‏]');
  static final RegExp _notLetters = RegExp('[^ء-ي\\s]');
  static final RegExp _spaces = RegExp(r'\s+');

  static String normalize(String input) {
    var s = input.replaceAll(_marks, '');
    s = s
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ی', 'ي')
        .replaceAll('ک', 'ك')
        .replaceAll('ة', 'ه')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ء', '');
    s = s.replaceAll(_notLetters, ' ');
    return s.replaceAll(_spaces, ' ').trim();
  }

  static List<String> words(String input) {
    final n = normalize(input);
    return n.isEmpty ? <String>[] : n.split(' ');
  }

  static List<String> displayWords(String input) {
    return input
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && normalize(w).isNotEmpty)
        .toList();
  }
}

enum WordStatus {
  /// لم تُقرأ بعد (أثناء التتبع الحي)
  pending,
  /// الكلمة الحالية التي يُتوقَّع نطقها الآن
  current,
  correct,
  near,
  wrong,
  missing,
}

class WordResult {
  const WordResult({
    required this.display,
    required this.expected,
    required this.status,
    this.heard,
  });

  final String display;
  final String expected;
  final WordStatus status;
  final String? heard;
}

class RecitationResult {
  const RecitationResult({
    required this.words,
    required this.extras,
    required this.correct,
    required this.near,
    required this.wrong,
    required this.missing,
    required this.score,
    this.lahn = const [],
  });

  /// ما يُشتبه فيه من اللحن الجلي (حروف وكلمات)
  final List<LahnFinding> lahn;

  final List<WordResult> words;
  final List<String> extras;
  final int correct;
  final int near;
  final int wrong;
  final int missing;
  final double score;

  bool get isPerfect => wrong == 0 && missing == 0 && extras.isEmpty && near == 0;
  bool get nothingHeard => correct == 0 && near == 0 && wrong == 0 && extras.isEmpty;
}

/// نتيجة التتبع الحي: مؤشر الكلمة الحالية + حالات الكلمات حتى الآن.
class LiveTrackResult {
  const LiveTrackResult({
    required this.words,
    required this.cursor,
    required this.matchedCount,
    required this.score,
  });

  final List<WordResult> words;

  /// فهرس الكلمة المتوقعة التالية (0..n). إن = n فقد اكتملت الآية تقريباً.
  final int cursor;
  final int matchedCount;
  final double score;

  bool get isComplete => cursor >= words.length && words.isNotEmpty;
}

class RecitationChecker {
  RecitationChecker._();

  static const double nearThreshold = 0.7;

  static double similarity(String a, String b) {
    if (a == b) return 1;
    final longest = a.length > b.length ? a.length : b.length;
    if (longest == 0) return 1;
    return 1 - _levenshtein(a, b) / longest;
  }

  static int _levenshtein(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;
    var prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final cur = List<int>.filled(b.length + 1, 0);
      cur[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        var best = prev[j - 1] + cost;
        if (prev[j] + 1 < best) best = prev[j] + 1;
        if (cur[j - 1] + 1 < best) best = cur[j - 1] + 1;
        cur[j] = best;
      }
      prev = cur;
    }
    return prev[b.length];
  }

  /// مقارنة نهائية كاملة بعد انتهاء التلاوة.
  static RecitationResult compare(String expectedText, String heardText) {
    final display = ArabicText.displayWords(expectedText);
    final exp = display.map(ArabicText.normalize).toList();
    final heard = ArabicText.words(heardText);
    final n = exp.length;
    final m = heard.length;

    const double del = 1, ins = 1, wrongSub = 1, nearSub = 0.5;
    double subCost(String e, String h) {
      if (e == h) return 0;
      return similarity(e, h) >= nearThreshold ? nearSub : wrongSub;
    }

    final dp = List.generate(n + 1, (_) => List<double>.filled(m + 1, 0));
    for (var i = 1; i <= n; i++) {
      dp[i][0] = i * del;
    }
    for (var j = 1; j <= m; j++) {
      dp[0][j] = j * ins;
    }
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final s = dp[i - 1][j - 1] + subCost(exp[i - 1], heard[j - 1]);
        final d = dp[i - 1][j] + del;
        final a = dp[i][j - 1] + ins;
        dp[i][j] = s <= d ? (s <= a ? s : a) : (d <= a ? d : a);
      }
    }

    final results = List<WordResult?>.filled(n, null);
    final extrasRev = <String>[];
    var i = n, j = m;
    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final sc = subCost(exp[i - 1], heard[j - 1]);
        if ((dp[i][j] - (dp[i - 1][j - 1] + sc)).abs() < 1e-9) {
          final status = sc == 0
              ? WordStatus.correct
              : (sc == nearSub ? WordStatus.near : WordStatus.wrong);
          results[i - 1] = WordResult(
            display: display[i - 1],
            expected: exp[i - 1],
            status: status,
            heard: status == WordStatus.correct ? null : heard[j - 1],
          );
          i--;
          j--;
          continue;
        }
      }
      if (i > 0 && (dp[i][j] - (dp[i - 1][j] + del)).abs() < 1e-9) {
        results[i - 1] = WordResult(
          display: display[i - 1],
          expected: exp[i - 1],
          status: WordStatus.missing,
        );
        i--;
        continue;
      }
      extrasRev.add(heard[j - 1]);
      j--;
    }

    final words = results.whereType<WordResult>().toList();
    final correct = words.where((w) => w.status == WordStatus.correct).length;
    final near = words.where((w) => w.status == WordStatus.near).length;
    final wrong = words.where((w) => w.status == WordStatus.wrong).length;
    final missing = words.where((w) => w.status == WordStatus.missing).length;
    final extras = extrasRev.reversed.toList();

    final denom = n + extras.length;
    final score = denom == 0 ? 0.0 : ((correct + 0.5 * near) / denom).clamp(0.0, 1.0);

    return RecitationResult(
      words: words,
      extras: extras,
      correct: correct,
      near: near,
      wrong: wrong,
      missing: missing,
      score: score,
      lahn: LahnJali.analyze(words, extras),
    );
  }

  /// تتبع حي تقدّمي: يطابق الكلمات المسموعة بالترتيب ويضع مؤشراً على الكلمة التالية.
  ///
  /// يستخدم نافذة أمامية صغيرة (مثل أنظمة التتبع المفتوحة) لتحمل أخطاء ASR.
  static LiveTrackResult trackLive(String expectedText, String heardText) {
    final display = ArabicText.displayWords(expectedText);
    final exp = display.map(ArabicText.normalize).toList();
    final heard = ArabicText.words(heardText);
    final n = exp.length;

    if (n == 0) {
      return const LiveTrackResult(words: [], cursor: 0, matchedCount: 0, score: 0);
    }

    // حالات أولية: الكل pending
    final statuses = List<WordStatus>.filled(n, WordStatus.pending);
    final heards = List<String?>.filled(n, null);

    var cursor = 0;
    var matched = 0;
    var correctN = 0;
    var nearN = 0;

    // نافذة بحث أمامية لتحمل إدخالات زائدة من ASR
    const lookAhead = 3;

    for (final h in heard) {
      if (cursor >= n) break;

      // ابحث أفضل تطابق في [cursor, cursor+lookAhead]
      var bestIdx = -1;
      var bestSim = -1.0;
      final end = (cursor + lookAhead + 1).clamp(0, n);
      for (var k = cursor; k < end; k++) {
        final sim = similarity(exp[k], h);
        if (sim > bestSim) {
          bestSim = sim;
          bestIdx = k;
        }
      }

      if (bestIdx < 0 || bestSim < 0.45) {
        // كلمة زائدة من ASR — نتجاهلها في التتبع الحي
        continue;
      }

      // كلمات بين cursor و bestIdx = متروكة
      for (var k = cursor; k < bestIdx; k++) {
        statuses[k] = WordStatus.missing;
      }

      if (bestSim >= 0.92) {
        statuses[bestIdx] = WordStatus.correct;
        correctN++;
      } else if (bestSim >= nearThreshold) {
        statuses[bestIdx] = WordStatus.near;
        heards[bestIdx] = h;
        nearN++;
      } else {
        statuses[bestIdx] = WordStatus.wrong;
        heards[bestIdx] = h;
      }
      matched++;
      cursor = bestIdx + 1;
    }

    // الكلمة التالية = current إن بقي شيء
    if (cursor < n) {
      statuses[cursor] = WordStatus.current;
    }

    final words = <WordResult>[
      for (var i = 0; i < n; i++)
        WordResult(
          display: display[i],
          expected: exp[i],
          status: statuses[i],
          heard: heards[i],
        ),
    ];

    final score = matched == 0 ? 0.0 : ((correctN + 0.5 * nearN) / n).clamp(0.0, 1.0);

    return LiveTrackResult(
      words: words,
      cursor: cursor,
      matchedCount: matched,
      score: score,
    );
  }
}
