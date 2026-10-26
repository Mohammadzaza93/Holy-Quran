import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/lessons.dart';
import '../models/lesson.dart';
import '../services/storage_service.dart';

/// قائمة حلقات شرح التجويد المصور (يوتيوب — الشيخ أيمن سويد).
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
        const SnackBar(content: Text('تعذّر فتح يوتيوب. تأكد من تثبيت التطبيق أو المتصفح.')),
      );
    }
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
                    'شرح كتاب التجويد المصور',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Lesson.attribution,
                    style: const TextStyle(height: 1.6),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اضغط أي حلقة لفتحها مباشرة على يوتيوب. يُفضَّل المشاهدة بالترتيب.',
                    style: TextStyle(height: 1.5, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'تقدمك: $read من $total حلقة',
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
                    label: const Text('فتح قائمة التشغيل كاملة'),
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
              onTap: () => _openLesson(lesson),
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
    required this.onTap,
  });

  final Lesson lesson;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
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
          child: Text(lesson.summary, style: const TextStyle(height: 1.4)),
        ),
        trailing: Icon(
          Icons.play_circle_outline,
          color: scheme.primary,
          size: 28,
        ),
      ),
    );
  }
}
