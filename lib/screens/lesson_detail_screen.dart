import 'package:flutter/material.dart';

import '../data/lessons.dart';
import '../models/lesson.dart';
import '../services/storage_service.dart';

/// شاشة عرض درس واحد من سلسلة الشروح مع حفظ التقدم.
class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late bool _isRead;

  @override
  void initState() {
    super.initState();
    _isRead = StorageService.instance.isLessonRead(widget.lesson.id);
    // اعتبار فتح الدرس قراءةً تلقائيًا
    if (!_isRead) {
      StorageService.instance.markLessonRead(widget.lesson.id).then((_) {
        if (mounted) setState(() => _isRead = true);
      });
    }
  }

  void _goTo(int order) {
    final next = getLessonByOrder(order);
    if (next == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LessonDetailScreen(lesson: next),
      ),
    );
  }

  Future<void> _toggleRead() async {
    final store = StorageService.instance;
    if (_isRead) {
      await store.markLessonUnread(widget.lesson.id);
      if (mounted) setState(() => _isRead = false);
    } else {
      await store.markLessonRead(widget.lesson.id);
      if (mounted) setState(() => _isRead = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lesson = widget.lesson;
    final hasPrev = lesson.order > 1;
    final hasNext = lesson.order < tajweedLessons.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('الدرس ${lesson.order}'),
        actions: [
          IconButton(
            tooltip: _isRead ? 'إلغاء تعليم كمقروء' : 'تعليم كمقروء',
            icon: Icon(_isRead ? Icons.check_circle : Icons.check_circle_outline),
            onPressed: _toggleRead,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
              if (_isRead)
                Chip(
                  avatar: Icon(Icons.check, size: 18, color: scheme.primary),
                  label: const Text('مقروء'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
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
          Row(
            children: [
              if (hasPrev)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goTo(lesson.order - 1),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('الدرس السابق'),
                  ),
                ),
              if (hasPrev && hasNext) const SizedBox(width: 12),
              if (hasNext)
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _goTo(lesson.order + 1),
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
                  'يُفضَّل الآن العودة إلى الاختبارات ومراجعة الأقسام المرتبطة.',
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
