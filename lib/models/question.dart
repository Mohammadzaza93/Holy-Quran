import 'package:flutter/material.dart';

/// تصنيفات الأسئلة
enum QuizCategory {
  makharij('مخارج الحروف', Icons.record_voice_over),
  sifat('صفات الحروف', Icons.graphic_eq),
  noon('النون الساكنة والتنوين', Icons.hearing),
  meem('الميم الساكنة', Icons.mic),
  madd('أحكام المدود', Icons.swap_horiz),
  misc('التفخيم والترقيق والقلقلة والوقف', Icons.tune),
  hafs('خصائص رواية حفص عن عاصم', Icons.menu_book);

  const QuizCategory(this.title, this.icon);
  final String title;
  final IconData icon;

  static QuizCategory? fromName(String? name) {
    for (final c in QuizCategory.values) {
      if (c.name == name) return c;
    }
    return null;
  }
}

/// سؤال اختيار من متعدد.
/// [correct] هي الإجابة الصحيحة و[wrong] هي المشتتات، ويتم خلط الخيارات وقت العرض.
class Question {
  const Question({
    required this.id,
    required this.category,
    required this.text,
    required this.correct,
    required this.wrong,
    required this.explanation,
    this.phrase,
    this.surah,
    this.ayah,
  });

  final String id;
  final QuizCategory category;
  final String text;
  final String correct;
  final List<String> wrong;
  final String explanation;

  /// كلمة أو عبارة قرآنية يدور حولها السؤال (اختياري)
  final String? phrase;

  /// موضع العبارة في المصحف (اختياري) ويُستخدم لعرض الآية كاملة وتشغيل صوتها
  final int? surah;
  final int? ayah;

  bool get hasAyahRef => surah != null && ayah != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.name,
        'text': text,
        'correct': correct,
        'wrong': wrong,
        'explanation': explanation,
        if (phrase != null) 'phrase': phrase,
        if (surah != null) 'surah': surah,
        if (ayah != null) 'ayah': ayah,
      };

  /// يحاول قراءة سؤال من JSON ويعيد null إن كان غير صالح.
  static Question? tryParse(dynamic e) {
    try {
      if (e is! Map) return null;
      final category = QuizCategory.fromName(e['category'] as String?);
      final text = e['text'] as String?;
      final correct = e['correct'] as String?;
      final wrongRaw = e['wrong'];
      if (category == null || text == null || correct == null) return null;
      if (wrongRaw is! List) return null;
      final wrong = wrongRaw.whereType<String>().toList();
      if (wrong.length < 2 || wrong.contains(correct)) return null;
      var id = (e['id'] ?? '').toString();
      if (id.isEmpty) id = text.hashCode.toString();
      if (!id.startsWith('r-')) id = 'r-$id';
      return Question(
        id: id,
        category: category,
        text: text,
        correct: correct,
        wrong: wrong,
        explanation: (e['explanation'] ?? '').toString(),
        phrase: e['phrase'] as String?,
        surah: e['surah'] as int?,
        ayah: e['ayah'] as int?,
      );
    } catch (_) {
      return null;
    }
  }
}
