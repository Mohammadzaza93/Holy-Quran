import 'package:flutter/material.dart';

import '../data/lessons.dart';
import '../models/lesson.dart';
import 'lesson_detail_screen.dart';

/// قائمة سلسلة شروح التجويد المتتابعة.
class LessonsListScreen extends StatelessWidget {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلسلة شروح التجويد'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'شروح أصلية متتابعة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'مستندة إلى محاضرات الشيخ أيمن رشدي سويد – كتاب النور المبين في تجويد القرآن الكريم.\n'
                    'يُفضَّل دراستها بالترتيب، ثم ربطها بأسئلة الاختبار.\n'
                    'تنبيه: هذه وسيلة مساعدة ولا تغني عن التلقي والمشافهة على مقرئ متقن.',
                    style: TextStyle(height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final lesson in tajweedLessons)
            _LessonTile(lesson: lesson),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonDetailScreen(lesson: lesson),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Text(
            '${lesson.order}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
        ),
        title: Text(
          lesson.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            lesson.summary,
            style: const TextStyle(height: 1.4),
          ),
        ),
        trailing: const Icon(Icons.chevron_left),
      ),
    );
  }
}
