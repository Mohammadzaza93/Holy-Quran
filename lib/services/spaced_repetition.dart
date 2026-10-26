/// منطق التكرار المتباعد (بسيط على نمط لايتنر) للأسئلة التي أخطأ فيها المتعلّم.
///
/// الجدولة: بعد الخطأ يُعاد السؤال بعد يوم، فإن أصاب فبعد ٣ أيام، فإن أصاب فبعد أسبوع،
/// فإن أصاب بعدها عُدّ متقَناً وخرج من الجدولة. أي خطأ يعيده إلى أول المراحل.
/// الدوال نقية (دون تخزين) لتسهيل الاختبار.
class SrsEntry {
  const SrsEntry({required this.box, required this.due});

  /// المرحلة (٠ = أول مراجعة)
  final int box;

  /// رقم اليوم (أيام منذ 1970-01-01) الذي يستحق فيه السؤال المراجعة
  final int due;

  Map<String, int> toJson() => {'b': box, 'd': due};

  static SrsEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final b = j['b'];
    final d = j['d'];
    if (b is! int || d is! int) return null;
    return SrsEntry(box: b, due: d);
  }
}

class SpacedRepetition {
  SpacedRepetition._();

  /// الفواصل بالأيام لكل مرحلة: يوم، ثلاثة أيام، أسبوع.
  static const List<int> intervals = [1, 3, 7];

  /// رقم اليوم المحلي (دون تأثر بتوقيت الصيف).
  static int dayNumber(DateTime now) =>
      DateTime.utc(now.year, now.month, now.day).difference(DateTime.utc(1970)).inDays;

  /// يعيد جدولة جديدة بعد الإجابة عن [id]. لا يعدّل [entries].
  static Map<String, SrsEntry> update(
    Map<String, SrsEntry> entries,
    String id,
    bool correct,
    int today,
  ) {
    final out = Map<String, SrsEntry>.of(entries);
    final cur = out[id];
    if (!correct) {
      out[id] = SrsEntry(box: 0, due: today + intervals[0]);
      return out;
    }
    if (cur == null) return out; // أصاب سؤالاً غير مجدول: لا شيء
    if (cur.due > today) return out; // لم يحن موعده بعد: لا يُحتسب تقدماً
    final next = cur.box + 1;
    if (next >= intervals.length) {
      out.remove(id); // أتقنه
    } else {
      out[id] = SrsEntry(box: next, due: today + intervals[next]);
    }
    return out;
  }

  /// معرّفات الأسئلة المستحقة اليوم أو المتأخرة.
  static Set<String> dueIds(Map<String, SrsEntry> entries, int today) => {
        for (final e in entries.entries)
          if (e.value.due <= today) e.key,
      };
}
