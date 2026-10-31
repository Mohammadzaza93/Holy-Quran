import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/lesson_quizzes.dart';
import '../data/lessons.dart';
import '../models/lesson.dart';
import '../services/storage_service.dart';
import 'quiz_screen.dart';

/// قائمة حلقات شرح التجويد المصور + اختبار لكل حلقة.
class LessonsListScreen extends StatefulWidget {
  const LessonsListScreen({super.key});

  @override
  State<LessonsListScreen> createState() => _LessonsListScreenState();
}

class _LessonsListScreenState extends State<LessonsListScreen> {
  Future<void> _openLesson(Lesson lesson) async {
    final store = StorageService.instance;
    await store.markLessonRead(lesson.id);

    final uri = Uri.parse(lesson.youtubeUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح يوتيوب. تأكد من تثبيت التطبيق أو المتصفح.'),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _startQuiz(Lesson lesson) async {
    final questions = questionsForLesson(lesson.id);
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يوجد اختبار لهذه الحلقة بعد.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          title: 'اختبار · حلقة ${lesson.order}',
          questions: questions,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openPlaylist() async {
    final uri = Uri.parse(Lesson.playlistUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final store = StorageService.instance;
    final total = tajweedLessons.length;
    final read = store.readLessonsCount;
    final progress = total == 0 ? 0.0 : read / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('شرح التجويد المصور'),
        actions: [
          IconButton(
            tooltip: 'فتح القائمة كاملة على يوتيوب',
            icon: const Icon(Icons.playlist_play),
            onPressed: _openPlaylist,
          ),
        ],
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
                    'منهج مقترح',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Lesson.attribution,
                    style: const TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '1) شاهد الحلقة على يوتيوب\n'
                    '2) ارجع للتطبيق وابدأ اختبار الحلقة\n'
                    '3) راجع الشرح عند الخطأ ثم انتقل للتالية',
                    style: TextStyle(height: 1.65, fontSize: 13.5),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'تقدم المشاهدة: $read من $total',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _openPlaylist,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('قائمة التشغيل كاملة'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final lesson in tajweedLessons)
            _LessonCard(
              lesson: lesson,
              isRead: store.isLessonRead(lesson.id),
              quizCount: lessonQuizCount(lesson.id),
              onWatch: () => _openLesson(lesson),
              onQuiz: () => _startQuiz(lesson),
            ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.isRead,
    required this.quizCount,
    required this.onWatch,
    required this.onQuiz,
  });

  final Lesson lesson;
  final bool isRead;
  final int quizCount;
  final VoidCallback onWatch;
  final VoidCallback onQuiz;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor:
                      isRead ? scheme.primary : scheme.primaryContainer,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lesson.summary,
                        style: TextStyle(
                          height: 1.4,
                          fontSize: 12.5,
                          color: scheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onWatch,
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: const Text('مشاهدة'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: quizCount == 0 ? null : onQuiz,
                    icon: const Icon(Icons.quiz_outlined, size: 20),
                    label: Text(
                      quizCount == 0 ? 'قريباً' : 'اختبار ($quizCount)',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
