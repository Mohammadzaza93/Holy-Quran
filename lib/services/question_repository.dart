import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/question_bank.dart';
import '../models/question.dart';
import 'storage_service.dart';

/// مصدر الأسئلة: البنك المدمج (دون اتصال) + حزمة اختيارية تُحدَّث من الإنترنت.
class QuestionRepository {
  static List<Question> all() =>
      [...builtInQuestions, ...StorageService.instance.remoteQuestions()];

  static List<Question> byCategory(QuizCategory c) =>
      all().where((q) => q.category == c).toList();

  static List<Question> wrongOnes() {
    final ids = StorageService.instance.wrongIds;
    return all().where((q) => ids.contains(q.id)).toList();
  }

  static int get remoteCount => StorageService.instance.remoteQuestions().length;

  /// يحمّل حزمة أسئلة من رابط JSON ويحفظها محلياً.
  /// الصيغة: {"questions": [ {category, text, correct, wrong:[...], explanation, phrase?, surah?, ayah?} ]}
  /// يعيد null عند النجاح، أو رسالة الخطأ.
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
      return null;
    } catch (_) {
      return 'تعذّر الاتصال أو قراءة الملف';
    }
  }
}
