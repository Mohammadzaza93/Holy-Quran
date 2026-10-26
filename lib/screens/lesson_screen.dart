import 'dart:math';

import 'package:flutter/material.dart';

import '../data/book_reference.dart';
import '../data/lessons.dart';
import '../data/surahs.dart';
import '../models/lesson.dart';
import '../services/question_repository.dart';
import '../services/storage_service.dart';
import 'quiz_screen.dart';
import 'reference_screen.dart';

/// عرض درس واحد، مع ذكر المرجع وأرقام الصفحات، وأزرار للتنقل والاختبار.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.index});

  /// ترتيب الدرس داخل [allLessons]
  final int index;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Lesson get _lesson => allLessons[widget.index];
  bool get _hasPrev => widget.index > 0;
  bool get _hasNext => widget.index < allLessons.length - 1;

  bool get _read => StorageService.instance.isLessonRead(_lesson.id);

  Future<void> _toggleRead() async {
    await StorageService.instance.setLessonRead(_lesson.id, !_read);
    if (mounted) setState(() {});
  }

  void _go(int delta) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LessonScreen(index: widget.index + delta)),
    );
  }

  void _quiz() {
    final c = _lesson.category;
    if (c == null) return;
    final pool = List.of(QuestionRepository.byCategory(c))..shuffle(Random());
    if (pool.isEmpty) return;
    final picked = pool.length > 10 ? pool.sublist(0, 10) : pool;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(title: 'اختبار: ${c.title}', questions: picked),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('الدرس ${widget.index + 1} من ${allLessons.length}'),
        actions: [
          IconButton(
            tooltip: 'عن المرجع',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReferenceScreen())),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              lesson.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.5),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.menu_book, size: 16),
                  label: Text('الكتاب: ص ${lesson.pages}'),
                ),
                Chip(visualDensity: VisualDensity.compact, label: Text(lesson.part)),
              ],
            ),
            for (final s in lesson.sections) _section(s, scheme),
            const Divider(height: 36),
            _referenceFooter(lesson, scheme),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _toggleRead,
              icon: Icon(_read ? Icons.check_circle : Icons.check_circle_outline),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_read ? 'تم إنهاء الدرس (اضغط للإلغاء)' : 'أنهيت هذا الدرس'),
              ),
            ),
            if (lesson.category != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _quiz,
                icon: const Icon(Icons.quiz),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text('اختبرني في ${lesson.category!.title}'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _hasPrev ? () => _go(-1) : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('الدرس السابق'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _hasNext ? () => _go(1) : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('الدرس التالي'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _referenceFooter(Lesson lesson, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EDE0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            BookReference.citation(lesson.pages),
            style: const TextStyle(fontSize: 13.5, height: 1.7, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'الدرس ملخص بصياغة التطبيق وليس نقلاً حرفياً؛ فراجع الكتاب للتفصيل، وتلقَّ التجويد من معلّم متقن.',
            style: TextStyle(fontSize: 12.5, height: 1.7, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _section(LessonSection s, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.heading,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: scheme.primary, height: 1.6),
          ),
          const SizedBox(height: 6),
          for (final p in s.body)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(p, style: const TextStyle(fontSize: 16.5, height: 1.95)),
            ),
          for (final p in s.points)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 9, left: 8),
                    child: Icon(Icons.circle, size: 7, color: scheme.primary),
                  ),
                  Expanded(
                    child: Text(p, style: const TextStyle(fontSize: 16.5, height: 1.9)),
                  ),
                ],
              ),
            ),
          for (final e in s.examples) _example(e, scheme),
          if (s.quote != null) _quote(s.quote!, s.quoteSource, scheme),
        ],
      ),
    );
  }

  Widget _example(LessonExample e, ColorScheme scheme) {
    final hasRef = e.surah != null && e.ayah != null;
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD9C79A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.phrase, style: const TextStyle(fontSize: 22, height: 2, color: Color(0xFF0B3D2E))),
          Text(
            hasRef ? '${e.note}  •  سورة ${surahName(e.surah!)} - الآية ${arabicDigits(e.ayah!)}' : e.note,
            style: TextStyle(fontSize: 13, color: scheme.outline, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _quote(String text, String? source, ColorScheme scheme) {
    // ملاحظة: لا نجمع borderRadius مع حد غير متساوي الجوانب (يسبب استثناءً في Flutter)،
    // لذلك نقصّ الزوايا بـ ClipRRect ونرسم الشريط الجانبي بالحد وحده.
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: scheme.secondaryContainer.withAlpha(110),
            border: BorderDirectional(
              start: BorderSide(color: scheme.secondary, width: 4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: const TextStyle(fontSize: 18, height: 2.0)),
              if (source != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('— $source', style: TextStyle(fontSize: 13, color: scheme.outline)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
