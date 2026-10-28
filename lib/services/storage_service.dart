import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';
import 'spaced_repetition.dart';

/// تخزين محلي مع إشعار المستمعين عند تغيّر البيانات.
class StorageService extends ChangeNotifier {
  StorageService._(this._p);

  final SharedPreferences _p;
  static late StorageService instance;

  static Future<void> init() async {
    instance = StorageService._(await SharedPreferences.getInstance());
  }

  void _notify() => notifyListeners();

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
    await _srsUpdate(q.id, isCorrect);
    await _bumpDailyQuiz();
    _notify();
  }

  // ───────── التكرار المتباعد ─────────
  static const _srsKey = 'srs_v1';

  Map<String, SrsEntry> get srsEntries {
    final raw = _p.getString(_srsKey);
    if (raw == null) return {};
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, SrsEntry>{};
      m.forEach((k, v) {
        final e = SrsEntry.fromJson(v);
        if (e != null) out[k] = e;
      });
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> _srsUpdate(String id, bool correct) async {
    final next = SpacedRepetition.update(
      srsEntries,
      id,
      correct,
      SpacedRepetition.dayNumber(DateTime.now()),
    );
    await _p.setString(
      _srsKey,
      jsonEncode(next.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  Set<String> get dueIds =>
      SpacedRepetition.dueIds(srsEntries, SpacedRepetition.dayNumber(DateTime.now()));

  int get scheduledCount => srsEntries.length;

  Set<String> get wrongIds => (_p.getStringList('wrong_ids') ?? <String>[]).toSet();

  Future<void> resetProgress() async {
    for (final c in QuizCategory.values) {
      await _p.remove('ans_${c.name}');
      await _p.remove('cor_${c.name}');
    }
    await _p.remove('wrong_ids');
    await _p.remove(_srsKey);
    _notify();
  }

  Future<void> clearQuizProgress() => resetProgress();

  // ───────── تقدم حلقات يوتيوب ─────────
  static const _lessonReadKey = 'lesson_read_ids';

  Set<String> get readLessonIds =>
      (_p.getStringList(_lessonReadKey) ?? <String>[]).toSet();

  bool isLessonRead(String lessonId) => readLessonIds.contains(lessonId);

  Future<void> markLessonRead(String lessonId) async {
    final ids = readLessonIds;
    if (ids.contains(lessonId)) return;
    ids.add(lessonId);
    await _p.setStringList(_lessonReadKey, ids.toList());
    _notify();
  }

  Future<void> markLessonUnread(String lessonId) async {
    final ids = readLessonIds;
    if (!ids.remove(lessonId)) return;
    await _p.setStringList(_lessonReadKey, ids.toList());
    _notify();
  }

  int get readLessonsCount => readLessonIds.length;

  Future<void> resetLessonProgress() async {
    await _p.remove(_lessonReadKey);
    _notify();
  }

  Future<void> clearLessonProgress() => resetLessonProgress();

  // ───────── الإعدادات ─────────
  static const defaultReciter = 'Alafasy_128kbps';

  String get reciter => _p.getString('reciter') ?? defaultReciter;
  Future<void> setReciter(String v) async {
    await _p.setString('reciter', v);
    _notify();
  }

  String get remoteUrl => _p.getString('remote_url') ?? '';
  Future<void> setRemoteUrl(String v) => _p.setString('remote_url', v);

  bool get onDeviceSpeech => _p.getBool('speech_on_device') ?? false;
  Future<void> setOnDeviceSpeech(bool v) async {
    await _p.setBool('speech_on_device', v);
    _notify();
  }

  String get themeModeName => _p.getString('theme_mode') ?? 'system';

  ThemeMode get themeMode {
    switch (themeModeName) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeModeName(String name) async {
    await _p.setString('theme_mode', name);
    _notify();
  }

  bool get onboardingDone => _p.getBool('onboarding_done') ?? false;

  Future<void> setOnboardingDone(bool v) async {
    await _p.setBool('onboarding_done', v);
    _notify();
  }

  // ───────── هدف يومي ─────────
  static const dailyQuizGoal = 10;

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  int get dailyQuizCount {
    if (_p.getString('daily_quiz_day') != _todayKey) return 0;
    return _p.getInt('daily_quiz_count') ?? 0;
  }

  Future<void> _bumpDailyQuiz() async {
    final key = _todayKey;
    if (_p.getString('daily_quiz_day') != key) {
      await _p.setString('daily_quiz_day', key);
      await _p.setInt('daily_quiz_count', 1);
    } else {
      await _p.setInt('daily_quiz_count', dailyQuizCount + 1);
    }
  }

  // ───────── سجل أخطاء محلي ─────────
  static const _errLogKey = 'local_error_log';

  List<String> get localErrorLog => _p.getStringList(_errLogKey) ?? const [];

  Future<void> logLocalError(String message) async {
    final list = localErrorLog.toList();
    final stamp = DateTime.now().toIso8601String();
    list.insert(0, '[$stamp] $message');
    while (list.length > 30) {
      list.removeLast();
    }
    await _p.setStringList(_errLogKey, list);
  }

  Future<void> clearLocalErrorLog() async {
    await _p.remove(_errLogKey);
    _notify();
  }

  // ───────── القراءة والتصحيح الصوتي ─────────
  double? ayahBestScore(int surah, int ayah) => _p.getDouble('read_$surah:$ayah');

  Future<void> saveAyahScore(int surah, int ayah, double score) async {
    final best = ayahBestScore(surah, ayah);
    if (best == null || score > best) {
      await _p.setDouble('read_$surah:$ayah', score);
    }
    await _p.setInt('read_attempts', readAttempts + 1);
    _notify();
  }

  int get readAttempts => _p.getInt('read_attempts') ?? 0;

  int masteredAyat(int surah, int ayahCount) {
    var n = 0;
    for (var a = 1; a <= ayahCount; a++) {
      if ((ayahBestScore(surah, a) ?? 0) >= 0.9) n++;
    }
    return n;
  }

  (int, int)? get lastPosition {
    final raw = _p.getString('last_pos');
    if (raw == null) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final s = int.tryParse(parts[0]);
    final a = int.tryParse(parts[1]);
    return (s == null || a == null) ? null : (s, a);
  }

  Future<void> saveLastPosition(int surah, int ayah) =>
      _p.setString('last_pos', '$surah:$ayah');

  Future<void> resetReading() async {
    for (final k in _p.getKeys().where((k) => k.startsWith('read_') || k == 'last_pos').toList()) {
      await _p.remove(k);
    }
    _notify();
  }

  // ───────── إشارات مرجعية ─────────
  static const _bookmarkKey = 'ayah_bookmarks';

  Set<String> get ayahBookmarks =>
      (_p.getStringList(_bookmarkKey) ?? <String>[]).toSet();

  bool isAyahBookmarked(int surah, int ayah) =>
      ayahBookmarks.contains('$surah:$ayah');

  Future<void> addAyahBookmark(int surah, int ayah) async {
    final ids = ayahBookmarks;
    final k = '$surah:$ayah';
    if (ids.contains(k)) return;
    ids.add(k);
    await _p.setStringList(_bookmarkKey, ids.toList());
    _notify();
  }

  Future<void> removeAyahBookmark(int surah, int ayah) async {
    final ids = ayahBookmarks;
    if (!ids.remove('$surah:$ayah')) return;
    await _p.setStringList(_bookmarkKey, ids.toList());
    _notify();
  }

  // ───────── حزمة الأسئلة المحمّلة ─────────
  List<Question>? _remoteCache;

  List<Question> remoteQuestions() {
    if (_remoteCache != null) return _remoteCache!;
    final raw = _p.getString('remote_pack');
    if (raw == null || raw.isEmpty) {
      _remoteCache = const [];
      return _remoteCache!;
    }
    try {
      final data = jsonDecode(raw);
      if (data is! List) {
        _remoteCache = const [];
        return _remoteCache!;
      }
      _remoteCache =
          data.map(Question.tryParse).whereType<Question>().toList(growable: false);
      return _remoteCache!;
    } catch (_) {
      _remoteCache = const [];
      return _remoteCache!;
    }
  }

  Future<void> saveRemoteQuestions(List<Question> questions) async {
    await _p.setString(
      'remote_pack',
      jsonEncode(questions.map((q) => q.toJson()).toList()),
    );
    _remoteCache = List.unmodifiable(questions);
    _notify();
  }

  Future<void> clearRemoteQuestions() async {
    await _p.remove('remote_pack');
    _remoteCache = const [];
    _notify();
  }

  // ───────── نصوص الآيات المخزنة ─────────
  String? cachedAyah(int surah, int ayah) => _p.getString('ayah_$surah:$ayah');
  Future<void> cacheAyah(int surah, int ayah, String text) =>
      _p.setString('ayah_$surah:$ayah', text);
}
