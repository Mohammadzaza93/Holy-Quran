import 'package:flutter/material.dart';

import '../data/lessons.dart';
import '../models/lesson.dart';

/// شاشة عرض درس واحد من سلسلة الشروح.
class LessonDetailScreen extends StatelessWidget {
  const LessonDetailScreen({super.key, required this.lesson});

  final Lesson lesson;

  void _goTo(BuildContext context, int order) {
    final next = getLessonByOrder(order);
    if (next == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(lesson: next),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPrev = lesson.order > 1;
    final hasNext = lesson.order < tajweedLessons.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('الدرس ${lesson.order}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            lesson.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            lesson.summary,
            style: TextStyle(
              fontSize: 15,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          SelectableText(
            lesson.content,
            style: const TextStyle(
              fontSize: 17,
              height: 1.85,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 28),
          // أزرار التنقل بين الدروس
          Row(
            children: [
              if (hasPrev)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goTo(context, lesson.order - 1),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('الدرس السابق'),
                  ),
                ),
              if (hasPrev && hasNext) const SizedBox(width: 12),
              if (hasNext)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _goTo(context, lesson.order + 1),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('الدرس التالي'),
                  ),
                ),
            ],
          ),
          if (!hasNext) ...[
            const SizedBox(height: 16),
            Card(
              color: scheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'أنهيت سلسلة الشروح الحالية.\n'
                  'يُفضَّل الآن العودة إلى الاختبارات ومراجعة الأقسام المرتبطة (مخارج، صفات، تفخيم وترقيق...).',
                  style: TextStyle(height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
