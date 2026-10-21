import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/question.dart';

/// تخزين محلي (يعمل دون اتصال): التقدم، الأخطاء، الإعدادات، الأسئلة المحمّلة، نصوص الآيات.
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

  // ───────── الإعدادات ─────────
  static const defaultReciter = 'Alafasy_128kbps';

  String get reciter => _p.getString('reciter') ?? defaultReciter;
  Future<void> setReciter(String v) => _p.setString('reciter', v);

  String get remoteUrl => _p.getString('remote_url') ?? '';
  Future<void> setRemoteUrl(String v) => _p.setString('remote_url', v);

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
