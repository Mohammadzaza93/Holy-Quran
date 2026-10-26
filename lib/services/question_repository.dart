import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/question_bank.dart';
import '../models/question.dart';
import 'storage_service.dart';

/// مصدر الأسئلة: البنك المدمج + حزمة اختيارية من الإنترنت.
/// يحتفظ بنسخة مؤقتة لتقليل إعادة الدمج والفلترة في كل بناء للواجهة.
class QuestionRepository {
  static List<Question>? _allCache;
  static Map<QuizCategory, int>? _countCache;

  static void invalidate() {
    _allCache = null;
    _countCache = null;
  }

  static List<Question> all() {
    if (_allCache != null) return _allCache!;
    final remote = StorageService.instance.remoteQuestions();
    _allCache = remote.isEmpty
        ? builtInQuestions
        : List<Question>.unmodifiable([...builtInQuestions, ...remote]);
    return _allCache!;
  }

  static List<Question> byCategory(QuizCategory c) =>
      all().where((q) => q.category == c).toList(growable: false);

  static int countInCategory(QuizCategory c) {
    _countCache ??= {
      for (final cat in QuizCategory.values)
        cat: all().where((q) => q.category == cat).length,
    };
    return _countCache![c] ?? 0;
  }

  static List<Question> wrongOnes() {
    final ids = StorageService.instance.wrongIds;
    if (ids.isEmpty) return const [];
    return all().where((q) => ids.contains(q.id)).toList(growable: false);
  }

  static List<Question> dueOnes() {
    final ids = StorageService.instance.dueIds;
    if (ids.isEmpty) return const [];
    return all().where((q) => ids.contains(q.id)).toList(growable: false);
  }

  static int get remoteCount => StorageService.instance.remoteQuestions().length;

  static Future<String?> updateFromUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return 'أدخل رابطاً صحيحاً يبدأ بـ https';
    }
    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 15));
      if (r.statusCode != 200) return 'تعذّر التحميل (رمز ${r.statusCode})';
      final data = jsonDecode(utf8.decode(r.bodyBytes));
      final list = data is Map ? data['questions'] : data;
      if (list is! List) return 'صيغة الملف غير صحيحة';
      final parsed = list.map(Question.tryParse).whereType<Question>().toList();
      if (parsed.isEmpty) return 'لم أجد أسئلة صالحة في الملف';
      final store = StorageService.instance;
      await store.saveRemoteQuestions(parsed);
      await store.setRemoteUrl(url.trim());
      invalidate();
      return null;
    } catch (_) {
      return 'تعذّر الاتصال أو قراءة الملف';
    }
  }
}
