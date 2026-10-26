import 'package:flutter/material.dart';

import '../data/lessons.dart';
import '../models/lesson.dart';
import '../services/storage_service.dart';
import 'lesson_detail_screen.dart';

/// قائمة سلسلة شروح التجويد المتتابعة مع تتبع التقدم.
class LessonsListScreen extends StatefulWidget {
  const LessonsListScreen({super.key});

  @override
  State<LessonsListScreen> createState() => _LessonsListScreenState();
}

class _LessonsListScreenState extends State<LessonsListScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = StorageService.instance;
    final total = tajweedLessons.length;
    final read = store.readLessonsCount;
    final progress = total == 0 ? 0.0 : read / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلسلة شروح التجويد'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'شروح أصلية متتابعة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'مستندة إلى محاضرات الشيخ أيمن رشدي سويد – كتاب النور المبين في تجويد القرآن الكريم.\n'
                    'يُفضَّل دراستها بالترتيب. تنبيه: هذه وسيلة مساعدة ولا تغني عن التلقي والمشافهة.',
                    style: TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'تقدمك: $read من $total درسًا',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final lesson in tajweedLessons)
            _LessonTile(
              lesson: lesson,
              isRead: store.isLessonRead(lesson.id),
              onOpened: () => setState(() {}),
            ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.isRead,
    required this.onOpened,
  });

  final Lesson lesson;
  final bool isRead;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LessonDetailScreen(lesson: lesson),
            ),
          );
          onOpened();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isRead ? scheme.primary : scheme.primaryContainer,
          child: isRead
              ? Icon(Icons.check, color: scheme.onPrimary, size: 22)
              : Text(
                  '${lesson.order}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
        ),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isRead ? scheme.onSurface.withValues(alpha: 0.75) : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            lesson.summary,
            style: const TextStyle(height: 1.4),
          ),
        ),
        trailing: isRead
            ? Icon(Icons.done_all, color: scheme.primary, size: 20)
            : const Icon(Icons.chevron_left),
      ),
    );
  }
}
