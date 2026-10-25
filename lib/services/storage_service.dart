import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

/// تخزين محلي (يعمل دون اتصال): التقدم، الأخطاء، الإعدادات، الأسئلة المحمّلة، نصوص الآيات، تقدم الدروس.
class StorageService {
  StorageService._(this._p);

  final SharedPreferences _p;
  static late StorageService instance;

  static Future<void> init() async {
    instance = StorageService._(await SharedPreferences.getInstance());
  }

  // ───────── التقدم ─────────
  int answered(QuizCategory c) => _p.getInt('ans_${c.name}') ?? 0;
  int correctCount(QuizCategory c) => _p.getInt('cor_${c.name}') ?? 0;

  int get totalAnswered =>
      QuizCategory.values.fold(0, (sum, c) => sum + answered(c));
  int get totalCorrect =>
      QuizCategory.values.fold(0, (sum, c) => sum + correctCount(c));

  double accuracy(QuizCategory c) {
    final a = answered(c);
    return a == 0 ? 0 : correctCount(c) / a;
  }

  Future<void> recordAnswer(Question q, bool isCorrect) async {
    final c = q.category;
    await _p.setInt('ans_${c.name}', answered(c) + 1);
    if (isCorrect) {
      await _p.setInt('cor_${c.name}', correctCount(c) + 1);
    }
    final wrong = wrongIds;
    if (isCorrect) {
      wrong.remove(q.id);
    } else {
      wrong.add(q.id);
    }
    await _p.setStringList('wrong_ids', wrong.toList());
  }

  Set<String> get wrongIds => (_p.getStringList('wrong_ids') ?? <String>[]).toSet();

  Future<void> resetProgress() async {
    for (final c in QuizCategory.values) {
      await _p.remove('ans_${c.name}');
      await _p.remove('cor_${c.name}');
    }
    await _p.remove('wrong_ids');
  }

  // ───────── تقدم قراءة الدروس ─────────

  static const _lessonReadKey = 'lesson_read_ids';

  /// مجموعة معرّفات الدروس التي قرأها المستخدم
  Set<String> get readLessonIds =>
      (_p.getStringList(_lessonReadKey) ?? <String>[]).toSet();

  bool isLessonRead(String lessonId) => readLessonIds.contains(lessonId);

  Future<void> markLessonRead(String lessonId) async {
    final ids = readLessonIds;
    if (ids.contains(lessonId)) return;
    ids.add(lessonId);
    await _p.setStringList(_lessonReadKey, ids.toList());
  }

  Future<void> markLessonUnread(String lessonId) async {
    final ids = readLessonIds;
    if (!ids.remove(lessonId)) return;
    await _p.setStringList(_lessonReadKey, ids.toList());
  }

  int get readLessonsCount => readLessonIds.length;

  Future<void> resetLessonProgress() async {
    await _p.remove(_lessonReadKey);
  }

  // ───────── الإعدادات ─────────
  static const defaultReciter = 'Alafasy_128kbps';

  String get reciter => _p.getString('reciter') ?? defaultReciter;
  Future<void> setReciter(String v) => _p.setString('reciter', v);

  String get remoteUrl => _p.getString('remote_url') ?? '';
  Future<void> setRemoteUrl(String v) => _p.setString('remote_url', v);

  // ───────── القراءة والتصحيح الصوتي ─────────

  /// استخدام التعرف الصوتي على الجهاز (قد يعمل دون إنترنت إن توفرت حزمة اللغة العربية)
  bool get onDeviceSpeech => _p.getBool('speech_on_device') ?? false;
  Future<void> setOnDeviceSpeech(bool v) => _p.setBool('speech_on_device', v);

  /// أفضل نتيجة (0..1) حققها المستخدم في آية، أو null إن لم يقرأها
  double? ayahBestScore(int surah, int ayah) => _p.getDouble('read_$surah:$ayah');

  Future<void> saveAyahScore(int surah, int ayah, double score) async {
    final best = ayahBestScore(surah, ayah);
    if (best == null || score > best) {
      await _p.setDouble('read_$surah:$ayah', score);
    }
    await _p.setInt('read_attempts', readAttempts + 1);
  }

  int get readAttempts => _p.getInt('read_attempts') ?? 0;

  /// عدد آيات السورة التي أتقنها المستخدم (نتيجة 90% فأكثر)
  int masteredAyat(int surah, int ayahCount) {
    var n = 0;
    for (var a = 1; a <= ayahCount; a++) {
      if ((ayahBestScore(surah, a) ?? 0) >= 0.9) n++;
    }
    return n;
  }

  /// آخر موضع قراءة (سورة، آية) لاستئناف القراءة
  (int, int)? get lastPosition {
    final raw = _p.getString('last_pos');
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final s = int.tryParse(parts[0]);
    final a = int.tryParse(parts[1]);
    return (s == null || a == null) ? null : (s, a);
  }

  Future<void> saveLastPosition(int surah, int ayah) => _p.setString('last_pos', '$surah:$ayah');

  Future<void> resetReading() async {
    for (final k in _p.getKeys().where((k) => k.startsWith('read_') || k == 'last_pos').toList()) {
      await _p.remove(k);
    }
  }

  // ───────── حزمة الأسئلة المحمّلة من الإنترنت ─────────
  List<Question> remoteQuestions() {
    final raw = _p.getString('remote_pack');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final data = jsonDecode(raw);
      if (data is! List) return const [];
      return data.map(Question.tryParse).whereType<Question>().toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveRemoteQuestions(List<Question> questions) =>
      _p.setString('remote_pack', jsonEncode(questions.map((q) => q.toJson()).toList()));

  Future<void> clearRemoteQuestions() => _p.remove('remote_pack');

  // ───────── نصوص الآيات المخزنة ─────────
  String? cachedAyah(int surah, int ayah) => _p.getString('ayah_$surah:$ayah');
  Future<void> cacheAyah(int surah, int ayah, String text) =>
      _p.setString('ayah_$surah:$ayah', text);
}
